import os
import argparse
import numpy as np
import tifffile
import torch
import torch.nn as nn
import torch.nn.functional as F
from sklearn.metrics import confusion_matrix
from scipy import ndimage as ndi
from skimage.morphology import binary_closing, disk

# --- optional skimage imports for refinement ---
try:
    from skimage.segmentation import clear_border
    from skimage.morphology import remove_small_objects, remove_small_holes
    SKIMAGE_OK = True
except Exception as e:
    SKIMAGE_OK = False
    _SKERR = e

# ----------------------------
# 1. Model definition (same UNetSmall)
# ----------------------------

class ConvBlock(nn.Module):
    def __init__(self, in_c, out_c):
        super().__init__()
        self.net = nn.Sequential(
            nn.Conv2d(in_c, out_c, 3, padding=1), nn.ReLU(inplace=True),
            nn.Conv2d(out_c, out_c, 3, padding=1), nn.ReLU(inplace=True),
        )
    def forward(self, x):
        return self.net(x)

class UNetSmall(nn.Module):
    def __init__(self):
        super().__init__()
        self.down1 = ConvBlock(1, 32)
        self.pool1 = nn.MaxPool2d(2)
        self.down2 = ConvBlock(32, 64)
        self.pool2 = nn.MaxPool2d(2)
        self.down3 = ConvBlock(64, 128)
        self.pool3 = nn.MaxPool2d(2)

        self.bottleneck = ConvBlock(128, 256)

        self.up3 = nn.ConvTranspose2d(256, 128, 2, stride=2)
        self.dec3 = ConvBlock(256, 128)
        self.up2 = nn.ConvTranspose2d(128, 64, 2, stride=2)
        self.dec2 = ConvBlock(128, 64)
        self.up1 = nn.ConvTranspose2d(64, 32, 2, stride=2)
        self.dec1 = ConvBlock(64, 32)

        self.out_conv = nn.Conv2d(32, 1, 1)

    def forward(self, x):
        d1 = self.down1(x)
        p1 = self.pool1(d1)

        d2 = self.down2(p1)
        p2 = self.pool2(d2)

        d3 = self.down3(p2)
        p3 = self.pool3(d3)

        bn = self.bottleneck(p3)

        up3 = self.up3(bn)
        cat3 = torch.cat([up3, d3], dim=1)
        dec3 = self.dec3(cat3)

        up2 = self.up2(dec3)
        cat2 = torch.cat([up2, d2], dim=1)
        dec2 = self.dec2(cat2)

        up1 = self.up1(dec2)
        cat1 = torch.cat([up1, d1], dim=1)
        dec1 = self.dec1(cat1)

        out = self.out_conv(dec1)
        return out  # logits


# ----------------------------
# 2. Image/mask loading helpers
# ----------------------------

def load_and_prepare_image(img_path):
    """
    Load raw .tif image, convert to grayscale if needed,
    normalise to [0,1], return float32 (H,W).
    """
    arr = tifffile.imread(img_path).astype(np.float32)

    if arr.ndim == 3 and arr.shape[-1] == 3:      # RGB-like
        arr = arr.mean(axis=-1)
    else:
        arr = np.squeeze(arr)

    arr = (arr - arr.min()) / (arr.max() - arr.min() + 1e-8)
    return arr.astype(np.float32)


def load_mask_if_exists(mask_path):
    """
    Load a ground-truth mask for evaluation, if present.
    Returns binary mask float32 in {0,1} with shape (H,W).
    """
    m = tifffile.imread(mask_path).astype(np.float32)
    m = np.squeeze(m)
    if m.max() > 1:
        m = (m > 0).astype(np.float32)
    else:
        m = (m > 0.5).astype(np.float32)
    return m.astype(np.float32)


# ----------------------------
# 3. Tiled prediction on full-res image
# ----------------------------

