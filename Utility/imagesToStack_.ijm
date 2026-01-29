//Author: Muhammad Aurangzeb Khan
//This macro can convert images present in some folder to a stack

#@ File    (label = "Source directory", style = "directory") //input path to the directory conataining input images.
#@ String  (label = "File extension", value=".tif") ext

processFolder(input);
function processFolder(input) {
	//pathToOrigImgs = input + "\\aligned";
	pathToOrigImgs = input;
	print(pathToOrigImgs);
	list = getFileList(pathToOrigImgs);
	strList = newArray();
	numList = newArray();
	
	imcnt =0;
	for (i = 0; i < list.length; i++) {
		if(endsWith(list[i], ext)){
			fName = list[i];
			strList[imcnt]=fName;
		    dotInd = indexOf(fName, ".");
			spInd = lastIndexOf(fName, " ");
			numList[imcnt]=parseInt(substring(fName,spInd+1,dotInd));
		
			imcnt = imcnt + 1;
		}
	}

	Array.sort(numList,strList);
	close("*");

	imcnt =0;
	for (i = 0; i < strList.length; i++) {
		if(endsWith(strList[i], ext)){
			imcnt = imcnt + 1;
			processFile(input, strList[i],imcnt);
			//break;
		}
	}
	
	run("Images to Stack", "  title=[WT] use"); //in title, replace 'WT' with some substring from names of the images 
}

function processFile(input, file,imcnt) {
	// Do the processing here by adding your own code.
	//pathToOrigImg = input + File.separator +"aligned"+File.separator +file;
	pathToOrigImg = input + File.separator +file;
	open(pathToOrigImg);
	
}