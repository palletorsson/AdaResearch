# Playtest fixes — active hands and projectile loading

The user reported a null `.new()` in `flying_skull.gd` during the skull attack and no hand ability in the biome or first-point area.

Changes:
- The skull now preloads its ball script. The reported failing expression was `load(head_ball.gd).new()` inside the attack. The ball creates its own glow using the existing `first_catalyst_glow.gdshader`, without loading the hand-ability script. The exact reason the user's running session returned null was not available in the retrieved logs.
- The hand ability now follows the **current XROrigin3D**. Previously it selected the first visible tracked origin, including the still-loaded menu rig, and could continue using that rig after a transition. It now rebinds when the current origin changes.
- Head Arena supplies the first hand ability for practice even on a fresh save. On exit it restores the earned state. Entering practice does not silently grant the persistent museum unlock.
- The museum unlock remains at the original sphere's field in **Point_Coordinates**. Activation and save/reload are verified there; no new field was added to Point_One.

Tests:
- Follow-up parser fix: removed the newly introduced `first_catalyst_glow.gd` dependency after the user's editor reported it missing. Both the hand ability and skull ball now construct their glow directly with the existing `.gdshader`. Fresh headless Godot run of `tools/probes/catalyst_load_check.gd`: **4/4 assertions, exit 0**, no parser/runtime errors. Checks hand sphere construction, skull firing, ball glow construction and hand firing. Output: `ada_run/encounter_pilot/Catalyst_Load_Check/stdout.log`.
- Actual Coordinates hall + controlled XRServer input: **49/49 assertions, exit 0**. Added two simultaneous visible tracked rigs at different locations; verified selection, switching and return. Headless run skips the six image assertions in the earlier rendered run.
- Actual menu/biome/three-hit combat/death/return: **26/26 assertions** starting without the earned ability. Skull fires after its warning; hand form works for practice; death returns to the biome; exit restores the unearned state. The known Windows/GLES shutdown crash still follows completion (3221225477), so this is not a clean full-process pass.
- No headset or APK run. Restart the game to load the new scripts. Tests use isolated save files; player progression was not reset.

Commands:
```
python -X utf8 tools/run_encounter_probe.py Point_Coordinates --sequence primitives --no-bridges --probe tools/probes/first_catalyst.gd --output-tag active-rig-fix
python -X utf8 tools/test_catalyst_first_abilities.py --combat --render
```

Files: `first_catalyst_ability.gd`, `head_ball.gd`, `flying_skull.gd`, `biome_arena.gd`, and the probes above. The temporary `first_catalyst_glow.gd` helper was removed. Earlier captures show the visual design; these fixes change runtime binding/loading and practice availability.
