#@ File    (label="Path to Unaligned Input Images", style="directory") origImgsDirPath
#@ File    (label="Path to Corresponding Segmented Images", style="directory") segImgsDirPath
#@ File    (label="Path to Output Aligned Images", style="directory") alignImgsDirPath
#@ String  (label="File extension", value=".tif") ext
#@ Integer (label="Height for Cropping the Image to compensate Translation", value=700) boxHeight
#@ Integer (label="Width for Cropping the Image to compensate Translation", value=1300) boxWidth

processFolder();

function processFolder() {
    print("Input (orig): " + origImgsDirPath);
    print("Input (seg) : " + segImgsDirPath);
    print("Output      : " + alignImgsDirPath);

    // Prepare output folder + summary CSV
    summaryPath = alignImgsDirPath + File.separator + "alignment_summary.csv";
    if (!File.exists(alignImgsDirPath)) File.makeDirectory(alignImgsDirPath);

    // Write header if file does not exist
    if (!File.exists(summaryPath)) {
        File.saveString("file,method,angle_deg,centreX,centreY,output_path\n", summaryPath);
    }

    list = getFileList(origImgsDirPath);

    // Build candidate list
    files = newArray();
    keys  = newArray(); // numeric keys if possible; NaN-like set to -1 and use alpha sort fallback
    cnt = 0;

    for (i = 0; i < list.length; i++) {
        if (endsWith(list[i], ext)) {
            files[cnt] = list[i];
            keys[cnt]  = extractTrailingNumberOrMinusOne(list[i]); // robust-ish
            cnt++;
        }
    }

    if (cnt == 0) {
        showMessage("No files found", "No files ending with '" + ext + "' were found in:\n" + origImgsDirPath);
        return;
    }

    // Sort:
    // If most keys are valid (>=0), sort by numeric key; otherwise sort alphabetically.
    validKeyCount = 0;
    for (i=0; i<keys.length; i++) if (keys[i] >= 0) validKeyCount++;

    if (validKeyCount >= round(keys.length * 0.6)) {
        Array.sort(keys, files);
        print("Sorting mode: numeric (trailing number in filename)");
    } else {
        Array.sort(files);
        print("Sorting mode: alphabetical");
    }

    close("*");

    for (i = 0; i < files.length; i++) {
        if (files[i] == "") continue;
        processFile(files[i], summaryPath);
        close("*");
    }

    print("Done. Summary CSV: " + summaryPath);
}

function processFile(fileName, summaryPath) {

    origPath = origImgsDirPath + File.separator + fileName;
    baseName = File.getNameWithoutExtension(origPath);
    segPath  = segImgsDirPath + File.separator + "pred_mask_" + baseName + "_refined.tif";

    // ---- Open original and store ID (do NOT rely on title later)
    open(origPath);
    origID = getImageID();
    origTitle = getTitle();
    getDimensions(w, h, c, z, t);

    method  = "";
    centreX = w/2;
    centreY = h/2;
    angleDeg = 0;

    if (File.exists(segPath)) {

        open(segPath);
        segID = getImageID();
        segTitle = getTitle();

        ok = getBoolean("Segmentation for:\n" + fileName + "\n\nLooks good? (Yes=use mask; No=manual line)");

        if (ok) {
            method = "mask";

            selectImage(segID);
            run("Maximum...", "radius=5");
            run("Keep Largest Region");

            roiManager("Reset");
            run("Create Selection");
            roiManager("Add");
            roiManager("Select", 0);

            Table.reset();
            // IMPORTANT: no label= here
            run("Oriented Bounding Box", "show");

			if (Table.size == 0) {
			    // Fallback to manual if OBB did not write results
			    method = "manual_fallback";
			    tmp = newArray(2);
			    angleDeg = manualAngleAndCentreByID(origID, tmp);
			    centreX = tmp[0];
			    centreY = tmp[1];
			} else {
			    centreX = Table.get("Box.Center.X", 0);
			    centreY = Table.get("Box.Center.Y", 0);
			    angleDeg = 180 - Table.get("Box.Orientation", 0);
			}


            roiManager("Reset");

        } else {
            method = "manual";

            // Close seg safely by selecting its ID first
           safeCloseWindow(segTitle);


            tmp = newArray(2);
            angleDeg = manualAngleAndCentreByID(origID, tmp);
            centreX = tmp[0];
            centreY = tmp[1];
        }

        // If seg still open, close it by ID (try-select then close)
        safeCloseWindow(segTitle);

    } else {
        method = "manual_no_seg";
        tmp = newArray(2);
        angleDeg = manualAngleAndCentreByID(origID, tmp);
        centreX = tmp[0];
        centreY = tmp[1];
    }

    // ---- From here onward, always select by origID
    selectImage(origID);

    angleToApply = normalizeAngleForRotation(angleDeg);
    run("Rotate... ", "angle=" + angleToApply + " grid=1 interpolation=Bilinear");

    // re-fetch dims after rotation
    getDimensions(w2, h2, c2, z2, t2);

    x0 = round(centreX - boxWidth/2);
    y0 = round(centreY - boxHeight/2);

    if (x0 < 0) x0 = 0;
    if (y0 < 0) y0 = 0;
    if (x0 + boxWidth > w2) x0 = maxOf(0, w2 - boxWidth);
    if (y0 + boxHeight > h2) y0 = maxOf(0, h2 - boxHeight);

    makeRectangle(x0, y0, boxWidth, boxHeight);
    run("Crop");

    outPath = alignImgsDirPath + File.separator + baseName + ".tif";
    saveAs("Tiff", outPath);

    line = fileName + "," + method + "," + d2s(angleToApply,3) + "," + d2s(centreX,3) + "," + d2s(centreY,3) + "," + outPath + "\n";
    File.append(line, summaryPath);

    safeClose("Results");
    safeClose("Log");
    Table.reset();
}


