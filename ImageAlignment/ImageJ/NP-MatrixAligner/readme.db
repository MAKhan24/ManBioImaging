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

