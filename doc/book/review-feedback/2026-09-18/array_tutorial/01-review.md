# Array Tutorial — 01 Review

Source-aware editorial and reader-experience review of the **array_tutorial** sequence.

Basis: `array_tutorial-book.md`, `array_tutorial-review.md`, and the supplied ZIP snapshot on branch `palm-scanner-door-entry`, captured 2026-09-18. No repository code was executed.

This review uses two linked lenses:

1. **Structural / technical:** what the implemented encounter actually supports, what each return does in the sequence, and where source, metadata, map, and manuscript disagree.
2. **Reader experience:** where curiosity builds, where the visitor can discover something before it is named, where explanation arrives too early, and whether the better intervention belongs to the artifact rather than the prose.

Before proposing any cut, the review asks what technical, poetic, critical, or structural work the passage performs. Recurrence is not treated as redundancy when an earlier idea returns through a changed body, medium, orientation, or use.

The sequence currently reads as:

> **absence → address → reachable volume → repeated rule → changed orientation → repeated rule in time**

A second formulation is:

> **A slot can persist when its occupant changes. An address can organise a row, a plane, a volume, a pattern, and finally a rhythm without determining what any of those should mean.**

---

## 1. One line per hall

| Hall | What carries it / main gap / next useful revision |
|---|---|
| **Array** | **Carries:** the best discovery-first encounter in the sequence. A cube disappears before “array” is fully explained; then the row and grid give absence two different spatial consequences: the row's label leaves with the cube, while the configured `notation:plate` grid leaves the address behind. **Gap:** the manuscript's contact/collection behaviour and live binary-table update depend on `pick_up_cube.gd` and `binary_table_display.gd`, which are referenced but not included in this snapshot. **Next:** preserve the prose; include those dependencies in the next bundle and runtime-test the disappearance/table update rather than explaining more. |
| **Tutorial 3D** | **Carries:** the third index is made bodily by giving the visitor a new locomotion permission; the strongest moment comes later when the visitor can occupy the neighbourhood of a slot whose stored value remains zero. **Gap:** curiosity is partially pre-empted by the artifact itself: `array_flight_lab.gd` titles the enclosure **FLY INTO THE THIRD INDEX** before the opening experiment has let the visitor discover which part of the address changes vertically. **Next:** rename the instruction/title so the relation can be discovered before it is named; runtime-test XR flight and entry/exit. |
| **Tutorial Tiling Floor** | **Carries:** addresses stop merely naming occupants and begin supplying a rule; the opening wisely asks the visitor to compare fields before naming them, and ONE EXCEPTION turns difference into an open compositional question rather than an error. **Gap:** CAPTURE evidence shows the museum's coloured wireframe/grid skin visually competing with the intentionally monochrome floor studies; this risks making the perceptual comparison harder than the text needs it to be. **Next:** improve the environmental presentation before adding or cutting explanation. |
| **Tutorial Tiling Walls** | **Carries:** this is a deliberate controlled return, not a duplicate of Floor. The six rules stay the same while orientation, viewing distance, forward visibility and collision change. The recurrence lets the visitor discover that a fixed image can acquire another spatial force. **Gap:** the same architecture-skin issue remains, though the vertical panels currently read more clearly than the floor captures. **Next:** preserve the chapter; verify the visual hierarchy and wall collision in the final museum skin. |
| **Tutorial Disco** | **Carries:** spatial addressing becomes temporal reading. The room first separates a floor's visual clock from a sequencer's clock, then returns to the original Array question in sound: a slot remains available when its value is off. The 16-step → 12-column wrap is an especially strong demonstration of representation losing provenance. **Gap:** the middle becomes somewhat procedural, and one discovery is announced before it can happen: the prose tells the reader that activating a cell previews its sound before asking them to hear it. The sequencer UI also hard-codes track labels that do not match the configured `90s_house` sounds. **Next:** delay the preview explanation and fix the UI labels; preserve the two-clock and 16→12 comparisons. |

---

## 2. Reader-experience lens

### Array

**Curiosity**

The opening is strong:

> “What remains at an address after its occupant has gone?”

It does not begin by defining an array. It gives the visitor something to lose and asks what survives.

The Transformation cube is also a useful recognition: a known object has acquired company. The new subject is not “what is a cube?” but “what becomes possible when several are indexed?”

**Discovery**

The best sequence is:

1. read an address;
2. predict the table change;
3. collect the cube;
4. point to the missing position;
5. only then receive the distinction between index and stored value.

