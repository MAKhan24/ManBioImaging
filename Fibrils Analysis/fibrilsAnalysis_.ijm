/*
 * Macro template to process multiple images in a folder
 */

#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".tif") suffix
#@ String (label = "If Image is Too big to be loaded in the RAM,enter a number to split the image into smaller partitions (e.g. To divide image into 4 parts, enter 4. 0 means no partitions)", value = 0) totalPartitions

#@ File (label = "Conda Env Path", style = "directory") venvPath
#@ String (choices={"Custom Model", "Default"}, style="radioButtonHorizontal") cpModelCh
#@ File (label = " Select Cellpose Custom Models", style = "file") cpCustomModel
#@ String (label = "Cellpose model", choices={"cyto","cyto2", "nuclei"}, style="listBox") cpDefaultModel
#@ Double(label="Cell diameter (default=300)", value=50.0) cpDiameter
#@ Integer(label="Channel-1 (0 means not present)", value=1, min=0) chan
#@ Integer(label="Channel-2 (0 means not present)", value=1, min=0) chan2

// Global parameters to store threshold values
var interactiveDone = false;
var metrics = newArray();
var multiArray =newArray();
var roiFileName = "temp";


// See also Process_Folder.py for a version of this code
// in the Python scripting language.

processFolder(input);

// function to scan folders/subfolders/files to find files with correct suffix


function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	imCnt=0;
	for (i = 0; i < list.length; i++) {
		//for (i = 0; i < 1; i++) {
		close("*");
		if(File.isDirectory(input + File.separator + list[i])){
			continue;
		}
		if(endsWith(list[i], suffix)){
			print("Image Number:" + imCnt);
			processFile(input, output, list[i],imCnt);
			imCnt++;
			if (i<list.length-1){
				if (getBoolean("Proceed to next image?", "Yes", "No")) {
					continue;
					}
				else{
					break;
					}			
				
				}			
			}
	}
	Dialog.create("All Done...");
	Dialog.addMessage("All the images are done and output files have been saved to "+ output);
	Dialog.show();
	if (isOpen("ROI Manager")) {roiManager("reset"); close("ROI Manager");}
    if (isOpen("Results")){run("Clear Results"); close("Results");}	
    if (isOpen("Log")){close("Log");}	
    close("*");

}

function processFile(input, output, file,imCnt) {
	//setBatchMode(true);
	print("Processing: " + input + File.separator + file);
	Array.print(multiArray);
    Array.print(metrics);
	path = input + File.separator + file;
	dir = File.getParent(path);
	fileName = File.getNameWithoutExtension(path);
	roiFileName = fileName +"_RoiSet.zip";
	open(path);
	origImgTitle ="Original Image";
	rename(origImgTitle);

	if (cpModelCh == "Custom Model"){
		cpModel = cpCustomModel;
		run("Cellpose ...", "env_path="+venvPath+ " env_type=conda model= model_path="+cpModel+ " diameter="+cpDiameter+ " ch1="+chan+"  ch2="+chan2+"  additional_flags=--use_gpu,--save_png");
	}
	else{
		cpModel = cpDefaultModel;
		run("Cellpose ...", "env_path="+venvPath+ " env_type=conda model="+cpModel+" model_path= diameter="+cpDiameter+ " ch1="+chan+"  ch2="+chan2+"  additional_flags=--use_gpu,--save_png");
	}
	run("Label image to ROIs");
	selectImage(origImgTitle);
	roiManager("Show All");

	filterROIsAtEdge(origImgTitle);
	roiManager("Save", output+ File.separator + roiFileName);
	if (imCnt == 0){
		if (getBoolean("Do you want to filter out fibrills based upon some metrics?", "Yes", "No")) {
        	filterROIsInteractive(origImgTitle,imCnt);
  	     	}
  		}
  	else{
  		if (interactiveDone){
  			filterROIsInteractive(origImgTitle,imCnt);
  			}  		 		
  		}
	
	roiManager("reset");
	selectImage(origImgTitle);
	roiManager("Open", output+ File.separator +roiFileName);
	roiManager("show all");
	run("Set Measurements...", "perimeter fit feret's redirect=None decimal=3");
	roiManager("deselect");
	roiManager("measure");
	saveAs("Results", output+ File.separator + fileName+"_Results.csv");


}


function filterROIsAtEdge(ImgTitle){
	selectImage(ImgTitle);
	// Get image dimensions
	getDimensions(width, height, channels, slices, frames);

	// Iterate through ROIs in the ROI Manager
	for (i = roiManager("count"); i > 0; i--) {
		// Select the current ROI
		roiManager("select", i - 1);
		// Get the ROI's bounding box
		getSelectionBounds(x, y, width1, height1);
		// Check if the ROI touches the edge
		if ((x == 0 || y == 0 || (x + width1) == width || (y + height1) == height)) {
			// Delete the ROI
			roiManager("delete");
			}
		}
}



// Interactive ROI Thresholding with Live Preview and Clear Filtering



function getROIValues(ImgTitle,metric) {
	selectWindow(ImgTitle);
	maxGreylevel =Math.pow(2, bitDepth())-1; 
	roiManager("reset");
	roiManager("Open", output+ File.separator +roiFileName);
	roiManager("show all");
    n = roiManager("count");
    print("roiCount before filering  "+ n);
    values = newArray(n);

    if (metric == "Mean") {
        run("Set Measurements...", "mean redirect=None decimal=3");
        label = "Mean";
        divider = maxGreylevel;
    } else if (metric == "Median") {
       run("Set Measurements...", "shape redirect=None decimal=3");
       label = "Circ.";
    } else if (metric == "Median") {
        run("Set Measurements...", "median redirect=None decimal=3");
        label = "Median";
    } else {
        run("Set Measurements...", "area redirect=None decimal=3");
        label = "Area";
    }
    run("Clear Results");
    roiManager("deselect");
    roiManager("measure");
    for (i = 0; i < n; i++) {
        values[i] = getResult(label, i);
    }
    run("Clear Results");
    return values;
}

