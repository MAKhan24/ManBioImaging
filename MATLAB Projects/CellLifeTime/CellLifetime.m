%function CellLifetime()
clear all
close all
clc

[dispCh, StatCh, noIterations, smthFactor, contrBias, blk_size, ratioTh, objArea, angStep]=parameters(1); %run parameters.m file to load all the parameters

%load both the images (color and lifetime)
uiwait(msgbox('Please Select a color (RGB) Image'));
folder = pwd;
% Get the name of the file that the user wants to use.

imcount =0;
while imcount < 2
    defaultFileName = fullfile(folder, '*.*');
    [baseFileName, folder] = uigetfile(defaultFileName, 'Select a file');
    if baseFileName > 0
        imcount =imcount+1;
        fullFileName = fullfile(folder, baseFileName);
        if imcount ==1
            x_rgb = imread(fullFileName);
            uiwait(msgbox('Please Select a lifetime Image'));
        else

            x_lifetime = double(imread(fullFileName));
        end
    end


end
x_rgb = x_rgb(:,:,1:3);
%%
% Reading and displaying the original RGB Image
figure,imshow(x_rgb,[]),title('Original RGB Image')

%%
%splitting into to colour layers
x_red = x_rgb(:,:,1);
x_green = x_rgb(:,:,2);
x_blue = x_rgb(:,:,3);



%%
%%%%%%%% Applying active contours (AC) algorithm to get the outer counter of the cell

% mask creation for AC
ResImg = zeros(size(x_green));
rOut = drawassisted;
maskOut = createMask(rOut);
maskuintOut = uint8(maskOut);
if dispCh
    figure,imshow(x_green,[]),title('Green Layer of Original RGB Image')
end
x_masked = (maskuintOut).* x_green;
mask = logical(maskuintOut);
% applying AC algorithm
bw = activecontour(x_masked,mask,noIterations,'Chan-Vese','SmoothFactor',smthFactor,'ContractionBias',contrBias);

% displaying outer contour and extracting within/on the cell coordinates
col = ['b'];
if dispCh
    figure,imshow(x_rgb),
    hold on
end
for i = 1:1
    B = bwboundaries(bw);
    xv= B{i}(:,1);
    yv= B{i}(:,2);
    if dispCh
        plot(yv,xv,col(i));
    end
    xq = 1:size(x_rgb,1);
    yq = 1:size(x_rgb,2);
    [Yq,Xq] = meshgrid(xq,yq);
    [in,on] = inpolygon(Xq,Yq,xv,yv);
    inCell{i} = in;
    onCell{i} = on;

end

%%
%%%%%%%%%%%%% Image enhancement
[r,c] = find(inCell{1}==1);
ch = 'n';
while ch=='n'| ch=='N'
    x_enhanced = x_green;
    for i = 1:length(r)
        blkGreen = x_green(r(i)-(blk_size-1)/2:r(i)+(blk_size-1)/2, c(i)-(blk_size-1)/2:c(i)+(blk_size-1)/2);
        blkBlue = x_blue(r(i)-(blk_size-1)/2:r(i)+(blk_size-1)/2, c(i)-(blk_size-1)/2:c(i)+(blk_size-1)/2);
        blkRed = x_red(r(i)-(blk_size-1)/2:r(i)+(blk_size-1)/2, c(i)-(blk_size-1)/2:c(i)+(blk_size-1)/2);
        BlueRatioGreen = sum(sum(blkBlue - mean(mean(blkBlue))))./sum(sum(blkGreen- mean(mean(blkGreen))));
        RedRatioGreen = sum(sum(blkRed- mean(mean(blkRed))))./sum(sum(blkGreen- mean(mean(blkGreen))));
        if BlueRatioGreen > ratioTh || RedRatioGreen > ratioTh
            x_enhanced(r(i),c(i)) = 0;

        end
    end

    if dispCh
        figure,imshow(x_enhanced)
    end
    %% Image binarization

    x_cropped = (im2double(x_enhanced.* uint8(inCell{1})));
    n=10;
    avg = mean2(x_cropped);
    sigma = std2(x_cropped);
    if avg-n*sigma < 0
        low = 0;
    else
        low = avg-n*sigma;
    end
    if avg+n*sigma > 1
        high = 1;
    else
        high = avg+n*sigma;
    end
    x_croppedEnh = imadjust(x_cropped,[low,high]);

    counts = imhist(x_croppedEnh,256);
    T = otsuthresh(counts)-0.034;

    BWs = imbinarize(x_croppedEnh,T);

    if dispCh
        figure,imshow(x_croppedEnh,[]), title('Cropped Image')
        figure,imshow(BWs), title('Binarized Image')
    end

    BWop = bwareaopen(BWs, objArea,8);
    BW = imcomplement(BWop);
    BWop= bwareaopen(BW, 2000,8);
    BWop = imcomplement(BWop);
    figure,imshow(BWop,[]),title('Image Mask')
    prompt = "Are you satisfied with the image? Y/N [Y] or M for manual tunning: ";
    ch = input(prompt,"s");
    if ch == 'n' | ch == 'N'
        prompt1 = ['Enter new value for ratioTh, previous value is ' num2str(ratioTh) ' : '];
        ratioTh = input(prompt1);
        prompt2 = ['Enter new value for blk_size, previous value is ' num2str(blk_size) ' : '];
        blk_size = input(prompt2);
        prompt3 = ['Enter new value for objArea, previous value is ' num2str(objArea) ' : '];
        objArea = input(prompt3);
        close all
        clc;
    elseif ch == 'M' | ch=='m'
        ch1 = 'n';
        while ch1 == 'n' | ch == 'N'
            disp('Select a region in Image Mask to clean it.');
            rOut  = drawassisted;
            prompt = "Change the colour of selected region, B for Black and W for white: ";
            ch2 = input(prompt,"s");
            maskOut = createMask(rOut);
            if ch2 == 'w' | ch2 == 'W'
                BWop(maskOut==1) = 1;
            else 
                BWop(maskOut == 1)=0;
            end
            %BWop = bitand(imcomplement(maskOut),BWop);
            close all;
            figure,imshow(BWop),title('Image Mask');
            prompt = "Are you satisfied with the image? Y/N [Y]: ";
            ch1 = input(prompt,"s");

        end
    end
