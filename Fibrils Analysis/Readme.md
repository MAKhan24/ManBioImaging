# EM-FibrilX: Advanced EM Fibril Segmentation and Quantification 
This repository contains an ImageJ macro (fibrilsAnalysis\_.ijm ) designed for the segmentation and analysis of fibrillar structures in Electron Microscopy (EM) images. The macro integrates the Cellpose deep learning tool to perform segmentation and provides both automated and semi-automated ROI filtering features.

---

## 🧬 Purpose

This macro is intended for researchers working with EM datasets who need to identify and quantify fibrillar structures such as extracellular matrix fibers. It is particularly useful for batch processing of grayscale `.tif` images.

---

## ⚙️ Features

- GPU-accelerated Cellpose integration (via conda)
- Support for default and custom Cellpose models
- ROI filtering:
  - Removes ROIs touching image edges
  - Semi-automated filtering based on user-defined metrics (mean, area, etc.)
- Results exported as CSV and ROI zip sets

---

## 📦 Installation

### 1. Install Fiji (ImageJ)

Download and install Fiji: [https://fiji.sc](https://fiji.sc)

### 2. Install Cellpose with GPU Support

Install [Miniconda](https://docs.conda.io/en/latest/miniconda.html), then run:

```bash
conda create -n cellpose_env python=3.8 -y
conda activate cellpose_env
pip install cellpose[torch]
```

Test Cellpose:

```bash
python -m cellpose --gpu
```

You should see `GPU=True` in the output.

---

## 🚀 How to Run the Macro

### Launching the Macro

You can run the macro in several ways:

- **Drag and drop** the `.ijm` file onto the Fiji toolbar
- Use **Plugins > Macros > Run...**
- Install via **Plugins > Macros > Install...** for repeated use

### Input Dialog Options

| Field                      | Description                               |
| -------------------------- | ----------------------------------------- |
| Input directory            | Folder with input `.tif` EM images        |
| Output directory           | Destination folder for results            |
| File suffix                | e.g., `.tif`                              |
| Image partition (0 = full) | *Under construction.* Intended for tiling |
| Path to Conda Environment  | Folder path to Cellpose environment       |
| Model type                 | Choose **Default** or **Custom**          |
| Custom model file          | If using Custom, select `.pt` model       |
| Cellpose model (Default)   | One of: `cyto`, `cyto2`, `nuclei`         |
| Cell diameter              | Estimated diameter in pixels              |
| Channel 1                  | For grayscale EM, use `1`                 |
| Channel 2                  | For grayscale EM, use `0`                 |

---

## 📊 Output Files

- `*_RoiSet.zip` — ROI Manager output
- `Results_<#>.csv` — Measurements of filtered ROIs
- Segmentation mask PNGs (optional, if enabled)

---

## 🔍 Key Functions

### `processFolder()`

Loops through all image files in a selected folder and passes each to `processFile()`.

### `processFile()`

- Loads image
- Runs Cellpose segmentation
- Imports masks as ROIs
- Filters out edge-touching ROIs
- Launches semi-automated filtering

### `filterROIsAtEdge(ImgTitle)`

Removes ROIs that intersect with the image boundary.

### `filterROIsInteractive(ImgTitle, imCnt)`

For the first image: prompts the user to select filtering metric (e.g., Mean, Area) and threshold. For subsequent images: applies saved thresholds automatically.

---

## 📚 Citation

If you use this macro, please cite:

> Stringer, C., Wang, T., Michaelos, M. et al. *Cellpose: a generalist algorithm for cellular segmentation.* Nat Methods 18, 100–106 (2021). [https://doi.org/10.1038/s41592-020-01018-x](https://doi.org/10.1038/s41592-020-01018-x)

> Schindelin, J. et al. *Fiji: an open-source platform for biological-image analysis.* Nat Methods 9, 676–682 (2012). [https://doi.org/10.1038/nmeth.2019](https://doi.org/10.1038/nmeth.2019)

---

## 🧑‍🔬 Authors

Muhammad Aurangzeb Khan
Manchester Cell–Matrix Centre (DRP)
Bioimaging Facility, University of Manchester
muhammadaurangzeb.khan@manchester.ac.uk
aurangzebniazi@gmail.com

---

## 📂 License

This project is provided for academic research use. Contact the author for reuse or redistribution beyond academic contexts.

