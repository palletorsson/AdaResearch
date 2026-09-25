# Noise_Columns: decisions

**Verdict:** targeted revision. The audit and its re-check agree on two false or overstated sentences, both about the dark orb's floor ring. I added one short passage on where the marble veins are sampled, following the audit's encounter fix (b), and checked it in the shader myself. Everything else stays as it was.

## Preserved

- The title question, the observe -> FREEZE -> SPIN -> MARBLE -> REVEAL order and every question put to the visitor.
- All three code excerpts (`driver_phase`, `melt_factor`/`height`, `pulse_t`, swarm `count/ring/small`). The audit matched them character for character.
- The three `<!-- @token -->` anchors (MeltingBerniniScene, dark_sphere, synthesis_stand).
- The claims the audit confirmed: the phase is a remapped value and not an angle, there is one phase per shaft, the 0.70 m drop, the 0.10 baseline, no supporting collision, a limit of 12 rebuilds per second, the hush/swarm choice, the plaque score as selection metadata, and the Noise One handoff.

## Changes

1. **L15, added two sentences (MARBLE paragraph).** The veining is not fixed to the stone. The shader samples it from each point's position relative to the viewer's eyes, so the veins slide as you walk around a frozen shaft and stay nearly in place under SPIN.
   - Evidence: `marble_column.gdshader:60-68` builds the fbm sample from `VERTEX` in `fragment()`. The shader has no `vertex()` function and no `world_vertex_coords` (`:2`), so this is Godot 4's view-space fragment position, despite the variable name `local_pos`. The trio's shafts use this material: `MeltingBerniniColumns.gd:823` -> `create_spiral_column` `:308` -> `create_shaft_material` `:244-261`, with `use_marble_shader` defaulting to true at `:37`. SPIN only rotates the column node (`:935-939`). While frozen, `u_time` holds (`:926-929`), so the view-space position is the only thing that moves the veins.
   - Why: the audit names this as real work the chapter leaves out. It also supports the paragraph's own point that "a changing appearance has several places to happen" and the brief's point that where we sample changes the value. The past tense fits because the visitor has just stopped SPIN with the veins on.
2. **L55.** Before: "Stay long enough to notice the pulse and the widening ring beneath it." After: "Stay long enough to notice the pulse, and the pool of shadow beneath it slowly deepening and fading."
   - Evidence: the bare `dark_sphere` (map_data.json:708) keeps `presence = "witness"` (`dark_sphere.gd:467`). The widening KinReach torus is built only when presence is "becoming" (`:956`) and is scaled only if it exists (`:613-618`). The floor disc is a fixed-radius CylinderMesh, commented "shadow/halo disc" (`:983-993`). Its radius is set once (`:642`), and `_process` changes only its alpha (`:621-625`).
   - I departed from the re-checker's "brightening": the disc is unshaded dark purple `Color(0.1, 0.04, 0.16)` (`:999`, `:1020`) with alpha between 0.08 and 0.20 (`:639-640`). Raising its alpha darkens the floor, so "deepening" is the accurate word.
3. **L63.** Before: "...and the surrounding ring changes size and opacity." After: "...and the pool beneath it pulses in opacity on a slower sine."
   - Evidence: the same code, `dark_sphere.gd:621-625`. The halo alpha follows `sin(t * pulse_speed * 0.7)`, so its sine is slower than the body's `sin(t * pulse_speed)` at `:599-600`. Nothing sets the halo's scale.
   - "Pool" replaces "surrounding ring" so the sentence agrees with L55.

## Left alone, and why

- "East half of the room" (L7): the audit offers "on your left as you enter" only as optional and did not show the phrase to be false.
- Grid-lane build, a possible double build of synthesis_stand, the museum pier at tile (6,7), and the uncommitted review files are space and code problems, not prose problems. The chapter describes the museum encounter the audit confirmed. Adding lane caveats would put audit apparatus into the book.
- The stale companions (technical.md, critical.md, walked.md, eye_shot.md) repeat the ring error, but they are outside the files I was allowed to write.

## Limits

- Read-only. Godot was not started, so the view-space vein behaviour is inferred from Godot 4's fragment `VERTEX` semantics and the shader source. It has not been observed in a capture. In stereo VR each eye has its own view space, so the veins may also differ slightly between the eyes. The chapter does not claim this.
- The trio's behaviour, including FREEZE reaching `u_time`, depends on working-tree edits the audit found uncommitted (`MeltingBerniniColumns.gd:926-934`). If those are reverted, the added passage still holds for the geometry, but not for the claim that FREEZE holds the veins.

## Installed

`after.md` was installed to `commons/maps/Noise_Columns/final.md` on 24 September 2026, after an independent second agent checked every changed or added sentence against the code and its fixes were applied. Line endings: LF, as in the baseline. Where this record says `final.md` was not touched, it describes the candidate stage. The diff is in `text.diff`, and the hashes are in `HASHES.txt`: before `d5e3f300bcf4…`, after `57cfa534fde3…`. No runtime or learner status changes, because the text changed and nothing new was walked.