end
%% displaying boundaries around the cell
if dispCh
    BW2 = bwmorph(BWop,'remove',Inf);
    figure,imshow(BW2), title('Thinned Image');
    col = ['b','r','g','m'];

    figure,imshow(x_rgb),
    hold on
    xBound=[];
    yBound = [];

    B = bwboundaries(BWop);
    boundLen =[];

    for i = 1:length(B)
        boundLen =[boundLen length(B{i})];
    end
    [boundLen, ind] = sort(boundLen,'descend');

    if length(ind)>1
        lastI = 2;
        xBound=[xBound imresize(B{ind(i)}(:,1),[max(length(B{ind(1)}(:,1)),length(B{ind(2)}(:,1))), 1],'bicubic')];
        yBound=[yBound imresize(B{ind(i)}(:,2),[max(length(B{ind(1)}(:,1)),length(B{ind(2)}(:,1))),1 ],'bicubic')];
        xBoundmean = mean(xBound,2);
        yBoundmean = mean(yBound,2);
        plot(yBoundmean,xBoundmean,'k')
    else
        lastI = 1;
    end

    for i = 1:lastI
        xv= B{ind(i)}(:,1);
        yv= B{ind(i)}(:,2);

        plot(yv,xv,col(i));
    end

end
%%
%%%%%Calculating lifetime

stats = regionprops(BWop,'centroid');

centX = round(stats(1).Centroid(1));
centY = round(stats(1).Centroid(2));
[r,c] = find(BWop==1);
[m,n] = size(BWop);
oldInd = sub2ind([m,n],r,c);
r = r-centY+((m/2)+1);
c = c-centX+((n/2)+1);
z_rgb = zeros(m,n,3);
z_red = zeros(m,n);
z_green = zeros(m,n);
z_blue = zeros(m,n);
newInd = (sub2ind([m,n],r,c));
z_red(newInd)=x_red(oldInd);
z_green(newInd)=x_green(oldInd);
z_blue(newInd)=x_blue(oldInd);

z_rgb(:,:,1) = z_red; z_rgb(:,:,2) = z_green; z_rgb(:,:,3) = z_blue;

figure,imshow(z_rgb), title('Final output image');

z_lifetime = zeros(m,n);
z_lifetime(newInd) = x_lifetime(oldInd);
% z_rgbNew = zeros(m,n,3);
% z_redNew = zeros(m,n);
% z_greenNew = zeros(m,n);
% z_blueNew = zeros(m,n);
% z_redNew(newInd) = x_red(oldInd);
% z_greenNew(newInd) = x_green(oldInd);
% z_blueNew(newInd) = x_blue(oldInd);
% z_rgbNew(:,:,1) = z_redNew; z_rgbNew(:,:,2) = z_greenNew; z_rgbNew(:,:,3) = z_blueNew;



BWop1 = zeros(m,n);
BWop1(newInd) = BWop(oldInd);
if dispCh
    figure,imshow(z_lifetime,[]);
end
[Y,X]  = meshgrid(1:m,1:n);
angImg = rad2deg(atan2((X-((m/2)+1)),(Y-((n/2)+1))));


angImg(angImg>0 & angImg<180)= 360-angImg(angImg>0 & angImg<180);
angImg(angImg<0)=abs(angImg(angImg<0));

lifeTime = [];

for ang =0:angStep:360-angStep
    angInd = find(angImg>=ang & angImg < (ang+angStep));
    TempInd = find(BWop1(angInd)==1);
    tempLeng = length(TempInd);
    z_lifetimeArr = z_lifetime(angInd);
    switch StatCh
        case 'mean'
            avgLifetime = sum(z_lifetimeArr(TempInd))./tempLeng;
        case 'median'
            avgLifetime = median(z_lifetimeArr(TempInd));
        case 'min'
            avgLifetime = min(z_lifetimeArr(TempInd));
        case 'max'
            avgLifetime = max(z_lifetimeArr(TempInd));
        case 'var'
            avgLifetime = var(z_lifetimeArr(TempInd));
        case 'std'
            avgLifetime = std(z_lifetimeArr(TempInd));

    end

    lifeTime = [lifeTime avgLifetime];

end

figure,plot(1:length(lifeTime),lifeTime),title('Cell Lifetime'),axis([1 length(lifeTime) min(lifeTime) max(lifeTime)]);

save imageData x_rgb z_rgb angImg lifeTime centX centY





