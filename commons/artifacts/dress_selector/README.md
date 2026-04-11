# Dress Selector

Outfit selection interface displaying three mannequin forms, each with a different color and a selection button. Provides a visual chooser for Classic, Wicked, and Custom outfit options.

## How It Works

The display builds three mannequin stands procedurally using capsule meshes for torsos, sphere meshes for heads, and cylinder meshes for stand poles and base plates. Each mannequin is color-coded to its outfit and has a glowing selection button sphere positioned in front. A Label3D identifies each option, and a title label floats above the entire display.

## Features

- Three mannequin display forms with distinct outfit colors (Classic blue, Wicked purple, Custom teal)
- Glowing emissive selection buttons in front of each mannequin
- Metallic stand poles with base plates
- Labels identifying each outfit option
- Scalable via `apply_grid_config` with a `scale` parameter

## Files

- `dress_selector.gd` -- Procedural mannequin display builder
- `dress_selector.tscn` -- Scene file