@torch.no_grad()
def predict_full_image_unet(model, img_2d, patch_size, overlap, device):
    """
    Slide a window across the full image, run the model on patches,
    blend predictions, and return:
      - pred_mask: binary (0/1) uint8
      - prob_map: probability map [0,1] float32
    """
    model.eval()

    H, W = img_2d.shape
    logits_full = np.zeros((1, H, W), dtype=np.float32)
    count_full  = np.zeros((1, H, W), dtype=np.float32)

    step = patch_size - overlap
    if step <= 0:
        raise ValueError("overlap must be smaller than patch_size")

    for y in range(0, H, step):
        for x in range(0, W, step):
            patch = img_2d[y:y+patch_size, x:x+patch_size]

            # pad if patch hits bottom/right edge
            ph, pw = patch.shape
            if ph < patch_size or pw < patch_size:
                pad_y = patch_size - ph
                pad_x = patch_size - pw
                patch = np.pad(patch, ((0, pad_y), (0, pad_x)))

            # model expects [B,1,H,W]
            patch_t = torch.from_numpy(patch[None, None, ...]).float().to(device)
            logits_patch = model(patch_t).cpu().numpy()  # shape (1,1,H,W)
            logits_patch = logits_patch[0,0,:,:]         # (H,W)

            # only write back the unpadded region
            logits_full[:, y:y+ph, x:x+pw] += logits_patch[:ph,:pw]
            count_full [:, y:y+ph, x:x+pw] += 1.0

    # average overlapping logits
    logits_full /= np.maximum(count_full, 1e-8)

    # safe sigmoid: clip logits to avoid overflow in exp()
    probs_full = 1.0 / (1.0 + np.exp(-np.clip(logits_full, -50, 50)))
    pred_mask  = (probs_full > 0.5).astype(np.uint8)  # binary 0/1

    return pred_mask[0], probs_full[0].astype(np.float32)


# ----------------------------
# 4. Dice and IoU calculation
# ----------------------------

def compute_metrics(pred_mask, gt_mask):
    """
    pred_mask: uint8 {0,1}
    gt_mask: float32 {0,1}
    returns (IoU, Dice)
    """
    pred_flat = pred_mask.flatten().astype(np.uint8)
    gt_flat   = gt_mask.flatten().astype(np.uint8)

    tn, fp, fn, tp = confusion_matrix(
        gt_flat, pred_flat, labels=[0,1]
    ).ravel()

    iou  = tp / (tp + fp + fn) if (tp+fp+fn) != 0 else 0.0
    dice = (2*tp) / (2*tp + fp + fn) if (2*tp+fp+fn) != 0 else 0.0
    return iou, dice

# ----------------------------
# 4) Post-processing / refinement
# ----------------------------

def refine_mask(mask_bin_uint8,
                invert=False,
                do_clear_border=True,
                min_size=50,
                hole_area=50,
                fill_all_holes=False,
                closing_radius=0):
    """
    Post-process a binary mask.

    Parameters
    ----------
    mask_bin_uint8 : np.uint8 {0,1}
    invert         : bool
        Invert mask before refinement (useful if your target is the background/void).
    do_clear_border: bool
        Remove connected components touching the image border.
    min_size       : int
        Remove small objects smaller than this many pixels (0 to disable).
    hole_area      : int
        Fill holes smaller than this area (0 to disable).
    fill_all_holes : bool
        If True, fill *all* interior holes regardless of size (uses scipy.ndimage.binary_fill_holes).
    closing_radius : int
        If >0, apply morphological closing with a disk of this radius AFTER hole filling.
        Useful to seal narrow gaps and smooth boundaries.
    """
    if not SKIMAGE_OK:
        raise ImportError(
            f"scikit-image is required for refinement but not available: {_SKERR}\n"
            "Install with:  pip install scikit-image  OR  conda install scikit-image"
        )

    m = mask_bin_uint8.astype(np.uint8)

    # Optional invert (so "background" becomes foreground to process as objects)
    if invert:
        m = 1 - m

    m_bool = m.astype(bool)

    # Remove border-touching components
    if do_clear_border:
        m_bool = clear_border(m_bool)

    # Remove small objects
    if min_size and min_size > 0:
        m_bool = remove_small_objects(m_bool, min_size=int(min_size))

    # Hole filling
    if fill_all_holes:
        # Fill all internal cavities (no area limit)
        m_bool = ndi.binary_fill_holes(m_bool)
    elif hole_area and hole_area > 0:
        # Fill small holes up to the given area
        m_bool = remove_small_holes(m_bool, area_threshold=int(hole_area))

    # Optional morphological closing to seal narrow gaps and smooth edges
    if closing_radius and closing_radius > 0:
        selem = disk(int(closing_radius))
        m_bool = binary_closing(m_bool, selem)

    return m_bool.astype(np.uint8)

