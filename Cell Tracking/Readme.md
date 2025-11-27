# README.md — TrackDataMiner: Automated extraction of cell-tracking features from raw ND2 datasets.

## Overview
This repository contains a three-stage automated workflow for **cell tracking, metadata extraction, and data mining** from time-lapse microscopy datasets (e.g., `.nd2` files).  
The pipeline combines:

- **TrackMate (Fiji)**
- **Cellpose segmentation (GPU-enabled)**
- **Custom ImageJ macros**
- **Python/Jython scripting inside Fiji**

It is designed for **cell–matrix biology**, including cell migration, ECM signalling, NP cell dynamics, and general time-lapse tracking applications.

## Workflow Summary
The workflow consists of **three consecutive steps**:

1. **Segmentation & Tracking (TrackMate + Cellpose)**
2. **Metadata Extraction (ImageJ Macro)**
3. **Raw CSV Mining & Feature Generation (ImageJ Macro)**

Each step must be run in order.

```
Raw ND2 Files
     │
     ▼
trackmate_detection_tracking.py
(Spot detection + tracking using Cellpose)
     │
     ▼
getImageInfo_.ijm
(Fetch frame interval, file name, series info)
     │
     ▼
reading_rawcsvdata_.ijm
(Merged & cleaned analytical CSV outputs)
```

# 1. Segmentation & Tracking  
## `trackmate_detection_tracking.py`
This Fiji-Jython script performs:

- Batch loading of ND2 files via Bio-Formats  
- Cellpose segmentation (custom cyto3 model)  
- GPU-based detection & contour extraction  
- TrackMate LAP tracking  
- Automatic folder creation per dataset  
- Export of:
  - `*-spots.csv`
  - `*-tracks.csv`

### Input
- Directory containing `.nd2` files  
- Number of series  
- Channel selection  
- Cellpose model path  

### Output
```
/OutputDirectory/
     sample1/
        series-1-spots.csv
        series-1-tracks.csv
```

# 2. Metadata Extraction  
## `getImageInfo_.ijm`
Extracts metadata such as:

- Frame interval  
- Pixel size  
- Filename and series  
- Acquisition info  

# 3. CSV Mining & Feature Processing  
## `reading_rawcsvdata_.ijm`
Processes raw TrackMate CSVs and merges them with metadata.

### Outputs:
- Trajectories  
- Displacement  
- Speed  
- Track statistics  
- Cleaned analysis-ready CSV files  

# Installation Requirements
### Software
- Fiji / ImageJ  
- TrackMate 7+  
- Cellpose plugin  
- Python 3.8+  
- CUDA GPU (recommended)

### Python Cellpose
```
pip install cellpose
```

# How to Run  
## Step 1 — TrackMate Detection
Load and run the Python script in Fiji.

## Step 2 — Metadata Extraction
Run `getImageInfo_.ijm`.

## Step 3 — CSV Mining
Run `reading_rawcsvdata_.ijm`.

# Directory Structure
```
Project/
   ├── Input/
   ├── 01_TrackMate_Output/
   ├── 02_Metadata/
   ├── 03_Final_Data/
```

# Intended Users
- Cell–matrix biologists  
- ECM signalling researchers  
- NP tissue researchers  
- Time-lapse imaging analysts  

# Citations
**Cellpose**  
Stringer C et al., Nature Methods 2021  
**TrackMate**  
Tinevez JY et al., Methods 2017

# Author
**Muhammad Aurangzeb Khan**  
Manchester Cell–Matrix Centre (DRP)  
Bioimaging Facility, University of Manchester 
muhammadaurangzeb.khan@manchester.ac.uk, 
aurangzebniazi@gmail.com

# License
MIT License
