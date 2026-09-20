# Openings, enclosure and route

The hall preserves the original `TerrainGeneratorUnifiedPortals`, `TerrainGenerator` and `QueerMarchingCave` scenes. The `iso_cave_workshop` binds the first two through their existing `apply_grid_config` methods. PLUMB cycles `bedded / overturned / weightless / steep` on `mc_inside_cave`; OCTAVES cycles `1 / 2 / 3 / 6`. PORTALS cycles `1 / 3 / 7 / 16`; BURIAL cycles `straddling / sunken / standing / floating` on `mc_portal_landscape`. HOLD keeps a non-colliding snapshot of the enclosing cave; RESET returns both primary works to their shipped values. The fixed desk readout states that a sampled opening is not a clearance proof.

The original 16×12 structure and all six inherited map tokens are preserved at `(3,28)` in a 30×44 open-roof court. `mc_inside_cave` and `mc_portal_landscape` are primary because the book compares their two readings of a boundary. `queer_marching_cave`, `rhizome_cave_demo` and `raymarched_metaballs` remain secondary collection works. The desk is decoration.

The portal field exposes `num_portals` and `burial`; the cave field exposes `plumb` and `octaves`. These are real generator parameters, not visual toggles. A rebuild replaces the generated surface and collision owned by the existing script. The held copy has no collision so it cannot create a hidden wall in the route.

The route question remains deliberately bounded. Mesh crossings are not treated as a connectivity graph, and connectivity is not treated as body clearance. Human headset reach, comfort and Quest performance remain unverified.
