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
from skimage import exposure
import array

import csv


class ScrollableFrame(ttk.Frame):
    def __init__(self, container, *args, **kwargs):
        super().__init__(container, *args, **kwargs)
        self.canvas = tk.Canvas(self,height=200,width=775)
        #self.canvas.pack( expand=True)
        self.canvas.grid(column=0,row=0,sticky=tk.W+tk.E+tk.N+tk.S)

        
        self.scrollbarV = ttk.Scrollbar(self, orient="vertical")
        self.scrollbarV.config(command=self.canvas.yview)
        #scrollbarV.pack(side="right", fill="y")
    

        self.scrollbarH = ttk.Scrollbar(self, orient="horizontal")
        self.scrollbarH.config(command=self.canvas.xview)
        #scrollbarH.pack(side="bottom", fill=X)
        self.canvas.configure(yscrollcommand=self.scrollbarV.set,xscrollcommand=self.scrollbarH.set)
        self.scrollbarH.grid(column=0,row=1,sticky='ew')
        self.scrollbarV.grid(column=1,row=0,sticky='ns')
        self.scrollable_frame = ttk.Frame(self.canvas)

        self.scrollable_frame.bind(
            "<Configure>",
            lambda e: self.canvas.configure(
                scrollregion=self.canvas.bbox("all")

            )
        )

        self.canvas.create_window((0,0), window=self.scrollable_frame, anchor="nw")


