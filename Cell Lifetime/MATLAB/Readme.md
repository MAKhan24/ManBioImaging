# Angular Lifetime Profiling Tool (ALPT)
*A MATLAB workflow for cell segmentation and angular fluorescence-lifetime quantification*

## Overview
The Angular Lifetime Profiling Tool (ALPT) is a MATLAB-based pipeline designed to extract angular fluorescence-lifetime profiles from single-cell imaging datasets. It processes paired RGB and lifetime images, segments the target cell, computes radial and angle-dependent lifetime values, and visualises results across partitioned angular sectors. It supports reproducible image-based quantification for cell–matrix biology, FLIM, and phenotypic analysis.

## Key Features
- Interactive cell segmentation via active contours.
- Image enhancement and binarisation for robust cell mask generation.
- Boundary extraction and radial/angular lifetime mapping.
- Angular partitioning with statistical measurements per sector.
- Automated polar visualisation of lifetime distribution.
- Centralised parameter control in `parameters.m`.

## Repository Structure
```
ALPT/
│
├── CellLifetime.m            # Main script for segmentation + lifetime extraction
├── AnglePartitionDisplay.m   # Visualisation of angular lifetime profiles
├── parameters.m              # Centralised parameter definitions
└── sample_data/              # Optional example images
```

## Workflow
### 1. Load Input Images
Select RGB and lifetime image pairs when prompted.

### 2. Cell Segmentation
The tool:
- Enhances contrast
- Applies active contours
- Generates a binary mask
- Extracts cell boundaries

### 3. Lifetime Computation
- Calculates centroid
- Partitions boundary into angle sectors
- Computes lifetime per angle
- Outputs data vectors and plots

### 4. Visualisation
Use `AnglePartitionDisplay.m` to generate polar plots.

## Usage
### Step 1: Add to MATLAB Path
```matlab
addpath(genpath('path_to_ALPT'));
```

### Step 2: Run
```matlab
CellLifetime
```

### Step 3: Adjust Parameters
Modify `parameters.m` to tune thresholds, number of angle partitions, smoothing, etc.

## Output Files
- Cell mask image
- Boundary overlay
- Angular lifetime vector
- Polar plot
- MATLAB workspace variables

## Intended Users
- Cell–matrix biologists
- Imaging scientists (FLIM)
- Computational biologists using MATLAB
- Researchers studying spatial lifetime heterogeneity

## Requirements
- MATLAB R2020+
- Image Processing Toolbox

## Citation
Stringer C, Wang T, Michaelos M, Pachitariu M. *Cellpose: a generalist algorithm for cellular segmentation.* Nature Methods 18, 100–106 (2021).

## Author
Muhammad Aurangzeb Khan  
Manchester Cell–Matrix Centre (DRP)
Bioimaging Facility, University of Manchester
muhammadaurangzeb.khan@manchester.ac.uk
aurangzebniazi@gmail.com
