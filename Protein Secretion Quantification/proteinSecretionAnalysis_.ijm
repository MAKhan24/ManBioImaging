 /*
 * Macro template to process multiple images in a folder
 */

#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".tif") suffix

#@ File (label = "Conda Env Path", style = "directory") venvPath
#@ String (choices={"Custom Model", "Default"}, style="radioButtonHorizontal") cpModelCh
#@ File (label = " Select Cellpose Custom Models", style = "file") cpCustomModel
#@ String (label = "Cellpose model", choices={"cyto","cyto2", "nuclei"}, style="listBox") cpDefaultModel
#@ Double(label="Cell diameter (default=100)", value=100.0) cpDiameter
#@ Integer(label="Channel-1 (0 means not present)", value=1, min=0) chan
#@ Integer(label="Channel-2 (0 means not present)", value=1, min=0) chan2

#@ Double(label="Distance threshold (in microns) for filtering out Nuclei with neighbours within the given distance", value=10) distThreshold
#@ Double(label="Size threshold (in microns) for filtering out larger Nuclei", value=500) sizeUpperThreshold
#@ Double(label="Size threshold (in microns) for filtering out veru small Nuclei", value=50) sizeLowerThreshold


//#@ Double(label="Enter maximum radial distance around nucleus (microns):", value=10) maxRadiusMicrons
#@ Double(label="Enter number of concentric rings:", value=1) numRings
#@ Double(label="Enter thickness of each ring (micron):", value=5.0) ringThicknessMicrons
#@ Double(label="Enter number of fan sectors per ring:", value=1) numSectors
#@ Double(label="Enter size of a buffer zone around nucleus to avoid any leakages from nucleus to each sector (micron):", value=2.0) bufferMicrons

//setBatchMode(true);
// Global parameters to store threshold values
// Specify the required extensions here
var requiredExts = newArray("_ProteinCoverage.xls", "_RoiSet.zip");
var interactiveDone = false;
var metrics = newArray();
var multiArray =newArray();



// See also Process_Folder.py for a version of this code
// in the Python scripting language.

processFolder(input);

function reset(){
	if (isOpen("ROI Manager")) {roiManager("reset"); close("ROI Manager");}
    if (isOpen("Results")){run("Clear Results"); close("Results");}	
    //if (isOpen("Log")){close("Log");}	
    close("*");
}


// Helper to expand an array by one element
function appendArray(array, value) {
    newArray1 = newArray(array.length + 1);
    for (k = 0; k < array.length; k++) newArray1[k] = array[k];
    newArray1[array.length] = value;
    return newArray1;
}

// Function to get base name of the latest complete file set
function getLatestCompleteSet(folderPath, requiredExts) {
    list = getFileList(folderPath);
    if (list.length == 0) return "none"; // Empty folder

    baseNames = newArray(0);
    counts = newArray(0);
    latestTime = newArray(0);

    for (i = 0; i < list.length; i++) {
        file = list[i];
        
        filePath = folderPath +File.separator +file;
        //print(filePath);
        if (File.isDirectory(filePath)) continue;

        dot = lastIndexOf(file, "_");
        if (dot < 0) continue;
        base = substring(file, 0, dot);
        ext = substring(file, dot);


        // Is this a required extension?
        isReq = false;
        for (e = 0; e < requiredExts.length; e++)
            if (ext == requiredExts[e]) isReq = true;
        if (!isReq) continue;

        // Find or add the base name
        idx = -1;
        for (j = 0; j < baseNames.length; j++) {
            if (baseNames[j] == base) {
                idx = j;
                break;
            }
        }
        //print(idx);
        if (idx == -1) {
            baseNames = appendArray(baseNames, base);
            counts = appendArray(counts, 1);
            latestTime = appendArray(latestTime, File.lastModified(filePath));
            
        } else {
            counts[idx] = counts[idx] + 1;
            //print(File.lastModified(filePath));
            if (File.lastModified(filePath) > latestTime[idx])
                latestTime[idx] = File.lastModified(filePath);
        }
    }
    // Find the latest complete set
    bestBase = "none";
    bestTime = 0;
    for (i = 0; i < baseNames.length; i++) {
    
        if (counts[i] == requiredExts.length) {
        	
            if (latestTime[i] > bestTime) {
                bestBase = baseNames[i];
                bestTime = latestTime[i];
            }
        }
    }

    return bestBase;
}




// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	lastfileName = getLatestCompleteSet(output, requiredExts);
	//print(lastfileName);
	list = getFileList(input);
	list = Array.sort(list);
	newFileInd = 0;
	imCnt =1;
	
	if (!lastfileName.matches("none")){
		for (i=0;i<list.length;i++){
			if(endsWith(list[i], suffix)){
				imCnt++;
				currentFileName = File.getNameWithoutExtension(list[i]);
				if (currentFileName.matches(lastfileName)){
					newFileInd = i+1;
					break;
					}
				
				}
			}
		}

	//imCnt=imCnt++;	
	totalImgs =0;
	for (i=0;i<list.length;i++){	
		if (endsWith(list[i], suffix)){
			totalImgs++;
			
			}
		}
	//print(newFileInd);
	for (i = newFileInd; i < list.length; i++) {
	//for (i = newFileInd; i <newFileInd+1 ; i++) {
		if(endsWith(list[i], suffix)){
			print("Image Number:" + (imCnt));	
			processFile(input, output, list[i]);
			if(i<list.length-1){
				if(endsWith(list[i+1], suffix)){				
//					if (getBoolean("Proceed to next image?", "Yes", "No")) {
					imCnt++;
//					}
//					else{
//						Dialog.create("All Done...");
//						Dialog.addMessage("You have successfully processed "+ (imCnt+1)+ " of " + totalImgs+ " images.\n The Output files have been saved to "+ output);
//						Dialog.show();
//						break;
//						}
					}
				}
						
			}
	
		}
	Dialog.create("All Done...");
	Dialog.addMessage("All the images are done and output files have been saved to "+ output);
	Dialog.show();
	reset();
	
	}


function processFile(input, output, file) {
	//setBatchMode(true);
	print("Processing: " + input + File.separator + file);
	reset();
	path = input + File.separator + file;
	fname = File.getNameWithoutExtension(path);
	dir = File.getParent(path);
	name = File.getName(path);
	roiFilePath= output + File.separator + fname + "_RoiSet.zip";
	
	//run("Bio-Formats Importer", "open=["+path+ "] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
	open(path);
	origImgTitle ="Original Image";
	nucImgTitle = "Nuclei Image";
	proImgTitle = "Protein Image";
	lblImgTitle = "Label Image";
	rename(origImgTitle);
	run("Split Channels");
	
	
	selectImage("C1-"+origImgTitle);
	getLut(r, g, b);
	Array.getStatistics(r, rmin, rmax, rmean, rstdDev);
	Array.getStatistics(g, gmin, gmax, gmean, gstdDev);
	Array.getStatistics(b, bmin, bmax, bmean, bstdDev);

	if (bmax > rmax && bmax > gmax) rename(nucImgTitle);
	if (gmax > rmax && gmax > bmax) rename(proImgTitle);
	run("Enhance Contrast", "saturated=0.35");
	
	
	selectImage("C2-"+origImgTitle);
	getLut(r, g, b);
	Array.getStatistics(r, rmin, rmax, rmean, rstdDev);
	Array.getStatistics(g, gmin, gmax, gmean, gstdDev);
	Array.getStatistics(b, bmin, bmax, bmean, bstdDev);
	if (bmax > rmax && bmax > gmax) rename(nucImgTitle);
	if (gmax > rmax && gmax > bmax) rename(proImgTitle);
	run("Enhance Contrast", "saturated=0.35");
	
	
	selectImage(nucImgTitle);
	if (cpModelCh == "Custom Model"){
		cpModel = cpCustomModel;
		run("Cellpose ...", "env_path="+venvPath+ " env_type=conda model= model_path="+cpModel+ " diameter="+cpDiameter+ " ch1="+chan+"  ch2="+chan2+"  additional_flags=--use_gpu,--save_png");
	}
	else{
		cpModel = cpDefaultModel;
		run("Cellpose ...", "env_path="+venvPath+ " env_type=conda model="+cpModel+" model_path= diameter="+cpDiameter+ " ch1="+chan+"  ch2="+chan2+"  additional_flags=--use_gpu,--save_png");
	}
	
	rename(lblImgTitle);
	selectImage(lblImgTitle);
	run("Label image to ROIs");
	
	run("Keep IsolatedROIs ", "threshold="+distThreshold);
	selectImage(nucImgTitle);
	print(roiManager("count"));
	roiManager("Show All");
	filterROIsAtEdge(nucImgTitle);
	print(roiManager("count"));
	
	close(lblImgTitle);
	//concentricFanShapedSectors(proImgTitle);
//	
	//print(roiManager("count"));
	if(roiManager("count")!=0){
		roiManager("Save", roiFilePath);
		createShapePreservingSectorTiles(roiFilePath,fname,proImgTitle,output,
		numRings,   // numRings
    	numSectors,   // numSectors
   		ringThicknessMicrons, // ring thickness in microns
   		bufferMicrons);  // buffer around nucleus in microns
	}
	
	
}


