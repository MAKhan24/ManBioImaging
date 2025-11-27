#@ File    (label = "Input directory", style = "directory") srcFile
#@ File    (label = "Output directory", style = "directory") dstFile
#@ String  (label = "File extension", value=".nd2") ext
#@ Integer  (label = "Number of Positions per Well", value=1) no_series
#@ String (label = "C1 for Nuclei and C2 for Cells", value="C2") channel


import sys
import os
from ij import IJ, ImagePlus,gui
from ij import WindowManager
from ij.process import ImageProcessor
from ij.process import ImageStatistics
from fiji.plugin.trackmate import Model
from fiji.plugin.trackmate import Settings
from fiji.plugin.trackmate import TrackMate
from fiji.plugin.trackmate import SelectionModel
from fiji.plugin.trackmate import FeatureModel
from fiji.plugin.trackmate import Logger
#from fiji.plugin.trackmate.detection import LogDetectorFactory
from fiji.plugin.trackmate.detection import ThresholdDetectorFactory
from fiji.plugin.trackmate.cellpose import CellposeDetectorFactory
from fiji.plugin.trackmate.cellpose.CellposeSettings import PretrainedModel
from fiji.plugin.trackmate.tracking.jaqaman import SparseLAPTrackerFactory
from fiji.plugin.trackmate.gui.displaysettings import DisplaySettingsIO
from fiji.plugin.trackmate.gui.displaysettings.DisplaySettings import TrackMateObject
from fiji.plugin.trackmate.features.track import TrackIndexAnalyzer

import fiji.plugin.trackmate.visualization.hyperstack.HyperStackDisplayer as HyperStackDisplayer
import fiji.plugin.trackmate.features.FeatureFilter as FeatureFilter
from fiji.plugin.trackmate.visualization.table import TrackTableView
from fiji.plugin.trackmate.visualization.table import AllSpotsTableView
from fiji.plugin.trackmate.io import CSVExporter
from java.io import File



def run():
	srcDir = srcFile.getAbsolutePath()
	dstDir = dstFile.getAbsolutePath()
	filenames = os.listdir(srcDir)
	#for root, directories, filenames in os.walk(srcDir):
	filenames.sort();
	
	for filename in filenames:
	  # Check for file extension
	  if not filename.endswith(ext):
	    continue
	  # Check for file name pattern
	  #if containString not in filename:
	   # continue
	  process(srcDir, dstDir, filename)
	


