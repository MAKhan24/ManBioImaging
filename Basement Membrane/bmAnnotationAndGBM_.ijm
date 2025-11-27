/*
 * Macro template to process multiple images in a folder
 */

#@ File (label = "Input directory", style = "directory") input

#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".tif") suffix

// See also Process_Folder.py for a version of this code
// in the Python scripting language.

// Specify the required extensions here
requiredExts = newArray("_HeatMap.tif", "_GBMprofile.csv", "_BM.zip");

processFolder(input);





function reset(){
	if (isOpen("ROI Manager")) {roiManager("reset"); close("ROI Manager");}
    if (isOpen("Results")){run("Clear Results"); close("Results");}	
    if (isOpen("Log")){close("Log");}	
    close("*");
}
// Helper to expand an array by one element
function append(array, value) {
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
            baseNames = append(baseNames, base);
            counts = append(counts, 1);
            latestTime = append(latestTime, File.lastModified(filePath));
            
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
	list = getFileList(input);
	list = Array.sort(list);
	newFileInd = 0;
	imCnt =0;
	
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
	imCnt=imCnt++;	
	totalImgs =0;
	for (i=0;i<list.length;i++){	
		if (endsWith(list[i], suffix)){
			totalImgs++;
			
			}
		}

	for (i = newFileInd; i < list.length; i++) {
		if(endsWith(list[i], suffix)){
			print("Image Number:" + (imCnt));	
			processFile(input, output, list[i]);
			if(i<list.length-1){
				if(endsWith(list[i+1], suffix)){				
					if (getBoolean("Proceed to next image?", "Yes", "No")) {
						imCnt++;
					}
					else{
						Dialog.create("All Done...");
						Dialog.addMessage("You have successfully processed "+ (imCnt+1)+ " of " + totalImgs+ " images.\n The Output files have been saved to "+ output);
						Dialog.show();
						break;
						}
					}
				}
			else{
				Dialog.create("All Done...");
				Dialog.addMessage("All the images are done and output files have been saved to "+ output);
				Dialog.show();

				}
							
			}
	
		}
	
	reset();
	
	}


function processFile(input, output, file){ 
	close("*");
	path = input + File.separator + file;
	print("Processing: " + input + File.separator + file);
	open(path);
	getPixelSize(unit, pw, ph, pd);
	//print(pw);
	origImgTitle ="Original Image";
	rename(origImgTitle);
	run("Duplicate...", "ignore");
	dupImgTitle ="Original Image-Dup";
	rename(dupImgTitle);
	selectImage(dupImgTitle);
	anotNO=1;
	roiManager("reset");
	while(true){
		waitForUser("Select the polygon tool and draw the basement membrane boundary,\n then click OK to proceed. (Use image with title Original Image-Dup )");

		// Get the user-drawn ROI
		if (selectionType()>0){ 

			roiManager("Add");
			roiManager("select", roiManager("count")-1);
			roiManager("Rename", "Basement_Membrane"+anotNO);
			if (getBoolean("Do you want to annotate other areas in the same images?", "Yes", "No")) {
				anotNO++;
				continue;
					}
			else{
				break;
				}
			}	
		else{
			continue;	
			}
	}
	fname = File.getNameWithoutExtension(path);
	roiManager("Save", output + File.separator + fname + "_BM.zip");
	print("Basement membrane annotation saved to: " +output + File.separator + fname + "_BM.zip");
	close(dupImgTitle);
	open(path);
	roiIndex = newArray(roiManager("count"));
	for(i=0;i<roiManager("count");i++){
		roiIndex[i]=i;			
		}
	roiManager("select", roiIndex);
	roiManager("combine");
	roiManager("Add");
	selectImage(origImgTitle);
	roiManager("show all without labels");
	roiManager("select", roiManager("count")-1);
	run("Clear Outside");
	run("Fill", "slice");
	run("Convert to Mask");
	run("Duplicate...", "ignore");
	rename(dupImgTitle);
	selectImage(dupImgTitle);
	//run("Local Thickness (masked, calibrated, silent)");
	run("Geometry to Distance Map", "threshold=255");
	thicknessImgTitle = "Local Thickness";
	rename(thicknessImgTitle);
	save(output+ File.separator + fname+"_HeatMap.tif");
	
	selectImage(dupImgTitle);
	run("Skeletonize");
	skeletonImgTitle = "Skeleton1";
	rename(skeletonImgTitle);
	run("Skeleton Geodesic Diameter", "input=[Skeleton1] chamfer=[Chessknight (5,7,11)] show image=[Skeleton1] export");
	selectImage(thicknessImgTitle);
	run("Duplicate...", "ignore");
	roiCount = roiManager("count");
	roiManager("Select", roiCount-1);
	//roiManager("Show All");
	run("Create Mask");
	run("32-bit");
	run("Divide...", "value=255");
	//multiplier = (Math.pow(2, 32));
	//run("Multiply...", "value="+multiplier);
	skeletonImgTitle = "Skeleton";
	rename(skeletonImgTitle);
	
	//selectImage(origImgTitle);
	//run("Distance Map");
	//imageCalculator("AND create", origImgTitle,dupImgTitle);
	imageCalculator("Multiply create", thicknessImgTitle,skeletonImgTitle);
	bmImgTitle = "BM Width Image";
	rename(bmImgTitle);
	selectImage(bmImgTitle);
	getDimensions(width, height, channels, slices, frames);
	

	
	
	profileArray = newArray(0);
	xVal = newArray(0);
	k = 0;
	xInd = newArray(0);
	yInd = newArray(0);
	for(i=0;i<width;i++){
		for(j=0;j<height;j++){
			if (getPixel(i,j)!=0){
				profileArray[k]=getPixel(i,j)*2;
				if (unit=="microns" && pw==ph) {
					profileArray[k] = profileArray[k]*pw;		
					}
				else if(unit=="pixels"){
					print("As pixel size in microns is not given, so the GBM will be in pixels.")
					profileArray[k] = profileArray[k];
				}
				xInd[k]=i; yInd[k]=j;
				xVal[k]=k;
				k=k+1;
				}
			}
		}
	// Open file for writing
	
	
	file = File.open(output+ File.separator + fname+"_GBMprofile.csv");

	// Write CSV header
	print(file, "Index,Value");

	// Write array values
	for (i = 0; i < profileArray.length; i++) {
    	print(file, i + "," + profileArray[i]);
	}

	// Close file
	File.close(file);
//	Plot.create("Simple Plot", "X","Y", xVal, profileArray);
//	Array.getStatistics(profileArray,minimum, maximum,mean,stdDev);
	//close("*");

}


