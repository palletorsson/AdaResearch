# Coordinates — implementation reference

Point_Coordinates was separated from Point_One on 29 September 2026. Its layout preserves the old wider room, shifting all retained coordinates eight source cells towards the entrance. Source cells are not museum world coordinates.

The first artifact is `point_held` at (7,2). `point_condition.gd` builds its label and instantiates the production `interactive_point_origin.tscn`, an XR Tools pickable. The black sphere keeps `coordinate_id = point_one_main`; this legacy identifier intentionally remains stable across the split.

`CoordinateSystem3M` is at (4,12), with `adopt_external_point:1`, `external_point_id:point_one_main` and `floating_point:0`. WORLD at (2,9) and LOCAL at (2,11) use the same `readout_channel`. The separate force point retains its different identity. The frame's origin sign is suppressed; the actual Point Zero origin remains in the preceding arrival hall.

The L-shaped basin is the union of [4,7,1,6] and [4,12,6,1]: eleven cells, depth one metre, glass collision at deck height, no fire. The coordinate artifact's +1 metre placement offset compensates for the basin floor. Do not raise its frame above the museum floor.

The hall opts into opaque, shaded pink/grey/black axes and matching projection markers. Axis length is 3.4 local units (5.1 m of shaft at the unchanged display scale 1.5), with radius 0.08 local units (24 cm diameter in the hall). Enlarging the drawing does not rescale LOCAL coordinates. The arms keep their existing placement along the basin; the Z arm points towards negative Z and its end label says −Z. The colours identify X/Y/Z independently of sign. Solidity here means opaque geometry, not a new collision barrier across the floor. Other placements retain the default RGB palette and transparency.

The target is at (6,10). Its existing radius is 0.45 metres and it rearms after departure. The target accepts eligible point-group members; the cards select the named primary point. The manuscript distinguishes these functions without teaching all their implementation here.

The separate coordinate download inherits the existing Day Zero base and prepares two sphere nodes with `points.gd`. It has no XR add-on. In-project pickup practice uses Ada's already configured player. Point_Lines is the next map and the first tutorial to calculate distance.
