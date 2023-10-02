function [maskBound,finalMask,maxArea,maskOrig,ch,dirCh] = createmaskNew(img,diskRad,maskOrig,ii,ch,dirCh,finalMask,PerCentMaskArea)
disp = false; % set disp as true to show all the images otherwise set as false

%Active contours
noIterations =1000; % default 1000
smthFactor = 3; %default 3
contrBias = 0; % default 0
col = ['b'];

low_out =0 ;
high_out = 1;
gamma =1;
img = im2double(img);

ResImg = zeros(size(img));

chMask = 'N';
if ii==2
    while (chMask == 'N' | chMask == 'n')
        imshow(img,[]),title('Original Image')
        rOut = drawassisted;
        maskOrig = createMask(rOut);
        n = 1.5;
        avg = mean2(img);
        sigma = std2(img);
        low_in =avg;%-n*sigma;
        high_in = avg+n*sigma;
%         xAd = imadjust(img,[low_in high_in],[]);
        xAd = img;
        xAd(maskOrig==1) = imadjust(img(maskOrig==1),[min(min(img(maskOrig==1))) max(max(img(maskOrig==1)))],[]);
        x = imgaussfilt(xAd,2);
        
        %         rOut = drawrectangle;
        x_masked = maskOrig .* x;
        %         x_masked = bitand(uint8(maskOrig),x);
        % applying AC algorithm
        bw = activecontour(x_masked,maskOrig,noIterations,'Chan-Vese','SmoothFactor',smthFactor,'ContractionBias',contrBias);
        B = bwboundaries(bw);
        hold on
        for i = 1:1%length(B)
            B = bwboundaries(bw);
            xv= B{i}(:,1);
            yv= B{i}(:,2);
            plot(yv,xv,col(i));
            xq = 1:size(x,2);
            yq = 1:size(x,1);
            [Yq,Xq] = meshgrid(xq,yq);
            [in,on] = inpolygon(Xq,Yq,xv,yv);
            inCell{i} = in;
            onCell{i} = on;
            
            
        end
        chMask = input('Are you satisfied with the mask (y for yes and n for no):-  ','s');
        close all
        
    end
else
    inCell ={};
    onCell = {};
    s = regionprops(finalMask,'centroid');
    centroid = cat(1,s.Centroid);
    n = 1.5;
    avg = mean2(img);
    sigma = std2(img);
    low_in =avg;%-n*sigma;
    high_in = avg+n*sigma;
%     xAd = imadjust(img,[low_in high_in],[]);
            xAd = img;
    xAd(maskOrig==1) = imadjust(img(maskOrig==1),[min(min(img(maskOrig==1))) max(max(img(maskOrig==1)))],[]);
    x = imgaussfilt(xAd,2);
    x_masked = maskOrig .* x;
    %     x_masked = bitand(uint8(maskOrig),x);
    % applying AC algorithm
    bw = activecontour(x_masked,maskOrig,noIterations,'Chan-Vese','SmoothFactor',smthFactor,'ContractionBias',contrBias);
    B = bwboundaries(bw);
    dist = zeros(1,length(B));
    for i = 1:length(B)
       
        xv= B{i}(:,1);
        yv= B{i}(:,2);
        xq = 1:size(x,2);
        yq = 1:size(x,1);
        [Yq,Xq] = meshgrid(xq,yq);
        [inCell{i},onCell{i}] = inpolygon(Xq,Yq,xv,yv);
        s = regionprops(inCell{i},'centroid');
        centroidNew = cat(1,s.Centroid);
        dist(i) = sqrt(sum((centroid - centroidNew) .^ 2));
    end
    [minDist,distInd] = min(dist);
    in = inCell{distInd};
    on = onCell{distInd};
    
end

se = strel("disk",8,6);
erodedI = imerode(in,se);
mask = bitxor(erodedI,in);

x_cropped = im2double(x.* in);
maskBound = uint8(bwperim(mask));
if disp
    figure,imshow(maskBound,[]);
