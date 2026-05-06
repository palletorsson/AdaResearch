# Noise Voxel — Summary

Noise_Voxel is the fourth map in the Noise sequence. It converts continuous noise into discrete solid-or-void geometry. The space is a cubic volume filled with a 3D noise field; a threshold slider at the entrance decides which cells become solid and which stay empty.

At low thresholds, most cells read as solid — a dense stone block with small scattered pockets. At high thresholds, most cells read as void, leaving floating stone islands suspended in the air. Between the extremes, caves open, overhangs form, shelves and bridges appear. The same noise field produces radically different topologies as the threshold changes, and the learner can scrub through the range live.

A smaller control set layers additional transformations. One slider selects the noise type; another adjusts the base frequency, so the learner can trade detail for feature size. A toggle switches between binary voxels and a softer surface that follows an iso-contour rather than a per-cell cut.

Within the sequence, Voxel is where noise starts behaving like architecture. The threshold operation is the minimum commitment a procedural world must make: somewhere there has to be a stone wall and somewhere there has to be air. Noise_6_Wall will next move the same kind of field to the GPU.
