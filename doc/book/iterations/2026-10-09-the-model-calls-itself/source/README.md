# The Model Calls Itself

**Preview only. No museum map or route placement.**

Open `res://commons/artifacts/model_overflow/preview.tscn` in the AdaResearch project and run F6. This uses the existing desktop player, an authored fixed courtyard, and native dials/rectangular buttons. The artifact itself owns no environment or camera.

## Three distinct mechanisms

- **CALLS:** an explicit list models pending recursive call frames. A child inherits a small turn, translation and scale from its parent. There is no base-case return in the simulated procedure. Capacity is checked *before* appending. On refusal, admitted geometry stays visible; the next, unadmitted bay is shown pink. No GDScript/native stack is exhausted.
- **LEAK:** sixteen intended sibling transforms should start from the same root. The fault saves the current transform and omits the restore, making every next sibling inherit the earlier transforms. The same explicit capacity check bounds saved frames. SOURCE shows the corrected sixteen siblings.
- **WRAP:** an indexed twelve-sided tower has 228 stored positions. A second model writes starting at logical address 228, deliberately wrapping modulo 228 onto the first model's slots. Existing triangle indices remain fixed. Seven positions are overwritten per step, up to 224. Intermediate faces bridge old and new positions. This is address-aliasing simulation, not actual out-of-bounds memory access or a call-stack overflow. The mesh still has 432 triangles.

The first two studies reuse `architecture_spine.gd.build_bay()` without mesh subdivision. The fixed miniature retains that source. WRAP adds its own simpler indexed skin so address reuse is legible. The source records remain immutable and RESET copies them again.

## Controls

Choose SOURCE / CALLS / LEAK / WRAP. STEP advances; PLAY / HOLD advances every 0.35 seconds; STEPS scrubs 0–32. CAPACITY sets 4–24 pending frames in CALLS and LEAK only. Changing it reconstructs the current requested step with the new capacity. RESET clears the current process; SOURCE shows the corrected sibling arrangement. Keys 1–4 choose modes, Space toggles play, Enter steps, R resets, left/right change steps, up/down change capacity. Models have no colliders; the fixed courtyard supplies support.

## Reproduce verification

`python tools/test_model_overflow.py`

Runs Godot 4.6 with rendering and real desktop pointer actions, checks saved/admitted frames, limits before append, deterministic transforms, in-bounds addresses, immutable source, reset, native dial values, play/hold, F6 environment, and exports exact geometry as GLB. It does not validate headset interaction, Quest performance, structural stability or a museum placement. Existing project UID/Jolt/shutdown warnings may remain in the retained log.
