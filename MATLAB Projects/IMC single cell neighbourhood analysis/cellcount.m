function [tempMsk,figTitle] = cellcount(imgStack,objsInImg,mask,emObjmask,soxObjmask,processCh,figTitle)
[chName,intTh] = parameters('cellcount');
if length(chName) ~= length(intTh)
    temp = ones(1,length(chName)-length(intTh))*intTh(1);
    intTh = [intTh temp];
end
nObjs = height(objsInImg);
thChoice ='n';
while thChoice == 'n' || thChoice == 'N'
    newObjmask = zeros(size(mask));
    for ii = 1:nObjs
        ind = find(mask==ii);
        meanChk =zeros(1,length(chName));
        allChannels = [chName{1}];
        for i = 1:length(chName)
            chInd = find(strcmpi(objsInImg.Properties.VariableNames,chName{i}));
            chTemp = imgStack(:,:,chInd-2);
            chTemp1 = chTemp*65535;
            chTemp1 = chTemp1./max(chTemp1(:));
            if i == length(chName)-1
                allChannels =[allChannels ' and ' chName{i+1}];
            elseif i < length(chName)-1
                allChannels =[allChannels ', ' chName{i+1}];
            end
            MeanInt = mean(chTemp1(ind));
            if intTh(i) < 0
                if MeanInt < abs(intTh(i))
                    meanChk(i) = 1;
                end
            else
                if MeanInt > intTh(i)
                    meanChk(i) = 1;
                end
            end


        end
        if sum(meanChk) == length(chName)
            newObjmask(mask==ii)= 1;
            newObjmask = logical(newObjmask);
        end

    end
    if processCh ~= "All"
        B2 = imoverlay(chTemp,mask,'green');
        B1 = imoverlay(B2,emObjmask,'blue');
        B0 = imoverlay(B1,soxObjmask,'red');
        B  = imoverlay(B0,newObjmask,'yellow');
        %figure,imshow(B,[]); title('CD68 +ve (Yellow), Sox9 +ve (Red), Cells within Epithelial region (Blue), other cells (Green)');
        figTitle = [allChannels ' +ve Cells (Yellow), ' figTitle];

        figure,imshow(B,[]); title(figTitle,'Interpreter','none');
        
        prompt = "Are you happy with the image, enter 'y' for yes and 'n' for no:   ";
        thChoice = input(prompt,'s');
        if thChoice == 'n' | thChoice == 'N'
            prompt = ["Enter the new Threshold, old one is " + num2str(intTh) +  ": "];
            intTh = input(prompt);
        end
    else
        thChoice = 'y';
    end

end
tempMsk =  bitand(mask,(uint16(newObjmask)*65535));
end