def process(srcDir, dstDir, fileName):
	# We have to do the following to avoid errors with UTF8 chars generated in 
	# TrackMate that will mess with our Fiji Jython.
	reload(sys)
	sys.setdefaultencoding('utf-8')
	imgTitlesTemp =WindowManager.getImageTitles()
	for title in imgTitlesTemp:
		impTemp = WindowManager.getImage(title)
		impTemp.close()
				
	print "Processing:"
	# Opening the image
	print "Open image file", fileName
	for s in range(1,no_series+1):
		print s
		srcDirPath = os.path.join(srcDir,fileName)
		srcDirPath = srcDirPath.replace('\\','/')
		#print srcDirPath
		IJ.run("Bio-Formats Importer", "open=["+srcDirPath+"] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_"+str(s))
		#if channels
		
		#IJ.run("Split Channels")
		#imgTitles =WindowManager.getImageTitles()

		#for title in imgTitles:
		#	if channel not in title:
				#WindowManager.getWindow(title)
		#		imp = WindowManager.getImage(title)
		#		imp.close()
		#	else:
		#		IJ.run("Duplicate...", "duplicate title="+fileName)
		#		imp = WindowManager.getImage(title)
		#		imp.close()
				
		imp = WindowManager.getCurrentImage()
		imgTitles =WindowManager.getImageTitles()
		imgTitles[0] = imgTitles[0].replace(ext, '.csv')
		#print fileName
		fileNameWoExt = fileName.replace(ext,"")
		#print fileNameWoExt
		dstDirPath = dstDir+'/'+fileNameWoExt+'/'
		#print dstDirPath
		#dstDirPath=dstDirPath.replace("."+ext,"")
	
		if not os.path.exists(dstDirPath):
			os.mkdir(dstDirPath)
		output_filename = dstDirPath+'/series-'+str(s)+'.csv'
		tracks_table_csv_file = File(output_filename.replace('.csv', '-tracks.csv' ))
		#print tracks_table_csv_file
		#spot_table_csv_file = File(output_filename.replace('.csv', '-spotsTemp.csv' ))
		spot_table_csv_file = output_filename.replace('.csv', '-spots.csv' )
		print spot_table_csv_file
		#----------------------------
		# Create the model object now
		#----------------------------
		# Some of the parameters we configure below need to have
		# a reference to the model at creation. So we create an
		# empty model now.
		
		model = Model()
		model.setPhysicalUnits("microns", "none")
		# Send all messages to ImageJ log window.
		model.setLogger(Logger.IJ_LOGGER)
			
		#------------------------
		# Prepare settings object
		#------------------------
		
		settings = Settings(imp)
		
		settings.detectorFactory = CellposeDetectorFactory()
		
		settings.detectorSettings['TARGET_CHANNEL'] = 1
		settings.detectorSettings['OPTIONAL_CHANNEL_2'] = 0
		settings.detectorSettings['CELLPOSE_PYTHON_FILEPATH'] = 'C:/Users/Public/Desktop/Cellpose/cellpose.exe'
		settings.detectorSettings['CELLPOSE_MODEL_FILEPATH'] = 'C:/Users/Public/Desktop/Cellpose/models/cyto3' #'C:/Users/BCF/.cellpose/models'
		#if channel=="C2":
		#	settings.detectorSettings['CELLPOSE_MODEL'] = PretrainedModel.CYTO
		#else:
		#	settings.detectorSettings['CELLPOSE_MODEL'] = PretrainedModel.NUCLEI
			
		settings.detectorSettings['CELLPOSE_MODEL'] = PretrainedModel.CUSTOM	
		settings.detectorSettings['CELL_DIAMETER'] = 30.0
		settings.detectorSettings['USE_GPU'] = True
		settings.detectorSettings['SIMPLIFY_CONTOURS'] = True
		
		# Configure spot filters - Classical filter on quality
		filter1 = FeatureFilter('QUALITY', 0.0, True)
		settings.addSpotFilter(filter1)
		
		# Configure tracker - We want to allow merges and fusions
		settings.trackerFactory = SparseLAPTrackerFactory()
		settings.trackerSettings = settings.trackerFactory.getDefaultSettings() # almost good enough
		settings.trackerSettings['ALLOW_TRACK_SPLITTING'] = False
		settings.trackerSettings['ALLOW_TRACK_MERGING'] = False
		settings.trackerSettings['MAX_FRAME_GAP'] = 2
		settings.trackerSettings['LINKING_MAX_DISTANCE'] = 50.0 #50
		settings.trackerSettings['GAP_CLOSING_MAX_DISTANCE'] = 30.0 #30
		
		# Add ALL the feature analyzers known to TrackMate. They will 
		# yield numerical features for the results, such as speed, mean intensity etc.
		settings.addAllAnalyzers()
		
		# Configure track filters - We want to get rid of the two immobile spots at
		# the bottom right of the image. Track displacement must be above 10 pixels.
		
		filter2 = FeatureFilter('TRACK_DISPLACEMENT',2 , True)
		settings.addTrackFilter(filter2)
		
		#-------------------
		# Instantiate plugin
		#-------------------
		
		trackmate = TrackMate(model, settings)
		
		#--------
		# Process
		#--------
		
		ok = trackmate.checkInput()
		if not ok:
			sys.exit(str(trackmate.getErrorMessage()))
		
		ok = trackmate.process()
		if not ok:
			sys.exit(str(trackmate.getErrorMessage()))
		
		
		#----------------
		# Display results
		#----------------
		
		# A selection.
		selectionModel = SelectionModel( model )
		
		# Read the default display settings.
		ds = DisplaySettingsIO.readUserDefault()
		# Color by tracks.
		ds.setTrackColorBy( TrackMateObject.TRACKS, TrackIndexAnalyzer.TRACK_INDEX )
		ds.setSpotColorBy( TrackMateObject.TRACKS, TrackIndexAnalyzer.TRACK_INDEX )
		
		displayer =  HyperStackDisplayer( model, selectionModel, imp, ds )
		displayer.render()
		displayer.refresh()
		
		# Echo results with the logger we set at start:
		model.getLogger().log( str( model ) )
		#print model.getTimeUnits()		
		
		only_visible = True # Export only visible tracks
		# If you set this flag to False, it will include all the spots,
		# the ones not in tracks, and the ones not visible.
		#home = expanduser("~")
		#spot_table_csv_file = 'D:/FakeTracks.csv'
		#spot_table_csv_file = spot_table_csv_file.replace('\\','/')
		CSVExporter.exportSpots( spot_table_csv_file , model, only_visible )
		
		
		# Track table.
		track_table = TrackTableView.createTrackTable( model, ds )
		track_table.exportToCsv(tracks_table_csv_file)
		print "Done -- " + fileName + "-" + str(s)


run()
print "Done----------"




		
		#----------------------------------------------------
		# 3/ Export spots, edges and track data to CSV files.
		#----------------------------------------------------
			
		# The following uses the tables that are displayed in the TrackMate
		# GUI. As a consequence the snippet cannot be used in 'headless' mode.
		# If you launch the script from the Fiji script editor, we won't
		# have a problem.
		
		# Spot table. Will contain only the spots that are in visible tracks.
		
		#spot_table = TrackTableView.createSpotTable( model, ds )		
		#spot_table.exportToCsv( spot_table_csv_file )
		
		# Save all spots table
		#spotsTableView = AllSpotsTableView(model, selectionModel, ds)
		#spotsTable = spotsTableView.createSpotTable(model,ds)
		#spotsTableView.exportToCsv(spot_table_csv_file)
		
		
		# Edge table.
		#edge_table = TrackTableView.createEdgeTable( model, ds )
		#edge_table.exportToCsv( edge_table_csv_file )
		#fm.putTrackFeature(0, "TRACK_DURATION", 30)

