#@ File    (label = "Input directory", style = "directory") srcFile
#@ File    (label = "Output directory", style = "directory") dstFile
#@ String  (label = "File extension", value=".tif") ext
#@ String  (label = "File name contains", value = "") containString
#@ boolean (label = "Keep directory structure when saving", value = true) keepDirectories

# See also Process_Folder.ijm for a version of this code
# in the ImageJ 1.x macro language.

import os
from ij import IJ, ImagePlus,gui
import math
import array

from ij.process import ImageProcessor
from ij.process import ImageStatistics

def run():
	srcDir = srcFile.getAbsolutePath()
	dstDir = dstFile.getAbsolutePath()
	for root, directories, filenames in os.walk(srcDir):
		filenames.sort();
	imcnt = 0
	print len(filenames)
	print srcDir
	print imcnt
	for filename in filenames:
		print filename
      # Check for file extension
		if not filename.endswith(ext):
			continue
      # Check for file name pattern
		if containString not in filename:
			continue
		if imcnt == 0:
			print "Open image file", filename
			imp = IJ.openImage(os.path.join(root, filename),12)
			gd = gui.GenericDialog("Histogram Clipping")
			gd.addNumericField("Percentage of Total Pixles: ",0);
			gd.showDialog();
			if gd.wasCanceled():
				cdfTh = 0
			else:
				cdfTh = int(gd.getNextNumber());
			process(imp,srcDir, dstDir, root, filename, keepDirectories,cdfTh)
			imp.close()
		else:
			print "Open image file", filename
			imp = IJ.openImage(os.path.join(root, filename),12)
			process(imp,srcDir, dstDir, root, filename, keepDirectories,cdfTh)
		imcnt = imcnt + 1
def process(imp,srcDir, dstDir, currentDir, filename, keepDirectories,cdfTh):
	print "Processing:"

	dimensions = imp.getDimensions()
	imProc  = imp.getProcessor()
	listBin,ind = imhist(imProc,dimensions)
	intTh = imcdf(listBin,ind,cdfTh,dimensions)
	listBin.reverse()
	ind_reverse = ind.reverse()
	#intTh_low = imcdf(listBin,ind,cdfTh,dimensions)
	MeanVal = 0
	numPixels = 0
	for pixelx in range(dimensions[0]):
		for pixely in range(dimensions[1]):
			sig = imProc.getPixel(pixelx,pixely)
			if sig < intTh:
				MeanVal = MeanVal + sig
				numPixels = numPixels + 1

	MeanVal = MeanVal/(dimensions[0]*dimensions[1])

	for pixelx in range(dimensions[0]):
		for pixely in range(dimensions[1]):
			sig = imProc.getPixel(pixelx,pixely)
			if sig > intTh:
				imProc.putPixel (pixelx, pixely,int(round(MeanVal,0)))
	imp.setProcessor(imp.getTitle(),imProc)
	imsave(imp,filename,srcDir,dstDir,keepDirectories)
	
  
  
  
def imhist(imp,dimensions):
	listBin = imp.getHistogram()
	ind = array.array('i',(i for i in range(0,len(listBin))))
	return listBin,ind

def imcdf(listBin,ind,cdfTh,dimensions):
	print len(listBin)
	cumSum = [float(listBin[0])/(dimensions[0]*dimensions[1])];
	print("CumSum",cumSum)
	for i in range(1,len(listBin)):
		cumSum.append(float(listBin[i])/(dimensions[0]*dimensions[1])+cumSum[i-1])
	for i in range(0,len(listBin)):
		if cumSum[i]*100 >= cdfTh:
			break
			
	intTh = ind[i]
	return intTh

def imsave(imp,filename,srcDir,dstDir,keepDirectories):
	   # Saving the image
	saveDir = currentDir.replace(srcDir, dstDir) if keepDirectories else dstDir
	if not os.path.exists(saveDir):
		os.makedirs(saveDir)
	print "Saving to", saveDir
	IJ.saveAs(imp, "Tiff", os.path.join(saveDir, filename));
	
 
run()
