# First catalyst: sourcing and three-hit combat

User request: Coordinates indicator glows on sphere placement; saved ability leaves a small hand glow, intensifies near hands, forms/shoots balls. Skull fires balls and explodes after three hits. Player dies after three hits.

Implemented:
- `commons/artifacts/drag_point_target/first_catalyst_field.gd`: activated field strength 1.25 (formerly dimmed to 0.25), trigger instructions. Existing original-point gate and saved unlock retained.
- `commons/hazards/becoming_catalyst/first_catalyst_ability.gd`: empty tracked hands form at 24 cm, separate beyond 32 cm; glow 0.16–1.0 as hands approach. Either controller's `trigger_click` fires the existing form projectile, direction from that controller. 0.35 s cooldown, max eight tracked shots. Player body collision excluded. Existing capability autoload save and rig discovery retained.
- `commons/hazards/catalyst_counterpart/head_ball.gd`: swept sphere collision against architecture/desktop and XR player layers; one hit per projectile, lifetime 5 s.
- `flying_skull.gd`: opt-in `combat_enabled`, fires at locked warning endpoint, three actual projectile hits create fragment burst and disable visible body/collision, reset restores. Earlier nonlethal studies retain old rule.
- `terrain_arena.gd`: enables combat in the biome; three discrete health steps, 0.75 s hit cooldown, flash on nonlethal hits, GameManager death on third. REST/RESET clean up both sides' projectiles. Test held catalyst remains alongside saved hand ability.
- `commons/scenes/death_scene.gd`: consumes GameManager `encounter_return_scene` when present; reloads biome via current XR staging. Other death destinations keep their existing route.
- `biome_arena.gd`: clears sourced projectiles on exit. Terrain/flora/residents unchanged.

Validation 2026-10-12:
- `python -X utf8 tools/run_encounter_probe.py Point_Coordinates --sequence primitives --no-bridges --probe tools/probes/first_catalyst.gd --output-tag sourcing-combat --render`: 52/52, exit 0.
- `python -X utf8 tools/test_catalyst_first_abilities.py --combat --render`: 24/24, then known shutdown access violation 3221225477.
- `python -X utf8 tools/test_catalyst_first_abilities.py --menu --render`: 43/43, then same known shutdown failure.
- `python -X utf8 tools/test_catalyst_first_abilities.py --arena`: 31/31, exit 0.
- New `tools/probes/catalyst_combat.gd` uses real projectile collisions, GameManager, staged death and actual return to biome/menu. Wait for scene_visible before issuing another scene transition; content ready alone precedes the reveal fade.
- Coordinates probe uses real hall, XRTools pickup and XRServer controller input. Save redirected to probe output; never overwrite player's actual capability save.

Native images and reports copied alongside this file. No headset acceptance or export. Rendering shutdown crash was reproduced in menu-only baseline in prior work; it is not fixed here. Workspace contains extensive unrelated work: do not blanket revert/stage. No commit made.

Later playtest fixes are recorded in `FIXES.md`: bind to the current XR origin, supply arena practice ability without persisting an unearned unlock, and preload skull projectiles. The temporary `first_catalyst_glow.gd` helper was removed after a missing-preload report; both glows use the existing `.gdshader` directly. Latest cold-start probe: `tools/probes/catalyst_load_check.gd`, 4/4 assertions, exit 0, no parser/runtime errors.
