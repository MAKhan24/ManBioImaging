
# 🧬 Cell and Nucleus Segmentation Macro for Fiji/ImageJ

This macro performs **automated segmentation of cells and nuclei** using the [Cellpose](https://www.cellpose.org/) plugin (via the BIOP Fiji update site). It supports both **default and custom-trained Cellpose models**, processes **multi-channel images**, and filters segmented cell ROIs to retain only those containing a nucleus. The macro outputs measurements and final flattened images with overlays.

## 📌 Features

- Dual segmentation (cytoplasm and nuclei) using Cellpose
- Option to use custom-trained models
- Automatic ROI filtering based on area and nucleus containment
- Intensity and area measurements for whole cells and their nuclear regions
- Export of results as CSV and TIFF

## 🧰 Requirements

- **Fiji/ImageJ** (https://fiji.sc)
- **BIOP Cellpose plugin** (from the ImageJ update sites)
- **Cellpose installed** in a Python environment (e.g., via Anaconda)
- A **multi-channel image** with cytoplasm and nucleus channels

## 🔧 Installation Instructions

1. **Install Fiji**:  
   Download and install Fiji from https://fiji.sc

2. **Install Cellpose plugin from BIOP**:
   - Go to `Help > Update...` in Fiji
   - Click `Manage Update Sites`
   - Enable **BIOP**
   - Click `Close`, then `Apply changes`
   - Restart Fiji

3. **Install Cellpose** in your Python environment:  
   Using conda:
   ```bash
   conda create -n bioimage_env python=3.8
   conda activate bioimage_env
   pip install cellpose
   ```

## 🖼️ Input Image Requirements

- Composite image with **multiple channels** (e.g., cytoplasm and nucleus)
- Can be a **single-plane** or **Z-stack** (macro handles 2D only)
- Supported formats: TIFF, LIF, CZI, etc. (as long as Fiji can open it)

## 🎛️ Macro Parameters (UI Prompts)

| Parameter                     | Description |
|------------------------------|-------------|
| `Path to Input Composite Image` | Full path to the multi-channel image to process |
| `Custom or Default Model`    | Choose whether to use a custom-trained Cellpose model |
| `Custom Model File`          | If custom model selected, choose `.pt` file |
| `Cellpose Model`             | Choose one of the built-in Cellpose models: `cyto`, `cyto2`, `nuclei` |
| `Cell Diameter`              | Approximate diameter (in pixels) of the full cell |
| `Nucleus Diameter`           | Approximate diameter (in pixels) of nucleus |
| `Cytoplasm Channel`          | 1-based index of cytoplasm channel (0 if not used) |
| `Nucleus Channel`            | 1-based index of nucleus channel (0 if not used) |

## 🚦 Processing Steps

1. **Load input image**
2. **Run Cellpose** on cytoplasm channel
   - Uses custom or default model
   - Generates label map and ROIs
3. **Filter out small cell ROIs** (<20% of mean area)
4. **Run Cellpose** on nucleus channel (default `nuclei` model)
5. **Filter out cell ROIs that do not contain any nucleus**
6. **Measure**:
   - Intensity and area for each valid cell
   - Intensity and area for the nucleus within that cell
7. **Export**:
   - ROI overlays flattened onto original image
   - Results saved as `.csv`
   - Image saved as `.tif`

## 💾 Output Files

All files are saved in the same directory as the input image.

| File | Description |
|------|-------------|
| `Results.csv` | CSV with per-cell measurements (total/nuclear intensity & area) |
| `ResImg.tif` | Flattened image with cell and nucleus ROI overlays |
| Temporary images | Intermediate duplicates are closed after processing |

## 🧪 Output Columns (Results.csv)

| Column                         | Meaning |
|--------------------------------|---------|
| `Sum of Intensities (Whole Cell)` | Integrated intensity of full cell ROI |
| `Sum of Intensities (Nuclei Region)` | Integrated intensity of nuclear ROI within the cell |
| `Area (Whole Cell)`           | Area of the segmented cell |
| `Area (Nuclei Region)`        | Area of the nucleus within the cell |

## 📖 How to Run

1. Launch Fiji
2. Open the macro via `Plugins > Macros > Run...`
3. Select your input image and parameters in the prompt dialogs
4. Let the macro run — a log message will confirm when it's done

## 📚 Citation

If you use this macro or Cellpose in your work, please cite the original Cellpose paper:

> **Stringer, Carsen, et al.**  
> "Cellpose: a generalist algorithm for cellular segmentation."  
> *Nature Methods* 18.1 (2021): 100–106.  
> [https://doi.org/10.1038/s41592-020-01018-x](https://doi.org/10.1038/s41592-020-01018-x)

## 🧼 Troubleshooting

- **"Unrecognized command: Cellpose ..."** → Check that you installed the **BIOP** plugin and restarted Fiji
- **Custom model not found** → Ensure the `.pt` model file is selected and Cellpose can find it
- **No ROIs generated** → Try adjusting `diameter`, `flow_threshold`, or check channel assignments
- **Image not calibrated** → Ensure you know the correct pixel sizes if using physical units

## 🔓 License

This macro is released under the MIT License. Feel free to adapt and extend for your own image analysis needs.