# ----------------------------
# 5. Main inference routine
# ----------------------------

def run_inference_on_folder(model_path, input_folder, output_folder,
                            patch_size=128, overlap=32,
                            evaluate=False, refine=True, invert=False,
                            min_size=50, hole_area=50,
                            no_clear_border=False,fill_all_holes=False,
                            closing_radius=0):
    """
    Runs UNet inference on a folder of .tif images and optionally refines the masks.

    Parameters
    ----------
    model_path : str
        Path to trained .pth file.
    input_folder : str
        Folder with test .tif images.
    output_folder : str
        Folder where output masks/prob maps will be saved.
    patch_size : int
        Size of each tile during inference.
    overlap : int
        Overlap between tiles (helps smooth seams).
    evaluate : bool
        Compute IoU/Dice if ground-truth masks exist.
    refine : bool
        Apply mask post-processing.
    invert : bool
        Invert mask before refinement.
    min_size : int
        Remove objects smaller than this size.
    hole_area : int
        Fill holes smaller than this area.
    no_clear_border : bool
        Skip removing border-touching objects.
    fill_all_holes : bool
        Fill all interior holes (overrides hole_area).
    closing_radius : int
        Morphological closing radius to seal gaps and smooth boundaries.
    """

    os.makedirs(output_folder, exist_ok=True)

    # load model
    device = "cuda" if torch.cuda.is_available() else "cpu"
    model = UNetSmall().to(device)
    state_dict = torch.load(model_path, map_location=device)
    model.load_state_dict(state_dict)
    model.eval()

    # list input .tif files
    test_files = [f for f in os.listdir(input_folder)
                  if f.lower().endswith((".tif", ".tiff"))]

    print(f"[INFO] Found {len(test_files)} .tif files in {input_folder}")

    results = []  # for metrics summary if evaluate=True

    for fname in test_files:
        fpath = os.path.join(input_folder, fname)
        base = fname
        base_lower = fname.lower()

        if base_lower.endswith(".tiff"):
            fnameWOExt = base[:-5]  # drop ".tiff"
        elif base_lower.endswith(".tif"):
            fnameWOExt= base[:-4]  # drop ".tif"
        else:
            fnameWOExt = base

        # skip any file that's clearly a mask already if we're evaluating
        if base_lower.endswith("_mask.tif") or "_mask" in base_lower:
            # don't run inference on the mask file itself
            continue

        print(f"[INFO] Processing {fname} ...")

        # load image and predict
        img_arr = load_and_prepare_image(fpath)
        pred_mask, prob_map = predict_full_image_unet(
            model,
            img_arr,
            patch_size=patch_size,
            overlap=overlap,
            device=device
        )

        # save outputs
        out_mask_path = os.path.join(output_folder, f"pred_mask_{fnameWOExt}.tif")
        out_prob_path = os.path.join(output_folder, f"pred_prob_{fnameWOExt}.tif")

        tifffile.imwrite(out_mask_path, (pred_mask * 255).astype(np.uint8))
        #tifffile.imwrite(out_prob_path, (prob_map * 255).astype(np.uint8))

        print(f"  -> saved {out_mask_path}")
        #print(f"  -> saved {out_prob_path}")

        # optional evaluation if ground truth exists
        if evaluate:
            # assume mask file is <original>_mask.tif or _Mask.tif
            # we remove ".tif"/".tiff" and append _mask.tif
            if base_lower.endswith(".tiff"):
                stem = base[:-5]  # drop ".tiff"
            elif base_lower.endswith(".tif"):
                stem = base[:-4]  # drop ".tif"
            else:
                stem = base

            # candidate mask names
            cand_masks = [
                stem + "_mask.tif",
                stem + "_Mask.tif",
                stem + "_mask.tiff",
                stem + "_Mask.tiff",
            ]

            gt_mask_path = None
            for cm in cand_masks:
                if os.path.exists(os.path.join(input_folder, cm)):
                    gt_mask_path = os.path.join(input_folder, cm)
                    break

            if gt_mask_path is not None:
                gt_mask = load_mask_if_exists(gt_mask_path)
                if gt_mask.shape != pred_mask.shape:
                    print(f"  [WARN] GT mask size mismatch for {fname}: {gt_mask.shape} vs {pred_mask.shape}")
                else:
                    iou, dice = compute_metrics(pred_mask, gt_mask)
                    results.append((fname, iou, dice))
                    print(f"  [METRICS] {fname}  IoU={iou:.4f}  Dice={dice:.4f}")
            else:
                print(f"  [INFO] No ground truth mask found for {fname}, skipping metrics.")

        # Refinement
        if refine:
            if not SKIMAGE_OK:
                raise ImportError(
                    "Refinement requested but scikit-image is not installed. "
                    "Install with: pip install scikit-image"
                )
            refined = refine_mask(
                pred_mask.astype(np.uint8),
                invert=invert,
                do_clear_border=(not no_clear_border),
                min_size=min_size,
                hole_area=hole_area
            )
            ref_mask_path = os.path.join(output_folder, f"pred_mask_{fnameWOExt}_refined.tif")
            tifffile.imwrite(ref_mask_path, (refined * 255).astype(np.uint8))
            print(f"  -> saved {ref_mask_path}")
    
    
    # print summary table if we evaluated
    if evaluate and len(results) > 0:
        print("\n=== Evaluation summary ===")
        for (fname, iou, dice) in results:
            print(f"{fname:30s} IoU={iou:.4f}  Dice={dice:.4f}")
    elif evaluate:
        print("\n[INFO] Evaluation requested but no valid pairs found.")


