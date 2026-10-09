# Colour — responding to the full-sequence review

The review recommends keeping the eight-hall order and making three small editorial revisions. I agree. Its most useful observation is that each hall changes where colour is held and what receives it. That gives the chapter a question to follow without turning every encounter into the same exercise.

This is a reading assessment from another model. It does not add evidence of learner comprehension or independent execution. The existing native checks remain the implementation evidence.

## Applied revisions

| Hall | Revision | What remains |
|---|---|---|
| [Colour](Color_Context_Placed/parallel.html) | Name the distinction before the code: the palette holds available values; the assignment says where they go. | The same five parts and complete tested program. |
| [Rainbow](Color_Rainbow/parallel.html) | Say explicitly that this example couples band count to palette length. Two colours could instead repeat over six parts. | Fixed opening and total radial thickness; making remains optional. |
| [Paint](Color_Paint/parallel.html) | State the manual causal chain first, keep `automatic = false`, add a concrete completion check, and move the automatic painter discussion to an explicitly optional continuation at the end. | Full runnable code and visible support files; the existing reflection still begins with an automatic painter. |

Flashlight, Nails, Pillar, Grid and Walls need no revision from this feedback. The eight reflections are unchanged. All student scripts are unchanged, including the automatic caller already disabled by default. This pass changes the reading priority and explanation, not the implementation.

The order stays in place for the next pass. The reviewer's “freeze” is treated as a recommendation to retain a working progression, not a permanent restriction on changing the project. These remain review drafts; canonical tutorials and museum logic have not been replaced.

## Paint's first completion point

**Hold → request spray → aim → accepted hit → surface address → retained colour.**

The learner chooses an ink and a place, predicts the mark, then demonstrates three states: an active miss adds nothing; an accepted hit deposits colour; releasing or dropping stops new marks while old ones remain. They can identify the image as the place where the result is kept.

That is a complete lesson. Afterwards the automatic caller can demonstrate that a different source of positions can use the same receiver. Its two oscillations are an optional return to motion, not another requirement for learning to paint.

The support implementation stays available in full. Hiding it would make the reconstruction incomplete; requiring the learner to study every pixel operation before making a mark would obscure the selected interaction. The text now gives a clear first goal and a later extension.

## What the chapter carries

**Where is the colour held, and what receives it?**

| Hall | Where the program keeps the relevant value | What the operation reaches |
|---|---|---|
| Colour | Palette values and assignment indices; then each material | The existing parts of a construction |
| Flashlight | The light's colour and aim | Illumination on an unchanged material |
| Nails | A function's returned Color; then a material | A preview of a chosen local position |
| Rainbow | An ordered palette | Bands sharing a fixed extent |
| Pillar | Authored HSV parameters and a returned RGB Color | A sample of the represented field |
| Grid | Palette state and stored MultiMesh instance colours | An addressed tile, or all addressed tiles under a rule |
| Paint | Accumulated pixels in an image | A surface that keeps receiving deposits |
| Walls | Palette values, material alpha and transparency mode | A layered view; the collider remains independent |

The companion question is: **what does that value leave undecided?** A material colour alone does not determine appearance. A cell's current value does not recover overwritten choices. An accumulated image does not retain a lossless record of gestures. Alpha does not determine whether a body may pass.

These questions help connect the two texts. The tutorial reconstructs a selected relation. The reflection can examine what that relation permits, leaves out or makes felt in the museum.

## Verification and review files

The comparison records the original and revised tutorial text for the three changed halls. All fenced GDScript blocks and all student script files are identical before and after. The sequence definition and every final.md also match the pre-revision snapshot. See [editorial verification](feedback/editorial-check.json).

The existing native checks were rerun for the revised tutorial sources: 216 assertions for the opening Colour lesson and 311 for the five-hall batch; all 15 corresponding deliberately broken versions were rejected. The five-hall render checks also passed again. Flashlight and Nails retain their earlier, hash-checked results. The collected totals remain 747 native assertions, 39 render checks and 25 deliberate faults rejected; these are not claims of headset or learner testing.

- [Complete revised sequence](index.html)
- [Full tutorial text](ALL_TUTORIALS.md)
- [Full reflective text](ALL_FINAL.md)
- [Updated reviewer ZIP](colour-review.zip)
- [Original supplied feedback](feedback/reviewer-original.txt)
- [Exact editorial changes](feedback/changes.diff)