The row/grid comparison is even stronger because the same event leaves different evidence. In `row_3_x.gd`, the `[i]` label is a child of the cube; when the cube leaves, its visible address leaves with it. In the placed grid instance, `grid_2d_4x4#notation:plate`, the dark plate and card are built independently at the slot and remain after the cube is removed.

The visitor can therefore discover **address persistence** before receiving a general statement about representation.

**Timing**

The definition—

> “An array keeps values in an indexed sequence.”

—arrives at the right moment: after one absence has already been experienced.

The later question about zero meaning absence / rest / reservation also arrives well. It does not undermine the first exercise; it reopens the newly learned representation by asking what its single stored value fails to distinguish.

**Return**

This hall establishes the sequence's recurring pair:

> **where is the slot? / what value is stored there?**

Later halls should keep returning to that distinction. That is the spine, not repetition.

---

### Tutorial 3D

**Curiosity**

The textual opening is excellent:

> “How do you reach an address above your head?”

and:

> “Which part of the address changes as it climbs?”

These are bodily questions before they are programming questions.

**Discovery**

The visitor can:

- change X, Y and Z separately at the console;
- see a transparent selected-address marker;
- enter an enclosure where vertical movement becomes possible;
- collect a cube and later hover near the recorded zero.

The strongest critical moment is:

> “The table still says zero: it records cubes, not everything that could exist there.”

That is an important development of Array. The body can physically occupy a place while the representation continues truthfully reporting something else because it was designed to record cubes.

**Timing**

The text's timing is good, but the **artifact's timing is not**.

`array_flight_lab.gd::_ready()` creates `museum_flight_box.gd` and sets:

```gdscript
enclosure.instruction_title = "FLY INTO THE THIRD INDEX"
```

The entrance capture shows this large heading before the visitor has entered the array.

So the artifact names the conceptual answer before the opening exercise has had time to generate it.

**Return**

The slot/value distinction from Array returns in a more interesting form:

- addressing gained a third component;
- reach required a separate locomotion permission;
- occupancy by the visitor still does not change the stored cube value.

The repetition has changed meaning.

---

### Tutorial Tiling Floor

**Curiosity**

This is one of the best openings in the bundle:

> “Before reading their names, find two that seem related. What has stayed the same between them?”

It explicitly protects a short period of unlabelled comparison.

**Discovery**

The visitor can discover several relations visually before code appears:

- repetition without changed orientation;
- alternation;
- quarter-turn progression;
- reflection;
- row displacement;
- one local deviation.

The line:

> “The unit that you notice need not be the unit stored by the program.”

is earned by the encounter because chevrons and bands can arise across several tiles.

ONE EXCEPTION is particularly good because the text does not decide whether the difference is an error, opening or direction.

**Timing**

The code arrives after the visitor has already walked several fields, which is correct.

The only problem is environmental: the dated captures show bright coloured museum wireframes running through and around the black/white studies. The bundle itself records that this regularity pass is unfinished and that floor images show interference.

This is not a reason to add explanation such as “ignore the grid lines.” The environment should give the monochrome comparison more perceptual authority.

**Return**

The address has acquired a new job. In Array it identified a slot; here `(cx, cy)` participates in the rule that decides orientation.

That is a meaningful progression.

---

### Tutorial Tiling Walls

**Curiosity**

The chapter tells the reader immediately that these are the **same six studies** standing up.

Ordinarily this might sound like explaining too early. Here it is experimental control. The visitor needs to know that the rule has been held constant so that the changed encounter can be attributed to orientation, viewpoint and bodily relation.

**Discovery**

The visitor can discover:

- a tile that was beneath the feet now occupying forward view;
- local squares becoming larger figures with distance;
- perspective altering apparent diagonal angles while the stored texture stays fixed;
- one exception becoming a landmark rather than merely a disturbed pattern.

The meeting-place question is especially useful because it gives the exception a possible function without declaring one.

**Timing**

The sentence explaining that the same image generator is used comes after an initial approach/retreat exercise. That is well timed.

The wall's separate collision is also explained only after the visitor has a chance to face it.

**Return**

This hall should not be compressed into Floor. The same code returning in another orientation is exactly what makes the comparison controlled.

The return changes meaning from:

> how does a rule organise an image?

to:

> how does the same image organise a body's view and route when it becomes architecture?

---

### Tutorial Disco

**Curiosity**

The opening is excellent:

> “How can an arrangement that sits still make a rhythm?”

and then:

> “Begin by stopping one of its clocks.”

