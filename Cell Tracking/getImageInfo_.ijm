/*
 * Macro template to process multiple images in a folder
 */
//run("Bio-Formats Macro Extensions");
#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".nd2") suffix

// See also Process_Folder.py for a version of this code
// in the Python scripting language.
processFolder(input)

// function to scan folders/subfolders/files to find files with correct suffix



function processFolder(input) {
	
	list = getFileList(input);
	list = Array.sort(list);
	
	for (i = 0; i < list.length; i++) {
		imcnt =0;
		if(File.isDirectory(input + File.separator + list[i]))
			continue;
			//processFolder(input + File.separator + list[i]);
		if(endsWith(list[i], suffix)){
			imcnt = imcnt + 1;
			processFile(input, output, list[i],imcnt);
		}
		
	}
	print("All done...............");
	close("*");
}

function processFile(input, output, file,imcnt) {
	// Do the processing here by adding your own code.
	// Leave the print statements until things work, then remove them.
	print("Processing: " + input + File.separator + file);
	sourcePath = input + File.separator + file;
	fileNameWoExt =  File.getNameWithoutExtension(file);
	dstPath = output+File.separator+fileNameWoExt;
	run("Bio-Formats Importer", "open=["+sourcePath+"] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_2");
	
	//print(Ext.getSeriesCount(seriesCount))
	frameInterval = Stack.getFrameInterval();
	//print(frameInterval);
	width = getWidth;
  	height = getHeight;
  	depth = nSlices;
  	//print(depth);
  	getPixelSize(unit, pw, ph, pd);
  	name1 = "ImageInfo.xls";

	path_Save = dstPath+ File.separator + name1;
	if (imcnt ==1){
		
		f = File.open(path_Save); // display file open dialog
		//f = File.open("/Users/wayne/table.txt");
		// use d2s() function (double to string) to specify decimal places 
		print(f, "File Name" + "\t"+ "Frame Interval" + " \t" + "Width" + " \t" + "Height" + " \t" + "No Of Frames" + " \t" + "Units");
		print(f, fileNameWoExt + " \t" + d2s(frameInterval,10) + " \t" + d2s(width,10) + " \t" + d2s(height,10)+ " \t" + d2s(depth,10)+ " \t" + unit);
		File.close(f);
	}
	else{
		File.append(fileNameWoExt + " \t" + d2s(frameInterval,10) + " \t" + d2s(width,10) + " \t" + d2s(height,10)+ " \t" + d2s(depth,10)+ " \t" + unit, path_Save );
		}
	//close("*");
}