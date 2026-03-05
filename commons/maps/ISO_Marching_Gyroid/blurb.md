# Isosurfaces: Marching Cubes

A cube has eight corners. Each corner is inside or outside. Eight binary states: 256 configurations. For each configuration, a lookup table says where the surface cuts through. March the cube through a scalar field, one voxel at a time. Geometry appears at the threshold.

The gyroid is the test case — a triply periodic minimal surface, zero mean curvature everywhere, no straight lines, no planes of symmetry. sin(x)cos(y) + sin(y)cos(z) + sin(z)cos(x) = 0. The equation is compact. The surface it describes never self-intersects, never ends, fills space with tunnels that connect everything to everything.

Sculpt the gyroid in VR. Watch marching cubes extract form from pure function. The algorithm doesn't know what shape it's finding — it only knows where the field crosses zero. The boundary decides itself.