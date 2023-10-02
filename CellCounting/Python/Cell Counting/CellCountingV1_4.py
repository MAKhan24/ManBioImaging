#!/usr/bin/python
from inspect import EndOfBlock
from typing import ClassVar
import cv2
import matplotlib.pyplot as plt
import numpy as np
import os
from tkinter import *
from PIL import Image, ImageTk
import tkinter.messagebox
from tkinter import ttk
from tkinter import filedialog
from skimage import morphology
from skimage.measure import label, regionprops, regionprops_table
import pathlib
import glob
import tkinter as tk
import scipy.spatial.distance
from scipy import ndimage
from skimage.filters import edges
from skimage.segmentation import watershed
from skimage.feature import peak_local_max
import CellCountingRedCells as nextstage
#import CellCountingV1_3 as nextstage
from skimage import exposure
import array



class CommandWindowBr:  
    def loadimageBright(self):
        global clickCountBr
        clickCountBr = 1

        self.frame = Frame(self.winBr)
        #self.frame.pack(side=TOP)
        self.frame.pack(expand=True, fill="both")
        self.bLoadBright["state"]="disabled"
        
        self.path= filedialog.askopenfilename(title="Select an Image", filetype=(('image files','*.tif'),('all files','*.*')))
        fname = os.path.basename(self.path)
        self.filename.append(fname)
        self.imgBright = np.matrix(cv2.imread(self.path,-1))  
        self.imgBright = self.imgBright/65535        
        lowIn = np.min(self.imgBright)        
        highIn = np.amax(self.imgBright)
        self.imgBrEn = self.ImProcess.imadjust(self.imgBright,lowIn, highIn,0,1,1)
        self.bDisp= ttk.Button(self.frame, default="disabled",text = "Bright Image" + " (" + fname + ")",command=lambda img=np.matrix(self.imgBrEn):self.dispimage(img,1,'Bright Image'))
        self.bDisp.pack(padx=275, pady=2)
        self.dispBts.append(self.bDisp)
        self.MainFunct() 
     
    
    def dispimage(self,img,figNum,figTitle,cmap='gray'):
        plt.figure(figNum)
        plt.title(label=figTitle, fontsize=20)
        plt.imshow(img, cmap, vmin=0,vmax=1)
        plt.xticks([]), plt.yticks([]) # to hide tick values on X and Y axis              
        plt.show()

   
    def sliderchangedBr(self,img):
        self.thBr= self.sliderBr.get()
        self.imgBrBin = self.ImProcess.imbinarize(img,float(self.thBr))
        self.dispimage(self.imgBrBin,3,'Bright Binary Image')

    def bcleanedcallbackBr(self):
        self.objAreaBr=int(self.tbObjAreaBr.get())
        self.imgCleanBr = self.ImProcess.noiseRemoval(self.imgBrBin,self.objAreaBr)
        self.dispimage(self.imgCleanBr,4,'Bright Clean Image')
  
    
    def bcellcountcallbackBr(self):
        imgBr = self.imgCleanBr
        #image =  imgBr.astype(np.uint8)*255
    
        #lblImg = label(imgBr[200:400,200:400])
        image = label(imgBr)
       
        distance = ndimage.distance_transform_edt(image)
        coords = peak_local_max(distance, footprint=np.ones((29, 29)), labels=image)
        mask = np.zeros(distance.shape, dtype=bool)
        mask[tuple(coords.T)] = True
        markers, _ = ndimage.label(mask)
        
        labels = watershed(-distance, markers,mask=image)
        regions = regionprops(labels)

        self.cellCountBr = len(regions)
        textCellCountBr = "Cell Count  = "+ str(self.cellCountBr)
        self.labelCellCountBr = Label(self.frame, text=textCellCountBr, font=('Caveat 10 bold'))
        self.labelCellCountBr.pack(pady=2)
        plt.figure(4)
        plt.title(label='Labelled Image', fontsize=20)
        plt.imshow(labels,plt.cm.nipy_spectral)
        plt.xticks([]), plt.yticks([]) # to hide tick values on X and Y axis              
        plt.show()
        self.bApplytoAll["state"]="normal"
        
        tkinter.messagebox.showinfo("showinfo", textCellCountBr +". Now press Apply to All button to see cell count for other images." )

    def load_images_from_folder(self,folder):
        images = []
        for filename in os.listdir(folder):
            #print(filename)
            
            if (('scan_Plate_R_' in filename) and ('d4' in filename) ):
                img = cv2.imread(os.path.join(folder,filename),-1)
                if img is not None:
                    images.append(img)
        return images


    def bapplytoallcallback(self):
        path = pathlib.Path(self.path)
        folder = path.parent
        images= self.load_images_from_folder(folder)
        self.processallimages(images)
    

    def bnextstagecallback(self):
        global nextstageclick
        nextstageclick=True
        self.nextStageHandle.main()             
       
        

        

    def processallimages(self, images):
        cellCountALL = []
        cellCountAvg = 0
        for i in range(len(images)):
            img = images[i]            
            img = np.matrix(img)
            img = img/65535
            lowIn = np.min(img)
            highIn = np.amax(img)
            imgEn = self.ImProcess.imadjust(img,lowIn, highIn,0,1,1)

            imgBin = self.ImProcess.imbinarize(imgEn,float(self.thBr))
            imgClean = self.ImProcess.noiseRemoval(imgBin,self.objAreaBr)
            #image =  imgClean.astype(np.uint8)*255
            lblImg = label(imgClean)
            distance = ndimage.distance_transform_edt(lblImg)
            coords = peak_local_max(distance, footprint=np.ones((29, 29)), labels=lblImg)
            mask = np.zeros(distance.shape, dtype=bool)
            mask[tuple(coords.T)] = True
            markers, _ = ndimage.label(mask)
            
            labels = watershed(-distance, markers,mask=lblImg)
            regions = regionprops(labels)
            cellCount = len(regions)              
            cellCountALL.append(cellCount)

            cellCountAvg = cellCountAvg + cellCount
        
        cellCountAvg = cellCountAvg/len(images)
        textCellCount = "Cell Count Average over all images "+ str(cellCountAvg)
        self.labelCellCountALL1 = Label(self.frame, text=textCellCount, font=('Caveat 10 bold')).pack()
        textCellCount = "Cell Count for each image "
        self.labelCellCountALL2= Label(self.frame, text=textCellCount, font=('Caveat 10 bold')).pack()
        textCellCount = str(cellCountALL)
        self.labelCellCountALL3 = Label(self.frame, text=textCellCount, font=('Caveat 10 bold')).pack()
        global clickCountBr
        clickCountBr = 2
        self.MainFunct() 


    def reset(self):
        global clickCountBr
        global nextstageclick
        #global nextStageHandle
        clickCountBr = 0
        plt.close('all')
        self.bApplytoAll["state"]="disabled"
        self.bLoadBright["state"]="normal"
        self.frame.destroy()
        if nextstageclick ==True:
            self.nextStageHandle.win.destroy()


    def __init__(self):
        self.ImProcess = ImgProcessingBr()
        
        self.winBr= Tk()
        self.labelCellCount =Label()
        self.labelCellCountALL1 = Label()
        self.labelCellCountALL2 = Label()
        self.labelCellCountALL3 = Label()

        self.dispBts = []
        global nextstageclick
        nextstageclick = False
        self.nextStageHandle = nextstage.CommandWindow()
       
        global clickCountBr
        clickCountBr = 0
        self.filename =list()
        self.slider = Scale()
        screen_width = self.winBr.winfo_screenwidth()
        screen_height = self.winBr. winfo_screenheight()
        #self.winBr.wm_minsize(screen_height,screen_width)
        self.winBr.geometry("800x600")
        self.winBr.resizable(0,0)
       
        self.winBr.title("Cell Counter")
        Label(self.winBr, text="Cell Counter", font=('Caveat 20 bold')).pack(pady=5)
        Label(self.winBr, text="Click the Button below to load Bright Images", font=('Caveat 10 bold')).pack(pady=5)
        self.bLoadBright= ttk.Button(self.winBr, text="Load Image", command= self.loadimageBright)
        self.bLoadBright.pack(ipadx=5, pady=2)

        self.bApplytoAll= ttk.Button(self.winBr, text="Apply to All",state=DISABLED, command=lambda:self.bapplytoallcallback())
        self.bApplytoAll.pack(ipadx=20, pady=0)
        self.bReset= ttk.Button(self.winBr, text="Reset", command= self.reset)
        self.bReset.pack(ipadx=5, pady=15)


        self.winBr.mainloop()
     
    def MainFunct(self):
        global clickCountBr
        if clickCountBr==1:
            Label(self.frame, text="Now choose the threshold uing sliding bar and then press the button to binarise Bright Image.", font=('Caveat 10 bold')).pack(pady=2)
            self.sliderValueBr = tkinter.DoubleVar()
            self.sliderBr = Scale(self.frame, from_=0, to=50,length=500, orient=HORIZONTAL,variable=self.sliderValueBr)
            self.sliderBr.set(0)  
            self.sliderBr.pack(pady=2)
            self.bBinaryBr= ttk.Button(self.frame, text="Binarise Image (Bright)", command=lambda img=np.matrix(self.imgBrEn):self.sliderchangedBr(img))
            self.bBinaryBr.pack(ipadx=5, pady=2)
            Label(self.frame, text="Once image is binarised clean the images by removing objects with ", font=('Caveat 10 bold')).pack(pady=2)
            Label(self.frame, text="areas smaller than the area defined in the text box.", font=('Caveat 10 bold')).pack(pady=2)
            self.tbObjAreaBr = Entry(self.frame)        
            self.tbObjAreaBr.pack(ipadx=5, pady=2)
            self.bCleanedBr= ttk.Button(self.frame, text="Noise Removal (Bright)", command=lambda:self.bcleanedcallbackBr())
            self.bCleanedBr.pack(ipadx=5, pady=2)
            self.bCellCountBr= ttk.Button(self.frame, text="Cell Count", command=lambda:self.bcellcountcallbackBr())
            self.bCellCountBr.pack(ipadx=5, pady=2)
        elif clickCountBr==2:
            self.bNextStage= ttk.Button(self.frame, text="Proceed to Next Stage", command=lambda:self.bnextstagecallback())
            self.bNextStage.pack(ipadx=5, pady=2)
            




       


