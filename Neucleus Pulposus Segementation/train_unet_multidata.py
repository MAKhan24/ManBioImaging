import os
import argparse
import math
import random
import numpy as np
import tifffile
import torch
import torch.nn as nn
import torch.nn.functional as F
import torch.optim as optim
from torch.optim.lr_scheduler import CosineAnnealingLR
from torch.utils.data import Dataset, DataLoader


# ----------------------------
# 1. Utility functions
# ----------------------------

def load_and_prepare_image(img_path):
    """
    Load raw microscopy image (.tif), convert to grayscale if needed,
    and normalise intensities to [0,1].
    Returns float32 array of shape (H, W).
    """
    arr = tifffile.imread(img_path).astype(np.float32)

    # If RGB-like (H, W, 3), average channels
    if arr.ndim == 3 and arr.shape[-1] == 3:
        arr = arr.mean(axis=-1)
    else:
        arr = np.squeeze(arr)

    # normalise to [0,1]
    arr = (arr - arr.min()) / (arr.max() - arr.min() + 1e-8)

    return arr.astype(np.float32)


def load_and_prepare_mask(mask_path):
    """
    Load the corresponding ground-truth mask and binarise to {0,1}.
    Returns float32 array of shape (H, W).
    """
    m = tifffile.imread(mask_path).astype(np.float32)
    m = np.squeeze(m)

    # binarise
    if m.max() > 1:
        m = (m > 0).astype(np.float32)
    else:
        m = (m > 0.5).astype(np.float32)

    return m.astype(np.float32)


def collect_image_mask_pairs(data_root):
    """
    Scan a directory, find image/mask pairs.

    Expected convention (case-insensitive):
        image: NAME.tif / NAME.tiff
        mask:  NAME_mask.tif or NAME_Mask.tif

    Returns a list of dicts:
        {
            "name": <base name>,
            "img":  np.array (H,W) float32 in [0,1],
            "mask": np.array (H,W) float32 in {0,1}
        }
    """

    # Gather all tif(f) files
    files = [f for f in os.listdir(data_root) if f.lower().endswith((".tif", ".tiff"))]

    # Build two maps: images[base] = path, masks[base] = path
    images = {}
    masks = {}

    for f in files:
        lower = f.lower()
        full_path = os.path.join(data_root, f)

        # Detect masks via suffix patterns
        if lower.endswith("_mask.tif") or lower.endswith("_mask.tiff") \
           or lower.endswith("_mask.tif".lower()) or lower.endswith("_mask.tiff".lower()) \
           or "_mask" in lower:
            # Remove "_mask" / "_Mask" and extension to get base
            base = lower
            base = base.replace("_mask", "")
            base = base.replace("_Mask", "")
            base = base.replace(".tiff", "")
            base = base.replace(".tif", "")
            masks[base] = full_path
        else:
            # treat as image
            base = lower
            base = base.replace(".tiff", "")
            base = base.replace(".tif", "")
            images[base] = full_path

    # Pair them
    pairs = []
    for base, img_path in images.items():
        if base in masks:
            mask_path = masks[base]

            img_arr = load_and_prepare_image(img_path)
            mask_arr = load_and_prepare_mask(mask_path)

            if img_arr.shape != mask_arr.shape:
                print(f"[WARN] Shape mismatch, skipping:\n"
                      f"  image: {img_path} {img_arr.shape}\n"
                      f"  mask:  {mask_path} {mask_arr.shape}")
                continue

            pairs.append({
                "name": base,
                "img": img_arr,
                "mask": mask_arr,
            })
        else:
            print(f"[WARN] No mask found for: {img_path}")

    print(f"[INFO] Found {len(pairs)} paired images.")
    for p in pairs:
        print(f" - {p['name']}  shape={p['img'].shape}")

    if len(pairs) == 0:
        raise RuntimeError("No valid (image, mask) pairs found in the directory.")

    return pairs


