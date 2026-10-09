# Reveal the construction

The user's correction: the purpose is not to put a flat mathematical diagram in a 3D scene. Film a procedural object revealing the operations and elements that constitute it. A structure can be read through profiles, rotation, extrusion, scale, repetition and composition, at different levels of explanation.

This prototype uses the existing `resolution_totem.gd` without editing it. That generator supplies five profiles and nine independently generated sections. We instantiate it privately, read the resulting mesh, extract a radial profile, reveal angular rings, and reveal the actual triangle data. The complete reveal preserves the original vertex data exactly. Re-uploading normals introduces a maximum difference of approximately 0.000128 due to mesh packing, within the tested 0.001 tolerance.

The filmed order is an explanation of the construction, not a literal instruction-by-instruction trace of CPU execution. Profile and revolution are derived from this model's mesh and known construction. The six-copy arrangement and two beams are a new composition for this study. They are not a reconstruction of the architectural photograph, nor a claim about how that building was historically made. No extrusion lesson has been implemented yet.

## Six moments

1. The chosen radial profile appears beside its axis.
2. Angular steps reveal the rings sampled around that axis.
3. Triangles connect the generated positions into a surface.
4. The nine component surfaces separate and return.
5. The same mesh is repeated at six positions, with a widening camera.
6. Plinths and beams complete a small colonnade.

Pause holds the construction and automatic camera motion. Step advances to the next explanatory moment. Next Form repeats the process using the next existing profile. Left/right arrow keys in the desktop preview orbit the private camera even while paused. The original line-and-trace scene remains available.

## Looking starts the film

The shared monitor now advances only while the viewer looks at the front of its screen within 14 metres, after a 0.18-second dwell. A ray from the active outer camera intersects the physical screen rectangle and checks solid-world occlusion. The private filming camera cannot activate its own monitor. The same check uses an XRCamera3D's head direction in VR; this is not eye tracking.

Looking away pauses the timeline immediately and preserves the last rendered frame. Returning resumes that moment without skipping elapsed real time. Explicit Pause remains paused when the viewer returns. Controls can request one refreshed frame while paused, and unwatched feeds stop rendering. The collision mask and dwell are exported settings.

In the desktop preview, hold the right mouse button and drag to look away. Home looks back at the monitor. The arrows still orbit the private filmed scene. `python tools/run_concept_monitor_gaze.py` checks 24 cases, including rendered texture retention, occlusion, front/back/range, manual pause, transformed placement and a synthetic XR camera. Physical headset testing remains open. These changes apply to the shared prototype monitor, not every existing CCTV in the museum.

## What matters for the museum and text

Seeing a completed object gives the learner a result. Seeing its operations exposes choices: which profile, which angular resolution, how many copies, how they are placed. The same animation can provide a monitor feed and book images. The reflective text can ask what these choices privilege or omit; it does not have to repeat the implementation.

For a facade, the later study might reveal a window surround swept from a section, one bay repeated, a central exception and a mirrored partner. Sculptural detail would need its own process and provenance. An explanation must identify its level of reduction rather than treat every visible difference as the output of one universal rule.

## Files and verification

- Live preview: `commons/artifacts/concept_monitor/construction_preview.tscn` (F6).
- Filmed scene: `commons/artifacts/concept_monitor/construction_stage.gd`.
- Source generator: `commons/artifacts/resolution_colonnade/resolution_totem.gd` (unchanged).
- Runtime checks and captures: `python tools/run_construction_monitor.py`.
- `report.json` records the geometry and control checks. Headset performance and hand interaction are not tested.
- `protected-sources.json` verifies the source generator, original gallery and Point_Trace map remained unchanged.

No museum map placement, tutorial or manuscript was edited. The monitor housing gained configurable button captions and the desktop preview gained a configurable monitor scene and orbit keys. The new construction scene is a separate prototype.
