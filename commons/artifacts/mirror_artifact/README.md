# Mirror Artifact

Reflective mirror panel that shows VR players what their hands look like. A large vertical mirror surface with a decorative wooden frame and label.

## How It Works

The artifact builds a vertical PlaneMesh with a fully metallic, zero-roughness StandardMaterial3D to create a reflective surface. A decorative frame made of four BoxMesh edges surrounds the mirror in a dark wood tone. A Label3D reading "Mirror" is placed above the frame.

## Features

- Highly reflective metallic surface for VR hand visualization
- Decorative dark wood-toned frame with four edge pieces
- 1.5m x 2.0m mirror surface positioned at standing height
- Scalable via `apply_grid_config` with a `scale` parameter

## Files

- `mirror_artifact.gd` -- Procedural mirror and frame builder
- `mirror_artifact.tscn` -- Scene file
