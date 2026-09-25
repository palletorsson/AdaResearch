# CA_BeyondBinary: decisions

**Verdict:** targeted revision. There are three edits: two sentences changed and one sentence added. Every other sentence stays word for word.

## Preserved
- The title, all 45 lines of structure, the `<!-- @game_of_life_petri -->` / `<!-- @ -->` anchors, every question, and both code excerpts.
- **The rule excerpt** matches game_of_life_petri.gd:410-413.
- **The receiver excerpt** matches address_study.gd:97-98 token for token. Only the spaces after commas differ, and the excerpt was kept as written.
- **The dynamics** were re-checked with a Python mirror of the spawn, rule and wrap (scratchpad bb/life_bb.py). Godot was not started. All five points hold:
  - The glider returns one address further along each axis after 4 generations.
  - A (10,10) is first occupied at generation 8.
  - BLINKER keeps A occupied in both phases.
  - MEET starts with A already inside the block.
  - RUN holds at generation 48 (address_study.gd:4,60-61,68).
- **The claims about LINK and one-way traffic** hold (life_address_receiver.gd:52-63, address_study.gd:76-79).
- **The contrast with the previous room** and **the handover to the next room** were kept, since the audit supports both.
- **The chapter's restraint** was kept: no claims about Turing completeness, edge of chaos or a living creature.

## Changes
1. **"Five pale cells" became "Five green cells"** (the re-checker's rewording).
   - The dish's live cells use the default alive_color Color(0.2,1.0,0.4) (game_of_life_petri.gd:39, 432). The study never recolours them.
   - The pale mint #90ebca belongs to the floor display (address_study.gd:94).
2. **Added "Press LINK again to reconnect the lamps." before "Choose MEET."**
   - This repairs the handover. The chapter asks for LINK at line 28 and never asks for it again.
   - replay() does not reset `linked` (address_study.gd:12, 38-53), and only toggle_link changes it (76-77).
   - A reader who follows the chapter's order would therefore reach "Predict which lamps will light" with every lamp forced dark (life_address_receiver.gd:59), and ONSETS could not count (life_address_receiver.gd:53).
   - The audit proposed this text fix instead of a code change, because a code change would alter the rule that reconnecting is not counted (address_study.gd:78).
3. **"Each button prepares a fresh beginning, so the difference can be revisited." became "GLIDER, BLINKER and MEET each prepare a fresh beginning, so the difference can be revisited; LINK keeps whatever setting you last gave it."** (the re-checker's rewording)
   - The preset buttons call replay() (address_study.gd:29-36), which resets cells, buffers, the generation and onsets (38-53; game_of_life_petri.gd:328-333; life_address_receiver.gd:48-50).
   - STEP, RUN and LINK prepare no beginning (callbacks at address_study.gd:166), and LINK carries over.

## Left alone, and why
- **"by generation 24 the field is empty" (MEET).** The mirror shows the field is empty from generation 6 onward, so the sentence is true, just loose. The audit summary flagged it, but the claim was not among those it re-checked or marked false. Under this brief it stays. It also matches field_notes.md.
- **Whitespace in the receiver excerpt.** Excerpts are to be preserved, and the difference is cosmetic.
- **The tutorial.md readout sentence, walked.md and eye_shot.md.** These are real faults that both agents agreed on, but they are outside final.md, and this pass may not edit them.
- **The rear gallery (mold_network, science_screen, dark_sphere, hexagon_ca_vr, ca_growth_network).** No sentences were added about it.
  - hexagon_ca_vr does fit the brief: each generation becomes a raised layer. But it is binary B2/S23 with an unseeded 1% flip, and its comment names a different rule.
  - Its extent against the front bay is unresolved between the code and the captures.
  - artifacts.md asks for "neighbourhood and rule together" to be reviewed before the chapter is extended.
  - The historical map name "BeyondBinary" is not echoed in the chapter. The chapter makes no multistate claim.

## Limits
- The dynamics were checked by the Python mirror and by reading code, not in Godot or a headset.
- The study gate in game_of_life_petri.gd and the 15x27 map exist only in the working tree (git status: M). At HEAD, the museum would build a dish without the study, and the chapter would describe something that is not built. Commit risk is outside this pass.
- Colour is judged from code, plus the re-checker's pixel readings from a probe capture. The rendered cells read as light-to-medium green, not neon, and "green" covers both.

## Installed

`after.md` was installed to `commons/maps/CA_BeyondBinary/final.md` on 24 September 2026. First an independent second agent checked every changed or added sentence against the code. Its verdict was install or install-with-fixes, and no fixes were needed. Line endings: LF, as in the baseline. Where this record says `final.md` was not touched, it describes the candidate stage. The diff is in `text.diff`, and the hashes are in `HASHES.txt`: before `4e649666dbd3…`, after `2110f41e925b…`. No runtime or learner status changes.
