# Point Trace - Map Summary

## Overview
Point Trace introduces duration and embodied gesture into geometry. Where previous maps dealt with discrete abstractions (points, measured lines, grids), the trace accumulates over time as a visible record of continuous movement. This map foregrounds gesture, repetition, and the residue of action - revealing geometry as a lived process rather than instantaneous calculation.

## Spatial Layout
- **Dimensions**: 7x14 grid (medium corridor)
- **Architecture**: Fragmented platform with raised ridge at row 4 (heights 1-2), tapering southern section
- **Entry**: Type "I" - immersive spawn into dark space
- **Atmosphere**: Very dark background [0.05, 0.05, 0.1] - intimate, focused

## Key Elements

### Primary Interactable
- **draw_dot** (3,4) - Continuous drawing tool that traces controller movement
  - Creates persistent visual marks in space
  - Records gesture as accumulating geometry
  - Sunken to height 0 (fillhole group) creating focused drawing pit

### Supporting Elements
- **grab_sphere_point_snap** (2,4) rotated 180 deg - Discrete point for comparison
- **dark_sphere** (3,3) - Encloses drawing area in intimate darkness
- **cube_scene markers** (3,5) and (4,5) height 0.9m - Spatial anchors in fillhole group

### Utilities
- **Teleporter** (5,10) - Exit to next map
- **Floating text** (3,13) - "the_trace" label
- **Annotation** (6,1) rotated -90 deg - Navigation marker

## Atmosphere
- **Background**: Very dark blue-black [0.05, 0.05, 0.1]
- **Lighting**: Warm directional light (1.2 energy) creating dramatic shadows
- **Mood**: Intimate, contemplative, focused on gesture
- **Visibility**: Hidden tiles except corners - space revealed through exploration

## Learning Sequence
1. Player spawns into dark, fragmented space
2. Encounters dark_sphere creating intimate enclosure
3. Discovers draw_dot tool in sunken area
4. Experiments with continuous gesture - moving controller traces visible line
5. Observes how trace accumulates over time - unlike discrete points
6. Compares grab_sphere_point_snap (discrete) with draw_dot (continuous)
7. Experiences duration and embodiment - the time of drawing matters
8. Exits having encountered geometry that remembers movement

## Design Intent
The **sunken drawing area** (fillhole group at height 0) creates a "pit" that focuses attention on the act of tracing. The very dark background makes the glowing trace lines highly visible. The fragmented platform architecture mirrors the concept - incomplete, accumulating, not predetermined.

Unlike Point_Line which reduces gesture to endpoints, Point_Trace preserves the entire path. The draw_dot tool resists discretization - it cannot be compressed to two coordinates and a distance. It must be experienced as duration.

## Key Contrast: Trace vs. Line

**Line** (Point_Line):
- Two endpoints
- Instant calculation
- No memory of path
- Pure abstraction

**Trace** (Point_Trace):
- Continuous accumulation
- Duration required
- Records entire gesture
- Embodied residue

## Connection to Sequence
- **Position in primitives sequence**: 3/11
- **Precedes**: Point_Line_Grid (coordinate systems)
- **Follows**: Point_Lines (grid systems)
- **Establishes**: Duration, gesture, resistance to complete discretization
- **Critical function**: Counterpoint to clean geometric logic - inserts time and body

