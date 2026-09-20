# A periodic field and a bounded clearance test

Primary mc_torus_sculpture is a fixed formula reference; primary GyroidDemo is the live periodic field. Both use their existing GPU compute shaders. The lesson resolves child TerrainGeneratorTorus/Gyroid nodes and exposes existing intrusion/period axes. Torus startup work is completed before stopping its redundant process loop. Ordinary scene defaults elsewhere are unchanged.

Gyroid: domain20 field units, scene scale0.5, iso_level1, 64 samples per axis. PERIOD order sheet/pair/lattice/weave corresponds to multipliers0.5/1/2/4. INTRUSION order formula/eroded/drifting/melted uses warp/erosion/modulation triples (0,0,0), (0,.5,0), (0,.5,1), (4,.5,1). The expression dot(sin(gp),cos(gp.yzx)) is a trigonometric gyroid approximation evaluated at the selected level, not an exact minimal-surface certificate. PERIOD scales only the gyroid argument, not all noise arguments. RESET restores formula/sheet and the smallest probe, preserving HOLD.

HOLD makes an independent deep mesh/material copy 18m behind the live specimen. It has no collision. Meshes are grounded after regeneration; the held geometry does not follow later changes. All three inherited artifact instances and historical structure cells remain.

PROBE uses a fixed world-horizontal12m segment through the live domain centreline, capsule centre1m above the hall floor, height1.7m, radii .2/.35/.6m. It checks initial overlap, then PhysicsDirectSpaceState3D.cast_motion against the gyroid's actual collision shapes on a dedicated query layer. The readout reports the safe fraction times12. Empty or omitted collision shapes make the test unavailable. This is not a pathfinder, head tracking test, step-height test or full CharacterBody3D motion simulation. Base extraction skips trimesh collision above30000 triangles; a rendered mesh alone cannot certify clearance.

Sources: res://algorithms/proceduralgeneration/isosurfaces/marchingcave/Scripts/TerrainGeneratorGyroid.gd and TerrainGeneratorTorus.gd; Compute/MarchingGyroid.glsl and MarchingCubesTorus.glsl. Lesson: res://commons/artifacts/timing_machines/iso_gyroid_workshop.gd.

