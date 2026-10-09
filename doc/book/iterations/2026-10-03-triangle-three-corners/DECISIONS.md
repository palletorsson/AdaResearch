# Three corners, then a face

The user approved continuing one lesson at a time after correcting the Trace-to-Grid handoff. Triangle continues that same source record. It copies three sampled positions without flattening, fitting, snapping or silently extracting a silhouette. The saved record remains available for another interpretation.

Select indices 0, n/3 and 2*(n/3) using integer division. This simple rule makes its limitation visible: index intervals are not equal spatial intervals, and three samples need not describe the whole gesture or span an area. The learner can move the selected corners. Fewer than three samples gives an honest empty state.

The new operation is an explicit face submission. Segment already supplies edge drawing; Point One established a mesh resource and its displaying node. ImmediateMesh now allows the learner to supply the vertices. The same three values drive edges and face each frame. A double-sided, unshaded material is supplied so light and back-face culling do not confound the first geometry experiment. This is a display choice, not thickness or collision.

The longer museum tutorial and its useful concave-fan failure remain in `commons/maps/Point_Triangle_Context/tutorial-museum.md`, with a frozen before copy here. The museum map, artifacts, final.md and critical track are unchanged. Normals, indexed meshes and general triangulation are deferred rather than smuggled into a first face.

The reference implementation in the local Godot 4.6 ImmediateMesh class XML uses these same three surface calls. The lesson has no dollar references, node lookups or scene-authored triangle. A local teaching contract declares new, reused and supplied concepts; the older numeric taxonomy remains unpromoted.
