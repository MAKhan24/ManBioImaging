**Install plugins**
Required files:
Collagen_Segmentation_.ijm
histClip_.py

Move/copy files to: ImageJ>plugins>Macros

To run plugins, can either open ImageJ, select the plugins tab, then navigate to the bottom of the menu to find relevant plugins or drag plugin file to Image J window to open code view. 

Data files
In working file, need a folder with full stack tiffs in & a file with single stack Tiffs exported from MCD viewer (which contain scale ref information).

**Image pre processing - HistClip **
First need to pre-process images so that hot pixels are removed. 

Run histClip_.py plugin. Amend directories to relevant paths. Output directory should generate a new folder titled ‘New Tiffs’ within the full stack tiff file (script will not run if a folder with ‘New Tiffs’ as title already exists). File extension should be .tiff. 

Popup window will present asking at what threshold to ‘clip’ the histograms. Set at 99 (pixels with the highest 1% of signal will be excluded) 

If run successfully, ‘New Tiffs’ folder should be generated & populated with new tiff files.

**Segmentation & ECM quant – Collagen_Segmentation_.ijm**

Run script. 

Modify input/output directories to appropriate paths. ‘input’ should be the full stack folder (not the ‘New TIFFs’ folder. Extension should be .tiff. 

Popup will query batch processing – batch processing will process all with same parameters set for first image. Option ‘No’ should be selected If want to manually approve each image. 

Popup will ask for path to ‘Image ref files’ this should be updated to location of single stack TIFFs. 

Once accepted, next popup will ask for Gaussian blur value. This is to smooth the image. A value of 15 will typically suffice. Review popup window and click ‘yes’ is happy.

Median filtering applied next. This can be used to remove random particles. If not applicable set to 0. 

Boundary extension. Currently this is in Pixels, set to 25. 
Note: Code is being amended to set to uM. 

Code will begin to run, showing masks overlayed onto channel being quantified. Check happy with each as they cycle for QC.  

‘Results.csv’ file will be generated in full stack folder, with the mean intensity values. 

Mean-1 is the Mean Value of Epithelial Region
Mean-2 is the Mean Value of region between Epithelial Region and extended boundary
Mean-3 is the Mean Value of whole region within extended boundary
Mean-4 is the Mean Value of whole field of view
 

