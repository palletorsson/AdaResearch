# Arrays — reviewed museum transfer, batch 13

Codex transferred Tutorial_Tiling_Walls. Claude Opus supplied Tutorial_Disco as
a two-file handoff; Codex checked all IDs, source configs, build order, geometry
and handler bodies before merging. Six independently editable installations
use the same rooms/layout files in desktop and VR.

Walls retains the six comparisons, rule desk, 25-sample chart and hinged wall
with its occupied-landing guard. Disco retains all four originals: monochrome
controls, 90s-house sequencer, phase film and the 12 x 12 floor of 0.8 m tiles.
The film moves one metre away from shaft A; its source orientation is retained.

The isolated trial uses eight-metre storeys for the full 6.3 m chart. Its signs
stand at [16,8], outside the exhibits. The museum's continuous enclosure is not
imported: integrating the turning sheet into a complete inside/outside boundary
is a curation decision. The main tower is unchanged.

Claude correctly identified that StandaloneDiscoSetup has an unscripted root.
Void now forwards this artifact's config to its original DiscoFloor child
before construction. Applying it afterwards caused a deferred replacement
collider to lose its expected name; native walking exposed that mismatch.
The floor also uses the existing Void tiling trial's unshaded, non-emissive
receiver finish: constant white emission had washed black tiles to pale grey.
Values, meshes, sizes, musical pulses and original scripts are preserved.
The original scene and script identities remain intact. JSON order keeps the
sequencer before the floor so the original bridge finds it on construction.
The handoff's written SPEED order is inaccurate: the source cycles
0.5 -> 1.0 -> 0.25 -> 0.5 seconds; the source behavior is preserved.

Evidence receipts report source preservation, real mouse and synthetic tracked
XR input, physical collision, clock/score behavior, floor residency, retry and
editor round trips. API-only checks are explicitly labelled. Web models are
arrangement snapshots; native Godot runs the original interactions and shaders.
Physical headset testing, curation and original text revision remain pending.
