//selectWindow("osmo and or erm kd divxy21c1.tif");


origImgTitle = getTitle();
Stack.getDimensions(width, height, channels, slices, frames);
//print(slices, frames);
slicesNO = newArray(slices);
for(z=1; z<=slices; z++){
	slicesNO[z-1] = z;
}

// inuput parameters for cell_count()

//Blurring
sigma = 2; //sigma value in pixels for gaussian filter to smooth out the image
//Morphological operations
radiusCellCount  = 2; // circular distance to replace intensity values with the maximum value 
//to find maxima
prom = 25; // prominence value to find maxima for each cell

// inuput parameters for roundcell_count()

//segmentation
Th = 240;    // threshold to locate/segment round cells.

//Morphological operations
radiusRoundCell = 10; // circular distance to replace intensity values with the maximum value 
iterations = 5; // number of iterations for erosion operation
noPixels = 250; // Area (number of pixels) for area openning, i.e. to remove all the objects having area below this value.
LoTh_cric = 0.75; // lower threshold for the circularity metric to find the circular objects with circularity higher than this threshold




totalCellCount = cell_count(origImgTitle,sigma,radiusCellCount,prom); //Total cell count


roundCellCount = newArray(slices);

roundCellCount = roundcell_count(origImgTitle,Th,radiusRoundCell,iterations,noPixels,LoTh_cric); // round cell count
Table.create("Cell Count");
for (i=0; i<slices; i++) {
   	 Table.set("Slice",i,i+1);
  	 Table.set("Cell Count",i,totalCellCount[i]);
   Table.set("Round Cell Count",i,roundCellCount[i]);
}
    
Array.getStatistics(totalCellCount, min, max, mean, stdDev);
print("Average Count for all the Cells across Slices: " + mean);
Array.getStatistics(roundCellCount, min, max, mean, stdDev);
print("Average Count for round Cells across Slices " + mean);


Plot.create("Plot  for Total Cell Count", "Slice", "Count");
Plot.add("Separated Bars",slicesNO,totalCellCount);
Plot.setStyle(0, "blue,#a0a0ff,1.0,Separated Bars");
Plot.show;

Plot.create("Plot for Bright Round Cell Count", "Slice", "Count");
Plot.add("Separated Bars",slicesNO,roundCellCount);
Plot.setStyle(0, "blue,#a0a0ff,1.0,Separated Bars");
Plot.show;



function cell_count(origImgTitle,sigma,radiusCellCount,prom){

	Ch = 0;
	while(Ch==0){
		selectWindow(origImgTitle);
		run("Enhance Contrast", "saturated=0.35");
		run("8-bit");
		run("Duplicate...", "duplicate");
		dupImg1Title = getTitle();
		run("Duplicate...", "duplicate");
		dupImg2Title = getTitle();
		selectWindow(dupImg2Title);

	
		Stack.getDimensions(width, height, channels, slices, frames);

		run("Invert", "stack");
		run("Enhance Contrast", "saturated=0.35");
		dupImg2Title = getTitle();
		
		selectWindow(dupImg2Title);	
		run("Maximum...", "radius=&radiusCellCount stack");
		run("Gaussian Blur...", "sigma=&sigma stack");
		//delay = 2000; // 2 seconds
		run("Point Tool...", "type=Hybrid color=Green size=Small auto-measure label");

		count = newArray(slices);
		avgCount = 0;
		for(z=1; z<=slices; z++){
			selectWindow(dupImg2Title);
  			Stack.setSlice(z);
  			run("Find Maxima...", "prominence=&prom output=List");
  			selectWindow("Results");
  			Xpoints = newArray(nResults);
  			Ypoints = newArray(nResults);
  			for (i = 0; i < nResults(); i++) {
    			X = getResult('X', i);
    			Y = getResult('Y', i);
    			Xpoints[i] = X;
    			Ypoints[i] = Y;    		
			}
			selectWindow(dupImg1Title);
			Stack.setSlice(z);
			makeSelection("point add", Xpoints, Ypoints);
			count[z-1] = nResults;
			run("Clear Results");
		}
		close("Results");
		Dialog.createNonBlocking("Cell Counting") ;
		Dialog.addCheckbox("If image looks good, check the box and press OK.",false);
		Dialog.show();
		Ch = Dialog.getCheckbox();
		selectWindow(dupImg2Title);
		if (Ch==0){
			Dialog.createNonBlocking("Cell Counting Parameters");
			Dialog.addNumber("Sigma Value for Gaussian Blurring (pixels):",sigma );
			Dialog.addNumber("circular distance to replace intensity values with the maximum value:", radiusCellCount);
			Dialog.addNumber("Prominence Value for finding Maxima:", prom);
			Dialog.show();
			sigma = Dialog.getNumber();
			radiusCellCount = Dialog.getNumber();
			prom = Dialog.getNumber();
			close(dupImg2Title);
			close(dupImg1Title);

		}

	}
	close(dupImg2Title);
	return count;
}


