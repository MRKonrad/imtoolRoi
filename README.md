# imtoolRoi(data, outputVariableName)
Matlab's imtool extended to 3rd dimension and with some ROI functionalities.
Features:
* clipboard for ROIs working between a few opened imtoolRois

# TODO
* contours 0-9
* disable cropping
* interpolation - pick number of points
* add 4th dim
* what is the best way of returning on figure close?
* undo (same way as clipboard)
* text not on the image. Maybe in a footer?
* now I have points stored in cells (z,t) with 2d points (x,t). How abour storing a point as a vector like [x,y,z,t]?