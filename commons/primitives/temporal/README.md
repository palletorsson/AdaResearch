# Temporal Primitives

`animated_folding_past.tscn` provides an ambient temporal visualization: nested frames collapsing through depth.

## Files

- `animated_folding_past.tscn`
- `animated_folding_past.gd`

## Implementation Notes

- Uses `MultiMeshInstance3D` for efficient repeated frame rendering.
- Updates transform and alpha per frame for motion.
- Intended as atmosphere/context, not direct manipulation.

## Usage

Registry key: `folding_past`
