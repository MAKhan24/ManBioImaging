#@ File (label = "Path to Input Composite Image", style = "file")imgPath  
dirPath= File.getParent(imgPath);

#@ String (choices={"Custom Model", "Default"}, style="radioButtonHorizontal") cpModelCh
#@ File (label = " Select Cellpose Custom Models", style = "file") cpCustomModel

#@ String (label = "Cellpose model", choices={"cyto","cyto2", "nuclei"}, style="listBox") cpDefaultModel


#@ Double(label="Cell diameter (default=200)", value=200.0) cpDiameter
#@ Double(label="Nuclei diameter (default=150)", value=150.0) nucleiDiameter
//#@ Float(label="Cell flow error threshold", style="slider", value=1, min=0, max=3, stepSize=0.1) cellposeFlowThreshold
//#@ Float(label="Cell probability threshold", style="slider", value=0, min=-6, max=6, stepSize=0.25) cellposeProbability
#@ Integer(label="Cytoplasm channel (0 means not present)", value=1, min=0) cytoChannel
#@ Integer(label="Nucleus channel (0 means not present)", value=-1, min=0) nucChannel


function getROIs(){
	run("Clear Results");
	roiManager("reset");
	//run("Fill Label Holes", "background=4 labeling=[8 bits]");
	run("Label image to ROIs");
	roiManager("Deselect");
	roiManager("Measure");
	run("Summarize");
	noROIs = roiManager("count");
	meanArea = getResult("Area",noROIs);
	//print(meanArea);
	roiToRemove= newArray();
	j=0;
	k=0;
	
	for (i =0; i < noROIs; i++) {
		areaTemp= getResult("Area",i);
		
		if (areaTemp<=(meanArea*0.20)){
			//print(areaTemp);
			roiToRemove[k]=i;
			k=k+1;
			}
	}
	if (roiToRemove.length>0){
		roiManager("select",roiToRemove);
		roiManager("delete");
		run("Label Size Filtering", "operation=Greater_Than size="+d2s(meanArea*0.20,0));
	}
 }

open(imgPath);

run("Colors...", "foreground=white background=black selection=red");
image = getTitle();
run("Remove Overlay");

roiManager("reset");
run("Clear Results");
run("Set Measurements...", "area centroid integrated redirect=None decimal=3");

////////////////////////////////////////////////////// CEll segmentation//////////////////////////////////////////////////////////
if (cpModelCh == "Custom Model"){
	cpModel = cpCustomModel;
	run("Cellpose ...", "env_path=C:\\Users\\d50111mk\\.conda\\envs\\bioimage_env env_type=conda model= model_path="+cpModel+" diameter="+cpDiameter+" ch1="+cytoChannel+" ch2="+nucChannel+" additional_flags=--use_gpu, True,--flow_threshold, 0.4,--cellprob_threshold, 0.0,--anisotropy, 1.0,--in_folders, True, --save_rois, True, --save_outlines, True");
	//run("Cellpose Advanced (custom model)", "diameter="+cpDiameter+" cellproba_threshold=0.0 flow_threshold=0.4 anisotropy=1.0 diam_threshold=0.0 model_path="+cpModel+"  model=cyto nuclei_channel="+nucChannel+" cyto_channel="+cytoChannel+" dimensionmode=2D stitch_threshold=0.0 omni=false cluster=false additional_flags=");
	}
else{
	cpModel = cpDefaultModel;
	run("Cellpose ...", "env_path=C:\\Users\\d50111mk\\.conda\\envs\\bioimage_env env_type=conda model="+cpModel+" model_path= diameter="+cpDiameter+" ch1="+cytoChannel+" ch2="+nucChannel+" additional_flags=--use_gpu, True,--flow_threshold, 0.4,--cellprob_threshold, 0.0,--anisotropy, 1.0,--save_rois, True");

	//run("Cellpose ...", "diameter="+cpDiameter+" cellproba_threshold=0.0 flow_threshold=0.4 anisotropy=1.0 diam_threshold=0.0 model="+cpModel+" nuclei_channel="+nucChannel+" cyto_channel="+cytoChannel+" dimensionmode=2D stitch_threshold=0.0 omni=false cluster=false additional_flags=");
	}

getMinAndMax(min, max);
segmentation = getTitle();
print(segmentation);
if(!endsWith(segmentation, "-cellpose")) exit("Cellpose did not return a labelmap");
selectWindow(segmentation);

getROIs();

run("Clear Results");
labelmap =getTitle();
if(labelmap!=segmentation){
	close(segmentation);
	}

selectImage(labelmap);
run("Duplicate...","title=LabelImg_Cells duplicate");
close(labelmap);

selectImage("LabelImg_Cells");
labelmap=getTitle();

selectImage(labelmap);

noROIs = roiManager("count");

roiManager("deselect");
roiManager("measure");
X_cell =newArray();
Y_cell =newArray();
for(i=0;i<noROIs;i++){
	X_cell[i]=getResult("X", i);
	Y_cell[i]=getResult("Y", i);
	}

