function imgStack = channelNormalize(fullImgName)
percentTh = parameters('channelNormalize');
tiff_info = imfinfo(fullImgName ); % return tiff structure, one element per image
imgStack = (double(imread(fullImgName,1)));
[ros,cols] = size(imgStack);
[cnts,cent] = hist(imgStack(:),max(imgStack(:)));
cdfCh = cumsum(cnts);
temp = ones(ros,cols);
ind = find(cdfCh>(percentTh*(ros*cols)));
temp(imgStack>=cent(ind(1)))=0;
imgStack(temp==0)=mean(imgStack(temp==1));
imgStack = imgStack./65535;
for ii = 2 : size(tiff_info, 1)
    temp = ones(ros,cols);
    imgCh = double(imread(fullImgName, ii));
    [cnts,cent] = hist(imgCh(:),65536);
    cdfCh = cumsum(cnts);
    ind = find(cdfCh>(percentTh*(ros*cols)));
    temp(imgCh>=cent(ind(1)))=0;
    imgCh(temp==0)=mean(imgCh(temp==1));
    
    
    
    
    %normalize each image channel from 0 to 1;
    imgCh = imgCh./65535;
    %     imgCh = imgCh./(max(imgCh(:))-min(imgCh(:)));
    imgStack = cat(3 , imgStack, imgCh);
    %     imshow(imgCh);  % Display image.
    %     drawnow; % Force display to update immediately.
end
