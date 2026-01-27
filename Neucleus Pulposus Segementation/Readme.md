# Neuceus Pulposus Segmentation (NP-MatrixSeg)
Automated deep-learning segmentation of the nucleus pulposus for cell–matrix analysis in mouse intervertebral discs.

## Overview
NP-MatrixSeg is a lightweight, fully open-source deep-learning pipeline for segmenting the nucleus pulposus (NP) region in mouse intervertebral disc (IVD) microscopy images. Built on a compact UNet architecture, the tool supports rapid, consistent extraction of the NP compartment—a matrix-rich, proteoglycan-dense region central to disc biomechanics and cell–matrix interactions.

## Features
- Compact UNet backbone
- Multi-image patch training
- Tiled full‑resolution inference
- Optional refinement steps
- IoU and Dice evaluation
- GPU or CPU compatible
## Repository Structure
```
Neuceus Pulposus Segmentation/

├── train_unet_multidata.py          # Multi-dataset U-Net training
├── infer_unet_folder.py             # Batch inference on a folder of images
├── segmentation_unet_vs_rl.yml      # Conda environment
└── README.md

```


---

## 🧠 Pipeline Overview

### 🔹 Training
- U-Net–based semantic segmentation
- Supports multiple datasets in a single training run
- Designed to improve robustness across imaging conditions
- Model checkpointing and loss monitoring

### 🔹 Inference
- Folder-level inference (no manual image handling)
- Automatic preprocessing
- Outputs segmentation masks per image

### 🔹 Reproducibility
- Fully defined Conda environment
- Portable across platforms (Linux / Windows / macOS)

---

## 🧪 Scripts Description

### 🏋️ `train_unet_multidata.py`

Trains a U-Net model using **multiple datasets** simultaneously.

**Key features**
- Multi-source dataset ingestion
- Batch training with validation
- Flexible loss functions (e.g. Dice, BCE, or combined losses)
- Saves best-performing model checkpoints

**Example usage**
```bash
python train_unet_multidata.py \
    --data_dirs data/dataset1 data/dataset2 \
    --epochs 100 \
    --batch_size 8 \
    --output_dir models/
```
### 🏋️ `infer_unet_folder.py`

**Key features**
- Automated folder processing
- Consistent preprocessing
- Saves predicted segmentation masks for each image

**Example usage**
```bash
python infer_unet_folder.py \
    --model_path unet_np_best.pth \
    --input_folder path/to/test_images \
    --output_folder outputs \
    --patch_size 128 \
    --overlap 32 \
    --refine \
    --min_size 200 \
    --hole_area 200
```
## Create the Environment
```
conda env create -f segmenationUNETvsRL.yml
conda activate segmenationUNETvsRL
```
---
## 🧪 Inputs and Outputs
### 📥 `Inputs`
Biomedical images (grayscale or RGB)
Ground-truth segmentation masks (training only)

### 📤 `Outputs`
Trained U-Net model weights
Binary or multi-class segmentation masks
Optional probability maps

---
## 📈 Evaluation and Comparison
NP-MatrixSeg is structured to support:

- Comparison between U-Net and reinforcement-learning-based segmentation approaches

- Cross-dataset generalisation studies

- Quantitative metrics such as:

- Dice coefficient

- Intersection over Union (IoU)

- Precision and Recall
---
## 🔬 Methods-style description (for manuscripts / reports)
### Model

We use a U-Net convolutional neural network for semantic segmentation of nucleus pulposus (NP) matrix regions. U-Net consists of an encoder–decoder architecture with skip connections that preserve spatial detail while learning robust contextual features.

### Data preparation and preprocessing

Input images are paired with manually curated segmentation masks. Prior to training, images are typically:

- normalised (e.g., min–max or z-score normalisation),

- optionally resized/cropped to a fixed input size,

- converted to a consistent channel format (grayscale or RGB).

### Training strategy (multi-dataset)

Training is performed using multiple datasets in a single run to improve generalisation across imaging conditions (e.g., different batches, microscopes, stains, or acquisition settings). Data are sampled across datasets during batching so that model updates reflect a diverse training distribution.

### Loss function and optimisation

Segmentation performance is optimised using overlap-aware losses (commonly Dice loss or a Dice + Binary Cross Entropy combination). Optimisation is typically performed with Adam (or equivalent), with validation monitoring and model checkpointing to retain the best-performing weights.

### Augmentation (if enabled in code)

To improve robustness, augmentation may be applied on-the-fly (e.g., flips, rotations, intensity jitter, elastic deformations), ensuring the model learns invariances relevant to biological variability and imaging artefacts.

### Inference and post-processing

For inference, a trained model is applied to each image in a target folder to generate predicted masks. Depending on implementation, outputs may be:

thresholded from probability maps,

optionally refined with simple morphology (remove small objects, fill holes),

saved as binary/multi-class masks for downstream quantification.

### Evaluation

Performance can be quantified using standard segmentation metrics:

- Dice coefficient

- Intersection over Union (IoU)

- Precision / Recall
- Optionally, cross-dataset testing can be used to assess generalisation.

---
## 🧬Intended Users
- Biomedical imaging researchers

- Spine and intervertebral disc researchers

- Computational biologists

- Image analysis core facilities

- Developers building matrix-focused segmentation pipelines

---
## 🔬 Downstream Integration
 
- Outputs from NP-MatrixSeg can be directly used in:

- ImageJ / Fiji (ROI analysis, morphometrics)

- Python-based quantification pipelines

- Statistical comparison workflows

---
## 📚 References
- Ronneberger et al., U-Net: Convolutional Networks for Biomedical Image Segmentation, MICCAI 2015

- van der Walt et al., scikit-image: image processing in Python, PeerJ 2014

---
## Author
**Muhammad Aurangzeb Khan**  
Manchester Cell–Matrix Centre (DRP)  
Bioimaging Facility, University of Manchester 
muhammadaurangzeb.khan@manchester.ac.uk, 
aurangzebniazi@gmail.com