class ImgProcessingBr:



    def imadjust(self,img,lowIn, highIn,lowOut,highOut,gamma=1):
        # Similar to imadjust in MATLAB.
        # Converts an image range from [a,b] to [c,d].
        # The Equation of a line can be used for this transformation:
        #   y=((d-c)/(b-a))*(x-a)+c
        # However, it is better to use a more generalized equation:
        #   y=((x-a)/(b-a))^gamma*(d-c)+c
        # If gamma is equal to 1, then the line equation is used.
        # When gamma is not equal to 1, then the transformation is not linear.
        


       
        #print(r[0],r[1],[2],r[3])



        img[img<lowIn] = lowIn
        imgOut = ((np.power(((img - lowIn) / (highIn - lowIn)),gamma)) * (highOut - lowOut)) + lowOut
        #imgOut= exposure.equalize_hist(imgOut)
        return imgOut
    
    # def imbinarize(self,img,Th=128):                  
    #     imgOut = np.matrix(np.zeros((np.size(img,0),np.size(img,1)),np.uint8))
    #     imgOut[(img*255 > Th)] = 1 
    #     # ret,imgOut = cv2.threshold(img,Th,1,cv2.THRESH_BINARY)            
    #     # th2 = cv2.adaptiveThreshold(img,255,cv2.ADAPTIVE_THRESH_MEAN_C,cv2.THRESH_BINARY,11,2)
    #     # th3 = cv2.adaptiveThreshold(img,255,cv2.ADAPTIVE_THRESH_GAUSSIAN_C,cv2.THRESH_BINARY,11,2)
    #     return imgOut
    def imbinarize(self,img,Th=5):           
        lowpass = ndimage.gaussian_filter(img, 3)
        gauss_highpass = img - Th * lowpass
        img = gauss_highpass
        lowIn = np.amin(img)
        highIn = np.amax(img)               
        img = self.imadjust(img,lowIn, highIn,0,1,1)*255   
        imgOut = cv2.adaptiveThreshold((img.astype(np.uint8)),255,cv2.ADAPTIVE_THRESH_GAUSSIAN_C,cv2.THRESH_BINARY,101,6)
        #imgOut = np.matrix(np.zeros((np.size(img,0),np.size(img,1)),np.uint8))
        #imgOut[(img> Th)] = 1 
        return np.invert(imgOut)
        #return imgOut
     
    
    def noiseRemoval(self,img,ObjArea = 100):
        imgMedfilt = cv2.medianBlur(img.astype(np.uint8),5)
        imgOut = morphology.remove_small_objects(imgMedfilt.astype(np.bool_), min_size=ObjArea, connectivity=8)
        return imgOut

    
CommandWindowBr()

    