The phrase “one of” already implies there is another clock to discover.

**Discovery**

Several experiments are strong:

- visual pattern can change while tile positions remain fixed;
- a sequencer cell can remain an address when inactive;
- pattern and tempo can change independently;
- stopping the sequencer does not stop the floor;
- stopping the floor does not stop the sequencer;
- sixteen sequencer addresses are folded onto twelve floor columns;
- the visitor can move with or against the pulse without being measured by it.

The 16 → 12 mapping is perhaps the strongest technical discovery in the room:

> the event is preserved, but its source address is no longer uniquely recoverable from the flash.

This is a clean continuation of the book's larger concern with productive partial representations.

**Timing**

The sequencing subsection is the one place where the prose becomes slightly too instructional before curiosity can form.

Current:

> “Select the empty pattern and turn on one cell. Activating it previews its sound immediately. Let that preview finish, then start playback…”

The visitor is told what the unexpected first sound means before they have heard it.

That is an opportunity to let the artifact speak first.

**Return**

The line:

> “This is the array room's question in another material: the slot remains available when its value changes.”

is a deliberate return that works very well.

The first room's absence has become silence. The address persists in both cases, but Disco adds a clock that repeatedly reads it.

Do not cut that recognition.

---

## 3. Four high-value changes

Four are enough. The sequence does not need a fifth intervention merely to fill a quota.

### 3.1 Tutorial 3D — let the visitor discover the third index before naming it

**Hall / instance**

`Tutorial_3D` · A1 `(10,13)` · `array_flight_lab`

**Passage**

> “How do you reach an address above your head?”
>
> “Before entering, follow one vertical line with your eyes. Which part of the address changes as it climbs?”

**SOURCE**

`commons/artifacts/regularity/array_flight_lab.gd::_ready()`

```gdscript
enclosure.instruction_title = "FLY INTO THE THIRD INDEX"
```

`commons/movement/museum_flight_box.gd::_sign()` makes that title part of the large entrance instruction panel.

The map itself also carries the title `Fly into the third index`.

**Evidence type**

TEXT + SOURCE + CAPTURE

**Problem**

The text creates a good discovery question, but the large physical sign answers it before the visitor has entered the enclosure.

This is not a prose problem. Shortening the manuscript would make it worse.

**Artifact proposal**

Change the encounter-facing title to something that preserves the action without naming the abstraction, for example:

> **FLY TO AN ADDRESS**

or:

> **ENTER THE ARRAY**

Keep the flight-control instructions underneath.

The internal map title can remain technical if it is not visitor-facing; if it appears publicly, change it too.

**Reason**

The technical name will mean more after Y has visibly changed and the body has climbed through layers. Clarity does not require naming the concept before the visitor has something to name.

---

### 3.2 Tiling Floor / Walls / Disco — reduce the museum skin before rewriting the monochrome lessons

**Hall / instances**

- `Tutorial_Tiling_Floor` · A1 `(10,15)` · `tiling_principles#mode:floor`
- `Tutorial_Tiling_Walls` · A1 `(10,15)` · `tiling_principles#mode:walls`
- `Tutorial_Disco` · A3 `(9,13)` · `standalone_disco#width:12#depth:12...`

**Passage work**

These chapters deliberately reduce the motif to black and white so that changes of arrangement can be compared without colour becoming another variable.

Floor says:

> “We have limited the palette to make the arrangement easier to compare.”

Walls then holds the generator constant while changing orientation.

**CAPTURE / bundle status**

The supplied entrance/inside captures show bright magenta/cyan grid-wire architecture competing with the black/white fields, especially in `Tutorial_Tiling_Floor` and `Tutorial_3D`.

The bundle's own runtime note says:

> the latest regularity pass is unfinished; coloured grid wireframes compete with intended monochrome studies; floor images show interference; full architecture skins need visual verification.

**Evidence type**

TEXT + CAPTURE + HYPOTHESIS

**Artifact / environment proposal**

Before changing the prose, test a quieter museum presentation for the regularity sequence:

- neutral or low-contrast architecture material;
- reduced/suppressed coloured wireframe on immediate floor/wall surfaces surrounding the primary study;
- retain enough structural contrast for navigation and boundaries.

Do not automatically remove the whole museum identity. The target is hierarchy: **the monochrome rule should be the first strong regularity the eye encounters.**

**Reason**

The prose already makes the comparison clear. Adding verbal instructions to ignore competing visual structure would make the book compensate for staging that should be solved spatially.

---

