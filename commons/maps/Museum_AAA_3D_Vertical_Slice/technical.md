# Technical contract

The map composes three existing dressing-room configs with `tools/compose_map_from_dressing_rooms.py`. No artifact geometry is resized to make the arrangement fit. The composition layer expands the floor plate around each authored footprint and joins the resulting rooms with a walkable route.

The negotiation is divided into three inspectable layers:

- artifact configs own footprint, support, interaction faces, and preferred clearance;
- the floor-plan composer owns placement, rotation, route connection, spawn, and exit;
- `museum_hall_shell` owns the reusable architectural envelope without replacing grid collision or navigation.

The map uses a 1.0 m tile, zero gutter, low-contrast floor material overrides, and `disable_biome: true`. Its 40 × 18 × 11 m bounds contain 180 structural tiles, one spawn, one exit, three featured artifacts, and one architectural shell. The shell is configured to 40 × 18 × 9 m with its optional sky plane disabled.

Desktop Godot loading and the multi-angle renderer both instantiate all four interactables. `tools/map_pathfinder.py check Museum_AAA_3D_Vertical_Slice` reports one map OK with zero issues. The current render is a white-box architectural acceptance pass; final materials, interior eye-level composition, and headset performance remain later gates.
