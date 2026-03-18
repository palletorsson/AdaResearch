# Necklace Anchor

Pendant and necklace display on a stand representing an identity anchor point. A vertical metallic stand holds a torus necklace ring with a glowing pendant gem that slowly rotates.

## How It Works

The artifact builds a vertical cylinder stand with a base plate, a torus mesh tilted to hang naturally at the top, and a glowing sphere pendant connected by a thin chain cylinder. During `_process`, the pendant rotates slowly around the Y axis. The materials use metallic gold for the torus and chain, with an emissive cyan gem for the pendant.

## Features

- Metallic gold torus necklace ring tilted for natural display
- Glowing emissive cyan pendant gem with slow rotation animation
- Thin chain connecting torus to pendant
- Tapered stand with weighted base plate
- "Identity Anchor" label above the display
- Scalable via `apply_grid_config` with a `scale` parameter

## Files

- `necklace_anchor.gd` -- Procedural necklace stand builder with animated pendant
- `necklace_anchor.tscn` -- Scene file
