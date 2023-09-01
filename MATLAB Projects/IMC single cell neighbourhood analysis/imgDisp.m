function imgDisp(sox9Ch,roi,mask,maskVoid,tempMskCnt,ii)
cellMask = zeros(size(mask));
cellMask(mask==ii)=1;
tempMask =zeros(size(mask));
tempMask(mask>0)=1;
B3 = imoverlay(sox9Ch,roi,'white');
B1 = imoverlay(B3,tempMask,'blue');
%B4 = imoverlay(B1,tempMskCnt,'yellow');
B2 = imoverlay(B1,maskVoid,'green');
B = imoverlay(B2,cellMask,'red');
cellNo = "Cell No:" + num2str(ii);
figure,imshow(B); title(cellNo + ", The Cell (Red), Region around the Cell(White), Void Region (Green), Other Cells (Blue)");
figure,imshow(roi); title(cellNo + ", Region around the Cell");



