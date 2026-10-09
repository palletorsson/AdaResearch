# Enter an ongoing painting

Watch the automatic can before taking a colour from the two-row tray. Hold a can, aim its nozzle at the canvas and hold the trigger. On desktop, right-click carries or returns the can and holding the left mouse button sprays. Merely picking it up makes no marks.

Try the same colour close to the canvas, then farther away. The closer mark is tighter and denser; the farther mark spreads thinner. Keep the nozzle still to build coverage. Tilt it to stretch the footprint. Release the trigger while keeping the can in your hand, then let go to return it to its dock.

The nozzle ray must hit this canvas without a wall or another object in between. Its range is three metres. The actual surface transform and four-by-two-and-a-half-metre mesh determine UV coordinates and the projected footprint. No coarse grid snap is applied to spray input.

```gdscript
last_radius_m = 0.012 + distance * tan(deg_to_rad(7.0))
```

This rule makes distance visible as the size of a mark. The pigment budget spreads over that area; trigger pressure and time spent in place affect coverage. The current code approximates a spray cone, not aerosol physics.

The automatic painter supplies its position from two oscillations and deposits through the same surface method. Its prescribed motion continues beside your gesture. The canvas stores the resulting image, not a recoverable list of strokes.

Compare that changing surface with a fixed arrangement in the Albers gallery. Continue into Color_Walls with the difference between a colour value, its neighbours and its receiving surface in mind.