function filterROIsAtEdge(imgTitle){
	selectImage(imgTitle);
	// Get image dimensions
	getDimensions(width, height, channels, slices, frames);
	run("Set Measurements...", "area redirect=None decimal=3");
	
	// Iterate through ROIs in the ROI Manager
	for (i = roiManager("count"); i > 0; i--) {
		// Select the current ROI
		roiManager("select", i - 1);
		roiManager("measure");
		// Get the ROI's bounding box
		getSelectionBounds(x, y, width1, height1);
		// Check if the ROI touches the edge
		if ((x == 0 || y == 0 || (x + width1) == width || (y + height1) == height || getResult("Area", 0)>sizeUpperThreshold || getResult("Area", 0)<sizeLowerThreshold)) {
			// Delete the ROI
			roiManager("delete");
			
			}
		run("Clear Results");	
			
		}
}

function createShapePreservingSectorTiles(roiZipPath, fname,imgTitle, output, numRings, numSectors, ringThicknessMicrons, bufferMicrons) {
    // Load image
    selectImage(imgTitle);

    // Load ROIs
    roiManager("reset");
    roiManager("Open", roiZipPath);
    roiCountAll = roiManager("count");
    print("Loaded " + roiCountAll + " ROIs");

    // Get image calibration
    getPixelSize(unit, pw, ph, pd);
    if (unit != "microns" && unit != "µm") {
        exit("Image must be calibrated in microns.");
    }
    micronPerPixel = pw;

    // Convert ring thickness and buffer to pixels
    ringThicknessPx = ringThicknessMicrons / micronPerPixel;
    bufferPx = bufferMicrons / micronPerPixel;

    // Prepare results
    if (isOpen("Results")) {
        selectWindow("Results");
        run("Clear Results");
    } else {
        run("Clear Results");
    }
    resultRow = 0;

    tempCnt =0;

    // Process each nucleus
    for (rIdx = 1; rIdx <= roiCountAll; rIdx++) {

   //for (rIdx =1; rIdx < 2; rIdx++) {
   		if (isOpen("ROI Manager")) {roiManager("reset"); close("ROI Manager");}
        // Generate ring-sector tiles
        //for (ring = 1; ring <= numRings; ring++) {
         //   for (sector = 0 ; sector <=numSectors ; sector++) { //numSectors
        for (ring = 1; ring <= numRings; ring++) {
            for (sector = 1 ; sector <=numSectors ; sector++) { //numSectors
            	print("sector "+ sector + " Ring" + ring + " Nucleus "+ rIdx);
            	run("Set Measurements...", "mean area centroid redirect=None decimal=3");
            	selectImage(imgTitle);
            	roiManager("reset");
    			roiManager("Open", roiZipPath);
        		roiManager("select", rIdx-1);
        		roiManager("reset");
        		roiManager("add");
        		roiManager("select", 0);
        		roiManager("rename", "Nucleus_" + (rIdx));
        		roiName = "Nucleus_" + (rIdx);
            	
            	
            	innerDist = bufferPx + (ring - 1) * ringThicknessPx;
            	outerDist = bufferPx + ring * ringThicknessPx;
            	//print("Inner and Outer dist:  " +innerDist + "  "+ outerDist);
                startAngle = (sector-1) * (360.0 / numSectors);
                endAngle = (sector ) * (360.0 / numSectors);

                // Duplicate nucleus shape and enlarge to outer radius
                roiManager("select", 0);
                //run("Restore Selection");
                roiManager("measure");
                xCenter = round(getResult("X", 0)/ micronPerPixel);
    			yCenter = round(getResult("Y", 0)/ micronPerPixel);
    			if (isOpen("Results")) {
   					selectWindow("Results");
    				run("Clear Results");
					}
				//print(xCenter+ " "+yCenter+ " "+micronPerPixel);
			    selectWindow(imgTitle);
			    roiManager("select", 0);
			    //print(roiName);
                run("Enlarge...", "enlarge=" + outerDist+ " pixel");
                
                roiManager("add");// Outer
                roiManager("select",roiManager("count") - 1)
                roiManager("rename", "Outer_ROI");
                run("Create Mask");
                rename("Outer Mask");
                
                selectWindow(imgTitle);
                getDimensions(width, height, channels, slices, frames);
                // Inner cutout
                roiManager("select",0);
                run("Enlarge...", "enlarge=" + innerDist + " pixel");
                roiManager("add"); // Inner
                roiManager("select",roiManager("count") - 1)
                roiManager("rename", "Inner_ROI");
                run("Create Mask");
                rename("Inner Mask");
                // Subtract inner from outer to get ring
                // Use image calculator to subtract inner from outer to create ring ROI
                imageCalculator("Subtract create", "Outer Mask", "Inner Mask");
                close("Inner Mask");
                close("Outer Mask");                  
                
                
                roiMask = "ROI Mask";
                rename(roiMask);


                // Create angular sector mask (approximate)
                // Get current ROI polygon coordinates
                run("Create Selection");
                roiManager("Add");
                roiManager("select",roiManager("count")-1);
                roiSector = "ROI Sector";
                roiManager("rename", roiSector);
               
                //Roi.getCoordinates(xpoints, ypoints);
                xpoints = newArray();
                ypoints = newArray();
                
                
                // Compute angles for sector limits in radians
                startRad = startAngle * PI / 180.0;
                endRad = endAngle * PI / 180.0;
                //print(startRad + "  "+endRad);
                pointCnt = 0;
                ind =0;
                selectWindow("ROI Mask");
                xPointsSector =newArray();
                yPointsSector =newArray();
                //print(width +"  "+height);
                for (i = 0; i < width; i++) {
                	for(j = 0; j<height; j++){
                		//print(getPixel(i, j));
                		angle = atan2((j-yCenter),(i-xCenter))+PI;
                		if (getPixel(i,j)==255 && angle>= startRad && angle<endRad ){
                			setPixel(i, j, 255);
                			}
                		else{
 							setPixel(i, j, 0);
                			
                			}
                		
                		}
                	}
                	
                run("Create Selection");
				roiManager("Add");
                roiManager("select",roiManager("count")-1);
                roiPoly = "Roi Polygon";
                roiManager("rename", roiPoly);

                 // Now intersect this sector polygon with the ring ROI shape to get final tile
                run("Create Mask");
                sectorMask = "Sector Mask";
                rename(sectorMask);
                // You can add further steps here to intersect masks if desired

                // Threshold protein within this tile separately
                selectImage(imgTitle);
				bitsPerPixel=bitDepth();

                selectWindow("Results");
        		run("Clear Results");
                run("Set Measurements...", "area mean standard min redirect=None decimal=3");       
                
				run("Measure");
				//proteinThValue = getResult("Max", nResults - 1)+(getResult("Max", nResults - 1)-getResult("Min", nResults - 1))/2;
				proteinThValue = getResult("Mean", nResults - 1)-getResult("StdDev", nResults - 1);
   				//print(proteinThValue);
   
   				run("Duplicate...","ignore");
                rename("TileCrop");
				selectWindow("TileCrop");
       			roiManager("select",roiManager("count")-1);
                //run("Crop");
				run("Clear Outside");
				selectWindow("Results");
        		run("Clear Results");
				run("Set Measurements...", "mean area redirect=None decimal=3");
				roiManager("measure");

                tileArea = getResult("Area", nResults - 1);
				
				run("Duplicate...","ignore");
				//setAutoThreshold("Default");
				//run("Threshold...");
                //setOption("BlackBackground", false);
                setThreshold(proteinThValue, Math.pow(2, bitsPerPixel), "raw");
                run("Convert to Mask");
                //run("Invert LUT");
                tileCropDup = getTitle();
                selectWindow("Results");
        		run("Clear Results");
        		//roiManager("reset");
                run("Set Measurements...", "mean area redirect=None decimal=3");
                run("Analyze Particles...", "clear summarize overlay add");
                selectWindow("Summary");
				roiCount = Table.get("Count", 0);
				//print(roiCount);
				if (roiCount == 0){
					proteinAreaMicron = 0;
					proteinMeanInt = 0;
					
					
					}
				else{
                	roiManager("Combine");
                	roiManager("add");
					roiManager("select",roiManager("count")-1);
                	selectWindow("TileCrop");
	                roiManager("measure");
                	selectWindow("Results");
                	proteinAreaMicron = getResult("Area", nResults - 1);
                	proteinMeanInt = getResult("Mean", nResults - 1); 
					}	
                
                
                name1 = fname+"_ProteinCoverage.xls";
			    path_Save = output+ File.separator + name1;
			    if (tempCnt ==0){
			    	f = File.open(path_Save); // display file open dialog
					// use d2s() function (double to string) to specify decimal places 
					print(f, "File Name" + "\t"+ "Nucleus ID" + " \t" + "Ring" + " \t" + "Sector"+  " \t" + "Start Angle" + " \t" + "End Angle" + " \t"+ "Mean Intensity" +  " \t" + "Tile Area"+  " \t" + "Protein Area"+  " \t" + "%ProteinCoverage" );
					print(f, name + "  \t" + d2s(rIdx,10) + " \t" + d2s(ring,10) + " \t" + d2s(sector,10)+ " \t" + d2s(startAngle,10)+ " \t" + d2s(endAngle,10) + " \t" + d2s(proteinMeanInt,10)+ " \t" + d2s(tileArea,10)+ " \t" + d2s(proteinAreaMicron,10)+ " \t" + d2s(100.0 * proteinAreaMicron / tileArea,10));
					File.close(f);
					}
			    else{
					File.append(name + "  \t" + d2s(rIdx,10) + " \t" + d2s(ring,10) + " \t" + d2s(sector,10)+ " \t" + d2s(startAngle,10)+ " \t" + d2s(endAngle,10) + " \t" + d2s(proteinMeanInt,10)+ " \t" + d2s(tileArea,10)+ " \t" + d2s(proteinAreaMicron,10)+ " \t" + d2s(100.0 * proteinAreaMicron / tileArea,10), path_Save );
					}

				run("Clear Results");

                // Safe close temporary images
                if (isOpen("TileCrop")) close("TileCrop");
                if (isOpen("TileProteinMask")) close("TileProteinMask");
                if (isOpen("TileMask")) close("TileMask");
                if (isOpen(tileCropDup)) close(tileCropDup);
                if (isOpen(sectorMask)) close(sectorMask);
                if (isOpen("ROI Mask")) close("ROI Mask");
                if (isOpen("Results")) close("Results");
                if (isOpen("ROI Manager")) close("ROI Manager");
                if (isOpen("Summary")) close("Summary");
                tempCnt++;
            }
        }
    }
    //print("Results saved.");
}

