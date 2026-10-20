# Cards become cloth

Two linked museum artifacts: a twelve-hook Jacquard-style loom and a sculpture of its recorded picks. Installed as `jacquard_studio` in **Tiling → Symmetry Seventeen**, cell `[16,14]`. The existing hand loom stays at `[16,21]`.

## Try it

1. Choose **PLAIN**, **TWILL** or **DIAMOND**. Eight physical cards hang in a laced loop beside the weaving bed; four more wait on the front tray.
2. Grab a card and release it near an empty numbered chain frame. Picking it up removes it from the program and stops automatic weaving after the current pick. Occupied frames refuse replacement. The belt advances over empty frames; an empty chain cannot weave.
3. **ONE PICK** advances the chain until the next card seats in the brass reader. The belt then stops, the selected warp threads rise, and the shuttle draws a visible weft through the shed. The reed brings the pass into the cloth and exactly one record is added. **RUN / STOP** repeats this cycle. The adjacent **NORMAL / SLOW** button switches between 2.8 and 8 seconds, including during a pass without restarting it. Stop finishes the current pick. The eight-card loop returns to its first card after the eighth pass. When parked, the reader identifies the card and pick just woven.
4. Pick up a card (or press **NEXT CARD**) to select it. The twelve numbered buttons punch or patch its openings. A held trigger also selects the card. A hole raises its corresponding warp; a solid cell leaves it below. Hole bits do not encode yarn colour.
5. Change the card order or load another set. Existing cloth keeps its original crossings. An already running pick keeps the mask it read when it started.
6. Pull the pink slider on the second table. **FLAT** shows the cloth; **LAYERS** separates the picks vertically. It uses the loom's exact record, including yarn colours. A flat drawdown beneath shows the upper thread at each crossing.
7. **CLEAR CLOTH** clears both views and retains the cards. Capacity is 128 picks. Cards and cloth are session state; this artifact does not save them to disk.

Desktop pickup/drop uses the museum's existing grab interface. All labelled buttons use the project's physical push button. The layer table also provides FLAT/LAYERS buttons as an alternative to its XR slider.

## Six woven samples

The front rim of the linked layer table has six named buttons. Each **replaces the current cloth with a fresh 96-pick sample**, including the corresponding card program and yarn colours. A held card must be returned first. The selected button lights up; manual edits mark the sample as edited.

| Button | Crossing rule | Yarn choices |
| --- | --- | --- |
| STRIPES | Plain weave | Unequal dark and pale warp bands; cream weft. Compare narrow and broad stripes. |
| CHECKS | Plain weave | Three navy, three cream in both directions. |
| TARTAN | 2/2 twill | The authored twelve-thread sett in both directions. |
| CHEVRON | Pointed, reversing twill | Cream warp and navy weft reveal the joined zigzags. |
| HERRINGBONE | Broken, reversing twill | The same yarn colours reveal the offset at each turn. |
| HOUNDSTOOTH | 2/2 twill | Four dark, four cream in both directions: an eight-thread colour period. |

Press **LAYERS**, or pull the slider, to separate the actual crossings. **FLAT** closes the same yarn mesh. The diagram underneath preserves the top-thread pattern while the yarns open. To see a sample being made, press **CLEAR CLOTH** on the loom, then **ONE PICK** or **RUN**. The chosen cards and yarn sequences remain in place. Ordinary card and colour edits affect future picks; only the explicitly named fresh-sample controls replace the existing cloth.

Stripes and checks share a lift rule but change colour order. Tartan and houndstooth both use 2/2 twill with different colour sequences. Chevron and herringbone change the lift rule itself. These are small teaching drafts, not an exhaustive classification of those pattern families.

## Follow one changed hole

On a fresh cream-and-pink sample, choose **PLAIN** and weave eight picks. Select **CARD 01** and press hook **1** to patch its first hole. Weave sixteen more picks. The change appears on picks **9 and 17**, each time that card returns. Earlier cloth remains intact. Because the twelve-hook unit repeats eight times across the width, each changed pick contains eight changed crossings. Open the layers to inspect where the cream warp now goes underneath the pink weft. This is a visitor experiment with the existing artifact, not an additional required tutorial lesson.

