/*
 * Macro template to process multiple images in a folder
 */

#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".tif") suffix
setBatchMode(false); 
// See also Process_Folder.py for a version of this code
// in the Python scripting language.
print(input);
print(output);
processFolder(input);

function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	print(list.length);
	
	
	for (imcnt = 0; imcnt < list.length; imcnt++) {
	//for (imcnt = 0; imcnt < 6; imcnt++) {
		if(File.isDirectory(input + File.separator + list[imcnt]))
			processFolder(input + File.separator + list[imcnt]);
			print(list[imcnt]);
		//if(imcnt>0){
		if(endsWith(list[imcnt], suffix))
			processFile(input, output, list[imcnt]);
		//}
	}

function processFile(input, output, file) {
	// Do the processing here by adding your own code.
	// Leave the print statements until things work, then remove them.
	print("Processing: " + input + File.separator + file);
	print("Saving to: " + output);
	close("*");
	//path = File.openDialog("Select a File");
	path = input + File.separator + file;
	dir = File.getParent(path);
	name = File.getName(path);
	run("Bio-Formats Macro Extensions"); 

	//run("Bio-Formats Importer", "open= + path color_mode=Default rois_import=[ROI manager] split_channels view=Hyperstack stack_order=XYCZT");
	run("Bio-Formats Importer", "open=" + path + " color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");		

	//open(path);
	run("16-bit");
	outputPath = output + File.separator + file;
	//run("Bio-Formats Exporter", "save=" +outputPath+ "export");
	saveAs("Tiff", outputPath);
}