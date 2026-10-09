# More Boolean spaces — 24 September 2026

## Built

Three additional production modes extend the original path, lens and shell, making six in total:

- **ring**: toroidal subtraction from a block preserves a central core. Two cylindrical openings meet the annular passage; an offset shaft admits light. Floor inlays curve around the core rather than pointing into it.
- **cross**: a union of two orthogonal horizontal cylinders, an upper diagonal cylinder and a vertical shaft is removed from the block. Main and side passages are supported; higher apertures are not presented as walking routes.
- **fold**: three alternating tilted boxes and an inclined slit are subtracted from a block. The surrounding faces incline while the floor stays level.

Each shares PEARL, AMBER, CHROME and CHALK finishes and the optional DRIFT control. The shader is unchanged. Geometry changes occur at construction time, not around an occupying player.

## Placement and play

`commons/artifacts/boolean_colour_chamber/more_spaces.tscn` is a separate F6 desktop study. The original study defaults remain path/lens/shell. The shared study script now accepts construction and finish arrays and an optional surrounding floor. The second study uses that floor so its lateral exits do not open onto a gap between platforms. It sits 2 cm below the room floors to avoid coplanar surfaces.

`Boolean_Colour_Spaces_II` places the new three artifacts in a separate development map. The original Boolean_Colour_Spaces receives one additional portal at grid (26,20), preserving its original return portal. The new map has a return to the first. This does not insert either study into the canonical Boolean sequence or replace an existing artifact.

## Evidence

The isolated runner uses the production generator, shader, scenes and the standard XR pointer-event class. It tests a 1.8 m tall capsule with radius 0.30 m:

- Both half-loops, together covering the full annular passage; the core blocks a direct ray shortcut.
- Main crossing passage in both directions, plus both side exits to the surrounding ground and back.
- Fold passage in both directions.
- Supported height throughout every tested route.
- Ray access to all finish buttons, actual pointer-event selection, unchanged mesh faces after finish selection, advancing drift and a held phase after stopping.

The runtime results and source hashes beside this file record the final test outcome. Native images show the same working artifact. This remains isolated desktop evidence; no tracked-headset, Quest performance or full museum-loader validation is claimed. The side-route checks establish the selected routes, not exhaustive clearance at every possible point.

The chapter and review use the same images. Existing production files touched by this extension were captured under `before/`; the initial three-space screenshots and runtime records remain as historical evidence rather than being overwritten.