The runtime probe performs this experiment through the real punch-button signal and animated cycles, then checks both the stored records and the generated warp paths. The evidence report includes the full before/after record.

## Tartan and yarn colours

**TARTAN + CLEAR** loads a small authored twelve-thread colour sett into both warp and weft, selects 2/2 twill cards and starts a fresh sample. Press ONE PICK or RUN to watch individual cycles, or **WEAVE 96 PICKS** on the layer table for a full sample. The sett is navy 2, green 2, cream 1, red 2, cream 1, green 2, navy 2; it is an enlarged teaching study, not a named historical tartan.

- The upper row of up to twelve colour buttons edits the **warp draft**. Only steps used by the current colour period are active. Press **THREAD + CLEAR** to apply it and start a fresh sample with new longitudinal threads. Editing the draft alone does not repaint existing cloth.
- The lower row edits the repeating **weft sequence**. A small mint marker follows the current step; the shuttle takes that colour. Changes affect future picks. The pass already under way retains its yarn colour.
- Each button cycles red, navy, green, cream, gold, black, pink and grey. Adjacent equal colours make wider stripes. **MATCH WEFT** copies the proposed warp order into the weft repeat.
- Cards and colours are independent programs. Eight card slots and the active weft colour sequence advance separately. In the tartan sample, the twill card mask repeats every four passes and the colour sett every twelve. Houndstooth retains its eight-step colour sequence across the twelve-hook boundary.
- A colour change starts a new weft yarn at the selvedge. Consecutive passes of the same colour remain connected. Yarn knots, tails, tension and colour blending are not simulated.
- The layer table keeps the recorded colours. Its flat drawdown shows each top yarn's colour, not an averaged or invented mixed colour. The twelve-hook lift repeats eight times across 96 warp threads; yarn colours repeat at their own period. Every row is one actual recorded pick. The diagram appears when opening the sample; the closed surface is real interlaced yarn geometry.

