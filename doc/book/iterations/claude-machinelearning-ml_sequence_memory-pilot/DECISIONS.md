# ML_Sequence_Memory — pilot delivery

Sequence `machinelearning`, hall 6 of 8. 23 September 2026.

---

## 1. What I preserved, and the one change this hall needed

Preserved: the opening question, the three-kinds-of-decision distinction (retain / admit / expose), the "is" versus "are" thought experiment, and the hall's refusal to claim training. Its honesty was never the problem.

The one change: the hall described an experiment instead of holding one. Its own last two paragraphs said so — *"it does not yet carry an input sequence through a computed recurrent memory"* and *"The next useful addition would make an input sequence and cell-state values visible, then compare two sequences differing at one earlier step."* Those paragraphs are now gone because the thing they asked for exists.

---

## 2. The encounter

### What was actually there

`LSTMs_VR.gd`, 516 lines, contained **no cell state**: no variable, no timestep index, no weight, no `tanh`. Its `@identity` header nonetheless states the artifact's essence as `c(t) = f·c(t-1) + i·tanh(W·[h,x]); h(t) = o·tanh(c(t))`. The only self-referencing numbers were four constant-rate clocks. `_update_training_metrics` was `pass`; `apply_grid_config` was `pass`; `input_tokens` was filled once and never read again; there was no `body_entered` anywhere, so there was no input channel at all.

Two floating `Label3D` read `CELL STATE / Long-term Memory` and `HIDDEN STATE / Short-term Memory`, hung over nothing.

### Built, gated on `#recurrent:on`

```gdscript
cell_state = forget * cell_state + input_gate * x
hidden_out = output * cell_state
```

A token crossing into the walk-in cell is the input — pale `+1`, dark `−1`, polled with hysteresis in the function that used to be `pass`. The three gates are the three spheres at hand height. The cell carries `c`; the output slab, which previously did nothing, rides `h`. A band up the post marks where no single admission can reach.

**Linear deliberately.** A trained LSTM squashes each step and computes its gates from the input. Linear keeps the divergence exact — two histories differing at one earlier step differ by exactly `2·f·i` — so the forget gate is legible as the coefficient on the past. The prose says this rather than calling the artifact an LSTM.

### Two repairs the encounter required

**The reach.** The gate spheres and tokens were scriptless `RigidBody3D`. XR Tools rejects any grab target without a `pick_up` method, so in a headset nothing here was touchable — beneath a source comment reading "XRTools pickable" and a header claiming "grabbable gate spheres [has]". They carry the addon's pickable script now.

**The datum.** Gate values read world `y`, so the resting activation depended on the floor height of the map the artifact stood in. Measured in the artifact frame now.

### Evidence

`commons/testing/probe_lstm_recurrence.gd`, 9 cases, exits non-zero, all pass.

| | check | measured |
|---|---|---|
| A | default off | inert; the other two placements unchanged |
| **B** | **two histories, same last input** | **h = −0.1250 and −0.3750** |
| C | the gap in `c` | 0.500000, exactly `2·f·i` |
| **D** | **forget gate at zero** | **both land on −0.250000** |
| E | the band | strongest single step h = 1.0000 |
| F | carried past | h = 2.0000, beyond it |
| G | computes | same history, forget 0.9 → −0.0250, forget 0.1 → −0.2250 |
| H | the datum | 0.5 at y=0 and at y=7 |
| I | the reach | 3 of 3 gates and 8 of 8 tokens answer `pick_up` |

---

## 3. The revision

Original at `before/final.md`; candidate at `final.candidate.md`, installed canonically; `final.diff` and `LSTMs_VR.diff` alongside. 410 → 591 words, 264 lines of code, artifact anchor preserved, pathfinder OK.

---

## 4. Field notes

**Method.** Two workflows: six readers with adversarial verification on every capability claim, then six independent designs scored by three judges. The scores were effectively tied (21.5 / 21 / 21 / 20 / 19.5 / 19), so no design won. What decided it was that all three judges independently hit the same trap — five of six proposals were built on a gesture that does not work in a headset, **because I had told the proposers the gates were reachable.** The panel caught my error rather than each other's. What shipped is three grafted ideas: the `2·f·i` arithmetic, the band, and the reach repair.

**Open, and it is a real loose end.** Both repairs are gated, so `lstms_vr` in `MachineLearning_LSTMs` and `Ribbon_Machinelearnin_01` is still unreachable in VR and its header is still false there. Ungating is the right call and needs a decision, because it changes those two halls.

**Not claimed.** Nothing here is trained. The gates are set by hand. The rule is linear. The memory particles are still a prescribed animation and the prose does not pretend otherwise. `transformers_vr` at row 17 is untouched — the assignment scoped it out.

**Not done.** Nobody has walked this hall. The probe drives the artifact's own methods; it does not press a token through the cell with a hand, and case I proves the grab interface answers, not that a controller reaches it.