### 3.3 Tutorial Disco — let the preview sound happen before explaining it

**Hall / instance**

`Tutorial_Disco` · A2 `(3,5)` · `step_sequencer:180:1.2:1.2#sound_preset:90s_house`

**Current text**

> “Find the sequencer's grid. Select the empty pattern and turn on one cell. Activating it previews its sound immediately. Let that preview finish, then start playback and predict when the moving playhead will reach the chosen column.”

**SOURCE**

`commons/audio/sequencer/step_sequencer.gd::_on_cell_toggled()`

```gdscript
func _on_cell_toggled(track: int, step: int, active: bool) -> void:
    if active:
        _play_sound(track)
```

The preview is real. The question is when to name it.

**Evidence type**

TEXT + SOURCE

**Proposed revision**

> Find the sequencer's grid. Select the empty pattern and turn on one cell. **Listen.**
>
> When the sound has finished, start playback. Predict when the moving playhead will reach the cell you chose. Compare the returning sound with the highlighted column.
>
> The first sound came when you switched the cell on: this interface previews an activated track. The returning sound came later, when playback read that stored cell. One address has already taken part in two different events.

**Reason**

This creates a small genuine discovery. The visitor hears something before the text tells them why. The explanation then becomes useful because there are two sounds to distinguish.

It also strengthens the room's central distinction between **writing state** and **reading state through time**.

---

### 3.4 Tutorial Disco — make track labels tell the truth about the selected sound preset

**Hall / instance**

`Tutorial_Disco` · A2 `(3,5)` · `step_sequencer...#sound_preset:90s_house`

**SOURCE**

`step_sequencer.gd` maps `90s_house` to:

```gdscript
[
    "TR909_KICK",
    "KORG_M1_PIANO",
    "ACID_606_HIHAT",
    "TB303_ACID_BASS"
]
```

But `sequencer_ui.gd::_create_ui()` hard-codes:

```gdscript
var track_names = ["Kick", "Snare", "HiHat", "Bass"]
```

`set_sound_preset()` updates the preset selector but does not update those track labels.

So in this placed encounter the second row can be labelled **Snare** while sounding a Korg M1 piano.

**Evidence type**

SOURCE

**Artifact proposal**

Either:

1. update track labels whenever the sound preset changes, using human-readable names for the loaded sources; or
2. use neutral labels such as **TRACK 1 / TRACK 2 / TRACK 3 / TRACK 4** unless a preset provides explicit semantic names.

The second option is safer if the purpose is primarily array/rhythm structure rather than instrument pedagogy.

**Reason**

This is exactly the kind of representational mismatch the manuscript is teaching the visitor to notice. It should be an intentional experiment if kept, not accidental UI misinformation.

The book wisely does not rely on the erroneous “Snare” name. Fix the artifact rather than adding a disclaimer.

---

## 4. Source / artifact discrepancies

### 4.1 Core collection behaviour cannot be independently source-verified from this ZIP

The first two halls depend heavily on the pickup cube:

- collection by bodily contact;
- cube disappearance;
- `tree_exiting` causing row/grid/volume state to change.

The scenes reference:

`res://commons/scenes/mapobjects/pick_up_cube.gd`

but that script is listed under `further_dependencies_not_traversed` and is not included.

`row_3_x.gd` and `grid_2d_4x4.gd` connect `tree_exiting` to their data update, but they do not establish what causes the cube to exit.

**Next bundle**

Include `pick_up_cube.gd` whenever pickup cubes are primary encounter mechanisms.

**Do not revise the manuscript on this basis alone.**

---

### 4.2 The binary table implementation is also missing

The manuscript relies on a live table in Array, including the claim that a particular row/column entry changes.

`row_3_x.gd` and `grid_2d_4x4.gd` call `binary_table.set_cell(...)`, but:

`res://algorithms/arrays/binary_table/binary_table_display.gd`

is not included in the snapshot.

The scripts support the intended data write, but the table's exact visible row/column behaviour needs the missing dependency or a runtime capture.

---

### 4.3 XR flight behaviour needs the missing provider

`museum_flight_box.gd` contains the enclosure and injects:

`res://commons/movement/museum_flight_provider.gd`

into XR player bodies.

That provider is listed as a dependency not traversed.

The manuscript's desktop controls are substantially visible in `museum_flight_box.gd::desktop_velocity()`. The exact VR claim—

> “the left stick follows the tilted left controller”

—should be verified against the missing provider and then in headset.

---

### 4.4 The sequencer's visible track names do not follow its sound preset

