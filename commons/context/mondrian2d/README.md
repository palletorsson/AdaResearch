# Mondrian 2D

Procedural Mondrian-style grid art generator, available in 2D and grabbable 3D forms.

## Key Files
- `mondrian_2d.gd` — Extends Node2D, class_name `mondrian_2d`; generates Mondrian-style patterns with red/yellow/blue/white/black; auto-changes pattern every 10s; viewport-aware canvas sizing at 60:55 aspect ratio
- `mondrian-3d-display.gd` — Extends Node3D; renders 2D Mondrian in 3D via SubViewport + Sprite3D with configurable aspect ratio and border frame
- `mondrian_2d_interaction.gd` — Animation sequencer with 6-step timer-based state machine for grid choreography
- `mondrian_scaler.gd` — Adjusts Sprite3D position; grab/drop stubs
- `mondrian_2d.tscn` — 3D scene with SubViewport rendering Mondrian, Camera3D, StaticBody3D with Sprite3D
- `grabable_mondrian.tscn` — Grabbable VR variant