function computeThreshold(values, multiplier) {
    n = values.length;
    sum = 0;
    for (i = 0; i < n; i++) sum += values[i];
    mean = sum / n;

    sumSq = 0;
    for (i = 0; i < n; i++) sumSq += pow(values[i] - mean, 2);
    std = sqrt(sumSq / n);

    return newArray(mean - multiplier * std, mean + multiplier * std);
}

function previewROIs(values, minT, maxT, lastMetric) {
    n = values.length;

	tempArray=newArray();
	j=0;
    for (i = 0; i < n; i++) {
    	if (lastMetric=="Area"){
        	if (values[i] <= minT || values[i] >= maxT) {
            	tempArray[j]=i;

            	j++;

        	}
    	}else if(lastMetric=="Circ."){
    		if (values[i] <= minT) {
            	tempArray[j]=i;

            	j++;

        	}

    	}else{
    		if (values[i] >= maxT) {
            	tempArray[j]=i;

            	j++;

        	}


    	}
    }
    roiManager("select", tempArray);
    roiManager("Delete");
    roiManager("Show All");
   }

function deleteOutliers(values, minT, maxT,lastMetric) {
    n = values.length;
    roiManager("reset");
    roiManager("Show None");
    roiManager("Open", output+ File.separator +roiFileName);
    print("ROI File Name:   "+output+ File.separator +roiFileName);
	tempArray=newArray();
	Array.print(values);
    deleted = 0;
    for (i = 0; i < n; i++) {
    	if (lastMetric=="Area"){
       		if (values[i] <= minT || values[i] >= maxT) {
 				tempArray[deleted]=i;

            	deleted++;
        	}
    	}else if(lastMetric=="Circ."){
    		if (values[i] <= minT) {
            	tempArray[deleted]=i;

            	deleted++;

        	}

    	}else{
    		if (values[i] >= maxT) {
 				tempArray[deleted]=i;

            	deleted++;
        	}


    	}
    }
	roiManager("select", tempArray);
 	roiManager("Delete");
    print("ROI count after filtering "+roiManager("count"));
    roiManager("Show All");
    roiManager("Save", output+ File.separator +roiFileName);

    return deleted;
}

function filterROIsInteractive(ImgTitle,imCnt) {
	selectImage(ImgTitle);
	lastMetric = "Mean";
	lastMultiplier =1.0;
	minT = 0.0;
	maxT=0.0;
    if (imCnt == 0) {
        // Show dialog on the first image
        tempCnt =0;
        deleted =0;
        while (true) {
        	roiManager("reset");
    		roiManager("Show None");
    		roiManager("Open", output+ File.separator +roiFileName);
    		roiManager("Show All");
            Dialog.create("Choose ROI Thresholding");
            Dialog.addChoice("Metric:", newArray("Mean", "Median", "Area","Circularity"), lastMetric);
            Dialog.addSlider("Threshold multiplier (±SD):", 0.0, 2.5, lastMultiplier);
            Dialog.show();

            lastMetric = Dialog.getChoice();
            lastMultiplier = Dialog.getNumber();

            values = getROIValues(ImgTitle,lastMetric);
            thresholds = computeThreshold(values, lastMultiplier);
            minT = thresholds[0];
            maxT = thresholds[1];

            previewROIs(values, minT, maxT,lastMetric);

	        if (getBoolean("Proceed with filtering and save thresholds?", "Yes", "No")) {
                interactiveDone = true;
                deleted= deleted + deleteOutliers(values, minT, maxT,lastMetric);
				metrics[tempCnt]=lastMetric;
                multiArray[tempCnt]=lastMultiplier;
                tempCnt++;
               // showMessage("Done", removed + " ROIs removed.");
                if (getBoolean("Do you want to try other metrics for filtering?", "Yes", "No")) {
                	continue;
                	}
               	//Array.print(metrics);
               	//Array.print(multiArray);
                break;
            }
        }
    } else {
        // Apply saved thresholds automatically
        deleted=0;
        Array.print(multiArray);
        Array.print(metrics);
        for (i=0;i<metrics.length;i++){
        	values = getROIValues(ImgTitle,metrics[i]);
        	thresholds = computeThreshold(values, multiArray[i]);
            minT = thresholds[0];
            maxT = thresholds[1];
        	deleted = deleted + deleteOutliers(values, minT, maxT,metrics[i]);

        }     	

    }
    print("Removed " + deleted + " ROIs for image #" + (imCnt + 1));
}

function imageSplitter(ImgTitle,totalPartitions){
	selectImage(ImgTitle);
	n=2;
	id = getImageID();
	title = getTitle();
	getLocationAndSize(locX, locY, sizeW, sizeH);
	width = getWidth();
	height = getHeight();
	tileWidth = width / n;
	tileHeight = height / n;
	tileWidth = width / n;
	tileHeight = height / n;
	for (y = 0; y < n; y++) {
		offsetY = y * height / n;
		for (x = 0; x < n; x++) {
			offsetX = x * width / n;
			selectImage(id);

			call("ij.gui.ImageWindow.setNextLocation", locX + offsetX, locY + offsetY);
			tileTitle = title + " [" + x + "," + y + "]";
			print(tileTitle);
 			run("Duplicate...");
			makeRectangle(offsetX, offsetY, tileWidth, tileHeight);
			run("Crop");
			rename(tileTitle);
			}
		}
selectImage(id);
close();

	}