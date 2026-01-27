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
Neuceus Pulposus Segmentation/
├── train_unet_multidata.py          # Multi-dataset U-Net training
├── infer_unet_folder.py             # Batch inference on a folder of images
├── segmentation_unet_vs_rl.yml      # Conda environment
└── README.md

## Installation
```
git clone https://github.com/YourUsername/NP-MatrixSeg.git
cd NP-MatrixSeg
pip install torch torchvision tifffile scikit-image numpy
```

## Training
```
python train_unet_multidata.py \
    --data_root path/to/training_data \
    --epochs 40 \
    --patch_size 128 \
    --batch_size 8 \
    --samples_per_epoch 2048 \
    --out_path unet_np_best.pth
```

## Inference
```
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

## Author
**Muhammad Aurangzeb Khan**  
Manchester Cell–Matrix Centre (DRP)  
Bioimaging Facility, University of Manchester 
muhammadaurangzeb.khan@manchester.ac.uk, 
aurangzebniazi@gmail.com
