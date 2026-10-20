# Cards become cloth

Two linked museum artifacts: a twelve-hook Jacquard-style loom and a sculpture of its recorded picks. Installed as `jacquard_studio` in **Tiling → Symmetry Seventeen**, cell `[16,14]`. The existing hand loom stays at `[16,21]`.

## Try it

1. Choose **PLAIN**, **TWILL** or **DIAMOND**. Eight physical cards form the repeating program; four more wait on the rack.
2. Grab a card and release it near an empty numbered slot. Picking it up removes it from the program. Occupied slots refuse replacement. Empty slots are skipped; an empty chain cannot weave.
3. **ONE PICK** reads one card, raises the selected warp threads, carries the shuttle through and beats in one weft pass. **RUN / STOP** repeats this cycle. Stop finishes the current pick.
4. Pick up a card (or press **NEXT CARD**) to select it. The twelve numbered buttons punch or patch its openings. A held trigger also selects the card. A hole raises its corresponding warp; a solid cell leaves it below. Hole bits do not encode yarn colour.
5. Change the card order or load another set. Existing cloth keeps its original crossings. An already running pick keeps the mask it read when it started.
6. Pull the pink slider on the second table. **FLAT** shows the cloth; **LAYERS** separates the picks vertically. It uses the loom's exact record, including yarn colours. A flat drawdown beneath shows the upper thread at each crossing.
7. **CLEAR CLOTH** clears both views and retains the cards. Capacity is 128 picks. Cards and cloth are session state; this artifact does not save them to disk.

Desktop pickup/drop uses the museum's existing grab interface. All labelled buttons use the project's physical push button. The layer table also provides FLAT/LAYERS buttons as an alternative to its XR slider.

## Tartan and yarn colours

**TARTAN + CLEAR** loads a small authored twelve-thread colour sett into both warp and weft, selects 2/2 twill cards and starts a fresh sample. Press ONE PICK or RUN to watch individual cycles, or **WEAVE 96 PICKS** on the layer table for a full sample. The sett is navy 2, green 2, cream 1, red 2, cream 1, green 2, navy 2; it is an enlarged teaching study, not a named historical tartan.

- The upper row of twelve colour buttons edits the **warp draft**. Press **THREAD + CLEAR** to apply it and start a fresh sample with new longitudinal threads. Editing the draft alone does not repaint existing cloth.
- The lower row edits the repeating **weft sequence**. A small mint marker follows the current step; the shuttle takes that colour. Changes affect future picks. The pass already under way retains its yarn colour.
- Each button cycles red, navy, green, cream, gold, black, pink and grey. Adjacent equal colours make wider stripes. **MATCH WEFT** copies the proposed warp order into the weft repeat.
- Cards and colours are independent programs. Eight card slots and twelve weft colour steps advance separately. The twill card mask repeats every four passes; the colour sett repeats every twelve.
- A colour change starts a new weft yarn at the selvedge. Consecutive passes of the same colour remain connected. Yarn knots, tails, tension and colour blending are not simulated.
- The layer table keeps the recorded colours. Its flat drawdown shows each top yarn's colour, not an averaged or invented mixed colour. The colour and lift repeat is applied eight times across 96 warp threads. Every row is one actual recorded pick. The diagram appears when opening the sample; the closed surface is real interlaced yarn geometry.

The Scottish Register of Tartans describes colour stripe sequences and their use in warp and weft: [threadcount guidance](https://www.tartanregister.gov.uk/threadcount). Our own small sett makes that relationship inspectable.

## Dense cloth and opening

The inspection table is 2.92 × 3.65 metres. Its cloth spans 2.4 metres across 96 closely packed, flattened yarns. A 96-pick sample is approximately 2.4 metres square; the 128-pick maximum extends to 3.2 metres. This remains an enlarged textile for inspection, not microscopic yarn scale.

**WEAVE 96 PICKS** runs the real card/colour program in a batch. It retains any pick already read and all earlier history, stops at 128, and updates both views together. It never tiles the row history to manufacture extra completed passes. The twelve hook choices and warp colours repeat eight times horizontally; the enlarged live hook display still explains one twelve-thread unit.

**FLAT** closes the yarns into cloth and hides the coloured diagram. The slider narrows yarn widths for inspection, exaggerates crossing height, and lifts successive rows up to 1.8 metres above their closed position. This is an inspection transform, not stretching a physical fabric. **LAYERS** opens the sample; the flat drawdown beneath keeps the pattern visible. The same vertex mesh remains in use as the slider moves: the GPU changes its shape without rebuilding it or modifying the records.

All 96 yarns and recorded weft passes are combined in one surface per view. The shader adds subtle filament shading and a matte finish. At maximum capacity the yarn mesh stays below 160,000 vertices per view. Clearing the cloth clears both views. The small controls and source cards stay within reach.

## What is simulated

The causal selection is explicit: one card → twelve hooks → one shed → one shuttle pass → one immutable record. The enlarged card at the head displays the card currently read. The small cards remain in fixed numbered sockets; a historical card cylinder and its mechanical linkages are not reconstructed.

Yarn paths prescribe over/under crossings. They do not solve tension, friction, yarn deformation or the structural viability of an arbitrary weave. Fully raised or lowered masks can produce floats. The layer table is an inspection transform of cloth history, not a claim that the loom manufactures a multilayer textile.

The relationship to the earlier hand loom is the move from choosing a lift by hand to storing and repeating that choice in a removable object. The program can change while the cloth retains evidence of previous decisions. The default cream/pink mode distinguishes warp from weft; the tartan controls add an independent colour program without changing what a punched hole means.

## Files and tests

- `weave_program.gd`: validated card slots, in-flight snapshot and committed history.
- `yarn_colours.gd`: palette, authored sett and top-thread colour lookup.
- `punch_card.gd`: real XRToolsPickable card, desktop hooks and placement callbacks.
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

Automated XR checks exercise XR Tools with simulated controller movement. Headset ergonomics still require a physical playthrough.

## References

The Science Museum Group describes punched cards selecting hooks that raise warp threads, and sets of cards carrying instructions for another pattern:

- [Ribbon loom with Jacquard head](https://collection.sciencemuseumgroup.org.uk/objects/co8404795/ribbon-loom-with-jacquard-head)
- [Jacquard cards](https://collection.sciencemuseumgroup.org.uk/objects/co471243/jacquard-cards)
- [Jacquard hand loom](https://collection.sciencemuseumgroup.org.uk/objects/co8405056/jacquard-hand-loom)

These inform the mechanism. Our small card chain and expanded layer view are teaching constructions.