end
% se = strel("disk",10);
% dilateI = imdilate(in,se);
% maskOrig = dilateI;
maskOrig = bwconvhull(on);
x1 = zeros(size(x));
x2 = zeros(size(x));
if ii==2
    [r,c] = find(mask==1);
    difRow = abs(max(r)-min(r));
    difCol = abs(max(c)-min(c));
    if difRow >difCol
        dirCh = 'V';
        mask1 = zeros(size(x));
        mask2 = zeros(size(x));
        RowSt1 = min(r);
        RowEnd1 = min(r)+round(difRow*PerCentMaskArea);
        RowSt2 = max(r)- round(difRow*PerCentMaskArea);
        RowEnd2 = max(r);
        mask1(RowSt1:RowEnd1,min(c):max(c)) = mask(RowSt1:RowEnd1,min(c):max(c));
        mask2(RowSt2:RowEnd2,min(c):max(c)) = mask(RowSt2:RowEnd2,min(c):max(c));
        x1(RowSt1:RowEnd1,min(c):max(c))=imfuse(x(RowSt1:RowEnd1,min(c):max(c)),mask(RowSt1:RowEnd1,min(c):max(c)),'blend','Scaling','joint');
        x2(RowSt2:RowEnd2,min(c):max(c))=imfuse(x(RowSt2:RowEnd2,min(c):max(c)),mask(RowSt2:RowEnd2,min(c):max(c)),'blend','Scaling','joint');
    else
        dirCh = 'H';
        mask1 = zeros(size(x));
        mask2 = zeros(size(x));
        ColSt1 = min(c);
        ColEnd1 = min(c)+round(difCol*PerCentMaskArea);
        ColSt2 = max(c)- round(difCol*PerCentMaskArea);
        ColEnd2 = max(c);
        mask1(min(r):max(r),ColSt1:ColEnd1) = mask(min(r):max(r),ColSt1:ColEnd1);
        mask2(min(r):max(r),ColSt2:ColEnd2) =  mask(min(r):max(r),ColSt2:ColEnd2);
        
        x1(min(r):max(r),ColSt1:ColEnd1)=imfuse(x(min(r):max(r),ColSt1:ColEnd1),mask(min(r):max(r),ColSt1:ColEnd1),'blend','Scaling','joint');
        x2(min(r):max(r),ColSt2:ColEnd2)=imfuse(x(min(r):max(r),ColSt2:ColEnd2),mask(min(r):max(r),ColSt2:ColEnd2),'blend','Scaling','joint');
        
    end
    figure,imshow(x1,[]),title('Region-A')
    figure,imshow(x2,[]),title('Region-B')
    
    ch = input('Enter the choice (a for Region-A and b for Region-B):-  ','s');
    if ch == 'a' | ch == 'A'
        
        finalMask = mask1;
    elseif ch == 'b' | ch == 'B'
        finalMask = mask2;
    end
    
else
    [r,c] = find(mask==1);
    difRow = abs(max(r)-min(r));
    difCol = abs(max(c)-min(c));
    if ch == 'a' | ch == 'A'
        if dirCh =='V'
            mask1 = zeros(size(x));
            RowSt1 = min(r);
            RowEnd1 = min(r)+round(difRow*0.25);
            mask1(RowSt1:RowEnd1,min(c):max(c)) = mask(RowSt1:RowEnd1,min(c):max(c));
            
        else
            mask1 = zeros(size(x));
            ColSt1 = min(c);
            ColEnd1 = min(c)+round(difCol*0.25);
            mask1(min(r):max(r),ColSt1:ColEnd1) =  mask(min(r):max(r),ColSt1:ColEnd1);
        end
        finalMask = mask1;
    elseif ch == 'b' | ch == 'B'
        if dirCh =='V'
            mask2 = zeros(size(x));
            RowSt2 = max(r)- round(difRow*0.25);
            RowEnd2 = max(r);
            mask2(RowSt2:RowEnd2,min(c):max(c)) = mask(RowSt2:RowEnd2,min(c):max(c));
            
        else
            mask2 = zeros(size(x));
            ColSt2 = max(c)- round(difCol*0.25);
            ColEnd2 = max(c);
            mask2(min(r):max(r),ColSt2:ColEnd2) =  mask(min(r):max(r),ColSt2:ColEnd2);
        end
        finalMask = mask2;
    end
    
    
end
se = strel("disk",diskRad);
finalMask = imdilate(finalMask,se);
maskBound = (bwperim(finalMask));
% figure,imshow(finalMask);
% figure,imshow(maskBound);
maxArea = length(find(finalMask==1));








