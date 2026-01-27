# NP-MatrixAligner
Segmentation-aware orientation alignment and cropping for NP-MatrixSeg outputs
This Fiji/ImageJ macro batch-aligns a folder of **unaligned original images** using either:

1. **Segmentation-based orientation** (preferred): reads a corresponding mask, extracts an **Oriented Bounding Box (OBB)**, rotates the original to a consistent orientation, then crops around the detected centre.
2. **Manual fallback**: if the mask is missing or not usable, you draw a **straight line** indicating the object orientation; the macro rotates and crops accordingly.

It also writes a **CSV summary log** (angle, method, centre, output path).

---

## Features

- Batch-process a full directory of images (`.tif` by default)
- Uses segmentation masks when available:
  - expects `pred_mask_<original_basename>_refined.tif`
- Manual fallback (interactive) when segmentation is missing or rejected
- Crops to a fixed-width/height box centred on the object
- Saves aligned images as TIFF
- Produces an `alignment_summary.csv` output log

---

## Requirements

- **Fiji (recommended)** or ImageJ with equivalent plugins
- Macro uses:
  - `Maximum...`
  - `Keep Largest Region`
  - `Create Selection`
  - `Oriented Bounding Box`
  - ROI Manager + Table access

> If `Oriented Bounding Box` is not available in your Fiji build, install/update Fiji and/or the plugin providing OBB.

---

## Folder Structure & Naming

### Input folders
- **Original images (unaligned):**
  - e.g. `orig/KO 206 46.tif`
- **Segmentation images (masks):**
  - must be named like:
    - `pred_mask_<original_basename>_refined.tif`

Example:
orig/
KO 206 46.tif
KO 206 47.tif

seg/
pred_mask_KO 206 46_refined.tif
pred_mask_KO 206 47_refined.tif


### Output folder
Aligned images will be written to:



aligned/
KO 206 46.tif
KO 206 47.tif
alignment_summary.csv


---

## Installation

1. Download the macro file (e.g. `BatchAlignAndCrop.ijm`).
2. Open Fiji.
3. Go to: **Plugins ▸ Macros ▸ Edit…**
4. Open the `.ijm` file in the editor.
5. (Optional) Save it into your Fiji macros folder:
   - `Fiji.app/macros/`  
   so you can run it easily in the future.

---

## How to Run (Step-by-Step)

1. In Fiji, open the macro:
   - **Plugins ▸ Macros ▸ Run…**
2. Select the macro file (`.ijm`).
3. Fill in the parameters in the dialog:

### Parameters

- **Path to Unaligned Input Images**  
  Folder containing your raw/original images.

- **Path to Corresponding Segmented Images**  
  Folder containing segmentation masks named:
  `pred_mask_<original_basename>_refined.tif`

- **Path to Output Aligned Images**  
  Destination folder for aligned outputs + summary CSV.

- **File extension**  
  Default: `.tif`  
  Change if your images are `.tiff`, `.png`, etc.

- **Height for Cropping** (`boxHeight`)  
  Default: `700`  
  Crop height after rotation.

- **Width for Cropping** (`boxWidth`)  
  Default: `1300`  
  Crop width after rotation.

4. Click **OK** to start.

---

## Interactive Step (Segmentation Quality Check)

For each image (if a mask exists), the macro asks:

> “Segmentation looks good? (Yes=use mask; No=manual line)”

### If you click **Yes**
- Macro uses the mask to:
  - smooth it (`Maximum...`)
  - keep largest region
  - compute OBB centre + orientation
- Rotates original image
- Crops around the computed centre
- Saves output

### If you click **No**
You will be prompted to manually define orientation:

1. The original image becomes active.
2. Draw a **straight line**:
   - **starting from the centre**
   - pointing along the object’s orientation
3. Click **OK** in the prompt.
4. The macro uses the line angle, rotates, crops, and saves output.

---

## Output Files

### 1) Aligned TIFF images
Saved into the output directory:

- `<original_basename>.tif`

### 2) `alignment_summary.csv`
A CSV log is appended for each processed image:

Columns:
- `file` – original filename
- `method` – `mask`, `manual`, `manual_no_seg`, etc.
- `angle_deg` – applied rotation angle (degrees)
- `centreX`, `centreY` – centre used for cropping
- `output_path` – full output path

---
## Requirements

- **Fiji (ImageJ distribution)** – strongly recommended  
  Download: https://fiji.sc

- The following Fiji plugins / commands are required and must be available:

### Core Fiji (usually installed by default)
- ROI Manager
- Results Table
- `Maximum...` (Process ▸ Filters)
- `Keep Largest Region` (Process ▸ Binary)
- `Create Selection` (Edit ▸ Selection)
- `Rotate...` (Image ▸ Transform)

### Required Plugin: Oriented Bounding Box
This macro relies on the **Oriented Bounding Box (OBB)** command to extract:
- object centre (`Box.Center.X`, `Box.Center.Y`)
- object orientation (`Box.Orientation`)

You must have a Fiji build that includes **Oriented Bounding Box**.

To check:
1. Open Fiji
2. Search via **Plugins ▸ Search…**
3. Type **Oriented Bounding Box**

If the command is missing:
- Update Fiji via **Help ▸ Update…**
- Restart Fiji after updating

> If the Oriented Bounding Box plugin is not available or fails, the macro will automatically fall back to **manual orientation mode**.

---
## Tips / Best Practices

- Choose `boxWidth` and `boxHeight` large enough so the object remains inside the crop even after rotation.
- Keep segmentation masks clean:
  - single connected region is ideal
  - macro keeps the largest region automatically
- If you are doing many manual steps, consider improving mask quality (or adding auto QC rules).

---

## Troubleshooting

### “Oriented Bounding Box” not found
- Update Fiji (**Help ▸ Update…**)
- Ensure the plugin providing **Oriented Bounding Box** is installed.

### Mask file not found
- Ensure the naming matches exactly:
  - `pred_mask_<basename>_refined.tif`
- Ensure the basename includes spaces exactly like the original filename.

### Cropped image is shifted
- Increase `boxWidth` / `boxHeight`
- Ensure the centre from segmentation is correct (largest region corresponds to your object)

### Too much manual work
- Improve segmentation quality or add additional mask cleanup steps before OBB.

---

## Customisation Ideas (Optional)

- Auto-skip the “Segmentation looks good?” prompt by adding a mask quality metric.
- Overlay mask on original for faster visual QC.
- Save an additional preview JPEG showing before/after alignment.
- Save the rotation angle into the TIFF metadata.

---

## Citation / Acknowledgements

If you use this in a publication, cite:
- Fiji / ImageJ (Schindelin et al., 2012; Rueden et al., 2017)

---
## Author
**Muhammad Aurangzeb Khan**  
Manchester Cell–Matrix Centre (DRP)  
Bioimaging Facility, University of Manchester 
muhammadaurangzeb.khan@manchester.ac.uk, 
aurangzebniazi@gmail.com
