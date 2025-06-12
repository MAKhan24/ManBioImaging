import ij.*;
import ij.gui.GenericDialog;
import ij.gui.Roi;
import ij.plugin.PlugIn;
import ij.plugin.frame.RoiManager;

import java.awt.Point;
import java.awt.Rectangle;
import java.util.ArrayList;

public class Keep_IsolatedROIs_ implements PlugIn {

    @Override
    public void run(String arg) {
        RoiManager rm = RoiManager.getInstance();
        if (rm == null || rm.getCount() == 0) {
            IJ.error("ROI Manager is empty.");
            return;
        }

        ImagePlus imp = IJ.getImage();
        if (imp == null) {
            IJ.error("No image open.");
            return;
        }

        GenericDialog gd = new GenericDialog("Threshold Distance");
        gd.addNumericField("Threshold (microns):", 15.0, 2);
        gd.showDialog();
        if (gd.wasCanceled())
            return;

        double threshold = gd.getNextNumber();

        double pw = imp.getCalibration().pixelWidth;
        double ph = imp.getCalibration().pixelHeight;
        int n = rm.getCount();

        ArrayList<ArrayList<Point>> polygons = new ArrayList<>();
        ArrayList<Rectangle> bounds = new ArrayList<>();
        for (int i = 0; i < n; i++) {
            Roi roi = rm.getRoi(i);
            if (roi.getPolygon() == null) {
                IJ.error("ROI #" + i + " is not polygonal.");
                return;
            }
            java.awt.Polygon poly = roi.getPolygon();
            ArrayList<Point> pts = new ArrayList<>();
            for (int j = 0; j < poly.npoints; j++) {
                int x = (int) Math.round(poly.xpoints[j] * pw * 1000);
                int y = (int) Math.round(poly.ypoints[j] * ph * 1000);
                pts.add(new Point(x, y));
            }
            polygons.add(pts);
            bounds.add(roi.getBounds());
        }

        boolean[] hasNeighbor = new boolean[n];
        for (int i = 0; i < n; i++)
            hasNeighbor[i] = false;

        for (int i = 0; i < n; i++) {
            for (int j = i + 1; j < n; j++) {
                if (bboxDistance(bounds.get(i), bounds.get(j), pw, ph) > threshold)
                    continue;
                if (boundaryClose(polygons.get(i), polygons.get(j), threshold)) {
                    hasNeighbor[i] = true;
                    hasNeighbor[j] = true;
                }
            }
        }

        for (int i = n - 1; i >= 0; i--) {
            if (hasNeighbor[i]) {
                rm.select(i);
                rm.runCommand("Delete");
            }
        }

       // IJ.showMessage("Done", "Remaining isolated ROIs: " + rm.getCount());
    }

    private double bboxDistance(Rectangle r1, Rectangle r2, double pw, double ph) {
        double dx = 0, dy = 0;
        if (r1.x > r2.x + r2.width)
            dx = r1.x - (r2.x + r2.width);
        else if (r2.x > r1.x + r1.width)
            dx = r2.x - (r1.x + r1.width);
        if (r1.y > r2.y + r2.height)
            dy = r1.y - (r2.y + r2.height);
        else if (r2.y > r1.y + r1.height)
            dy = r2.y - (r1.y + r1.height);
        return Math.sqrt(dx * dx * pw * pw + dy * dy * ph * ph);
    }

    private boolean boundaryClose(ArrayList<Point> p1, ArrayList<Point> p2, double threshMicrons) {
        int threshInt = (int) Math.round(threshMicrons * 1000);
        int threshSq = threshInt * threshInt;
        for (Point pt1 : p1) {
            for (Point pt2 : p2) {
                int dx = pt1.x - pt2.x;
                int dy = pt1.y - pt2.y;
                if ((dx * dx + dy * dy) <= threshSq)
                    return true;
            }
        }
        return false;
    }
}
