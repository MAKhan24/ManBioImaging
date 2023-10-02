function VideoMerge()
uiwait(msgbox('Please Select First Video'));
folder = pwd;
defaultFileName = fullfile(folder, '*.*');
[FileName1, folder1] = uigetfile(defaultFileName, 'Select a file');
fullFileName1 = fullfile(folder1, FileName1);
tiff_info1= imfinfo(fullFileName1); % return tiff structure, one element per image

uiwait(msgbox('Please Select Second Video'));
[FileName2, folder2] = uigetfile(defaultFileName, 'Select a file');
fullFileName2 = fullfile(folder2, FileName2);
tiff_info2= imfinfo(fullFileName2); % return tiff structure, one element per image

img = imread(fullFileName1, 1); 

imwrite(img,'comboVideo.tif')
for ii = 2:size(tiff_info1, 1)
    img = imread(fullFileName1, ii);
    imwrite(img,'comboVideo.tif','WriteMode','append') ;
end

for ii = 1:size(tiff_info2, 1)
    img = imread(fullFileName2, ii);
    imwrite(img,'comboVideo.tif','WriteMode','append') ;
end