
# ARMeasure

This project is a basic example of measuring real world objects using *ARKit*.

All the code is fully commented so the apps functionality should be clear to everyone.

**Requirements:**

This project was written in Swift 4, and at the time of writing uses Xcode 9.4 Beta.
The project is setup for iPhone, and in Portait Orientation.

**Core Functionality:**

This project allows you to measure objects using *touchGestures*. 

Each time the screen is tapped, a *markerNode* is placed, and the distances between these are calculated automatically using `GLKit Math Utilities`.

When there are more than 3 nodes on the screen, the angle between these is also calculated.

The `SettingsMenu` allows the user to toggle whether 3D Distance & Angle Labels should be shown, and whether markerNode placement should be done using either `featurePoints` or `ARPlaneAnchors`.

For more accurate results it is recommended the `PlaneDetection` be set to on.

Results are automatically displayed in:
(a) Metres,
(b) Centimetres,
(c) Millimetres,
(d) Feet,
(e) Inches.

There is also a `join` function which can be used when more than 3 markers have placed.

Essentially this creates a shape, by joining the first and last `markerNodes` which have been placed.
