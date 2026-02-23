# Color_Flashlight - Map Summary

## Overview
Color_Flashlight closes the active color sequence by reducing color to its relational minimum: beam, surface, and observer. After Color_Walls showed continuous gradients as a field, this map narrows attention to controlled light sources. Four flashlights (red, green, blue, white) illuminate a neutral canvas and make additive color logic directly visible.

## Spatial Layout
- **Dimensions**: 11x13 declared grid (12 populated rows in current map data)
- **Architecture**: Open laboratory plate with one raised interaction pedestal and a late-map drop/exit point
- **Height**: Mostly level 1 floor, with one level 2 block at the flashlight station and one level 0 void near exit
- **Structure**: Centralized demo stage rather than corridor progression

## Key Elements

### Interactables
- **flashlight_demo:180** (5,6) - Main additive-light exhibit with red/green/blue/white flashlights and a canvas target
- **dark_sphere** (6,5) - Black enclosure dome that increases contrast and keeps the light experiment legible

### Utilities
- **Teleporter** (`t`) at (11,6) - Sequence exit back to the next flow state

## Atmosphere
- **Lighting**: Low ambient environment plus directional light in map settings; demo scene itself also applies a dark `WorldEnvironment`
- **Background**: Dark sky tone (`[0.1, 0.1, 0.15]`)
- **Mood**: Focused, studio-like, perceptual testing chamber

## Learning Sequence
1. Player enters a minimal open floor with the flashlight demo on a raised center tile.
2. Player approaches the demo and observes separate red, green, blue, and white beams.
3. Player compares beam behavior on the canvas under low ambient light.
4. Player notices additive mixing patterns where colored light overlaps.
5. Player uses the dark_sphere zone to understand why color needs controlled context.
6. Player exits through the teleporter after the final color-sequence comparison.

## Design Intent
This map shifts from "color as object" to "color as condition." Color_Flashlight does not ask the player to collect or paint. It asks them to inspect how illumination itself structures perception. The single pedestal and sparse utility layout remove distraction so the core relation stays visible: object appearance depends on incident light.

Placing the teleporter near a floor void creates a small threshold gesture at sequence end. The player leaves after performing comparison, not accumulation.

## Connection to Sequence
- **Position in color sequence**: 7/7 (active sequence endpoint)
- **Follows**: Color_Walls (continuous gradient field)
- **Establishes**: Controlled additive light as final perceptual check
- **Returns to**: Lab (`lab_map` progression after color completion)