The Scottish Register of Tartans describes colour stripe sequences and their use in warp and weft: [threadcount guidance](https://www.tartanregister.gov.uk/threadcount). Our own small sett makes that relationship inspectable.

## Dense cloth and opening

The inspection table is 2.92 × 3.65 metres. Its cloth spans 2.4 metres across 96 closely packed, flattened yarns. A 96-pick sample is approximately 2.4 metres square; the 128-pick maximum extends to 3.2 metres. This remains an enlarged textile for inspection, not microscopic yarn scale.

**WEAVE 96 PICKS** runs the real card/colour program in a batch. It retains any pick already read and all earlier history, stops at 128, and updates both views together. It never tiles the row history to manufacture extra completed passes. The twelve hook choices repeat eight times horizontally, independently of the yarn colour period; the enlarged live hook display still explains one twelve-thread unit.

**FLAT** closes the yarns into cloth and hides the coloured diagram. The slider narrows yarn widths for inspection, exaggerates crossing height, and lifts successive rows up to 1.8 metres above their closed position. This is an inspection transform, not stretching a physical fabric. **LAYERS** opens the sample; the flat drawdown beneath keeps the pattern visible. The same vertex mesh remains in use as the slider moves: the GPU changes its shape without rebuilding it or modifying the records.

All 96 yarns and recorded weft passes are combined in one surface per view. The shader adds subtle filament shading and a matte finish. At maximum capacity the yarn mesh stays below 160,000 vertices per view. Clearing the cloth clears both views. The small controls and source cards stay within reach.

## What is simulated

The causal selection is explicit: physical card advances → seats → twelve hooks lift → one shed → one shuttle pass → one immutable record. The enlarged mask above the weaving bed displays the committed in-flight choice. It appears after the card seats. Card and colour edits apply to future picks; the running cycle keeps its starting snapshot.

The belt is a prescribed kinematic path, with laces, an upper drum and an open return run. Its eight numbered frames carry the actual pickable cards, including their collision shapes. The drum turns with the advancing belt. This is a simplified selection mechanism, not a simulation of card-chain gravity, cord tension or every historical mechanical linkage. The colour controls sit beside the bed to keep the forming cloth visible. **WEAVE 96 PICKS** remains an explicit fast sample: it skips animation, retains real records and parks the belt at the last card used. ONE PICK or RUN resumes from the next card.

Yarn paths prescribe over/under crossings. They do not solve tension, friction, yarn deformation or the structural viability of an arbitrary weave. Fully raised or lowered masks can produce floats. The layer table is an inspection transform of cloth history, not a claim that the loom manufactures a multilayer textile.

The relationship to the earlier hand loom is the move from choosing a lift by hand to storing and repeating that choice in a removable object. The program can change while the cloth retains evidence of previous decisions. The default cream/pink mode distinguishes warp from weft; the tartan controls add an independent colour program without changing what a punched hole means.

## Files and tests

- `weave_program.gd`: validated card slots, in-flight snapshot and committed history.
- `weave_samples.gd`: six named drafts, each declaring its lift rule and independent yarn sequences.
- `yarn_colours.gd`: palette, authored sett and top-thread colour lookup.
- `punch_card.gd`: real XRToolsPickable card, desktop hooks and placement callbacks.
- `card_chain.gd`: laced eight-frame loop, drum, reader window and index motion.
- `jacquard_weaver.gd`: reader, hooks, shed, shuttle, reed, controls and cloth geometry.
- `weave_layers.gd`: linked record, interlacement and XR handle slider.
- `weave_geometry.gd`: perforated cards, live hook tubes and crossing diagrams.
- `weave_fabric.gd`: dense, batched yarn geometry from the recorded rows.
- `woven_yarn.gdshader`: matte yarn shading and reversible GPU opening.
- `jacquard_studio.gd`: explicitly connects the two instances; no global state.
- `tools/probes/jacquard_weaver_test.gd`: runtime assertions, simulated XR pickup/drop/slider and native captures.
- `tools/probes/jacquard_museum_test.gd`: current hall loading, retained hand loom and clear standing approaches. Uses an isolated current museum snapshot in `ada_run/jacquard_review/` so it does not navigate the user's session.

Run the runtime probe with Godot 4.6, `--path . --xr-mode off --no-window --audio-driver Dummy --script res://tools/probes/jacquard_weaver_test.gd -- --capture`. Captures need a GPU renderer. Results are in `doc/book/iterations/2026-10-10-jacquard-cards-and-layers/`.

For both probes and a fresh isolated museum snapshot, run `python tools/run_jacquard_review.py --godot <path-to-Godot-4.6>`. This also republishes the review after successful tests.

For hanging-chain evidence, run `python tools/run_jacquard_review.py --chain`, then `python tools/publish_jacquard_chain.py`. Tests include seating before lift, stationary chain during the shuttle pass, one record per pass, full-loop wrap, sparse decks, pickup interruption and resuming after a batch. This revision writes to `doc/book/iterations/2026-10-10-jacquard-hanging-chain/`.

For the six-pattern revision, run `python tools/run_jacquard_review.py --samples`, then `python tools/publish_jacquard_samples.py`. The sample probe checks all 9,216 crossings and drawdown colours per pattern, full opening/closing, animated replay, the independent houndstooth repeat, held-card refusal and preservation of existing picks during manual edits. The museum probe activates all six installed buttons and captures each sample flat and open. Evidence is in `doc/book/iterations/2026-10-10-six-woven-patterns/`.

Automated XR checks exercise XR Tools with simulated controller movement. Headset ergonomics still require a physical playthrough.

## References

The Science Museum Group describes punched cards selecting hooks that raise warp threads, and sets of cards carrying instructions for another pattern:

- [Ribbon loom with Jacquard head](https://collection.sciencemuseumgroup.org.uk/objects/co8404795/ribbon-loom-with-jacquard-head)
- [Jacquard cards](https://collection.sciencemuseumgroup.org.uk/objects/co471243/jacquard-cards)
- [Jacquard hand loom](https://collection.sciencemuseumgroup.org.uk/objects/co8405056/jacquard-hand-loom)

These inform the mechanism. Our small card chain and expanded layer view are teaching constructions.

For weave structures and colour effects: [CottonWorks, Weaving 101](https://cottonworks.com/wp-content/uploads/2023/03/Weaving-101.pdf) and [Handwoven, November/December 2013](https://www.datocms-assets.com/75077/1687814092-hwnd13.pdf). Houndstooth here uses four dark/four light in warp and weft with 2/2 twill. Chevron joins reversing diagonals; the herringbone draft offsets their junctions.
