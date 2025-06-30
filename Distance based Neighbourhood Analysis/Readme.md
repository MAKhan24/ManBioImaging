# neighbourhoodAnalysis_.ijm

## 1. Purpose

This macro processes a folder of images (e.g., `.jpg`), automatically thresholds and edge-detects each image, and lets you manually select objects of interest using the Magic Wand tool. It calculates distances between all pairs of centroids for selected objects and exports the results as CSV files for each image.

---

## 2. Requirements

- [Fiji (ImageJ)](https://fiji.sc) installed  
- Folder of single-channel `.jpg` images (or any Fiji-supported format) with objects suitable for edge detection

---

## 3. Loading the Macro

You can run this macro in Fiji using any of these methods:
- **Plugins > Macros > Run...**
- **Drag and drop** the macro file into the Fiji toolbar
- **Plugins > Macros > Install...**
- **File > Open...** and run from the Fiji script editor

---

## 4. Main Setup Dialog

You will see this dialog box:

![Main Setup Dialog](Distance based Neighbourhood Analysis/Images/main-setup-dialog.png)

| Field               | Description                                      |
|---------------------|--------------------------------------------------|
| Input directory     | Folder with your images                           |
| Output directory    | Folder where results will be saved                |
| File suffix         | `.jpg` (or other, as needed)                      |

> **Note:**  
> The macro supports any Fiji-readable image format (e.g., `.jpg`, `.png`, `.tif`). Enter the appropriate file suffix in the dialog.

---

## 5. Automated Image Preprocessing

For each image, the macro automatically:
- Performs thresholding and edge detection to generate a new window (`Original Image-Dup`) with clear object boundaries.

---

## 6. Manual ROI Selection Workflow

### A. Select an ROI Boundary

You will see this dialog:

![Select ROI Dialog](Distance based Neighbourhood Analysis/Images/action-required-dialog.png)

> Click within any cell area to select the cell boundary, then click OK to proceed. (Use image with title Original Image-Dup)

- Use the Magic Wand tool on **Original Image-Dup** to click inside an object of interest.
- Press **OK** in the dialog.

---

### B. Select More ROIs?

After pressing OK, this dialog appears:

![Select More ROIs Dialog](Distance based Neighbourhood Analysis/Images/select-more-rois-dialog.PNG)

> Do you want to select other cells in the same image?

- **Yes:** The selection dialog returns; click in another object and press OK.  
- **No:** Finish ROI selection and proceed to analysis.  
- **Cancel:** Exits the macro.

Repeat until all desired ROIs are selected, then press **No**.

---

## 7. Centroid Extraction & Distance Analysis

After ROI selection:
- The macro measures each ROI to extract centroid coordinates (`X`, `Y`)
- Calculates Euclidean distances between every pair of centroids:
Distance_{i,j} = sqrt((X_i - X_j)^2 + (Y_i - Y_j)^2)

- Saves results as a CSV file named after the image (e.g., `Distances_image1.csv`).

---

## 8. Output

Each CSV contains:

| From | To | Distance |
|------|----|----------|
| 1    | 1  | 0        |
| 1    | 2  | ...      |
| ...  | ...| ...      |

---

## 9. Tips & Troubleshooting

- Always use the **Original Image-Dup** window for ROI selection.
- If "No ROIs found!" appears, ensure you've selected at least one region before clicking OK.
- Results and ROI Manager are reset between images.
- CSV files open in Excel, R, Python, etc.

---

## 10. Results Location

Check your chosen output directory for one CSV per image after macro completion.

