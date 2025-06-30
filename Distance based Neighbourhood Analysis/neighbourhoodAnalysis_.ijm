/*
 * Macro template to process multiple images in a folder
 */

#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".tif") suffix

// See also Process_Folder.py for a version of this code
// in the Python scripting language.

print(output);
processFolder(input);


// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);

	imcnt =0;
	for (i = 0; i < list.length; i++) {
		if (isOpen("ROI Manager")) {roiManager("reset"); close("ROI Manager");}
        if (isOpen("Results")){run("Clear Results"); close("Results");}
		if(File.isDirectory(input + File.separator + list[imcnt]))
			processFolder(input + File.separator + list[imcnt]);
		
			
		if(endsWith(list[imcnt], suffix)){
			if(i>0){
				Ch_proceed = getBoolean("Proceed to next image?");
				if(Ch_proceed == 1){

					processFile(input, output, list[imcnt]);
					
					imcnt = imcnt + 1;
				}
				else
					break;						
			}
			else{
				processFile(input, output, list[imcnt]);

				imcnt = imcnt + 1;
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

function processFile(input, output, file) {
	// Do the processing here by adding your own code.
	// Leave the print statements until things work, then remove them.
	print("Processing: " + input + File.separator + file);
	print("Saving to: " + output);
	close("*");

	path = input + File.separator + file;
	dir = File.getParent(path);
	imageName = File.getNameWithoutExtension(path);
	open(path);
	getPixelSize(unit, pw, ph, pd);
	origImgTitle ="Original Image";
	rename(origImgTitle);
	run("8-bit");
	thresholding(origImgTitle);
	run("Convert to Mask");
	
	run("Duplicate...", "ignore");
	dupImgTitle ="Original Image-Dup";
	rename(dupImgTitle);
	selectImage(dupImgTitle);
	run("Find Edges");
	setTool("wand");
	anotNO=1;
	roiManager("reset");
	while(true){
		waitForUser("Click within any cell area to select the cell boundary,\n then click OK to proceed. (Use image with title Original Image-Dup )");
		// Get the user-drawn ROI

		roiManager("Add");
		roiManager("select", roiManager("count")-1);
		roiManager("Rename", "Cell-"+anotNO);
		if (getBoolean("Do you want to select other cells in the same image?", "Yes", "No")) {
			anotNO++;
			continue;
		
			}
		else{
			break;
			}
	}
	if (!File.exists(output + File.separator + imageName)) {
    	File.makeDirectory(output + File.separator + imageName);
		}
	roiManager("Save", output + File.separator + imageName + File.separator + "imageROIs.zip");
	print(roiManager("count"));
	for (r=0;r<roiManager("count");r++){
		selectWindow(origImgTitle);
		roiManager("select", r);
		roiName =Roi.getName;
		run("Analyze Particles...", "clear add");
		run("Set Measurements...", "centroid redirect=None decimal=3");
		roiManager("deselect");
		roiManager("Measure");
		computeCentroidDistances(output,imageName,roiName);
		if (!File.exists(output + File.separator + imageName)) {
    		File.makeDirectory(output + File.separator + imageName);
			}
		roiManager("Save", output + File.separator + imageName + File.separator + roiName + "_rois.zip");
		roiManager("reset");
		roiManager("open", output + File.separator + imageName + File.separator + "imageROIs.zip");
		
		}
	
	
}

function thresholding(origImgTitle){
	selectWindow(origImgTitle);
	setThreshold(254, 255, "raw");
	//setThreshold(254, 255);
	run("Convert to Mask");
	run("Invert LUT");
	run("Median", "radius=3");
	
	}
	
function computeCentroidDistances(output,imageName,roiName) {
    nRows = nResults;
    if (nRows == 0) {
        showMessage("Error", "No data in Results table.");
        return;
    }

    // Read centroid X and Y values
    ArrayX = newArray(nRows);
    ArrayY = newArray(nRows);
    ArrayCol =newArray(nRows);
    for (i = 0; i < nRows; i++) {
        ArrayX[i] = getResult("X", i);
        ArrayY[i] = getResult("Y", i);
        ArrayCol[i]=d2s(i+1,0);
    }
    // Clear current results table
    run("Clear Results");

    // Calculate pairwise distances and populate new table
    counter = 0;
    for (i = 0; i < nRows; i++) {
        for (j = 0; j < nRows; j++) {
            dx = ArrayX[i] - ArrayX[j];
            dy = ArrayY[i] - ArrayY[j];
            dist = sqrt(dx*dx + dy*dy);
            setResult(ArrayCol[j], counter, dist);

        }
        counter++;
    }

    updateResults();
   // output = "D:/Bioimaging_Projects/Peter March";
    //imageName ="temp";
    if (!File.exists(output + File.separator + imageName)) {
    	File.makeDirectory(output + File.separator + imageName);
		}
    saveAs("Results", output+ File.separator + imageName+File.separator + roiName + "_Centroid_Distances.csv");
}