# ----------------------------
# 2. Dataset for patch sampling
# ----------------------------

class MultiImagePatchDataset(Dataset):
    """
    Randomly samples training patches from ANY of the annotated images.

    Each __getitem__:
      - choose one image/mask pair
      - random crop of size patch_size
      - random flips/rotations
      - optional mild intensity jitter
      - returns tensors of shape (1, patch_size, patch_size)
        for both image (float32 in [0,1]) and mask (float32 in {0,1}).
    """
    def __init__(
        self,
        pairs,
        patch_size=128,
        samples_per_epoch=2048,
        augment=True,
        intensity_jitter=False,
    ):
        self.pairs = pairs
        self.patch = patch_size
        self.samples_per_epoch = samples_per_epoch
        self.augment = augment
        self.intensity_jitter = intensity_jitter

        # Store shapes for fast crop range sampling
        self.shapes = [(p["img"].shape[0], p["img"].shape[1]) for p in pairs]

    def __len__(self):
        return self.samples_per_epoch

    def __getitem__(self, idx):
        import numpy as np  # local import so script is self-contained

        # 1. Choose which image/mask to sample from
        which = random.randint(0, len(self.pairs) - 1)
        img_full = self.pairs[which]["img"]
        msk_full = self.pairs[which]["mask"]
        H, W = self.shapes[which]

        ps = self.patch
        # 2. Random crop
        y = np.random.randint(0, H - ps + 1)
        x = np.random.randint(0, W - ps + 1)
        img_patch = img_full[y:y+ps, x:x+ps]
        msk_patch = msk_full[y:y+ps, x:x+ps]

        # 3. Geometric augmentation
        if self.augment:
            if random.random() < 0.5:
                img_patch = np.flip(img_patch, axis=0)
                msk_patch = np.flip(msk_patch, axis=0)
            if random.random() < 0.5:
                img_patch = np.flip(img_patch, axis=1)
                msk_patch = np.flip(msk_patch, axis=1)
            if random.random() < 0.5:
                k = np.random.randint(0, 4)
                img_patch = np.rot90(img_patch, k)
                msk_patch = np.rot90(msk_patch, k)

        # 4. Intensity jitter (optional)
        if self.intensity_jitter:
            if random.random() < 0.3:
                img_patch = img_patch + np.random.normal(0, 0.02, img_patch.shape)
            if random.random() < 0.3:
                scale = np.random.uniform(0.9, 1.1)
                img_patch = img_patch * scale
            img_patch = np.clip(img_patch, 0.0, 1.0)

        # 5. Ensure mask is {0,1}
        if msk_patch.max() > 1.0:
            msk_patch = (msk_patch > 0).astype(np.float32)

        # 6. Convert to tensors [1,H,W]
        img_t = torch.from_numpy(img_patch.astype(np.float32))[None, ...]
        msk_t = torch.from_numpy(msk_patch.astype(np.float32))[None, ...]

        return img_t, msk_t


# ----------------------------
# 3. UNet model (compact)
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

"""
class UNetSmall(nn.Module):
    """
"""
    A lightweight UNet-like model:
      - 1 encoder downsample
      - 1 decoder upsample with skip connection
      - Outputs a single-channel logit map
    """
"""
    def __init__(self):
        super().__init__()
        self.enc1 = ConvBlock(1, 32)
        self.enc2 = ConvBlock(32, 64)
        self.pool = nn.MaxPool2d(2)
        self.dec1 = ConvBlock(96, 32)  # 32 skip + 64 upsampled
        self.outc = nn.Conv2d(32, 1, 1)

    def forward(self, x):
        x1 = self.enc1(x)            # (B,32,H,W)
        x2 = self.pool(x1)           # (B,32,H/2,W/2)
        x2 = self.enc2(x2)           # (B,64,H/2,W/2)
        x2_up = F.interpolate(x2, scale_factor=2, mode='bilinear', align_corners=False)  # (B,64,H,W)
        x_cat = torch.cat([x1, x2_up], dim=1)  # -> (B,96,H,W)
        x3 = self.dec1(x_cat)        # (B,32,H,W)
        out = self.outc(x3)          # (B,1,H,W) logits
        return out
"""
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
# 4. Training loop
# ----------------------------

