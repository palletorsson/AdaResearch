# Color_Rainbow - Map Summary

## Overview
Color_Rainbow transforms the visible spectrum into traversable architecture. A narrow corridor lined with rainbow emitters creates an immersive walk through cycling colors. The player experiences the spectrum temporally - not as a static image but as animated light surrounding their path.

## Spatial Layout
- **Dimensions**: 7×17 suspended corridor
- **Architecture**: Narrow walkway with void on either side
- **Height**: Single elevated level
- **Structure**: Linear processional path

## Key Elements

### Interactables
- **rainbow:0:0.5:0.1** (×10) - Animated spectrum emitters along corridor
- **pick_up_cube** - Interaction reset point mid-path
- **dark_sphere** - Ambient atmosphere at entrance

### Utilities
- **Spawn point** (s) - Player start at entrance
- **Extra light** (el) - Mid-corridor illumination
- **Walkway point** (wp) - Navigation marker
- **Teleporter** (t) - Exit to next map
- **Score point** (sp) - Completion marker

## Atmosphere
- **Lighting**: Cool ambient with emissive rainbow elements
- **Background**: Sky blue (0.2, 0.3, 0.7)
- **Palette**: rainbow_gradient with custom emission
- **Mood**: Immersive, meditative, chromatic

## Learning Sequence
1. Player enters at corridor start
2. Observes rainbow emitters activating
3. Walks through cycling color tunnel
4. Passes through spectrum zones (red → violet)
5. Collects pickup cube at midpoint
6. Continues through second half of spectrum
7. Reaches end platform
8. Exits via teleporter

## Design Intent
The map makes the **spectrum navigable**. Instead of viewing a rainbow from outside, you walk through it. This shifts color from object to environment, from seen to inhabited. The cycling animation shows that the spectrum is not static but a continuous process of wavelength variation.

## Connection to Sequence
- **Position in color sequence**: 3/6
- **Follows**: Color_Grid_Pallet (systematic color)
- **Establishes**: Spectrum as space, color as environment
- **Leads to**: Color interaction and mixing