# ----------------------------
# 6. CLI entry point
# ----------------------------

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run UNet inference on a folder of .tif images and save predictions.")

    parser.add_argument(
        "--model_path",
        type=str,
        required=True,
        help="Path to trained model weights (.pth) from train_unet_multidata.py"
    )

    parser.add_argument(
        "--input_folder",
        type=str,
        required=True,
        help="Folder with test .tif images (and optional *_mask.tif for evaluation)"
    )

    parser.add_argument(
        "--output_folder",
        type=str,
        required=True,
        help="Where to save predicted masks and probability maps"
    )

    parser.add_argument(
        "--patch_size",
        type=int,
        default=128,
        help="Patch size used during tiling (must match training scale)"
    )

    parser.add_argument(
        "--overlap",
        type=int,
        default=32,
        help="Overlap between tiles in pixels (more overlap = smoother seams)"
    )

    parser.add_argument(
        "--eval",
        dest="evaluate",
        action="store_true",
        help="If set, and *_mask.tif exists for an image, compute IoU/Dice"
    )
    
    # Refinement options
    parser.add_argument("--refine", dest="refine", action="store_true", help="Enable post-processing refinement")
    parser.add_argument("--invert", dest="invert", action="store_true", help="Invert mask before refinement")
    parser.add_argument("--min_size", type=int, default=50, help="Minimum object size to keep")
    parser.add_argument("--hole_area", type=int, default=50, help="Fill holes up to this area")
    parser.add_argument("--no_clear_border", dest="no_clear_border", action="store_true",help="Do NOT remove border-touching objects")
    parser.add_argument("--fill_all_holes", dest="fill_all_holes", action="store_true", help="Fill all internal holes (overrides --hole_area)")
    parser.add_argument("--closing_radius", type=int, default=0, help="Morphological closing with disk radius (0 disables)")
    args = parser.parse_args()

    run_inference_on_folder(
        model_path=args.model_path,
        input_folder=args.input_folder,
        output_folder=args.output_folder,
        patch_size=args.patch_size,
        overlap=args.overlap,
        evaluate=args.evaluate,
        refine=args.refine,
        invert=args.invert,
        min_size=args.min_size,
        hole_area=args.hole_area,
        no_clear_border=args.no_clear_border,
        fill_all_holes=args.fill_all_holes,
        closing_radius=args.closing_radius
    )