/////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////// Nuclei segmentation//////////////////////////////////////////////////////////
selectImage(image);
run("Cellpose ...", "env_path=C:\\Users\\d50111mk\\.conda\\envs\\bioimage_env env_type=conda model=nuclei model_path= diameter="+nucleiDiameter+" ch1="+nucChannel+" ch2=0 additional_flags=--use_gpu, True ,--flow_threshold, 0.4,--cellprob_threshold, 0.0,--anisotropy, 1.0,--in_folders, True,--save_rois, True, --save_outlines, True");
//run("Cellpose Advanced", "diameter="+nucleiDiameter+ " cellproba_threshold=0.0 flow_threshold=0.4 anisotropy=1.0 diam_threshold=0.0 model=nuclei nuclei_channel=3 cyto_channel=2 dimensionmode=2D stitch_threshold=0.0 omni=false cluster=false additional_flags=");


labelImgNucTemp = getTitle();
selectImage(labelImgNucTemp);
getROIs();

labelImgNuc =getTitle();
if(labelImgNuc!=labelImgNucTemp){
	close(labelImgNucTemp);
	}


run("Clear Results");





selectImage(labelImgNuc);
run("Duplicate...","title=LabelImg_Nuclei duplicate");
close(labelImgNuc);

selectWindow("LabelImg_Nuclei");
labelImgNuc=getTitle();




selectImage(image);
run("Duplicate...", "title=Dup"+image+ " duplicate");

run("Split Channels");
redImg = "C1-Dup"+image;
greenImg ="C2-Dup"+image;
blueImg = "C3-Dup"+image;
selectImage(redImg);

noROIs_Nuclei = roiManager("count");
roiManager("deselect");
roiManager("measure");
X_nuclei =newArray();
Y_nuclei =newArray();
sumInt_nucleiTemp = newArray();
area_nucleiTemp = newArray();

for(i=0;i<noROIs_Nuclei;i++){
	X_nuclei[i]=getResult("X", i);
	Y_nuclei[i]=getResult("Y", i);
	sumInt_nucleiTemp[i] = getResult("IntDen",i);
	area_nucleiTemp[i] = getResult("Area",i);
	}

close(redImg);
close(greenImg);
close(blueImg);
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////Remove Cell rois that don't contain nuclei///////////////////////////////////////////////
selectImage(labelmap);
run("Label image to ROIs", "rm=[RoiManager[size=2, visible=true]]");
getROIs();
tempLabelimg=getTitle();


if(labelmap!=tempLabelimg){
	close(labelmap);
	labelmap=tempLabelimg;
	}


run("Clear Results");

selectImage(image);
run("Duplicate...", "title=Dup"+image+ " duplicate");

run("Split Channels");
redImg = "C1-Dup"+image;
greenImg ="C2-Dup"+image;
blueImg = "C3-Dup"+image;

close(greenImg);
close(blueImg);

selectImage(redImg);
roiManager("deselect");
roiManager("measure");
sumInt_total = newArray();
area_total = newArray();
sumInt_nuclei = newArray();
area_nuclei = newArray();

k=0;
m=0;
roiToRemove=newArray();
nucleiCheck =newArray(noROIs_Nuclei); // array to check for extra nuclei 
print(noROIs);
print(noROIs_Nuclei);

for(i=0;i<noROIs;i++){
	roi_Flag =false;
	roiManager("select",i);
	for(j=0;j<noROIs_Nuclei;j++){
		if(Roi.contains(X_nuclei[j], Y_nuclei[j])){
			sumInt_total[k]=getResult("IntDen",i);             //array to store total sum of intensities if nuclus present
			area_total[k]=getResult("Area",i);				     //array to store total area if nuclus present
			sumInt_nuclei[k]= sumInt_nucleiTemp[j];
			area_nuclei[k]=	area_nucleiTemp[j];		
			roi_Flag =true;
			k=k+1;
			nucleiCheck[j]=1;
			break;
		}
	}
	if(roi_Flag==false){
		roiToRemove[m]=i;
		m=m+1;	
		}
	//print(i);
}
print(roiToRemove.length);
if (roiToRemove.length>0){
	roiManager("select",roiToRemove);
	roiManager("delete");
}
//Array.print(nucleiCheck);
//print(roiManager("count"));

//print(sumInt_total.length);
//print(area_total.length);
//print(sumInt_nuclei.length);
//print(area_nuclei.length);

close(redImg);

close("Results");

noROIs = roiManager("count");


Table.create("Results");

Table.setColumn("Sum of Intensities (Whole Cell) ", sumInt_total);
Table.setColumn("Sum of Intensities (Nuclei Region) ", sumInt_nuclei);
Table.setColumn("Area (Whole Cell) ", area_total);
Table.setColumn("Area (Nuclei Region) ", area_nuclei);

selectImage(labelmap);
roiManager("reset");
run("Label image to ROIs");

selectImage(image);
roiManager("Show None");
roiManager("Show All");
run("Flatten");
flatImage=getTitle();

selectImage(labelImgNuc);
roiManager("reset");
run("Label image to ROIs");
selectImage(flatImage);
run("Colors...", "foreground=white background=black selection=yellow");
roiManager("Show None");
roiManager("Show All");
run("Flatten");


close(flatImage);
selectImage(labelImgNuc);
close();
selectImage(labelmap);
close();
close(image);
close("ROI Manager");


saveAs("Results", dirPath + File.separator + "Results.csv");
saveAs("Tiff", dirPath + File.separator +"ResImg.tif");
print("Done------");
