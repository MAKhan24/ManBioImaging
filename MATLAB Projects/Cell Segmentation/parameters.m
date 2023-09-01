function [varargout]=parameters(ch)

if ch==1
    
    %parameters for CellLifetime function
    
    
    disp = false; % set disp as true to show all the images otherwise set as false
    StatCh = 'mean'; %set statistic choice as 'mean', 'median','min','max','var','std'
    %Active contours
    noIterations =1000; % default 1000
    smthFactor = 3; %default 3
    contrBias = 0; % default 0

    %Image Enhancement
    blk_size = 7;
    ratioTh = 0.55; %default 0.55
    %Image Binarization
    objArea = 1500;
    %Lifetime Calculations
    angStep = 5;
   
    
    
    varargout{1} = disp;
    varargout{2} = StatCh;
    varargout{3} = noIterations;
    varargout{4} = smthFactor;
    varargout{5} = contrBias;
    varargout{6} = blk_size;
    varargout{7} = ratioTh;
    varargout{8} = objArea;
    varargout{9} = angStep;
  

else
    %parameters for AnglePartitionDisplay function
    
    %Lifetime Calculations
    angStep = 5;
    PartDisp = [1 7 10 20];
    
    varargout{1} = angStep;
    varargout{2} = PartDisp;
    
end
