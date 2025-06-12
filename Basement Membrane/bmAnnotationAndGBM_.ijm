/*
 * Macro template to process multiple images in a folder
 */

#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".tif") suffix

// See also Process_Folder.py for a version of this code
// in the Python scripting language.
//run("Clear Results");

processFolder(input);


// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	imCnt =1;
	for (i = 0; i < list.length; i++) {
		
	//for (i = 0; i < 1; i++) {
		
		//if(File.isDirectory(input + File.separator + list[i]))
			//processFolder(input + File.separator + list[i]);
		if(endsWith(list[i], suffix)){
			print("Image Number:" + imCnt);	
			processFile(input, output, list[i],imCnt);
			if(i<list.length-1){
				if (getBoolean("Proceed to next image?", "Yes", "No")) {
					imCnt++;
					//continue;
				}
				else{
					break;
					}
			}
							
		}
	
	}
}

function processFile(input, output, file,imCnt){ 
	close("*");
	path = input + File.separator + file;
	//print(path);
	open(path);
	getPixelSize(unit, pw, ph, pd);
	
//	print(unit);
//	print(pw);
//	print(ph);
//	print(pd);
//	
	origImgTitle ="Original Image";
	rename(origImgTitle);
	run("Duplicate...", "ignore");
	dupImgTitle ="Original Image-Dup";
	rename(dupImgTitle);
	selectImage(dupImgTitle);
	anotNO=1;
	roiManager("reset");
	while(true){
		waitForUser("Draw the basement membrane boundary using the Freehand tool,\n then click OK to proceed. (Use image with title Original Image-Dup )");
		// Get the user-drawn ROI

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
	fname = substring(File.getNameWithoutExtension(path),0,lengthOf(File.getNameWithoutExtension(path))-4);
	roiManager("Save", output + File.separator + fname + "_BM.zip");
	print("Basement membrane annotation saved to: " +output + File.separator + file + "_BM.zip");
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
	run("32-bit");
	run("Divide...", "value=255");
	run("Multiply...", "value=1023");
	skeletonImgTitle = "Skeleton";
	rename(skeletonImgTitle);
	
	//selectImage(origImgTitle);
	//run("Distance Map");
	//imageCalculator("AND create", origImgTitle,dupImgTitle);
	imageCalculator("AND create", thicknessImgTitle,skeletonImgTitle);
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
	close("*");

}

