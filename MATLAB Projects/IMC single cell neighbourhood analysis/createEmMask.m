function emMask = createEmMask(imgStack)

[sigma,minArea,medFiltSize] = parameters('createEmMask');

smaImg = (imgStack(:,:,1)).*65535;
smaImg = smaImg./max(smaImg(:));

panKerImg = (imgStack(:,:,4)).*65535;
panKerImg = panKerImg./max(panKerImg(:));


greenCh = (zeros(size(smaImg)));
rgbImg = cat(3,smaImg,greenCh,panKerImg);

%figure,imshow(rgbImg,[])
labImg = rgb2lab(rgbImg);

filtImg = imgaussfilt((labImg(:,:,1)),sigma);
filtImg = normalize_x(filtImg);
th = graythresh(filtImg);
BW = imbinarize(filtImg,th);
BW2 = bwareaopen(BW, minArea);
emMask = medfilt2(BW2, [medFiltSize medFiltSize]);
%figure,imshow(BW3);

