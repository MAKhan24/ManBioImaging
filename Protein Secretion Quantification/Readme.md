Protein Localisation & Secretion Analyzer (PLSA)

A Fiji/ImageJ macro for quantifying intracellular and extracellular protein localisation and secretion.

Overview

PLSA is an ImageJ/Fiji macro that automates the quantification of intracellular and extracellular protein signals in fluorescence microscopy datasets.
It detects or imports cell ROIs, measures compartment-specific intensities, and computes secretion/localisation metrics suitable for high-throughput and reproducible analysis.

The macro is designed for users studying protein trafficking, ECM secretion, or spatial localisation patterns in cell biology and microscopy workflows.

Features

Automated cell detection (via Cellpose) or use of user-provided ROIs

Quantification of intracellular and extracellular protein intensity

Calculation of secretion indices (e.g., extracellular:intracellular ratio)

Batch processing of entire folders

Export of per-cell and per-image CSV summaries

Visual QC overlays

Works with TIFF, PNG, JPG, and all Fiji-supported formats

Workflow

Load a single image or folder.

Run the macro through ImageJ/Fiji.

The macro will:

Preprocess the image

Segment cells using Cellpose (or read supplied ROIs)

Define intracellular and extracellular regions

Measure intensities in each compartment

Compute secretion/localisation metrics

Outputs are automatically saved to a chosen directory.

Input Requirements

Fluorescence microscopy images

Protein channel(s)

Optional: nuclear channel or pre-existing ROI masks

Any ImageJ-compatible format (TIFF recommended)

Outputs

PLSA generates the following:

QC overlays showing segmentation and analysis regions

Per-cell CSVs with:

Intracellular intensity

Extracellular intensity

Extracellular/Intracellular ratio

Background-corrected intensities

Per-image summary CSV

Settings log file

Installation

Download proteinSecretionAnalysis_.ijm.

Open Fiji → Plugins → Macros → Run….

Select and run the macro.

Ensure Cellpose Fiji plugin is installed from the BIOP update site if using automatic segmentation.

Usage

Open Fiji/ImageJ

Run via Plugins → Macros → Run…

Select input image or folder

Set parameters (Cellpose model, channel selection, measurement settings, etc.)

Click OK to process

Secretion Metrics Calculated

Intracellular mean intensity

Extracellular mean intensity

Extracellular / Intracellular secretion ratio

Total signal

Background-corrected intensities

Intended Users

Cell biologists investigating secretion pathways

ECM and protein trafficking researchers

Imaging core facility users

Data scientists analysing spatial protein patterns

Anyone requiring a reproducible, automated secretion-quantification workflow

Cellpose Citation

If you use the Cellpose segmentation option within this macro, please cite the official papers:

Cellpose 1.0
Stringer C, Wang T, Michaelos M, Pachitariu M.
Cellpose: a generalist algorithm for cellular segmentation.
Nature Methods, 2021.

Cellpose 2.0
Pachitariu M, Stringer C.
Cellpose 2.0: how to train your own model.
Nature Methods, 2022.

Repository Structure
📁 PLSA/
 ├── proteinSecretionAnalysis_.ijm      # Main ImageJ macro
 ├── README.md                          # Documentation
 ├── example_data/                      # (Optional) Demo files
 └── outputs/                           # (Optional) Example outputs

Acknowledgements

Please cite PLSA and the ManBioImaging GitHub repository if this macro contributes to your work.
If Cellpose is used for segmentation, the Cellpose papers (above) should also be cited.

Author

Muhammad Aurangzeb Khan
Manchester Cell–Matrix Centre (DRP)
Bioimaging Facility, University of Manchester

If you want, I can also create a diagram of the workflow, parameter documentation, or a PDF user guide for GitHub.
