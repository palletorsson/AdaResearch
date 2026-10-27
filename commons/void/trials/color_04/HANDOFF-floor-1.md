# Color Paint / Codex transfer

Three source assemblies, unchanged scenes, scales, yaw, heights and configs.
A rigid source translation x = column - 9, z = row - 7 places the original
Albers gallery, automated spray canvas and dark sphere inside the standard
42 x 32 x 6 m tower. No additional props or geometry, no text revisions.

The gallery contains all 98 nested-square pictures with its original lights.
The painting station retains its automated spray and thirty grabbable spray
cans. Web export captures the geometry; its evolving GPU canvas runs in Godot.
Focused checks will verify actual desktop/XR pickup, trigger spraying, docking,
and autonomous painting. Gallery palette tuning is not a source interaction.

## Minimal Void input adapter

Native tests exposed the source spray cans on collision bitmask 3 (world layers
1 and 2). Both Void pickup systems select layer 3, whose bitmask is 4. The Void
mount now adds that pickable bit and stores it in the original XRTools drop
restore value. Source scenes and scripts are unchanged; actual mouse and tracked
XR grip, trigger spray, release and return-to-dock pass. This is input mounting,
not a new paint implementation. The original canvas emits a benign sizing
warning; native engine-error checks remain separate.