function roundcell_count(origImgTitle,Th,radiusRoundCell,iterations,noPixels,LoTh_cric){
	Ch = 0;
	while(Ch==0){
		selectWindow(origImgTitle);

		run("Enhance Contrast", "saturated=0.35");
		run("8-bit");
		run("Duplicate...", "duplicate");
		dupImg1Title = getTitle();
		run("Duplicate...", "duplicate");
		dupImg2Title = getTitle();
		selectWindow(dupImg2Title);
		maskImgTitle = getTitle();
		Stack.getDimensions(width, height, channels, slices, frames);
		slicesNo = newArray(slices);
		for (z=1; z<=slices; z++){
			selectWindow(maskImgTitle);
  			Stack.setSlice(z);
  			slicesNo[z] = z;
			for (i=0; i<width; i++) {
				for (j=0; j<height; j++){
					if (getPixel(i,j)>=Th){
						setPixel(i,j,255);
					}
						else{
						setPixel(i,j,0);
							}
							
				}
			}
		}

	
		run("Maximum...", "radius=&radiusRoundCell stack");
		run("Fill Holes", "stack");
		run("Options...", "iterations=&iterations count=2 black edm=8-bit do=Erode stack");
		for (z=1; z<=slices; z++){
			Stack.setSlice(z);
			run("Area Opening", "pixel=&noPixels");
			areaOpen =getTitle();
			run("Duplicate...", "title=AreaOpen");
			close(areaOpen);
			selectWindow(maskImgTitle);
		}	
		close(maskImgTitle);
		run("Images to Stack", "name=ImageAreaOpen title=AreaOpen");
		imgstackTitle = getTitle();
		run("Set Measurements...", "area mean standard shape add redirect=None decimal=3");
		selectWindow(imgstackTitle);
	
		run("Set Measurements...", "area mean standard shape add redirect=None decimal=3");
		run("Analyze Particles...", "  circularity=&LoTh_cric-1.00 show=Nothing exclude clear summarize add stack");
		selectWindow(dupImg1Title);
		roiManager("Show All without labels");
		Dialog.createNonBlocking("Round Cell Counting") ;
		Dialog.addCheckbox("If image looks good, check the box and press OK.",false);
		Dialog.show();
		Ch = Dialog.getCheckbox();
		if (Ch==0){
			Dialog.createNonBlocking("Round Cell Counting Parameters");
			Dialog.addNumber("Threshold for Binarization(0-255):", Th);
			Dialog.addNumber("circular distance to replace intensity values with the maximum value:", radiusRoundCell);
			Dialog.addNumber("Area in number of pixels for area openning:", noPixels);
			Dialog.addNumber("Circularity Threshold:", LoTh_cric);
			Dialog.show();
			Th = Dialog.getNumber();
			radiusRoundCell = Dialog.getNumber();
			noPixels = Dialog.getNumber();
			LoTh_cric = Dialog.getNumber();
		}
		close("ImageAreaOpen");
		roiManager("reset");
		close(dupImg1Title);
		close(dupImg2Title);
	}
	
	//sliceNO = Table.getColumn("Slice", "Summary of ImageAreaOpen");
	//Array.print(slicesNo);
	count = Table.getColumn("Count", "Summary of ImageAreaOpen" );
	//Array.print(count);
	close("Summary of ImageAreaOpen");
	//close("ROI Manager");
	return count;
}
	
