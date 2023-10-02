run("8-bit");
run("Duplicate...", "duplicate");
title = getTitle();
objTitle = "Objects map of " + title;
centTitle = "Centroids map of " + title;

//run("Enhance Contrast...", "saturated=0.80 normalize process_all use");
run("Enhance Contrast...");

run("Median...", "radius=10 stack");
run("3D OC Options", "nb_of_obj._voxels centroid dots_size=20 font_size=16 store_results_within_a_table_named_after_the_image_(macro_friendly) redirect_to=none");
run("3D Objects Counter");
selectWindow(title);
close();
//selectWindow(objTitle);
//close();

selectWindow(centTitle);
setForegroundColor(255, 255, 255);
setBackgroundColor(0, 0, 0);
run("Convert to Mask", "method=Huang background=Light calculate black create");
run("Invert", "stack");
run("Analyze Particles...", "  show=Nothing exclude clear summarize add stack");
sliceNO = Table.getColumn("Slice", "Summary of MASK_Centroids map of " + title);
//Array.print(sliceNO);
count = Table.getColumn("Count", "Summary of MASK_Centroids map of " + title);
//Array.print(count);
Plot.create("Plot of Summary of MASK_Centroids map of " + title, "Slice", "Count");
Plot.add("Separated Bars",sliceNO,count);
Plot.setStyle(0, "blue,#a0a0ff,1.0,Separated Bars");
