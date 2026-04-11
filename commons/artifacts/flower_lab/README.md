# Flower Lab

Interactive VR laboratory for exploring procedural flower morphology. Wraps the BotanicalFlower generator with VR slider controls, letting learners manipulate parameters in real time and observe how each one shapes the flower's anatomy.

## How It Works

The lab instantiates a BotanicalFlower scene and creates a VR control panel with seven horizontal sliders arranged in two rows, plus buttons for symmetry toggle, randomize, and save preset. Each slider maps to a flower parameter (petal count, length, width, curve, stem height, color hue, leaf count) via normalized value callbacks. Moving a slider rebuilds the flower in real time. Educational notes in the source explain the biological significance of each parameter.

## Features

- Seven VR sliders controlling petal count, length, width, curve, stem height, color hue, and leaf count
- Symmetry toggle button switching between radial and bilateral symmetry
- Randomize button that samples all parameters for discovery of unexpected flower forms
- Save preset button that writes current config to timestamped JSON in user://
- Real-time flower rebuild on every parameter change
- Info label displaying current parameter values
- Dark backing panel for visual grouping of controls
- Grid system integration via `apply_grid_config` with support for named species presets

## Files

- `flower_lab.gd` -- VR flower laboratory with slider controls and educational parameter ranges
- `flower_lab.tscn` -- Scene file
