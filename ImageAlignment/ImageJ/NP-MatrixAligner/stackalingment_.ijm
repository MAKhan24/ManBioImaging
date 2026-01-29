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

    // normalise extension filter
    extLC = toLowerCase(ext);
    allowTiffFamily = (extLC == ".tif" || extLC == ".tiff");

    files = newArray(); // will grow
    cnt = 0;

    for (i = 0; i < list.length; i++) {

        name = list[i];

        // skip directories (they usually end with File.separator in IJM listing)
        if (endsWith(name, File.separator)) {
            // print("Skipping folder: " + name);
            continue;
        }

        nameLC = toLowerCase(name);

        ok = 0;
        if (allowTiffFamily) {
            if (endsWith(nameLC, ".tif") || endsWith(nameLC, ".tiff")) ok = 1;
        } else {
            if (endsWith(nameLC, extLC)) ok = 1;
        }

        if (ok) {
            files[cnt] = name;
            cnt++;
        } else {
            // optional: log skipped entries
            // print("Skipping (ext mismatch): " + name);
        }
    }

    if (cnt == 0) {
        showMessage("No files found",
            "No matching files found in:\n" + origImgsDirPath +
            "\n\nFilter: " + ext + " (case-insensitive)");
        return;
    }

    Array.sort(files); // alphabetical, reliable

    print("Found " + cnt + " matching files.");

    // Process each file
    for (i = 0; i < files.length; i++) {
        if (files[i] == "") continue;

        print("Processing: " + files[i]);
        processFile(files[i], summaryPath); // your existing function
        close("*"); // clean slate per file (ok here)
    }

    print("Done.");
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

            clearResultsSafely();

			oldT = findOBoxTableTitle(segTitle);
			if (oldT != "") safeCloseWindow(oldT);
			
			// Run OBB
			run("Oriented Bounding Box", "show");
			
			// Find the created table title dynamically
			tTitle = findOBoxTableTitle(segTitle);
			
			if (tTitle == "") {
			    // Fallback if table not found
			    method = "manual_fallback";
			    tmp = newArray(2);
			    angleDeg = manualAngleAndCentreByID(origID,origTitle, tmp);
			    centreX = tmp[0];
			    centreY = tmp[1];
			} else {
			    // Read centre + orientation from the active OBox table
				obb = newArray(3);
				readOBoxFromTable(tTitle, obb);
				
				centreX = obb[0];
				centreY = obb[1];
				angleDeg = 180 - obb[2];
			
			    // Close the table to keep workspace clean (optional)
			    safeCloseWindow(tTitle);
			}

		roiManager("Reset");
		} else {
            // Manual mode even though segmentation exists
            method = "manual";

            // Close seg so it doesn't steal focus
            safeCloseWindow(segTitle);

            tmp = newArray(2);
            angleDeg = manualAngleAndCentreByID(origID, origTitle,tmp);
            centreX = tmp[0];
            centreY = tmp[1];
        }
		
        // If seg still open, close it by ID (try-select then close)
        safeCloseWindow(segTitle);

    } else {
        method = "manual_no_seg";
        tmp = newArray(2);
        angleDeg = manualAngleAndCentreByID(origID,origTitle, tmp);
        centreX = tmp[0];
        centreY = tmp[1];
    }

    // ---- From here onward, always select by origID
    selectImage(origID);
	selectImage(origTitle);
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

    safeCloseWindow("Results");
    safeCloseWindow("Log");
    roiManager("reset");
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
function manualAngleAndCentreByID(imgID,imgTitle, outArr) {

    selectImage(imgID);
    selectImage(imgTitle);
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

function clearResultsSafely() {
    // Clears the standard Results table without relying on Table.reset()
    if (isWindowOpen("Results")) {
        selectWindow("Results");
        run("Clear Results");
    } else {
        // If Results isn't open, still fine to call; it will create/activate in most builds
        run("Clear Results");
    }
}

function findOBoxTableTitle(segTitle) {
    // The plugin creates a table titled like:
    // "<segTitle>-largest-Obox"
    // We'll search for the newest/most relevant one.

    titles = getList("window.titles");

    // 1) Best match: starts with segTitle and contains "Obox"
    for (i = titles.length-1; i >= 0; i--) {
        if (startsWith(titles[i], segTitle) && indexOf(titles[i], "Obox") >= 0)
            return titles[i];
        if (startsWith(titles[i], segTitle) && indexOf(titles[i], "OBox") >= 0)
            return titles[i];
    }

    // 2) Fallback: any table containing "Obox"
    for (i = titles.length-1; i >= 0; i--) {
        if (indexOf(titles[i], "Obox") >= 0 || indexOf(titles[i], "OBox") >= 0)
            return titles[i];
    }

    return "";
}

function readOBoxFromTable(tableTitle, outArr) {
    // outArr[0] = centreX
    // outArr[1] = centreY
    // outArr[2] = orientation

    selectWindow(tableTitle);

    outArr[0] = Table.get("Box.Center.X", 0);
    outArr[1] = Table.get("Box.Center.Y", 0);
    outArr[2] = Table.get("Box.Orientation", 0);
}

