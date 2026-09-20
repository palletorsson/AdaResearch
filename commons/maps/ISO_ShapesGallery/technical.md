# Different fields, one extractor

The lesson binds `MarchingShapesGallery.gd`, retaining its existing four repertoires and four levels: exact=0, broken=-2, padded=4, fused=10. These are preset names, not guarantees of connectivity or usefulness. Six `TerrainGeneratorShapes` instances run `MarchingCubesShapes.glsl` through a local RenderingDevice each. The sampling domain is 120 field units across and 64 samples per axis; rendering scale .09 and spacing 5.5m make the six fields readable in the court.

REPERTOIRE selects household, laboratory, abstract, survey. LEVEL changes the global extraction level for the entire composition. HOLD duplicates the middle-column meshes (slots 1 and 4: Chair and Cup in household), with materials, independent of generator lifetime. Held specimens are visual comparisons without colliders. RESET preserves them; CLEAR removes them. The opt-in `preserve_empty_result` flag intercepts a verified zero raw GPU triangle counter and keeps an empty ArrayMesh, with no collision. Other placements keep their existing fallback behavior. A safety-aborted oversized result does not qualify as empty. The desk reports a failed GPU extraction instead of treating the generator's fallback spheres as successful shape results.

In the shader the chair unions a seat, back and four rounded-box legs. The cup subtracts an inner capped cylinder from an outer cylinder and unions a torus handle. Union is min(a,b); subtraction is max(-inside,outside). Compound fields should not be assumed to preserve an exact distance everywhere. Changing level is not a local wall-thickness edit.

Sources: res://algorithms/proceduralgeneration/isosurfaces/marchingcave/Scripts/MarchingShapesGallery.gd; Scripts/TerrainGeneratorShapes.gd; Scripts/TerrainGeneratorBase.gd; Compute/MarchingCubesShapes.glsl. Desk: res://commons/artifacts/timing_machines/iso_shapes_workshop.gd.

The original torus sculpture, VR sculptor and gyroid remain secondary specimens behind the front court. Their separate interactions and headset performance require later review.