As described above, `90s_house` loads M1 piano on the second track while the UI continues displaying “Snare”.

This is a concrete source-level discrepancy in the configured primary encounter.

---

### 4.5 `DiscoSequencerBridge.gd`'s header comment overstates when floor pulses occur

Header:

> “On each sequencer step: pulse tiles to the beat.”

Actual connection:

```gdscript
step_sequencer.step_triggered.connect(_on_step_triggered)
```

and `StepSequencer._advance_playhead()` emits `step_triggered` only inside:

```gdscript
for track in active_tracks:
    _play_sound(track)
    step_triggered.emit(track, _playhead_position)
```

So the bridge receives **active-cell sound events**, not every silent playhead step.

The manuscript is more accurate:

> “The bridge briefly brightens a floor column when that step sounds…”

**SOURCE maintenance**

Change the bridge comment to something like:

> On each active sequencer event: pulse the corresponding floor column.

This avoids a future reviewer “correcting” accurate book prose to match an inaccurate source comment.

---

### 4.6 The old artifact identity prose is often stronger than the current book

Some source headers still make broad claims such as:

> “a 3D array is the minimum structure needed to represent volumetric space”

or describe an abstract array as if its physical placement “proves” what addresses essentially are.

The current manuscript is much more disciplined. It consistently says that addresses and values acquire their meaning through this particular representation.

Treat source identity comments as historical/design metadata, not statements the book needs to recover.

---

## 5. Runtime questions

No runtime execution was performed for this review. The included JSON checks and screenshots are dated evidence from a prior session, and learner verification remains `False` for all five halls.

| Hall | RUNTIME TEST |
|---|---|
| **Array — row** | Does bodily contact, rather than only manual grabbing, reliably remove the cube in XR and desktop? Does the `[i]` label disappear with it? Does the binary table change the intended cell exactly once? |
| **Array — grid** | With `notation:plate`, does the floor plate/card remain legible after the cube disappears? Does the binary table's row/column orientation match the manuscript's `[x,z]` explanation? Can a visitor relocate an empty off-diagonal slot without the cube? |
| **Tutorial 3D — visibility** | From the entrance, can a visitor read one vertical sequence of cube labels and infer which coordinate changes, or do 64 no-depth-test labels / architecture lines overwhelm the comparison? |
| **Tutorial 3D — flight** | Do desktop and XR controls actually hover neutrally, rise/descend as described, and release cleanly when exiting through either ground door? Is the flight volume boundary perceptible without feeling like an invisible locomotion mode switch? |
| **Tutorial 3D — collection** | Can the visitor select an address, fly to it, collect its cube, return to the console and still use the marker to locate the recorded absence? |
| **Tiling Floor** | Are all six fields distinguishable from the intended standing/viewing positions? Does the museum wireframe interfere with black/white figure-ground, especially at field boundaries? Can ONE EXCEPTION be found from a distance before approaching? |
| **Tiling Walls** | From the central aisle, can local tile detail and larger emergent figures both be perceived at different distances? Does the solid backing stop the body exactly where the visual panel suggests? Can the one exception genuinely function as a landmark? |
| **Disco — floor** | Does `disco_controls` reliably find only the floor in its own hall, disable the floor's autonomous processing, and make PLAY/HOLD, ONE STEP, PATTERN and SPEED visibly distinct? |
| **Disco — sequencer** | Are the 2D-in-3D cells comfortable to point at/toggle in XR? Is the empty pattern actually the initial state? Does activation preview the intended track sound before playback? |
| **Disco — clocks** | Can a visitor stop the sequencer while the controlled floor continues, then hold the floor while the sequencer continues, without another hidden state making the comparison ambiguous? |
| **Disco — bridge** | On active steps 1 and 13 (zero-based 0 and 12 if that is the UI convention), do flashes land on the same of twelve floor columns while the sequencer preserves distinct sixteen-step addresses? Is the flash visible long enough before the floor control repaints it? |
| **Disco — audio labels** | With `90s_house`, does the second row visibly say “Snare” while producing M1 piano? If so, decide whether to make labels preset-aware or neutral. |

---

## 6. What I would not cut

### Do not cut the row → grid comparison in Array

Both encounters record an occupant becoming zero, but they stage address differently.

The first asks the visitor to remember a slot whose visible tag vanished.

The second leaves a plate behind.

That is not repetition. It lets the reader discover that **address persistence is itself a representational decision**.

---

### Do not merge Tiling Floor and Tiling Walls