def train_model(data_root, epochs, patch_size, batch_size, samples_per_epoch, out_path):
    # 4.1 collect data
    pairs = collect_image_mask_pairs(data_root)

    # 4.2 build dataset/loader
    dataset = MultiImagePatchDataset(
        pairs,
        patch_size=patch_size,
        samples_per_epoch=samples_per_epoch,
        augment=True,
        intensity_jitter=False,
    )
    loader = DataLoader(dataset, batch_size=batch_size, shuffle=True, drop_last=True)

    # 4.3 setup model / optimiser / scheduler
    device = "cuda" if torch.cuda.is_available() else "cpu"
    model = UNetSmall().to(device)
    criterion = nn.BCEWithLogitsLoss()
    optimizer = optim.Adam(model.parameters(), lr=1e-4, weight_decay=1e-5)

    scheduler = CosineAnnealingLR(optimizer, T_max=epochs, eta_min=1e-7)

    best_loss = float("inf")
    best_state = None

    # 4.4 training over epochs
    for epoch in range(1, epochs + 1):
        model.train()
        running = 0.0
        num_batches = 0

        for img_batch, mask_batch in loader:
            img_batch = img_batch.to(device)
            mask_batch = mask_batch.to(device)

            optimizer.zero_grad()
            logits = model(img_batch)
            loss = criterion(logits, mask_batch)
            # Safety check: skip bad batches
            if torch.isnan(loss) or torch.isinf(loss):
                print("⚠ skipping batch due to unstable loss:", loss.item())
                continue
            loss.backward()

            torch.nn.utils.clip_grad_norm_(model.parameters(), max_norm=1.0)
            optimizer.step()

            running += float(loss.item())
            num_batches += 1

        avg_loss = running / max(num_batches, 1)
        scheduler.step()
        current_lr = scheduler.get_last_lr()[0]

        print(f"Epoch {epoch}/{epochs} - Loss {avg_loss:.6f} - LR {current_lr:.6f}")

        if avg_loss < best_loss:
            best_loss = avg_loss
            best_state = model.state_dict().copy()

    # 4.5 save best checkpoint
    torch.save(best_state, out_path)
    print(f"[INFO] Training complete. Best loss={best_loss:.6f}")
    print(f"[INFO] Saved best model to {out_path}")


# ----------------------------
# 5. CLI entry point
# ----------------------------

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Train UNetSmall on a folder of images+mask pairs.")

    parser.add_argument(
        "--data_root",
        type=str,
        required=True,
        help="Path to folder containing .tif images and *_mask.tif masks."
    )

    parser.add_argument(
        "--epochs",
        type=int,
        default=20,
        help="Number of training epochs (default: 20)"
    )

    parser.add_argument(
        "--patch_size",
        type=int,
        default=128,
        help="Patch size for random crops (default: 128)"
    )

    parser.add_argument(
        "--batch_size",
        type=int,
        default=8,
        help="Batch size for training (default: 8)"
    )

    parser.add_argument(
        "--samples_per_epoch",
        type=int,
        default=2048,
        help="How many random patches to draw per epoch (default: 2048)"
    )

    parser.add_argument(
        "--out_path",
        type=str,
        default="unet_best_multidata.pth",
        help="Where to save the best model weights (default: unet_best_multidata.pth)"
    )

    args = parser.parse_args()

    train_model(
        data_root=args.data_root,
        epochs=args.epochs,
        patch_size=args.patch_size,
        batch_size=args.batch_size,
        samples_per_epoch=args.samples_per_epoch,
        out_path=args.out_path,
    )
