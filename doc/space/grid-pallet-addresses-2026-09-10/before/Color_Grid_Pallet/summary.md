# Color_Grid_Pallet - Map Summary

## Overview
Color_Grid_Pallet introduces systematic color application through a grid colorizer interface. Players paint the floor grid cell by cell, experiencing color as addressable data - each tile a pixel, each color choice recorded at specific coordinates. The spectrum forest demonstrates color variation in three-dimensional space.

## Spatial Layout
- **Dimensions**: 11×13 illumination grid
- **Architecture**: Open workspace with corner lighting frame
- **Height**: Single level with elevated transport cube access
- **Structure**: Laboratory layout for color experimentation

## Key Elements

### Interactables
- **gridcolorizer** (0,0) - Primary interface for coloring grid tiles
- **spectrum_forest** (5,6) - 3D color variation display
- **dark_sphere** (5,5) - Ambient atmosphere dome

### Utilities
- **Extra lights** (el) - Corner workspace illumination (×4)
- **Next cube** (n) - Progression trigger at (5,1)
- **Transport cube** (tc:5:y) - Vertical access at (7,3)
- **Spawn point** (s) - Player start position
- **Teleporter** (t) - Exit at (9,11)

## Atmosphere
- **Lighting**: Cool ambient with warm directional accents
- **Background**: Sky blue
- **Mood**: Systematic, experimental, constructive

## Learning Sequence
1. Player enters the colorizer lab
2. Approaches gridcolorizer console
3. Selects colors and applies to grid tiles
4. Observes color patterns emerging on floor
5. Explores spectrum_forest for 3D color variation
6. Uses transport cube to gain elevated perspective
7. Activates next cube to proceed
8. Exits via teleporter

## Design Intent
The map systematizes color through **spatial indexing**. Every color exists at an address - a grid coordinate. This mirrors how digital images work: pixels at (x, y) positions, each storing RGB values. The player becomes both artist and data entry operator, painting by coordinates.

## Connection to Sequence
- **Position in color sequence**: 2/6
- **Follows**: Color_Nails (personal color selection)
- **Establishes**: Color as addressable data, grid as canvas
- **Leads to**: Spectral color (rainbow)
