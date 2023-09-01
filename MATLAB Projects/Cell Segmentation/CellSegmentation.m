clear all
close all
clc


diskrad = 2;
dispCh = 'y';
StatCh ='mean'; % 'median','max','min','var','std'
folder = pwd;
PerCentMaskArea = 0.25;



uiwait(msgbox('Please Select a Green Image'));
 defaultFileName = fullfile(folder, '*.*');
[GChannelFileName, folder] = uigetfile(defaultFileName, 'Select a file');
GfullFileName = fullfile(folder, GChannelFileName);
tiff_infoGr= imfinfo(GfullFileName); % return tiff structure, one element per image

answer = questdlg('Would you like to load a Red Image?', ...
    'Load Image', ...
    'Yes Please','No thank you','No thank you');
RChannelFileName = 0;
switch answer
    case 'Yes Please'
        [RChannelFileName, folder] = uigetfile(defaultFileName, 'Select an Image');
    case 'No thank you'
        RChannelFileName = 0;
end

if RChannelFileName~=0
    RfullFileName = fullfile(folder, RChannelFileName);
    tiff_infoRd= imfinfo(RfullFileName); % return tiff structure, one element per image
end


answer = questdlg('Would you like to load a Blue Image?', ...
    'Load Image', ...
    'Yes Please','No thank you','No thank you');

BChannelFileName = 0;

switch answer
    case 'Yes Please'
        [BChannelFileName, folder] = uigetfile(defaultFileName, 'Select an Image');
    case 'No thank you'
        BChannelFileName = 0;
end
if BChannelFileName~=0
    BfullFileName = fullfile(folder, BChannelFileName);
    tiff_infoBl= imfinfo(BfullFileName); % return tiff structure, one element per image
end



datafile = [];
meanIntGr = 0;
meanIntRd = 0;
meanIntBl = 0;
dataArr =[];
for ii = 2:size(tiff_infoGr, 1)
    imgGr = imread(GfullFileName, ii) ; % read in first image
    
    
    
    if ii == 2
        maskOrig = 0;ch = 'a';dirCh='V';mask=0;
        [maskBound,mask,maxArea,maskOrig,ch,dirCh] = createmaskNew(imgGr,diskrad,maskOrig,ii,ch,dirCh,mask,PerCentMaskArea);
    else
        [maskBound,mask,maxArea,maskOrig,ch,dirCh] = createmaskNew(imgGr,diskrad,maskOrig,ii,ch,dirCh,mask,PerCentMaskArea);
    end
    switch StatCh
        case 'mean'
            meanIntGr = mean(imgGr(mask~=0));
        case 'median'
            meanIntGr = median(imgGr(mask~=0));
            
        case 'min'
            meanIntGr = min(imgGr(mask~=0));
        case 'max'
            meanIntGr = max(imgGr(mask~=0));
        case 'var'
            meanIntGr = var(imgGr(mask~=0));
        case 'std'
            meanIntGr = std(imgGr(mask~=0));
    end
    dataArr = [maxArea meanIntGr];
    

    
    if dispCh=='y' || dispCh =='Y'
        newImgGr=imfuse(imgGr,uint16(maskBound)*max(imgGr(:)),'blend');%,'Scaling','none');
        figure,imshow(newImgGr,[]),title('Green Channel')
    end
    if RChannelFileName~=0
        imgRd = imread(RfullFileName, ii) ; % read in first image

        switch StatCh
            case 'mean'
                meanIntRd  = mean(imgRd(mask~=0));
            case 'median'
                meanIntRd  = median(imgRd(mask~=0));
                
            case 'min'
                meanIntRd  = min(imgRd(mask~=0));
            case 'max'
                meanIntRd  = max(imgRd(mask~=0));
            case 'var'
                meanIntRd  = var(imgRd(mask~=0));
            case 'std'
                meanIntRd  = std(imgRd(mask~=0));
        end

        if dispCh=='y' || dispCh =='Y'
            newImgRd=imfuse(imgRd,uint16(maskBound)*max(imgRd(:)),'blend');%,'Scaling','none');
            figure,imshow(newImgRd,[]),title('Red Channel')
        end
        dataArr = [dataArr meanIntRd];
    end
    if BChannelFileName~=0
        imgBl = imread(BfullFileName,ii);

        switch StatCh
            case 'mean'
                meanIntBl  = mean(imgBl(mask~=0));
            case 'median'
                meanIntBl  = median(imgBl(mask~=0));
                
            case 'min'
                meanIntBl  = min(imgBl(mask~=0));
            case 'max'
                meanIntBl  = max(imgBl(mask~=0));
            case 'var'
                meanIntBl  = var(imgBl(mask~=0));
            case 'std'
                meanIntBl  = std(imgBl(mask~=0));
        end
        
        if dispCh=='y' || dispCh =='Y'
             newImgBl=imfuse(imgBl,uint16(maskBound)*max(imgBl(:)),'blend');%,'Scaling','none');
            figure,imshow(newImgBl,[]),title('Blue Channel');
        end
        dataArr = [dataArr meanIntBl];
    end
    datafile = [datafile; dataArr];
    dataArr =[];
    
end


if size(datafile,2)==4
    Area = datafile(:,1);
    MeanIntensityGreen = datafile(:,2);
    MeanIntensityRed = datafile(:,3);
    MeanIntensityBlue= datafile(:,4);
    T = table(Area,MeanIntensityGreen, MeanIntensityRed, MeanIntensityBlue);
    figure,plot(datafile(:,2:4),'LineWidth',2),title('Mean Intensities over Time');
    legend({'Green Channel','Red Channel', 'Blue Channel'})
    xlabel('Time')
    ylabel('Mean Intensity')
elseif (size(datafile,2)==3 && BChannelFileName==0)
    Area = datafile(:,1);
    MeanIntensityGreen = datafile(:,2);
    MeanIntensityRed = datafile(:,3);
    T = table(Area,MeanIntensityGreen, MeanIntensityRed);
    figure,plot(datafile(:,2:3),'LineWidth',2),title('Mean Intensities over Time');
    legend({'Green Channel','Red Channel'})
    xlabel('Time')
    ylabel('Mean Intensity')
elseif (size(datafile,2)==3 && RChannelFileName==0)
    Area = datafile(:,1);
    MeanIntensityGreen = datafile(:,2);
    MeanIntensityBl = datafile(:,3);
    T = table(Area,MeanIntensityGreen, MeanIntensityBlue);
    figure,plot(datafile(:,2:3),'LineWidth',2),title('Mean Intensities over Time');
    legend({'Green Channel','Blue Channel'})
    xlabel('Time')
    ylabel('Mean Intensity')
else
    Area = datafile(:,1);
    MeanIntensityGreen = datafile(:,2);
    T = table(Area,MeanIntensityGreen);
    figure,plot(datafile(:,2),'LineWidth',2),title('Mean Intensities over Time');
    legend({'Green Channel'})
    xlabel('Time')
    ylabel('Mean Intensity')
end

figure,plot(Area,'g--o','LineWidth',2,...
    'MarkerSize',10,...
    'MarkerEdgeColor','b',...
    'MarkerFaceColor',[0.5,0.5,0.5]);


%T = table(Area,MeanIntensityGreen, MeanIntensityRed, MeanIntensityBlue);
% writetable(T,'tabledata.csv','Delimiter','\t');
writetable(T,'myData.xlsx','Sheet',1);%"WriteMode","append");