class CommandWindow:  
    def loadimage(self):
        global clickCount       
        global CountRd
        global fnameR
        clickCount = clickCount+1
        if clickCount==1:        
            self.frame = ScrollableFrame(self.win)
            self.frame.pack(side=TOP)
            self.frame.pack(side="top", expand=True, fill="both")
            self.frame2 = Frame(self.win)
            self.frame2.pack(side="bottom", expand=True, fill="both")
      
        if clickCount < 2:
            self.path= filedialog.askopenfilename(title="Select an Image", filetype=(('image files','*.tif'),('all files','*.*')))
            fname = os.path.basename(self.path)
            self.filename.append(fname)
            if ('d1' in fname):
                fnameR=fname
                CountRd = CountRd+1
                self.imgRed = np.matrix(cv2.imread(self.path,-1)) 
                self.imgRed.astype('float16')
                self.imgRed = self.imgRed/65535
                lowIn = np.amin(self.imgRed)
                highIn = np.amax(self.imgRed)               
                self.imgRdEn = self.ImProcess.imadjust(self.imgRed,lowIn, highIn,0,1,1)                
                self.bDisp= ttk.Button(self.frame.scrollable_frame, default="disabled",text = "Red Image" + " (" + fnameR + ")",command=lambda img=np.matrix(self.imgRdEn):self.dispimage(img,2,'Red Image'))
                self.bDisp.pack(padx=275, pady=2)
                self.dispBts.append(self.bDisp)
                if clickCount==1:
                    tkinter.messagebox.showinfo("showinfo", "You have successfully loaded the Red Image.")

            else:
                    tkinter.messagebox.showinfo("showinfo", "Please load either Red Image.")  
                    clickCount = clickCount-1
                    if clickCount == 0:
                        self.frame.canvas.destroy()
                        self.frame.canvas.master.destroy()
                        self.frame.scrollbarH.destroy()
                        self.frame.scrollbarV.destroy()
                        self.frame.scrollable_frame.destroy()
                        self.frame2.destroy()

        if clickCount==1:
            self.bLoad["state"]="disabled"
        if (CountRd>1):
            tkinter.messagebox.showinfo("showinfo", "You have loaded the Red image. Click Reset button to change the images.")
        else:
            self.MainFunct()        
    
    def dispimage(self,img,figNum,figTitle):
        plt.figure(figNum)
        plt.title(label=figTitle, fontsize=20)
        plt.imshow(img, cmap='gray', vmin=0,vmax=1)
        plt.xticks([]), plt.yticks([]) # to hide tick values on X and Y axis              
        plt.show()

    def sliderchanged(self,img):
        self.thRd = self.slider.get() #self.get_currentSlider_value() 
        self.imgRedBin = self.ImProcess.imbinarize(img,float(self.thRd))
        self.dispimage(self.imgRedBin,3,'Red Binary Image')
    
    def bcleanedcallback(self):
        self.objAreaRd=int(self.tbObjArea.get())
        self.imgClean = self.ImProcess.noiseRemoval(self.imgRedBin,self.objAreaRd)
        self.dispimage(self.imgClean,4,'Red Clean Image')

    def bcellcountcallback(self):
        self.cellCount = self.ImProcess.localproc(np.matrix(self.imgClean))
        textCellCount = "Cell Count  = "+ str(self.cellCount)
        if self.labelCellCount.winfo_exists():
            self.labelCellCount.destroy()
        self.frame2.destroy()
        self.frame2 = Frame(self.win)
        self.frame2.pack(side="bottom", expand=True, fill="both")
        #if self.bApplytoAll["state"]=="disabled":
        self.bApplytoAll["state"]="normal"
        tkinter.messagebox.showinfo("showinfo", textCellCount +". Now press Apply to All button to see cell count for other images." )
        self.labelCellCount = Label(self.frame.scrollable_frame, text=textCellCount, font=('Caveat 10 bold'))
        self.labelCellCount.pack()

    def load_images_from_folder(self,folder):
        imagesRd = []

        for filename in os.listdir(folder):
            #print(filename)
            
            if (('scan_Plate_R_' in filename) and ('d1' in filename) ):
               # newfilename = filename[:len(filename)-5] + '2' + filename[len(filename)-4:]
                #print(newfilename)
                imgRd = cv2.imread(os.path.join(folder,filename),-1)
                if imgRd is not None:
                    imagesRd.append(imgRd)

        return imagesRd


    def bapplytoallcallback(self):
        path = pathlib.Path(self.path)
        folder = path.parent
        #print(folder)
        imagesRd = self.load_images_from_folder(folder)

        #print(len(imagesRd),len(imagesGr))
        self.processallimages(imagesRd)
    
    def processallimages(self, imagesRd):
        cellCountALL = []
        cellCountALLpc = []

        cellCountAvg = 0
        self.BrCellCount=int(self.tbBrCellCount.get())
        distTh  =  50 #self.distTh
        for i in range(len(imagesRd)):
            imgRd = imagesRd[i]

                      
            imgRd = np.matrix(imgRd)
            imgRd.astype('float16')
            imgRd = imgRd/65535
            lowIn = np.min(imgRd)
            highIn = np.amax(imgRd)
            imgRedEn = self.ImProcess.imadjust(imgRd,lowIn, highIn,0,1,1)
            imgRedBin = self.ImProcess.imbinarize(imgRedEn,float(self.thRd))
            imgClean = self.ImProcess.noiseRemoval(imgRedBin,self.objAreaRd)

            cellCount = self.ImProcess.localproc( np.matrix(imgClean))
                   
            
            cellCountAvg = cellCountAvg + cellCount
            cellCountALL.append(cellCountAvg)
            cellCountALLpc.append(round((cellCountAvg/self.BrCellCount)*100,2))
            

        if self.labelCellCountALL1.winfo_exists():
            self.frame2.destroy()
        self.frame2 = Frame(self.win)
        self.frame2.pack(side="bottom", expand=True, fill="both")
        
       
        self.labelCellCountALL1 = Label()
        self.labelCellCountALL2 = Label()
        self.labelCellCountALL3 = Label()
        self.labelCellCountALL4 = Label()
        self.labelCellCountALL5 = Label()

            
        cellCountAvg = cellCountAvg/len(imagesRd)
        textCellCount = "Cell Count Average over all images "+ str(cellCountAvg)
        self.labelCellCountALL1 = Label(self.frame2, text=textCellCount, font=('Caveat 10 bold'))
        self.labelCellCountALL1.pack()
        textCellCount = "Cumulative Cell Count across Time"
        self.labelCellCountALL2= Label(self.frame2, text=textCellCount, font=('Caveat 10 bold'))
        self.labelCellCountALL2.pack()
        textCellCount = str(cellCountALL)
        self.labelCellCountALL3 = Label(self.frame2, text=textCellCount, font=('Caveat 10 bold'))
        self.labelCellCountALL3.pack()
        textCellCount = "Cumulative Cell Count Percentage with respect to Bright Field across Time"
        self.labelCellCountALL4= Label(self.frame2, text=textCellCount, font=('Caveat 10 bold'))
        self.labelCellCountALL4.pack()
        
        textCellCount = str(cellCountALLpc)
        self.labelCellCountALL5 = Label(self.frame2, text=textCellCount+'%', font=('Caveat 10 bold'))
        self.labelCellCountALL5.pack()
        Data1 = np.array(range(len(cellCountALL)))
        Data2 = np.array(cellCountALL)
        Data3 = np.array(cellCountALLpc)
        Data = np.array([Data1, Data2, Data3])
        brightFieldCellCount = self.tbBrCellCount.get()

        header =(['Cell Counter'])
        header1 = (['Bright Field Image Cell Count', brightFieldCellCount])
        header2 = (['Time Instance', 'Cumulative Cell Count','Cell Count Percentage'])

        f = open('cellcount_file.csv','w')
        writer =csv.writer(f, delimiter=',')
        writer.writerow(header)
        writer.writerow(header1)
        writer.writerow(header2)
        writer.writerows(Data.T)
        f.close()

    def reset(self):
        global clickCount
        clickCount = 0
        global CountGr
        global CountRd
        CountGr = 0
        CountRd = 0
        self.frame.canvas.delete('all')
        self.frame.canvas.destroy()
        self.frame.scrollbarH.destroy()
        self.frame.scrollbarV.destroy()
        self.frame.scrollable_frame.destroy()
        self.frame.canvas.master.destroy()
        self.frame2.destroy()
        plt.close('all')

        self.bApplytoAll["state"]="disabled"
        self.bLoad["state"]="normal"

    def main(self):
        self.ImProcess = ImgProcessing()        
        self.win= Tk()
        self.labelCellCount =Label()
        self.labelCellCountALL1 = Label()
        self.labelCellCountALL2 = Label()
        self.labelCellCountALL3 = Label()
        self.labelCellCountALL4 = Label()
        self.labelCellCountALL5 = Label()
        self.imgRed = 0
        self.dispBts = []
        global CountGr
        CountGr = 0
        global CountRd
        CountRd = 0
        global clickCount
        clickCount = 0
        self.filename =list()
        self.slider = Scale()
        screen_width = self.win.winfo_screenwidth()
        screen_height = self.win. winfo_screenheight()
  
        self.win.geometry("800x600")
        self.win.resizable(0,0)
    
        self.win.title("Cell Counter")
        Label(self.win, text="Cell Counter", font=('Caveat 20 bold')).pack(pady=5)
        Label(self.win, text="Bright Field Cell Count", font=('Caveat 10 bold')).pack(pady=5)
        self.tbBrCellCount = Entry(self.win)        
        self.tbBrCellCount.pack(pady=2)
        Label(self.win, text="Click the Button below to load Red Image", font=('Caveat 10 bold')).pack(pady=5)
        self.bLoad= ttk.Button(self.win, text="Load Image", command= self.loadimage)
        self.bLoad.pack(ipadx=5, pady=2)
        self.bApplytoAll= ttk.Button(self.win, text="Apply to All",state=DISABLED, command=lambda:self.bapplytoallcallback())
        self.bApplytoAll.pack(ipadx=20, pady=2)
        self.bReset= ttk.Button(self.win, text="Reset", command= self.reset)
        self.bReset.pack(ipadx=5, pady=2)

        self.win.mainloop()
     
    def MainFunct(self):
        global clickCount
        if clickCount==1:
            Label(self.frame.scrollable_frame, text="Choose the threshold to binarise Red Image", font=('Caveat 10 bold')).pack(pady=2)
            self.current_value = tkinter.DoubleVar()
            self.slider = Scale(self.frame.scrollable_frame, from_=0, to=255,length=500, orient=HORIZONTAL,variable=self.current_value)
            self.slider.set(0)  
            self.slider.pack()
            self.bBinary= ttk.Button(self.frame.scrollable_frame, text="Binarise Image (Red)", command=lambda img=np.matrix(self.imgRdEn):self.sliderchanged(img))
            self.bBinary.pack(ipadx=5, pady=2)
            Label(self.frame.scrollable_frame, text="Remove objects with areas smaller than the area defined in the text box.", font=('Caveat 10 bold')).pack(pady=2)
            self.tbObjArea = Entry(self.frame.scrollable_frame)        
            self.tbObjArea.pack(ipadx=5, pady=2)
            self.bCleaned= ttk.Button(self.frame.scrollable_frame, text="Noise Removal (Red)", command=lambda:self.bcleanedcallback())
            self.bCleaned.pack(ipadx=5, pady=2)
            #Label(self.frame.scrollable_frame, text="Choose threshold and minimum object area, ", font=('Caveat 10 bold')).pack(pady=2)
            #Label(self.frame.scrollable_frame, text="to binarise and clean the Red Image then press the button to get the Cell Count", font=('Caveat 10 bold')).pack(pady=2)
            #self.T1 = tkinter.DoubleVar()
            #self.sliderT1 = Scale(self.frame.scrollable_frame, from_=0, to=255,length=500, orient=HORIZONTAL,variable=self.T1)
            #self.sliderT1.set(0)  
            #self.sliderT1.pack()
            #self.tbObjAreaRed = Entry(self.frame.scrollable_frame)        
            #self.tbObjAreaRed.pack(ipadx=5, pady=2)
            self.bCellCount= ttk.Button(self.frame.scrollable_frame, text="Cell Count", command=lambda:self.bcellcountcallback())
            self.bCellCount.pack(ipadx=5, pady=2)
            





