function AnglePartitionDisplay()
try
    load imageData;
catch
    uiwait(msgbox('Unable to read file z_rgb.mat. No such file or directory. Please run the CellLifetime function'));
    return
end

[angStep,PartDisp]=parameters(2);  %run the parameters.m file to load the relvent parameters


%%%%% angle partition display
Mask1 =zeros(size(z_rgb,1),size(z_rgb,2));
Mask2 =zeros(size(z_rgb,1),size(z_rgb,2));
Mask3 =zeros(size(z_rgb,1),size(z_rgb,2));
Mask = zeros(size(z_rgb));
datafile =[];
for i = 1:length(PartDisp)
    
    angPart = PartDisp(i);
    angInd = find(angImg>=(angPart*angStep)-angStep & angImg < (angPart*angStep));
    datafile = ( [datafile; [angPart (angPart*angStep)-angStep (angPart*angStep) lifeTime(angPart)]]);
    Mask1(angInd)=255;
    Mask2(angInd)=255;
    Mask3(angInd)=255;
    
    
end
Mask1_New =zeros(size(z_rgb,1),size(z_rgb,2));
Mask2_New =zeros(size(z_rgb,1),size(z_rgb,2));
Mask3_New =zeros(size(z_rgb,1),size(z_rgb,2));
Mask_New = uint8(zeros(size(z_rgb)));

[r,c] = find(Mask1==255);
[m,n] = size(Mask1);

r1 = r-((m/2)+1)+centY;
c1 = c-((n/2)+1)+centX;

rTemp = find(r1>m | r1<1);


r1(rTemp)=[];
c1(rTemp)=[];
r(rTemp)=[];
c(rTemp)=[];
cTemp = find(c1>m | c1<1);
r1(cTemp)=[];
c1(cTemp)=[];
r(cTemp)=[];
c(cTemp)=[];



oldInd = sub2ind([m,n],r,c);

newInd = (sub2ind([m,n],r1,c1));
Mask1_New(newInd)=Mask1(oldInd);
Mask2_New(newInd)=Mask2(oldInd);
Mask3_New(newInd)=Mask3(oldInd);

% Mask_New(:,:,1) = Mask1_New; Mask_New(:,:,2) = Mask2_New; Mask_New(:,:,3) = Mask3_New;






PartNo = datafile(:,1);
LAngle = datafile(:,2);
UAngle = datafile(:,3);
Lifetime = datafile(:,4);
T = table(PartNo, LAngle, UAngle, Lifetime);
writetable(T,'tabledata.csv','Delimiter','\t');
% 
% z1 = z_rgb(:,:,1);
% z2 = z_rgb(:,:,2);
% z3 = z_rgb(:,:,3);
% Mask1=xor(Mask1, z1);
% Mask2=xor(Mask2, z2);
% Mask3=xor(Mask3,z3);

Mask(:,:,1) = Mask1;
Mask(:,:,2) = Mask2;
Mask(:,:,3)= Mask3;
figure,imshow(Mask)
z_Masked = imfuse(z_rgb,Mask,'blend','Scaling','joint');
figure,imshow(z_Masked)
Mask_New(:,:,1) = Mask1_New;
Mask_New(:,:,2) = Mask2_New;
Mask_New(:,:,3)= Mask3_New;
x_Masked = imfuse(x_rgb,Mask_New,'blend','Scaling','joint');
figure,imshow(x_Masked)