They deliberately hold the six tiling rules constant.

Floor investigates:

> repetition, motif, rule, exception, figure/ground.

Walls asks what happens when that same image enters:

> forward view, perspective, bodily obstruction, distance, landmarking.

The recurrence is the experimental control that makes the second room intelligible.

---

### Do not cut the Array callback inside Disco

> “This is the array room's question in another material: the slot remains available when its value changes.”

This is exactly the kind of recognition a sequence needs.

In Array:

> value 0 = recorded absence of a cube.

In Disco:

> value off = a silent event position that the playhead can still visit.

The return changes the medium and adds time.

---

### Do not cut the independent-clock comparison in Disco

The floor clock and sequencer clock initially appear to inhabit one audiovisual environment.

Stopping one and discovering the other continues is not explanatory redundancy. It breaks an easy causal assumption produced by the staging.

The room becomes more interesting because related events are **partly coupled rather than one system pretending to be two**.

---

### Do not reduce ONE EXCEPTION to a lesson about error

The text asks:

> “Does it read as a direction, an error, an opening?”

That is the right level of openness.

The code creates a local difference. Meaning remains available for use.

This is one of the sequence's clearest queer-method moments without needing to call itself queer.

---

## 7. Reader-experience strengths to protect

Several passages already do exactly what the new review lens asks for.

### Discovery before naming

**Array**

The cube disappears before the definition of an array arrives.

### Prediction before explanation

**Array**

The visitor predicts which table entry changes.

**Disco**

The visitor predicts when the playhead reaches a cell.

### Encounter before code

**Tiling Floor**

The visitor walks the fields and looks for relations before receiving the modulo rule.

### Same operation, changed meaning

**Floor → Walls**

The rule is held constant while the encounter changes.

### Mechanism increases attention rather than closing it

**ONE EXCEPTION**

Knowing the exception is one extra quarter turn does not answer whether it is an error, direction or opening.

### Representation becomes questionable through use

**Tutorial 3D**

A body can inhabit the neighbourhood of a stored zero without making the data wrong.

**Disco**

Sixteen source addresses become twelve visible destination columns.

These are strong Ada moments and should be used as models for later sequences.

---

## 8. Questions for the author

### 8.1 Should “third index” be discovered or announced?

The manuscript currently creates a discovery:

> which part of `[x,y,z]` changes when the cubes rise?

But the physical flight sign says **FLY INTO THE THIRD INDEX**.

If that phrase is intended as playful anticipation, keep it.

If the desired experience is discovery-first, rename the sign and let “third index” arrive after the vertical comparison.

My preference is discovery-first here.

---

### 8.2 Should the tiling-rule names be available on first glance?

The Floor text says:

> “Before reading their names, find two that seem related.”

But the six labels are physically present from the beginning.

Is the desired gesture simply “look before reading,” or would you actually like a first unlabeled comparison?

If the latter, an optional **NAMES** reveal could make the experiment stronger—but I would only add that control if runtime observation shows visitors immediately reading labels instead of comparing the patterns.

Do not add interface merely for theoretical purity.

---

### 8.3 Are instrument names part of the Disco lesson?

If musical identity matters, the sequencer's track labels should follow `sound_preset`.

If the primary lesson is address / state / timing, neutral **TRACK 1–4** labels may be more honest and less distracting.

The manuscript currently behaves as though track identity is secondary. That suggests neutral labels may fit the sequence better.

---

## 9. Overall conclusion

This sequence is small but structurally very strong.

It makes a clean transition out of Transformation: a single transformed object becomes **many indexed copies**, then the index becomes capable of organising a volume, an image, an architectural surface and a temporal score.

The manuscript already handles explanation timing better than many later sequences:

- action usually precedes definition;
- prediction precedes code;
- returns usually change medium or bodily consequence;
- the critical observations arise from actual representational limits rather than being added as commentary afterward.

The most useful work now is therefore not substantial cutting.

It is:

1. **protecting discovery from premature artifact labels;**
2. **making the monochrome studies visually dominant enough to perform their own argument;**
3. **repairing the sequencer's misleading preset-independent labels;**
4. **testing the bodily interactions that source alone cannot certify;**
5. **including the missing primary dependencies in future review bundles.**

The reader-experience principle I would carry forward from this sequence is:

> **Name the structure after the visitor has had one good chance to notice what needs a name.**

And the artifact principle remains:

> **When prose seems to be explaining too much, first ask whether the artifact is currently showing too little—or telling too much too soon.**
