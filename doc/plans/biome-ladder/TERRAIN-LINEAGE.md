# Terrain lineage — the floor learns too

Palle's direction, 2026-10-13. Agreed design; playable stages now reach Tiling.

Every sequence adds a new operation to the same world. The changes must be felt through walking, cover, aiming and contact. The sphere/catalyst, useful shelters, learned operations and colour remain available as the ground develops. Cumulative capacity does not require every behaviour to run simultaneously.

## Agreed ground progression

| Sequence | Ground and bodily consequence | Status |
|---|---|---|
| Primitives | White floor with thin black outlines; static forms provide shelter. | Implemented |
| Transformation | White outlined tiles shrink by ×0.8 and turn +22.5° per catalyst hit; solid backing stays walkable. Surrounding forms translate, rotate and scale; fixed refuge remains. | Implemented |
| Arrays | Black/white tiled grid adds spacing and repetition; shots still shrink and turn the tile they hit. | Implemented |
| Colour | Player shots shrink, turn and recolour the same tile. Skull balls recolour the tile they hit. Untouched disco tiles keep cycling; marks persist until RESET or a fresh START. | B12 implemented |
| Tiling | Catalyst hits repeat their scale, turn and colour at the same address in every 2 × 2 group across the floor. 18 copies per address. Solid backing keeps the gaps walkable. | B15 implemented; TILING.md |
| Change | A sustained action accumulates change in an opening or support. | Proposed |
| Forces | Movable forms and deflected balls let the player rearrange shelter. | Proposed |
| Formfinding | Adjust supports; a tensioned surface settles into a usable shape. | Proposed |
| Waves | Walk on the sine-shaped floor from the museum sequence. Periodic relief changes sightlines and the route underfoot. | Agreed direction; not built in ladder |
| Randomness | Sample varied heights to make a rougher floor that is a little harder to traverse. Keep a viable crossing; the floor is stable during an attempt. | Agreed direction; not built in ladder |
| Noise | Neighbouring heights become correlated, making the floor smoother again while retaining variation. Compare at a similar height range and footprint. | Agreed direction; not built in ladder |

Noise does not inherently guarantee easy terrain: amplitude and spatial frequency still matter. The intended contrast here is an independently varied surface followed by a deliberately more continuous surface. Randomness is not implemented by resampling every frame beneath the player.

## Reuse the museum's work

- `commons/maps/WaveFunctions_Sine_Space/map_data.json` describes the existing broad sine floor, including colliding relief and balls that roll across it.
- `algorithms/wavefunctions/sine_space/SineSpace.gd` has an opt-in `floor_mode = "walk"`, which uses `commons/context/walkgrids/sine_space.tscn` and its matching mesh/collider. Inspect that branch before adapting the footprint; the default sphere-field branch is not the walkable floor.
- `commons/maps/sequences/randomness.json` places the comparison of independent heights and correlated neighbours in `Random_Space_Geometry`.
- `commons/maps/sequences/noise.json` includes terrain and route comparisons in `Noise_Space_10`. Reuse the authored encounter's useful construction after inspecting it.

These are source connections, not claims that the later biomes are already integrated. Before expanding route.gd, verify actual sequence endings and entry controls rather than using old Lab-order metadata.

## Acceptance for each terrain step

1. Visible relief and collision agree; objects rest on the actual surface.
2. The change can be felt while walking and read from standing height.
3. The player can still reach refuge, controls and the next passage.
4. Colour marks address the actual receiving surface; cover impacts do not paint through it.
5. Retain a repeatable seed for Randomness/Noise comparisons and debugging.
6. Show a native screenshot, run collision/route checks, then test movement in the headset.

First implement and review one change at a time. Tiling now carries forward Colour's retained mark and Transformation's scale and turn. Next sequence: Change; its specific play addition remains a proposal. Tutorial and final.md are outside this biome pass.