//////////////////////
// Helper functions  //
//////////////////////

// Try to extract a trailing integer right before the extension.
// If not found, return -1.
function extractTrailingNumberOrMinusOne(name) {
    dot = lastIndexOf(name, ".");
    if (dot < 0) return -1;

    // Scan backwards from dot-1 collecting digits
    i = dot - 1;
    digits = "";
    while (i >= 0) {
        ch = substring(name, i, i+1);
        if (ch >= "0" && ch <= "9") {
            digits = ch + digits;
            i--;
        } else {
            break;
        }
    }
    if (lengthOf(digits) == 0) return -1;

    return parseInt(digits);
}

// Manual mode: user draws a line starting at centre and parallel to orientation.
// Stores centre in globals MANUAL_cx/MANUAL_cy and returns angle.
function manualAngleAndCentreByID(imgID, outArr) {

    selectImage(imgID);
    roiManager("Reset");

    waitForUser(
        "Manual orientation:\n\n" +
        "Draw a STRAIGHT LINE starting from the centre and parallel to the object's orientation.\n" +
        "Then click OK."
    );

    if (selectionType() == -1) {
        getDimensions(w, h, c, z, t);
        outArr[0] = w/2;
        outArr[1] = h/2;
        return 0;
    }

    // Get ROI coordinates
    getSelectionCoordinates(x, y);

    // Must have at least 2 points for a line
    if (x.length < 2) {
        getDimensions(w, h, c, z, t);
        outArr[0] = w/2;
        outArr[1] = h/2;
        return 0;
    }

    // First point is centre (your original behaviour)
    outArr[0] = x[0];
    outArr[1] = y[0];

    // Compute angle in degrees from first -> last point
    dx = x[x.length-1] - x[0];
    dy = y[0] - y[y.length-1]; // invert because image y increases downward

    // Avoid divide-by-zero
    if (dx == 0 && dy == 0) return 0;

    ang = atan2(dy, dx) * 180 / PI;

    return ang;
}




// Your normalization logic, kept but packaged.
function normalizeAngleForRotation(t) {
    if (t > 90 && t < 180) {
        return (t - 180);
    } else if (t > -180 && t < -90) {
        return (180 + t);
    } else {
        return t;
    }
}

function safeClose(title) {
    // Close a window only if it exists
    if (isOpen(title)) {
        selectWindow(title);
        run("Close");
    }
}

function isOpen(title) {
    // Returns 1 if window title exists
    list = getList("window.titles");
    for (i=0; i<list.length; i++) {
        if (list[i] == title) return 1;
    }
    return 0;
}

function maxOf(a,b) {
    if (a>b) return a;
    return b;
}

function safeCloseByID(id) {
    // Try selecting; if it fails, do nothing
    ok = 1;
    // selectImage(id) throws if invalid; ImageJ macro has no try/catch,
    // so we guard by checking list of open IDs via window titles indirectly:
    // Easiest reliable approach: only call this when you *know* you opened it.
    selectImage(id);
    run("Close");
}

function closeIfAnyOpen() {
    // Last-resort: close current image only if at least one image is open
    titles = getList("window.titles");
    if (titles.length > 0) {
        selectWindow(titles[0]);
        run("Close");
    }
}

function isWindowOpen(title) {
    titles = getList("window.titles");
    for (i=0; i<titles.length; i++) {
        if (titles[i] == title) return 1;
    }
    return 0;
}

function safeCloseWindow(title) {
    if (isWindowOpen(title)) {
        selectWindow(title);
        run("Close");   // <-- IMPORTANT: NOT close();
    }
}

// keep compatibility with your existing calls
function safeClose(title) {
    safeCloseWindow(title);
}
