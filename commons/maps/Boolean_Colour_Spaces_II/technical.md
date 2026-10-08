# Construction

Scene: commons/artifacts/boolean_colour_chamber/more_spaces.tscn (F6 desktop study). Modes ring, cross, fold are implemented by the shared boolean_colour_chamber artifact. Configuration uses #mode and #surface. All floors have their top at local y=0; explicit placement height 0 avoids automatic grounding.

Ring: 13 x 7 x 13 stock minus a CSG torus with inner/outer radii 1.45/5.55, centred at y=1.35, plus entry/exit cylinders and an offset light shaft. The centre-line of its annular route has radius 3.5.

Cross: 13 x 8 x 13 stock minus a union of two orthogonal horizontal cylinders (radius 2.55), a raised diagonal cylinder and a vertical shaft. Upper cuts admit views/light without implying walkable upper storeys.

Fold: 13 x 8 x 13 stock minus three overlapping 5.5 x 6 x 6.4 box cutters, alternately turned 10 degrees about Y and 22 degrees about Z, plus an inclined roof slit.

Evidence is recorded in doc/book/iterations/2026-09-24-boolean-more-spaces/. The isolated probe uses a 1.8 m / 0.30 m radius capsule and standard pointer events. Museum-loader, tracked-headset and Quest performance verification are separate.
