/*
 * Macro template to process multiple images in a folder
 */

#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".tif") suffix

// See also Process_Folder.py for a version of this code
// in the Python scripting language.


processFolder(input);
var Sigma = 0;
var noPixel_Med = 0;
var noPixel_Ext = 0;

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	Mode = getBoolean("For Auto Batch Processing press 'Yes', otherwise press 'No'.");
	
	
	inputImgInfo = getDir("Choose a Directory for Image Info Files"); 
	imcnt =0;
	//for (i = 0; i < list.length; i++) {
	for (i = 0; i < 2; i++) {
		if(File.isDirectory(input + File.separator + list[imcnt]))
			processFolder(input + File.separator + list[imcnt]);
		
			
			if(endsWith(list[imcnt], suffix)){
				if(i>0){
					Ch_proceed = getBoolean("Proceed to next image?");
					if(Ch_proceed == 1){
						processFile(input, output, list[imcnt],imcnt,Mode,inputImgInfo);
						
						imcnt = imcnt + 1;
					}
					else
						break;
						
								
				}
				else{
					processFile(input, output, list[imcnt],imcnt,Mode,inputImgInfo);

					imcnt = imcnt + 1;
					}
			}
	}
			
	
}

function processFile(input, output, file,imcnt,Mode,inputImgInfo) {
	// Do the processing here by adding your own code.
	// Leave the print statements until things work, then remove them.
	print("Processing: " + input + File.separator + file);
	print("Saving to: " + output);
	close("*");

	path = input + File.separator + file;
	dir = File.getParent(path);
	name = File.getName(path);

	open(path,1);
	titleSMA = getTitle();
	width=getWidth(); height=getHeight();
	run("Duplicate...", "title=imgSMA");
	//close(titleSMA);
	open(path, 4);
	idKERATIN  = getImageID();
	titleKERAT = getTitle();
	run("Duplicate...", "title=imgKERAT");

	//close(titleKERAT);

	//run("Merge Channels...", "c1=imgSMA c2=imgSOX c3=imgKERAT");
	run("Merge Channels...", "c1=imgSMA c3=imgKERAT");
	selectWindow("RGB");
	run("RGB to CIELAB");
	run("Stack to Images");
	selectWindow("b");
	close();
	selectWindow("a");
	close();
	selectWindow("L");
	
//gaussian Smooting	
	if (Mode == 1){
	
		if (imcnt == 0){
			run("Duplicate...", "title=Smoothing");
			Sigma = getNumber("Gaussian Blur: Sigma/Radius (Pixels)", 0);
			gaussian_smooth();
			Ch = getBoolean("If Image looks good press 'Yes' otherwise press 'No'.");

			while(Ch==0){
				close();
				run("Duplicate...", "title=Smoothing");
				Sigma = getNumber("Gaussian Blur: Sigma/Radius (Pixels)", 0);
				gaussian_smooth();			
				Ch = getBoolean("If Image looks good press 'Yes' otherwise press 'No'.");
			}
		}
		else{
			run("Duplicate...", "title=Smoothing");
			gaussian_smooth();
			}
	}
	else{
		run("Duplicate...", "title=Smoothing");
		Sigma = getNumber("Gaussian Blur: Sigma/Radius (Pixels)", 0);
		gaussian_smooth();
		Ch = getBoolean("If Image looks good press 'Yes' otherwise press 'No'.");
		while(Ch==0){
			close();
			run("Duplicate...", "title=Smoothing");
			Sigma =getNumber("Gaussian Blur: Sigma/Radius (Pixels)", 0);
			gaussian_smooth();
			Ch = getBoolean("If Image looks good press 'Yes' otherwise press 'No'.");
		}
	}
		
// Median Filtering
	if (Mode == 1){
		if (imcnt == 0){
			run("Duplicate...", "title=Median_Filtering");
			noPixel_Med = getNumber("Median Filtering: Area (in Pixels)", 0);
			run("Median...", "radius=&noPixel_Med");
			Ch = getBoolean("If Image looks good press 'Yes' otherwise press 'No'.");

			while(Ch==0){
				close();
				run("Duplicate...", "title=Median_Filtering");
				noPixel_Med = getNumber("Median Filtering: Area (in Pixels)", 0);
				run("Median...", "radius=&noPixel_Med");
				Ch = getBoolean("If Image looks good press 'Yes' otherwise press 'No'.");
			}
		}
	
		else{
			run("Duplicate...", "title=Median_Filtering");
			run("Median...", "radius=&noPixel_Med");
		}
	}
	else{
		run("Duplicate...", "title=Median_Filtering");
		noPixel_Med = getNumber("Median Filtering: Area (in Pixels)", 0);
		run("Median...", "radius=&noPixel_Med");
		Ch = getBoolean("If Image looks good press 'Yes' otherwise press 'No'.");
		while(Ch==0){
			close();
			run("Duplicate...", "title=Median_Filtering");
			noPixel_Med = getNumber("Median Filtering: Area (in Pixels)", 0);
			run("Median...", "radius=&noPixel_Med");
			Ch = getBoolean("If Image looks good press 'Yes' otherwise press 'No'.");
		}
	}
	
	
	titleMed = getTitle();
	
//image info
	/*newfile = replace(file,"_ac_full.tiff",".tiff");
	pathImgInfo = inputImgInfo + File.separator + newfile;
	open(pathImgInfo);
	titleImgInfo = getTitle;
	widthImgInfo = getWidth;
	heightImgInfo = getHeight;
	depthImgInfo = nSlices;
	getPixelSize(unit, pw, ph, pd);
	close(titleImgInfo);
	MicronsPerPixel = pw*25400;
	ImRes = 1/MicronsPerPixel; */
	ImRes = 1;
	
			
// boundary extension
	if (Mode == 1){
		if (imcnt == 0){
			run("Duplicate...", "title=Extended_Boundary");
			run("Create Selection");
			noPixel_Ext = getNumber("Boundary Extension (in Microns), enter -ve value to shrink", 0);
			noPixel_Ext = noPixel_Ext * ImRes;
			run("Enlarge...","enlarge=&noPixel_Ext");
			//ID = getImageID();
			//selectImage(ID);
			//wait(1000);
			Ch = getBoolean("If Image looks good press 'Yes' otherwise press 'No'.");

			while(Ch==0){
				close();
				run("Duplicate...", "title=Extended_Boundary");
				run("Create Selection");
				noPixel_Ext = getNumber("Boundary Extension (in Microns), enter -ve value to shrink", 0);
				noPixel_Ext = noPixel_Ext * ImRes;
				run("Enlarge...","enlarge=&noPixel_Ext");
				Ch = getBoolean("If Image looks good press 'Yes' otherwise press 'No'.");
			}
		}
		
		else{
			run("Duplicate...", "title=Extended_Boundary");
			run("Create Selection");
			run("Enlarge...","enlarge=&noPixel_Ext");
		}
	}
	else{
		run("Duplicate...", "title=Extended_Boundary");
		run("Create Selection");
		noPixel_Ext = getNumber("Boundary Extension (in Microns), enter -ve value to shrink", 0);
		noPixel_Ext = noPixel_Ext * ImRes;
		run("Enlarge...","enlarge=&noPixel_Ext");
		//ID = getImageID();
		//selectImage(ID);
		//wait(1000);
		Ch = getBoolean("If Image looks good press 'Yes' otherwise press 'No'.");
		while(Ch==0){
			close();
			run("Duplicate...", "title=Extended_Boundary");
			run("Create Selection");
			noPixel_Ext = getNumber("Boundary Extension (in Microns), enter -ve value to shrink", 0);
			noPixel_Ext = noPixel_Ext * ImRes;
			run("Enlarge...","enlarge=&noPixel_Ext");
			Ch = getBoolean("If Image looks good press 'Yes' otherwise press 'No'.");
		}
	}
	selectWindow("Extended_Boundary");
	setForegroundColor(255, 255, 255);
	run("Fill", "slice");
	selectWindow("Extended_Boundary");
	run("Create Mask");
	selectWindow("Extended_Boundary");
	close();
	imageCalculator("Subtract create", "Mask","Median_Filtering");
	selectWindow("Median_Filtering");
	//close();
	selectWindow("Mask");
	selectWindow("Result of Mask");
	setOption("ScaleConversions", true);
	run("16-bit");


	
	
	
//Mean calculation


	path = input + File.separator +"New Tiffs" + File.separator + file;


	open(path);
	titleColl6 = getTitle();
	width=getWidth(); height=getHeight();
	run("Duplicate...", "title=Collagen6");

	close(titleColl6);
	
	/*roiManager("reset");
	selectWindow("Median_Filtering");
	setOption("ScaleConversions", true);
	run("8-bit");
	run("Create Selection");
	roiManager("Add");
	selectWindow("Median_Filtering");
	run("16-bit");
	selectWindow("Median_Filtering");
	selectWindow("Collagen6");
	
	run("Duplicate...", "title=Collagen6_1");
	run("From ROI Manager");
	roiManager("Select", 0);
	run("Clear Results");
	run("Measure");

	selectWindow("Results");
	mean5 = getResult("Mean", 0);
	print("Mean Value of whole field of view without Epithilial Region= " + mean5);*/
	
	
	
	
	
	
	
	
	roiManager("reset");
	selectWindow("Median_Filtering");
	setOption("ScaleConversions", true);
	run("8-bit");
	run("Create Selection");
	roiManager("Add");
	selectWindow("Median_Filtering");
	run("16-bit");
	selectWindow("Median_Filtering");
	selectWindow("Collagen6");
	run("Duplicate...", "title=Collagen6_1");
	run("From ROI Manager");
	roiManager("Select", 0);
	run("Clear Results");
	run("Measure");

	selectWindow("Results");
	mean1 = getResult("Mean", 0);
	print("Mean Value of Epithelial Region = " + mean1);

	
	
	
	roiManager("reset");
	selectWindow("Result of Mask");
	setOption("ScaleConversions", true);
	run("8-bit");
	run("Create Selection");
	roiManager("Add");
	selectWindow("Result of Mask");
	run("16-bit");

	selectWindow("Result of Mask");

	selectWindow("Collagen6");
	run("Duplicate...", "title=Collagen6_2");
	run("From ROI Manager");
	roiManager("Select", 0);
	run("Clear Results");
	run("Measure");

	selectWindow("Results");
	mean2 = getResult("Mean", 0);
	print("Mean Value of region between Epithelial Region and extended boundary = " + mean2);


	roiManager("reset");
	selectWindow("Mask");
	run("Create Selection");
	roiManager("Add");
	selectWindow("Collagen6");
	run("Clear Results");
	run("Duplicate...", "title=Collagen6_3");
	run("From ROI Manager");
	roiManager("Select", 0);
	run("Measure");

	selectWindow("Results");
	mean3 = getResult("Mean", 0);
	Area3 = getResult("Area", 0);
	print("Mean Value of region within extended boundary = " + mean3);
	Sum3 = mean3 * Area3;
	
	run("Clear Results");
	selectWindow("Collagen6");
	run("Measure");
	mean4 = getResult("Mean", 0);
	Area4 = getResult("Area",0);
	print("Mean Value of whole field of view = " + mean4);	
	Sum4 = mean4 * Area4;
	
	Area5 = Area4 - Area3;
	Sum5 = Sum4 - Sum3;
			
	mean5 = Sum5/Area5; 

	print("Mean Value of whole field of view without Epithilial Region= " + mean5);
	name1 = "Results.xls";
	path_Save = dir+ File.separator + name1;
	if (imcnt ==0){
		
		f = File.open(path_Save); // display file open dialog
		//f = File.open("/Users/wayne/table.txt");
		// use d2s() function (double to string) to specify decimal places 
		print(f, "File Name" + "\t"+ "Mean1" + " \t" + "Mean2" + " \t" + "Mean3" + " \t" + "Mean4" +  " \t" + "Mean5");
		print(f, name + "  \t" + d2s(mean1,10) + " \t" + d2s(mean2,10) + " \t" + d2s(mean3,10)+ " \t" + d2s(mean4,10) + " \t" + d2s(mean5,10));
		File.close(f);
	}
	else{
		File.append(name + "  \t" + d2s(mean1,10) + " \t" + d2s(mean2,10) + " \t" + d2s(mean3,10)+ " \t" + d2s(mean4,10)+ " \t" + d2s(mean5,10), path_Save );
		}
 //Sigma,noPixel_Med,noPixel_Ext
}


function gaussian_smooth(){
	run("Gaussian Blur...", "sigma=&Sigma");
	run("Options...", "iterations=1 count=1 black pad edm=16-bit");
	run("Convert to Mask");
	run("Fill Holes");
}
