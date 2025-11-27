
//print("Hello")

/*
 * Macro template to process multiple images in a folder
 */

#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output

// See also Process_Folder.py for a version of this code
// in the Python scripting language.
processFolder(input)

// function to scan folders/subfolders/files to find files with correct suffix



function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	Array.print(list);
	imcnt = 0;
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i])){
			print(imcnt); 
			processSubDir(input, output, list[i],imcnt);
			imcnt=imcnt+1;
		}
		else{
			continue;
		}
	}
}

function processSubDir(input, output, tempfile,imcnt) {
	// Do the processing here by adding your own code.
	// Leave the print statements until things work, then remove them.
	file = tempfile.substring(0,lengthOf(tempfile)-1);
	print("Processing: " + input + File.separator + file);
	path = input + File.separator + file;
	filename = file;
	imgInfoPath = input + File.separator + file+File.separator+"ImageInfo.xls";
	//print(imgInfoPath);
	run("Table... ", "open=["+ imgInfoPath + "]");
	imgInfoTable = "ImageInfo.xls"; 
	frameInterval = Table.get("Frame Interval",0,imgInfoTable);
	//print(frameInterval);
	width = Table.get("Width",0,imgInfoTable);
	height = Table.get("Height",0,imgInfoTable);
	depth = Table.get("No Of Frames",0,imgInfoTable);

	//close("*");

	csvFilesList = getFileList(path);
	csvFilesList = Array.sort(csvFilesList);
	//Array.print(csvFilesList);


					
	mjTable = "Median Major Axis";
	Table.create(mjTable);
	miTable = "Median Minor Axis";
	Table.create(miTable);
	ratioTable = "Median Major-Minor Ratio";
	Table.create(ratioTable);
	arTable = "Median Area";
	Table.create(arTable);
	ciTable = "Median Circularity";
	Table.create(ciTable);
	ccTable = "Cell Count";
	Table.create(ccTable);
	trackTable = "Cell Position in Each Track";
	Table.create(trackTable);
	trackDurInFramesTable = "Tracks Frame Duration";
	Table.create(trackDurInFramesTable);
	meanSpeedTable = "Tracks Mean Speed";
	Table.create(meanSpeedTable);
	TDTTable = "Total Distance Traveled";
	Table.create(TDTTable);
	MSLPTable = "Mean Straight Line Speed";
	Table.create(MSLPTable);
	LFPTable = "Linearty of Forward Progression";
	Table.create(LFPTable);
	DirChgRtTable = "Mean Directional Change Rate";
	Table.create(DirChgRtTable);


	for (i = 0; i <csvFilesList.length; i++) { //csvFilesList.length
		print(csvFilesList[i]); 
		if (endsWith(csvFilesList[i],"-tracks.csv")){
			csvFilenameWOExt = File.getNameWithoutExtension(csvFilesList[i]);
			pathToFile = path+ File.separator + csvFilesList[i] ;
			run("Table... ", "open=["+ pathToFile + "]");
			rawTable  = csvFilesList[i];
			
			scriptNo = csvFilesList[i].substring(7,8);
			headings = split(Table.headings(rawTable));


			for(k=0; k<headings.length;k++){
				if (headings[k].matches("LABEL") || headings[k].matches("TRACK_INDEX") || headings[k].matches("TRACK_ID") || headings[k].matches("NUMBER_SPOTS") || headings[k].matches("TRACK_DURATION") || headings[k].matches("TRACK_START") || headings[k].matches("TRACK_STOP") || headings[k].matches("TRACK_DISPLACEMENT") || headings[k].matches("TRACK_X_LOCATION") || headings[k].matches("TRACK_Y_LOCATION") || headings[k].matches("TOTAL_DISTANCE_TRAVELED") || headings[k].matches("TRACK_MEAN_SPEED") || headings[k].matches("MEAN_STRAIGHT_LINE_SPEED") || headings[k].matches("LINEARITY_OF_FORWARD_PROGRESSION") || headings[k].matches("MEAN_DIRECTIONAL_CHANGE_RATE") ){
					continue;						
					}
				else {
					Table.deleteColumn(headings[k],rawTable);
					}
				
				}
			col = Table.getColumn("TRACK_DURATION",rawTable); 
			colName1 = filename.substring(4,6)+"-"+scriptNo+"_TRACK_ID";
			colName2 = filename.substring(4,6)+"-"+scriptNo+"_START_Frame";
			colName3 = filename.substring(4,6)+"-"+scriptNo+"_END_Frame";
			colName4 = filename.substring(4,6)+"-"+scriptNo+"_Duration";
			colName5 = filename.substring(4,6)+"-"+scriptNo+"_Displacement";	
			
			colName6 = filename.substring(4,6)+"-"+scriptNo+"_TOTAL_DISTANCE_TRAVELED";
			colName7 = filename.substring(4,6)+"-"+scriptNo+"_TRACK_MEAN_SPEED";
			colName8 = filename.substring(4,6)+"-"+scriptNo+"_MEAN_STRAIGHT_LINE_SPEED";
			colName9 = filename.substring(4,6)+"-"+scriptNo+"_LINEARITY_OF_FORWARD_PROGRESSION";
			colName10 = filename.substring(4,6)+"-"+scriptNo+"_MEAN_DIRECTIONAL_CHANGE_RATE";
			

			arrayDuration = newArray();
			arrayStart = newArray();
			arrayStop = newArray();
			arrayID = newArray();
			arrayDisp = newArray();
			
			arrayTDT =  newArray();
			arrayTMS =  newArray();
			arrayMSLP=  newArray();
			arrayLFP=  newArray();
			arrayMDCR=  newArray();
			
			
			
			rowInd =0;
			for(j=3; j<Table.size;j++){
				duration = Table.get("TRACK_DURATION",j,rawTable);
				start = Table.get("TRACK_START",j,rawTable);
				stop = Table.get("TRACK_STOP",j,rawTable);
				ID = Table.get("TRACK_ID",j,rawTable);
				disp = Table.get("TRACK_DISPLACEMENT",j,rawTable);
				
				arrayTDT[rowInd] = Table.get("TOTAL_DISTANCE_TRAVELED",j,rawTable);
				arrayTMS[rowInd] = Table.get("TRACK_MEAN_SPEED",j,rawTable);
				arrayMSLP[rowInd] = Table.get("MEAN_STRAIGHT_LINE_SPEED",j,rawTable);
				arrayLFP[rowInd] = Table.get("LINEARITY_OF_FORWARD_PROGRESSION",j,rawTable);
				arrayMDCR[rowInd] = Table.get("MEAN_DIRECTIONAL_CHANGE_RATE",j,rawTable);
				
				
				
				arrayDuration[rowInd]=Math.round(duration/frameInterval);
				arrayStart[rowInd]=Math.round(start/frameInterval);
				arrayStop[rowInd]=Math.round(stop/frameInterval);
				arrayID[rowInd]=ID;
				arrayDisp[rowInd]=disp;
				rowInd++;
			}
			
			Table.setColumn(colName1,arrayID,trackDurInFramesTable);
			Table.setColumn(colName2,arrayStart,trackDurInFramesTable);
			Table.setColumn(colName3,arrayStop,trackDurInFramesTable);
			Table.setColumn(colName4,arrayDuration,trackDurInFramesTable);
			Table.setColumn(colName5,arrayDisp,trackDurInFramesTable);
			
			Table.setColumn(colName6,arrayTDT,trackDurInFramesTable);
			Table.setColumn(colName7,arrayTMS,trackDurInFramesTable);
			Table.setColumn(colName8,arrayMSLP,trackDurInFramesTable);
			Table.setColumn(colName9,arrayLFP,trackDurInFramesTable);
			Table.setColumn(colName10,arrayMDCR,trackDurInFramesTable);
			
			
			Table.update(trackDurInFramesTable);

			Table.save(input + File.separator + filename +  File.separator + trackDurInFramesTable+".csv",trackDurInFramesTable);
			close(rawTable);
			}
		else if(endsWith(csvFilesList[i],"-spots.csv")){
				
				csvFilenameWOExt = File.getNameWithoutExtension(csvFilesList[i]);
				pathToFile = path+ File.separator + csvFilesList[i] ;
				//print(pathToFile);
				run("Table... ", "open=["+ pathToFile + "]");
				headings = split(Table.headings(csvFilesList[i]));
				
				scriptNo = csvFilesList[i].substring(7,8);
				
				
				rawTable  = csvFilesList[i]; //Table.title();

				headings = split(Table.headings(rawTable));
				
				for(k=0; k<headings.length;k++){
					if (headings[k].matches("TRACK_ID") || headings[k].matches("POSITION_X") || headings[k].matches("POSITION_Y") ||headings[k].matches("FRAME") || headings[k].matches("ELLIPSE_MAJOR") || headings[k].matches("ELLIPSE_MINOR") || headings[k].matches("AREA") || headings[k].matches("CIRCULARITY")){
						continue;						
						}
					else {
						Table.deleteColumn(headings[k],rawTable);
						}
				
					}
				col = Table.getColumn("AREA",rawTable); 
				
				for(j=0; j<col.length;j++){
					major = Table.get("ELLIPSE_MAJOR",j,rawTable);

					minor = Table.get("ELLIPSE_MINOR",j,rawTable);
					area = Table.get("AREA",j,csvFilesList[i]);
					//Table.set("ELLIPSE_MAJOR",j,(major/resolution),csvFilesList[i]);
					//Table.set("ELLIPSE_MINOR",j,(minor/resolution),csvFilesList[i]);
					//Table.set("AREA",j,(area/(resolution*resolution)),csvFilesList[i]);
					Table.set("ELLIPSE_MAJOR",j,(major),rawTable);
					Table.set("ELLIPSE_MINOR",j,(minor),rawTable);
					Table.set("AREA",j,(area),rawTable);
					}
	


				colName = filename.substring(4,6)+"-"+scriptNo;
				
				arrayMajor = newArray();
				arrayMinor = newArray();
				arrayArea = newArray();
				arrayCirc = newArray();
				arrayRatio = newArray();
				arrayMedMajor = newArray();
				arrayMedMinor = newArray();
				arrayMedArea = newArray();
				arrayMedCirc = newArray();	
				arrayMedRatio = newArray();
				arrayFrameNo = newArray();
				
				for (fNo=0; fNo<depth;fNo++){
					rowInd = 0;
					for(j=3; j<Table.size(rawTable);j++){
						frameNo = parseInt(Table.get("FRAME",j,rawTable)); 
						if(frameNo ==fNo){
							major = parseFloat(Table.get("ELLIPSE_MAJOR",j,rawTable));
							minor = parseFloat(Table.get("ELLIPSE_MINOR",j,rawTable));
							area = parseFloat(Table.get("AREA",j, rawTable));
							circ = parseFloat(Table.get("CIRCULARITY",j, rawTable));
							ratio = major/minor;

							arrayMajor[rowInd] = major;
							arrayMinor[rowInd] = minor;
							arrayRatio[rowInd] = ratio;
							arrayArea[rowInd] = area;
							arrayCirc[rowInd] = circ;
							rowInd++;
							
							}
						}
						if (arrayMajor.length==0){
							arrayMedMajor[fNo] = 0;
							arrayMedMinor[fNo] = 0;
							arrayMedRatio[fNo] = 0;
							arrayMedArea[fNo] = 0;
							arrayMedCirc[fNo] = 0;
							arrayFrameNo[fNo] = fNo;
							}
						else{
							arrayMedMajor[fNo] = median(arrayMajor);
							arrayMedMinor[fNo] = median(arrayMinor);
							arrayMedRatio[fNo] = median(arrayRatio);
							arrayMedArea[fNo] = median(arrayArea);
							arrayMedCirc[fNo] = median(arrayCirc);
							arrayFrameNo[fNo] = fNo;
								}

				}
				if (scriptNo == "1"){
					Table.setColumn("FRAME",arrayFrameNo, mjTable);
					Table.setColumn("FRAME",arrayFrameNo, miTable);
					Table.setColumn("FRAME",arrayFrameNo, ratioTable);
					Table.setColumn("FRAME",arrayFrameNo, arTable);
					Table.setColumn("FRAME",arrayFrameNo, ciTable);

					Table.update(mjTable);
					Table.update(miTable);
					Table.update(ratioTable);
					Table.update(arTable);
					Table.update(ciTable);
				}		
				Table.setColumn(colName,arrayMedMajor,mjTable);
				Table.setColumn(colName,arrayMedMinor,miTable);
				Table.setColumn(colName,arrayMedRatio,ratioTable);
				Table.setColumn(colName,arrayMedArea,arTable);
				Table.setColumn(colName,arrayMedCirc,ciTable);

				Table.update(mjTable);
				Table.update(miTable);
				Table.update(ratioTable);
				Table.update(arTable);
				Table.update(ciTable);
				close(rawTable);	

				Table.save(input + File.separator + filename +  File.separator + mjTable + ".csv", mjTable );
				Table.save(input + File.separator + filename +  File.separator + miTable + ".csv", miTable );
				Table.save(input + File.separator + filename +  File.separator + ratioTable + ".csv", ratioTable );
				Table.save(input + File.separator + filename +  File.separator + arTable + ".csv", arTable );
				Table.save(input + File.separator + filename +  File.separator + ciTable + ".csv", ciTable );
				close(rawTable);
			//}	
		//else if(endsWith(csvFilesList[i],"-spotsNuclei.csv")){
		//else if(endsWith(csvFilesList[i],"-spotsN.csv")){

				csvFilenameWOExt = File.getNameWithoutExtension(csvFilesList[i]);
				pathToFile = path + File.separator + csvFilesList[i] ;
				//print(pathToFile);
				run("Table... ", "open=["+ pathToFile + "]");
				scriptNo = csvFilesList[i].substring(7,8);
				rawTable  = csvFilesList[i]; //Table.title();
				headings = split(Table.headings(rawTable));

				for(k=0; k<headings.length;k++){
					if (headings[k].matches("TRACK_ID") || headings[k].matches("POSITION_X") || headings[k].matches("POSITION_Y")|| headings[k].matches("FRAME") || headings[k].matches("POSITION_T")){
						continue;						
						}
					else {
						Table.deleteColumn(headings[k],csvFilesList[i]);
						}
				
					}
				headings = split(Table.headings(rawTable));
				colName1 = filename.substring(4,6)+"-"+scriptNo+"_TRACK_ID";
				colName2 = filename.substring(4,6)+"-"+scriptNo+"_POS_X";
				colName3 = filename.substring(4,6)+"-"+scriptNo+"_POS_Y";
				colName4 = filename.substring(4,6)+"-"+scriptNo+"_Normalized_POS_X";
				colName5 = filename.substring(4,6)+"-"+scriptNo+"_Normalized_POS_Y";
				colName6 = filename.substring(4,6)+"-"+scriptNo+"_Instantaneous_Speed";
				
				arrayTrackID = newArray();
				arrayX = newArray();
				arrayY = newArray();
				arrayNormX = newArray();
				arrayNormY = newArray();
				arrayIntSpeed = newArray();
				rowInd =0;
				prevTrackID = 20000;
				for(j=3; j<Table.size(rawTable);j++){
					trackID = Table.get("TRACK_ID",j,rawTable);
					//print(trackID);
				
					if (isNaN(trackID)){
						continue;
					}
					else{ //if(trackName.contains("Track")){
						//print(trackId);
						trackID = parseInt(trackID);
						xPos = parseFloat(Table.get("POSITION_X",j,rawTable));
						yPos = parseFloat(Table.get("POSITION_Y",j,rawTable));
						time = parseFloat(Table.get("POSITION_T",j,rawTable));
						
						
						if ((j+1)<Table.size(rawTable)){
							trackIDNext = parseInt(Table.get("TRACK_ID",j+1,rawTable));
							xPosNext = parseFloat(Table.get("POSITION_X",j+1,rawTable));
							yPosNext = parseFloat(Table.get("POSITION_Y",j+1,rawTable));
							timeNext = parseFloat(Table.get("POSITION_T",j+1,rawTable));
							if	(trackID==trackIDNext){
								dist = sqrt(Math.sqr(yPosNext-yPos)+Math.sqr(xPosNext-xPos)) ;
								arrayIntSpeed[rowInd] = dist / (timeNext-time);
							}
							else{
								arrayIntSpeed[rowInd] = arrayIntSpeed[rowInd-1];
								
								}
						}
						else{
							arrayIntSpeed[rowInd] = arrayIntSpeed[rowInd-1];
							
							}
						

						arrayX[rowInd] = xPos;
						arrayY[rowInd] = yPos;
						arrayTrackID[rowInd]=trackID;
						
						if(trackID!=prevTrackID){
							startX = xPos;
							startY = yPos;
							prevTrackID = trackID;							
							}
						arrayNormX[rowInd] = xPos - startX;
						arrayNormY[rowInd] = yPos - startY;
						
						rowInd++;
						
					}
				}
				Table.setColumn(colName1,arrayTrackID,trackTable);
				Table.setColumn(colName2,arrayX,trackTable);
				Table.setColumn(colName3,arrayY,trackTable);
				Table.setColumn(colName4,arrayNormX,trackTable);
				Table.setColumn(colName5,arrayNormY,trackTable);
				Table.setColumn(colName6,arrayIntSpeed,trackTable);
				Table.update(trackTable);
				
				arrayCellCount = newArray();
				arrayFrameNo = newArray();
				colName = filename.substring(4,6)+"-"+d2s(scriptNo,0);
				
				for (fNo=0; fNo<depth;fNo++){
					spotsNo = 0;
					rowInd = 0;
					
					for(j=3; j<Table.size(rawTable);j++){
						frameNo = parseInt(Table.get("FRAME",j,rawTable));
						if(frameNo ==fNo){							
							spotsNo++;
						}
							
					}
					arrayCellCount[fNo] = spotsNo;
					arrayFrameNo[fNo] = fNo;
				}
				if (scriptNo == "1"){
					Table.setColumn("FRAME",arrayFrameNo, ccTable);
					Table.update(ccTable);
				}
				Table.setColumn(colName,arrayCellCount,ccTable);
				Table.update(ccTable);
				close(rawTable);
				//Table.reset(rawTable);				
				Table.save(input + File.separator + filename +  File.separator + ccTable + ".csv", ccTable );
				Table.save(input + File.separator + filename +  File.separator + trackTable + ".csv", trackTable );		
			}
	
				
		}
	close("*");
	
	close(mjTable);
	close(miTable);
	close(ratioTable);
	close(arTable);
	close(ciTable);
	close(ccTable);
	close(trackTable);
	close(trackDurInFramesTable);
					

}


function median(x){
    x=Array.sort(x);
    if (x.length%2>0.5) {
        m=x[floor(x.length/2)];
    }else{
        m=(x[x.length/2]+x[x.length/2-1])/2;
    };
    return m
}