class ImgProcessing:


    def imadjust(self,img,lowIn, highIn,lowOut,highOut,gamma=1):
        # Similar to imadjust in MATLAB.
        # Converts an image range from [a,b] to [c,d].
        # The Equation of a line can be used for this transformation:
        #   y=((d-c)/(b-a))*(x-a)+c
        # However, it is better to use a more generalized equation:
        #   y=((x-a)/(b-a))^gamma*(d-c)+c
        # If gamma is equal to 1, then the line equation is used.
        # When gamma is not equal to 1, then the transformation is not linear.
        
        #cv2.imshow("image", img)
 
        # height, width, number of channels in image
        height = img.shape[0]
        width = img.shape[1]
        blank_image = np.zeros((height,width), np.uint8)
        cv2.namedWindow("image", cv2.WINDOW_NORMAL) 
        cv2.resizeWindow("image", 500, 500)
        r = cv2.selectROI("image", img)
        cv2.waitKey(0)
        cv2.destroyAllWindows()
        blank_image[int(r[1]):int(r[1]+r[3]),int(r[0]):int(r[0]+r[2])] = 1
        img[blank_image==1] = np.mean(img[blank_image==0])


        cdfTh = 98
        h,w= img.shape

        hist,bins = np.histogram(img.ravel(),65536,[0,1])
        # = imp.getHistogram()
        ind = array.array('i',(i for i in range(0,len(hist))))

        cumSum = [float(hist[0])/(h*w)]
        #print("CumSum",cumSum)
        for i in range(1,len(hist)):
            cumSum.append(float(hist[i])/(h*w)+cumSum[i-1])
        for i in range(0,len(hist)):
            if cumSum[i]*100 >= cdfTh:
                break
        
        intTh = ind[i]
        MeanVal = 0
        numPixels = 0
        MeanVal = 0
        numPixels = 0

        for pixelx in range(h):
            for pixely in range(w):
                sig = img[pixelx,pixely]
                if sig < intTh:
                    MeanVal = MeanVal + sig
                    numPixels = numPixels + 1
        MeanVal = MeanVal/(h*w)
        for pixelx in range(h):
            for pixely in range(w):
                sig = img[pixelx,pixely]
                if sig > intTh:
                    img[pixelx, pixely] = MeanVal


        img = 10*img
        lowIn = np.min(img)
        highIn = np.max(img)
        img[img<lowIn] = lowIn
        imgOut = ((np.power(((img - lowIn) / (highIn - lowIn)),gamma)) * (highOut - lowOut)) + lowOut
        #imgOut= exposure.equalize_hist(imgOut)
        return imgOut
    
    def imbinarize(self,img,Th=128): 
        imgOut = np.matrix(np.zeros((np.size(img,0),np.size(img,1)),np.uint8))
        imgOut[(img*255 > Th)] = 1 


        # ret,imgOut = cv2.threshold(img,Th,1,cv2.THRESH_BINARY)            
        # th2 = cv2.adaptiveThreshold(img,255,cv2.ADAPTIVE_THRESH_MEAN_C,cv2.THRESH_BINARY,11,2)
        # th3 = cv2.adaptiveThreshold(img,255,cv2.ADAPTIVE_THRESH_GAUSSIAN_C,cv2.THRESH_BINARY,11,2)
        return imgOut
    
    def noiseRemoval(self,img,ObjArea = 100):
        imgMedfilt = cv2.medianBlur(img.astype(np.uint8),5)
        imgOut = morphology.remove_small_objects(imgMedfilt.astype(np.bool_), min_size=ObjArea, connectivity=8)
        return imgOut
    
    def localproc(self,imgRed):
       
        image = label(imgRed)
       
        distance = ndimage.distance_transform_edt(image)
        coords = peak_local_max(distance, footprint=np.ones((29, 29)), labels=image)
        mask = np.zeros(distance.shape, dtype=bool)
        mask[tuple(coords.T)] = True
        markers, _ = ndimage.label(mask)
        
        labels = watershed(-distance, markers,mask=image)
        regions = regionprops(labels)
        cellCount = len(regions)              

        return cellCount
    


#def quitWin():
 #   CmdWin = CommandWindow()
  #  CmdWin.win.quit()



