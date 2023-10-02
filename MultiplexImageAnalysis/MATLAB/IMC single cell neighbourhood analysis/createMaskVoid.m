function maskVoid = createMaskVoid(imgStack,objsInImg)
%fullImgName =['C:\SEO Manchester Uni\Andrew Gilmore\Robert Pedley\IMC single cell neighbourhood analysis for muhammad\IMC single cell neighbourhood analysis for muhammad\Steinbock\img\31_009.tiff']
%imgStack = channelNormalize(fullImgName);
[chName,intTh,medFiltSize,r,dispCh] = parameters('createMaskVoid');
chInd = find(strcmpi(objsInImg.Properties.VariableNames,chName{1}));
x1 = imgStack(:,:,chInd-2)*65535;
chInd = find(strcmpi(objsInImg.Properties.VariableNames,chName{2}));
x2 = imgStack(:,:,chInd-2)*65535;
%figure,imshow(x1,[])
chInd = find(strcmpi(objsInImg.Properties.VariableNames,chName{3}));
x3 = imgStack(:,:,chInd-2)*65535;

x1 = x1./max(x1(:));
x2 = x2./max(x2(:));
x3 = x3./max(x3(:));

imRGB = cat(3,x1,x2,x3);
% figure,imshow(imRGB,[]);
maskVoid = zeros(size(x1));
% th1 = graythresh(x1);
% th2 = graythresh(x2);
% th3 = graythresh(x3);
 maskVoid(x1<intTh(1) & x2<intTh(2) & x3<intTh(3))=1;
% maskVoid(x1>th1 & x2>th2 & x3>th3)=1;
% maskVoid((x1+ x2 + x3)./3<0.006)=1;
BW = bwmorph(maskVoid,'fill');
BW1 = bwmorph(BW,'close');
BW2 = bwmorph(BW1,'clean');
BW3 = bwmorph(BW2,'majority');


maskVoid = medfilt2(BW3,[medFiltSize medFiltSize]);

se = strel('disk',r);
maskVoid = imdilate(maskVoid,se);
if dispCh == 1
    figure,imshow(imRGB,[]), title('Original Image (Three Channels)')
    figure,imshow(maskVoid,[]), title('Void Regions')
end
    




