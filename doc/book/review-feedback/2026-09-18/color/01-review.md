# Color — 01 Review

Source-aware editorial and reader-experience review of the **Color** sequence.

Basis: `color-book.md`, `color-review.md`, and the supplied ZIP snapshot on branch `palm-scanner-door-entry`, captured 2026-09-18. No repository code was executed.

This review uses two linked lenses:

1. **Structural / technical:** what the implemented encounter actually supports, what each return does in the sequence, and where source, metadata, map, and manuscript disagree.
2. **Reader experience:** where curiosity builds, where the visitor can discover something before it is named, where explanation arrives too early, and whether the better intervention belongs to the artifact rather than the prose.

Before proposing any cut, the review asks what technical, poetic, critical, or structural work the passage performs. Recurrence is not treated as redundancy when an earlier idea returns through a changed body, medium, orientation, scale, or use.

The sequence now reads as:

> **assignment → illumination → embodiment → partition → field/sample → address/write → accumulation/history → mediation/representation → message/receiver**

A second formulation is:

> **Colour is not one datum moving unchanged through the chapter. It repeatedly changes role: assignment, condition, sample, addressable state, trace, partition and message.**

The manuscript is generally more technically cautious than several source headers/comments. Where those disagree, this review prefers the implementation and the current manuscript over stale source rhetoric.

---

## 1. One line per hall

| Hall | What carries it / main gap / next useful revision |
|---|---|
| **Color Context Placed** | **Carries:** a long, static promenade in which Primitives, Transformation and Arrays return as composition. The first groups hold variables still and vary colour rule, alphabet or pose; later groups loosen proportion and then introduce named/adapted compositions and associations. The 61 m hall and 23 primary stacks justify a longer chapter. **Gap:** the visitor-facing plates state the active rule before a first comparison has much time to become a discovery, and the prose names the chapter's “scientific and associative” thesis before the associative gallery has actually produced it. **Next:** preserve the density, but delay some naming rather than cutting the encounters. |
| **Color Flashlight** | **Carries:** one of the sequence's cleanest discovery structures. The visitor moves light first, notices a changed patch while material stays fixed, and only then receives `SpotLight3D`, albedo and RGB. The patch of colour becomes relational without turning the room into a physics claim. **Gap:** source contains its own `WorldEnvironment` and the museum contributes lighting too; source alone cannot certify the perceived overlap, brightness or shadow hierarchy in the live hall. **Next:** preserve the prose; runtime-test the actual museum lighting and pickable lamps. |
| **Color Nails** | **Carries:** an RGB coordinate becomes a bodily material choice, then scale separates “same recipe” from “same feeling.” The chapter carefully limits the identity claim: editable channels are one surface choice, not a complete body. **Gap:** the primary controller source clearly updates its preview plus the actual XR hand meshes when they can be found, and persists the choice through `GameManager`; the supplied snapshot does **not** include the secondary `nail_salon` implementation needed to verify the manuscript's stronger claim that the giant/petite display hands answer the same choice when tracked hands are absent. **Next:** verify/wire the display-hand relation rather than hedging the text prematurely. |
| **Color Rainbow** | **Carries:** celebration arrives before obedience; then a familiar arch survives different partitions. “Continuous” becoming 48 strips is an excellent computational discovery, and colours outside the sweep are physically present elsewhere in the room. **Gap:** not the book—the source comments still make stronger physical claims (“no seams”, “spectrum as it physically is”) that the current manuscript correctly refuses. **Next:** preserve the chapter; clean source commentary and runtime-test collision/celebration/readability. |
| **Color Pillar** | **Carries:** perhaps the calmest and clearest conceptual pivot: a field assigns values continuously while 35 pillars embody only samples. The palette wall then introduces assembled collections as another way to decide what belongs together. **Gap:** most of the work is perceptual: the floor shader and sampled pillars must visibly agree enough that “field versus sample” can be discovered rather than merely accepted. **Next:** preserve text; verify the gradient, labels and carryable wall swatches in the live hall. |
| **Color Grid Pallet** | **Carries:** sample becomes writeable state. Selection moves while stored colour stays; RULE then overwrites an exception without changing geometry. The room develops Arrays rather than merely repeating it: an address now holds a mutable colour and exposes asymmetry between visitor reach and rule reach. **Gap:** no major text/source contradiction found. **Next:** protect the sequence `select → write → leave → return → overwrite`; runtime-test marker/readout visibility and whether RULE's larger reach is bodily legible. |
| **Color Paint** | **Carries:** strongest curiosity opening after Rainbow: painting begins before the visitor acts. Manual and automatic motion enter one receiver; the surface preserves an image while losing separate gesture histories. The return to clocks from Disco/Trace is structurally meaningful. **Gap:** the main text makes a specific frame-dependent fading claim, but the ZIP omits the wet-paint shader that performs the actual feedback calculation; the artifact also gives no direct experiment for a beginner to distinguish “auto brush elapsed time” from “wet surface render updates.” **Next:** expose that distinction in the artifact or move the frame-rate consequence to the technical layer until it can be observed. |
| **Color Walls** | **Carries:** the revised transition is conceptually strong: first coloured space organises bodily passage, then colour values themselves are organised in space, then fixed endpoints admit different interpolation paths. “The agreement about where to begin and end did not decide how to travel” is an excellent return of Transformation/Trace. **Gap:** SPACE evidence places the RGB/HSV navigator and interpolator at lower z than the cubicle office; assuming the straight hall is traversed from the low-z entrance towards the far teleporter, the visitor physically encounters the models before the cubicles, opposite the manuscript's intended argument. Also, source comments/functions still say HSL in places while the actual construction is HSV. **Next:** verify route direction; if confirmed, restage artifacts to match the manuscript rather than undoing the new transition. |
| **Chamber Color** | **Carries:** the sequence closes by turning colour into a message whose consequence belongs to the receiver. One shot bundles tint, neighbourhood recolouring and geometric transformation; the unchanged collision then returns Walls' visual/bodily disagreement underfoot. **Gap:** the supplied source includes the mounted launcher and `mode_chromatic.gd`, but not the dynamically loaded `chromatic_projectile.gd` or the secondary `catalyst_target` implementation on which most of the manuscript's impact-radius, deformation, collision and three-hit/reset claims depend. **Next:** preserve the conceptual closure, but include those receiver/projectile sources and runtime-test the full shot cycle before treating the current draft as technically closed. |

---

## 2. Reader-experience lens

### Color Context Placed

**Curiosity**

The new opening gives the sequence a much better threshold than a conventional colour-theory definition:

> “Colour has been here all along.”

That is important. The visitor enters Color with a memory of forms already used rather than with a taxonomy of colour models.

The long sightline also does real poetic work. The entrance capture shows later, stranger stacks visible behind the first controlled comparisons. The room therefore promises that the simple experiment will proliferate.

The progression itself builds curiosity well:

- same geometry / different colour rule;
- same colour assignment / different alphabet;
- same alphabet / different pose;
- increasingly composed stacks;
- named/adapted art and design studies;
- a striped column;
- whole configurations becoming parts of taller configurations.

The room's length is not by itself a reason to cut. It corresponds to an actual developmental promenade.

**Discovery**

The best discovery is in the first four columns: colour can group unchanged geometry differently.

The next strong move is the fixed by-shape assignment carried across another alphabet. The cone and wedge sharing yellow makes classification inspectable without claiming the colour belongs naturally to a shape.

Later, the changing pose lets yellow become a visual thread across silhouettes.

The Kraš/rainbow column gives another kind of discovery: colour order repeats through modulo while associations remain external to the array.

**Timing**

Two things currently arrive early.

First, every `chroma_stack` builds a plate on its approach side. `_plate_title()` produces explicit titles such as:

> `BY HEIGHT · BAUHAUS`  
> `BY SHAPE · BAUHAUS`

and `_plate_body()` explains the rule:

> “the colour reads the height”  
> “the colour names the kind”  
> “each colour is the complement of the one below”

The entrance capture shows these plates prominently in the first field of view. The manuscript asks the visitor to follow a block and compare columns, but the artifact can answer the question before the comparison has generated it.

Second, the prose states:

> “Colour is deeply scientific and deeply associative.”

This is important structural work—it names the double attention the whole sequence wants—but it appears before the gallery names, memories and personal associations have had a chance to demonstrate the associative half.

Neither issue calls for deleting the material. They are timing issues.

**Return**

This hall earns its repeated references to Primitives, Transformation and Arrays. It is explicitly a synthesis room: familiar operations are no longer the subject but the means by which colour becomes compositional.

Do not compress those returns into a single retrospective paragraph.

---

### Color Flashlight

**Curiosity**

Excellent opening:

> “Pick one edge. Which lamp is responsible for it?”

The question is local enough to test and does not yet tell the visitor what additive light is supposed to look like.

**Discovery**

The visitor can:

- move red away;
- bring it across green;
- separate and overlap pools;
- introduce blue;
- later introduce white;
- point a lamp away from the board onto another receiver.

The sequence lets the visitor encounter appearance before technical naming.

**Timing**

This is one of the best-timed chapters in Color.

Only after moving the beam does the book say:

- receiving material stays fixed;
- lamp is a `SpotLight3D`;
- `light_color` is an RGB value.

The physical/spectral limit also arrives after an actual renderer encounter. It does not pre-empt the experience.

**Return**

Context introduced assigned material colour. Flashlight now holds the material and changes illumination. That is a genuine experimental contrast.

---

### Color Nails

**Curiosity**

The giant hand, tiny manicure table and petite hand produce an immediate scale puzzle before the RGB explanation begins.

> “Which of these bodies are you about to dress?”

is an effective question because the room contains several possible receivers.

**Discovery**

The visitor first moves one axis and predicts the channel change.

Then the same selected value can be compared:

- preview swatch;
- nail surface;
- hand surface;
- giant/petite geometry;
- potentially the visitor's tracked hands.

This is a strong progression from coordinate to material encounter.

**Timing**

The technical RGB explanation arrives at the right moment.

The identity paragraph also arrives late enough: the visitor has already exercised one available freedom before being asked which freedoms remain unavailable.

The reader problem is not timing. It is whether all of the promised receivers actually answer.

**Return**

Scale from Transformation returns with a new meaning. In Scale, a world became large relative to the player. Here two differently scaled bodies can receive the same colour recipe, allowing perceptual delicacy/monumentality to separate from the stored RGB value.

That is a meaningful return.

---

### Color Rainbow

**Curiosity**

The room does something rare and valuable:

> the room celebrates your arrival before you have demonstrated competence.

The confetti is not withheld as proof of success. That changes the emotional economy of the tutorial.

**Discovery**

A boundary is chosen first, then RE-DIVIDE changes its status.

The visitor can discover:

- band count changes while arch width stays fixed;
- geometry/passage stays available while the colour partition changes;
- “continuous” still has visible or potentially discoverable seams;
- room decorations contain colours the arch's HSV sweep does not.

The latter is especially strong: the representation's outside is already materially present in the same room.

**Timing**

The code arrives only after multiple repartitions.

The statement that four choices are pre-authored comes after the visitor has discovered variation; it therefore acts as a limit on freedom rather than as a disclaimer before play.

**Return**

Arrays return as list position assigning colour; Primitives return as mesh strips and triangles; Transformation returns as fixed geometry surviving another partition.

These returns are doing work.

---

### Color Pillar

**Curiosity**

The room does not ask the visitor to operate a machine first. It asks them to walk two directions and notice that different aspects of colour change.

That slower pace is useful after Rainbow.

**Discovery**

The visitor can discover:

- one direction changes saturation;
- another changes hue;
- pillars are discrete;
- floor continues between them;
- stepping back makes fixed sample values enter different visual company.

The palette wall then gives a second representation of collection that is visibly authored rather than evaluated from position.

**Timing**

The field equation arrives quickly, but only after the initial embodied walk.

“Each pillar is a sample” names something the visitor has already had a chance to perceive.

**Return**

Arrays/addressing return, but now an address queries a function rather than merely locating stored state.

This prepares Grid Palette well.

---

### Color Grid Pallet

**Curiosity**

The strongest opening action is:

> choose an address before choosing a colour.

That reverses the more ordinary colour-picker logic and puts the array relation first.

**Discovery**

The visitor can discover:

- selection moves;
- stored colour stays;
- returning to the address finds it again;
- RULE erases the local exception;
- the floor remains geometrically unchanged;
- palette can change without changing assignment form.

The line:

> “The white outline has travelled. Your exception has not followed it.”

is a concise perceptual conclusion, not an explanation substituted for one.

**Timing**

Very good.

The critical question—

> “Why should its reach exceed yours?”

—only arrives after the visitor has successfully made an exception and watched the general rule overwrite it.

That means the politics of permission grows directly from a technical asymmetry rather than being announced over a neutral grid.

**Return**

The original Array question returns in mutable form: a slot persists while what it stores changes.

This is one of the strongest cross-sequence callbacks.

---

### Color Paint

**Curiosity**

Excellent:

> “A painting is underway without your hand.”

The visitor arrives after agency has already begun elsewhere.

Then they intervene on a surface that refuses to wait for them.

**Discovery**

The visitor can discover:

- automatic and manual paths share a canvas;
- releasing a ball stops their contribution and returns it to its dock;
- another painter continues;
- marks persist but also transform/fade;
- returning after looking elsewhere reveals loss and accumulation.

The authorship question—

> “Which part of the image can you still call yours?”

—therefore emerges from an actual shared receiver.

**Timing**

The first technical explanation is well timed: the automatic path is exposed after the visitor has already observed and crossed it.

The wet-surface explanation also makes sense after marks have started changing.

The questionable timing comes at the frame-rate paragraph. It performs real technical and structural work: Disco introduced independent clocks, and here brush time and feedback time differ. But the current encounter gives the visitor no controlled way to observe the consequence of slower rendering. The explanation becomes knowledge supplied by the text rather than a distinction generated by the room.

This is a case for improving the artifact or relocating one technical paragraph—not for removing the idea.

**Return**

Trace returns through finite positional snapping.

Disco returns through independent clocks.

Albers then returns as a held comparison beside an accumulating one.

All three returns change meaning.

---

### Color Walls

**Curiosity**

The cubicle opening is excellent:

> “Your view took a route your body could not.”

This can be discovered bodily before transparency is named as the variable.

The GLASS / OPAQUE toggle then changes orientation/navigation without changing passage.

**Discovery**

The room potentially supports three distinct discoveries:

1. visibility ≠ traversability;
2. colour values can be spatial coordinates;
3. endpoints do not determine interpolation path.

The revised transition now makes those belong together:

> “You have been walking through an arrangement of coloured space. These models arrange colour values in space.”

That is strong enough that I no longer recommend splitting the room.

**Timing**

The prose timing is good.

The potential problem is spatial timing. The source plan places:

- `color_space_navigator` at `(18,10)`,
- `gradient_interpolator` at `(28,10)`,
- `color_constellation_office` at `(23,20)`.

The old map documentation places the next teleporter toward the far/high-z end. If the museum's straight passage is indeed encountered from low z toward that exit, a visitor meets the abstract models before the cubicle investigation, reversing the manuscript's intended discovery sequence.

This must be confirmed in a live walkthrough or spawn record before changing anything.

**Return**

Transformation returns strongly here:

> same endpoints / another path.

Primitives/Array return in colour-space sampling.

Body/Polyhedra returns in collision versus appearance.

This hall is a convergence point and should not be simplified just because it holds three experiments.

---

### Chamber Color

**Curiosity**

The mounted instrument starts with one remaining choice:

> when.

The first shot is allowed to produce a confusing bundle before the text separates it.

That is good reader timing.

**Discovery**

The visitor can potentially notice:

- flight appearance differs from delivered stored value;
- crate and nearby floor both change;
- participation has a radius;
- colour and geometry change together but not causally because one “causes” the other;
- rendered grid gaps do not become collision gaps;
- target returns while floor alterations remain.

This is an excellent sequence of consequences if the runtime encounter performs it reliably.

**Timing**

The random-hue code arrives after the first shot.

The distance rule arrives after a splash has already looked continuous.

The collision mismatch is named only after the visitor is asked to approach the changed floor.

All of this is well timed.

**Return**

Almost the whole Color sequence returns here:

- value;
- material;
- neighbourhood;
- address/grid;
- appearance;
- collision;
- persistence/reset.

The closing formulation—receiver decides what the value does—is earned.

Do not shorten the synthesis merely because many earlier concepts recur.

---

## 3. Four high-value changes

Four are sufficient. Several other issues belong in source maintenance or runtime verification rather than manuscript revision.

### 3.1 Color Context Placed — let the thesis arrive after the visitor has encountered both halves of it

**Hall / instances**

`Color_Context_Placed`

Primary promenade:
- A1–A15 `chroma_stack`
- A16–A23 `color_dna_stack`

**Work performed by the current passage**

The paragraph:

> “Colour is deeply scientific and deeply associative. We can ask how light, surfaces and vision make a colour available to us... We can also find ourselves remembering a room, wanting a garment, recognising a warning.”

is important. It states the methodological breadth of the entire sequence and prevents the technical material from pretending that a renderer value exhausts colour.

It should not be cut.

**Reader timing problem**

It currently appears immediately after the controlled rule/pose studies, before the named compositions and before the manuscript has actually invited memories, references or associations.

The visitor is told the chapter has two modes of attention before the second one has emerged from the hall.

**Editorial proposal**

Move that paragraph later—after the Mondrian/Albers/Memphis/Bauhaus discussion and preferably after the striped-column association passage:

> “If a Pride flag, a sweet wrapper or a fairground comes to mind, the array has not stored that memory...”

Then let the methodological paragraph name what has just happened:

> The value gave us one way to inspect the construction. The columns have now given us another kind of evidence: recognition, attraction, memory, association. Colour is deeply scientific and deeply associative...

Minor wording can be adjusted at that point; the conceptual content should remain.

**Artifact timing note**

`chroma_stack.gd::_add_plate()` also puts explicit rule titles and explanations on every stack:

- `BY SHAPE · BAUHAUS`
- `BY HEIGHT · BAUHAUS`
- etc.

and the plate body names the rule before the visitor has to infer it.

The entrance capture shows these plates prominently.

Before redesigning them, first observe learners. If they read plates before comparing the stacks, consider moving the rule explanation to the side/back of the object, shortening the first-facing plate, or adding a later reveal. If they naturally look at the columns first, no new control is needed.

**Reason**

This keeps the technical clarity while allowing the hall itself to generate the chapter's thesis.

---

### 3.2 Color Nails — verify or repair the promised receiver before rewriting the chapter

**Hall / instances**

`Color_Nails`

Primary:
- A5 `nail_color_controller:...#mount:salon`
- A6 `hand_color_controller:...#mount:salon`

Secondary:
- A4 `nail_salon`

**Current text**

> “Look up at the giant nails, then down at the petite hand on the table. Both answer the same choice.”

and later:

> “These two display hands remain available without tracked hands. They let you see a material change beyond the swatch...”

**SOURCE**

The supplied `nail_color_controller.gd` clearly does three things:

1. maps `ValueMapper3D` RGB values;
2. updates a preview swatch;
3. attempts to find the **actual XR hand meshes** under `XROrigin3D`, assigning material overrides to nails or skin.

It also writes the chosen colour to `GameManager`, explicitly for persistence across scene transitions.

The source snapshot does **not** include the implementation of the secondary `nail_salon` artifact. Therefore it does not establish that the giant/petite display hands actually listen to those choices.

**Artifact/source proposal**

Before changing the manuscript:

1. include the `nail_salon` source in the next snapshot;
2. verify whether both display hands subscribe to the saved nail/hand colour;
3. if they do not, wire them to the same state/signal used by the controllers.

If the intended experience is that only XR hands change, revise the manuscript instead. But artifact repair is preferable because the scale comparison between giant and petite receivers is conceptually valuable and already staged.

**Runtime extension**

Also test whether the selected hand/nail colour actually persists visibly into Rainbow in VR. The controller source intends persistence through `GameManager`. If that works, “carry one of those chosen colours toward the rainbow” can become a literal bodily continuity rather than only a metaphorical transition.

**Reason**

This is a case where shortening or hedging would remove a strong embodied comparison that the artifact may simply need to finish implementing.

---

### 3.3 Color Paint — either expose the second clock or move its consequence to the technical layer

**Hall / instance**

`Color_Paint`

A3:
`ball_painting_demo:0:0.5#automated:true`

**Current text**

> “The automatic brush advances by elapsed time. The wet surface updates with rendered frames. Even their clocks differ. A slower rendering pace can change how much the image has faded during the same time on your watch. The computer's ability to keep up participates in what the painting becomes.”

**Work performed**

This is not incidental optimisation detail.

It returns to the independent-clock problem from Disco in a new material:

- the automatic brush uses accumulated `delta`;
- the receiver is a feedback simulation;
- two processes can occupy one picture without sharing the same temporal basis.

It also makes computation itself part of the material condition of the image.

So the idea deserves to remain somewhere.

**SOURCE**

`ball_painting_automation.gd::_process(delta)` advances `elapsed` and emits strokes at an approximately 30 Hz gate.

`wet_paint_canvas.tscn` uses a `SubViewport` with `render_target_update_mode = 3` and a fixed shader parameter:

`dissipation = 0.995`.

However, the shader actually applying dissipation,

`res://algorithms/color/drawing/wet_paint_simulation.gdshader`,

is listed among dependencies not traversed and is absent from this ZIP. Therefore the quoted shader line and exact frame-rate consequence cannot be independently source-verified from this snapshot.

The room also gives the beginner no deliberate control that isolates this clock difference.

**Proposal**

Choose one of two routes:

**Preferred artifact route:** give the wet receiver one minimal comparison control, e.g. **WET HOLD / WET RUN**, while the automatic brush continues. The visitor could then see that mark arrival and receiver evolution are separable operations before reading about two clocks.

Or, if such a control would distort the artwork:

**Editorial route:** keep the explanation of the wet surface in the main chapter, but move the specific frame-rate consequence to the technical chapter until the shader is included and the distinction can be tested.

**Reason**

The concept is valuable. The current difficulty is not excess text but an explanation outrunning what the encounter lets a beginner discover.

---

### 3.4 Color Walls — preserve the new conceptual order by checking and, if necessary, changing the spatial order

**Hall / instances**

`Color_Walls`

Primary:
- A3 `color_space_navigator` at `(18,10)`
- A4 `gradient_interpolator` at `(28,10)`
- A5 `color_constellation_office` at `(23,20)`

**Current manuscript order**

1. cubicle office;
2. leave the cubicle;
3. RGB cube / HSV cylinder;
4. interpolation bench.

This is conceptually excellent:

> coloured space organising the visitor  
> → colour values organised in space  
> → path through a colour representation.

**SPACE / HYPOTHESIS**

The authored coordinates place the abstract models at lower z than the office.

The map documentation puts the next teleporter toward the far/high-z end and describes a straight passage. If the live museum spawn enters from the low-z side, the visitor meets the colour models before the cubicles, reversing the manuscript's intended discovery sequence.

Source plans do not prove the actual visitor spawn or route.

**Proposal**

First perform a walkthrough / spawn check.

If the visitor indeed encounters A3/A4 before A5, change the **placement**, not the manuscript. Stage the office first along the entrance-to-exit path, then the navigator/interpolator.

Do not revert the prose to the older “two unrelated halves” structure simply to match an accidental spatial order.

**Reason**

The revised transition—

> “You have been walking through an arrangement of coloured space. These models arrange colour values in space.”

—solves a major conceptual issue. The architecture should support that sentence.

---

## 4. Source / artifact discrepancies

### 4.1 `color_dna_stack` dynamically loads data that is not included in the snapshot

`color_dna_stack.gd` reads:

- `commons/artifacts/color_dna_stack/studies.json`
- `commons/artifacts/color_dna_stack/configs/<source>.json`

through `FileAccess`.

Those files are not included in this ZIP's static snapshot.

As a result, the source package cannot independently verify several exact manuscript claims about the later DNA columns:

- which primitive-stack configurations make the Mondrian/Albers/Memphis/Bauhaus studies;
- exact height adaptations;
- the Kraš shaft's stripe count and palette;
- how the combined crown/beacon parts are assembled.

The two included captures support the existence and broad visual form of the rainbow column, but not every numerical/configuration claim.

**Next bundle**

Teach the exporter to include known dynamic `FileAccess`/JSON dependencies for primary artifacts, or explicitly list these files in the source manifest.

---

### 4.2 `rainbow.gd` comments overclaim what the current book correctly limits

The `continuous` branch says:

> “No seams at all — the spectrum as it physically is, cut only by the resolution of the mesh.”

But the implementation creates exactly 48 entries using:

```gdscript
Color.from_hsv(t * 0.78, 1.0, 1.0, 1.0)
```

and the current manuscript correctly says:

> “The option called `continuous` still makes forty-eight strips.”

The artifact is not spectrally simulating physical rainbow wavelengths.

Similarly, top-level identity comments describe physical double-rainbow accuracy and “a rainbow has no location” while the placed `stage:celebration` deliberately instantiates a small, opaque, solid-looking, unshaded authored arch.

**SOURCE maintenance**

Update the comments to distinguish:

- legacy atmospheric rainbow study;
- celebration-stage authored HSV band construction.

The manuscript should remain as cautious as it is.

---

### 4.3 `color_space_navigator.gd` calls the companion HSL in source naming while implementing HSV

The actual construction uses:

- hue around the cylinder;
- saturation as radius;
- value as vertical coordinate;
- `Color.from_hsv(...)`.

Its visible title is correctly:

> `HSV Cylinder`

and the manuscript correctly calls it HSV.

But source names/comments still include:

- `_build_hsl_cylinder`
- `_create_sample_points_hsl`
- “HSL companion model”
- `show_hsl_cylinder`

**SOURCE maintenance**

Rename those comments/functions/config concepts when convenient, or explicitly document that the legacy identifier `hsl` now contains HSV behaviour.

Do not change the book to “HSL.”

---

### 4.4 The Paint shader is a missing primary dependency

`wet_paint_canvas.tscn` references:

`res://algorithms/color/drawing/wet_paint_simulation.gdshader`

but the file is outside the two-hop snapshot.

The manuscript quotes and interprets the shader's dissipation operation, so this dependency is primary evidence for the chapter and should be packaged.

---

### 4.5 Nails depends on an unbundled secondary artifact for one of its main manuscript comparisons

The primary controllers are present.

The visible giant/petite display-hand claim depends on `nail_salon`, which is secondary in the map and absent from `sources/`.

Because the manuscript makes the display hands part of the main encounter, source export should follow the **manuscript dependency**, not only role classification.

---

### 4.6 Chamber Color lacks the receiver and projectile sources on which most of its chapter depends

The package includes:

- `becoming_catalyst.gd`
- `chromatic_study.gd`
- `mode_chromatic.gd`

This establishes:

- mounted rather than wrist-based operation;
- `FIRE COLOUR`;
- fixed aim toward a discovered target;
- `randf()` hue choice;
- launch/readout.

But `mode_chromatic.gd` dynamically loads:

`chromatic_projectile.gd`

and that file is only listed under further dependencies.

The placed `catalyst_target` is a secondary artifact and its implementation is also not included.

Therefore this snapshot does **not** independently verify the manuscript's central receiver claims:

- glow cycling while stored colour remains unchanged;
- distance-based hue shift;
- 1.5 m impact neighbourhood;
- visual scale/rotation/displacement;
- unchanged collision;
- three-hit disappearance;
- four-second return;
- target reset while grid remains altered.

**Next bundle**

Include both projectile and target sources whenever the chapter's main argument depends on their interaction with a primary launcher.

---

### 4.7 Source identity rhetoric in several Color artifacts is stronger than the manuscript

Examples include claims such as:

- colour “as identity”;
- a colour “is a position” because a navigator “proves” it;
- the rainbow as a physical spectrum;
- colour mixing “proven by architecture.”

The current manuscript has moved beyond that rhetoric. It consistently says:

- *this implementation maps a value this way*;
- *this representation makes a relation available*;
- *the renderer does not calculate wavelengths*;
- *another receiver or model could behave differently*.

Protect that development. Source headers should be cleaned over time rather than used to re-strengthen the prose.

---

## 5. Runtime questions

No repository code was executed. All nine halls still show `learner_verified: false` in the review state.

| Hall | RUNTIME TEST |
|---|---|
| **Context — first comparisons** | From the actual entrance, do visitors look at the four stacks before reading their plates, or do `BY SHAPE / BY HEIGHT / BY NEIGHBOUR` answer the experiment first? Which details are legible at the authored spacing? |
| **Context — promenade** | Does the 61 m hall sustain a sense of progression, or do 23 stacks become visually equivalent? Are the later DNA names/plates readable at useful moments rather than from too far away? |
| **Context — art DNA** | Verify the exact Kraš stripe count, heights and compound-study construction against the dynamic JSON configs not included in this bundle. |
| **Flashlight** | Can each lamp be comfortably picked up/aimed in XR? Do overlapping pools remain distinguishable under the museum lighting plus the artifact's own `WorldEnvironment`? Does the white lamp start sufficiently aside to preserve the first RGB comparison? |
| **Nails — mapper** | Does one-axis movement reliably read as one RGB-channel change to a beginner? Are equal-distance movements perceptually unequal enough to make the manuscript question meaningful rather than obscure? |
| **Nails — receivers** | Do giant/petite salon hands actually change with the primary controllers? Do tracked XR hands update nails/skin on both left and right meshes? What happens on desktop? |
| **Nails — persistence** | Does a selected nail/hand colour remain visible after leaving the hall, as intended by `GameManager` persistence? If so, can the visitor literally carry it into Rainbow? |
| **Rainbow** | Does entering the welcome patch reliably trigger celebration for XR/desktop museum bodies? Does RE-DIVIDE cycle 6→7→48→2 as intended? Are seams in the 48-strip mode visible at any useful distance? Is the arch non-colliding while the low candy steps remain walkable? |
| **Pillar** | Does the shader floor visibly agree with the pillar samples at their positions? Are the 5×7 labels legible without overwhelming the field? Can wall swatches be picked up and carried back toward pillars? |
| **Grid Palette** | Does the white selection marker sit clearly over the intended cell? Does X+/Z+ wrap the 5×5 visitor selection correctly? Does RULE visibly rewrite the user's exception while preserving floor collision and geometry? Is the distinction between the 5×5 editable region and the larger rule-covered interior evident? |
| **Paint — automatic/manual** | Is the automatic line already visibly changing on arrival? Do manual balls paint only while picked up and reliably return to their docks on release? Are differences in brush size and snap resolution noticeable rather than merely random variation? |
| **Paint — wet receiver** | Does fading/flow occur at the rate described? Verify the missing shader source. If framerate is reduced, does wall-clock fading change measurably? If this matters to the main text, create a reproducible comparison rather than relying on inference. |
| **Walls — route order** | Record the actual spawn and natural walking order. Does the visitor meet navigator/interpolator before the cubicle office despite the manuscript's office-first structure? |
| **Walls — office** | Does GLASS/OPAQUE change only material visibility while every partition collision and each 1.2 m entrance remains unchanged? Can the visual route/body route disagreement be felt without accidental alternate gaps? |
| **Walls — colour models** | Are 500 RGB and 500 HSV sample points readable as finite samples rather than visual fog? Does the brightened black corner remain identifiable? |
| **Walls — interpolation** | With red/blue endpoints, does RGB/HSV switching visibly produce the expected darker RGB versus bright-magenta HSV middle under the live renderer? |
| **Chamber** | Verify the full three-shot cycle from mounted FIRE COLOUR through projectile, target, grid mutation, collision mismatch, disappearance, four-second return and non-restored surrounding grid. Confirm whether the launcher readout and visual projectile make stored hue versus flight glow legible. |

---

## 6. What I would not cut

### Do not shorten Color Context merely because it is the longest room

At 1,190 words it is almost twice many later halls, but it also contains 23 primary stacks across a 61 m promenade.

More importantly, the repetitions are controlled comparisons:

- same geometry / different colour rule;
- same assignment / different alphabet;
- same alphabet / different pose;
- richer proportions;
- named/adapted compositions;
- repetition around a shaft;
- whole configurations becoming parts.

The editorial task is **timing and hierarchy**, not arbitrary compression.

---

### Do not cut the “scientific and associative” thesis—move it

That paragraph is one of the sequence's key methodological statements.

Its problem is that it arrives before the associative evidence.

Let the gallery produce memory/recognition first, then name the double attention.

---

### Do not simplify Flashlight by replacing the renderer caveat with a colour-theory slogan

The room's strength is exactly that it says:

> this is RGB light in this renderer, on this chosen surface, under other illumination.

That care should remain.

---

### Do not reduce Nails to “RGB picker”

The giant/petite comparison, tracked-hand possibility and explicit limit on bodily editability are what prevent the room from becoming a generic interface tutorial.

If the receivers are not currently linked, improve the linkage.

---

### Do not cut Rainbow's celebration material as decoration

The confetti, level path, mushrooms and repeated CELEBRATE button perform critical work.

They establish that the visitor does not have to solve the formal problem to be welcomed into the room.

That changes the meaning of the later control over partition.

---

### Do not separate Pillar → Grid Palette → Paint

This is one of the strongest three-room chains in the book:

> **field sampled at positions**  
> → **address holds a mutable value**  
> → **surface accumulates writes while losing separate histories**

The recurring address is developing, not repeating.

---

### Do not cut the return to “company” in Grid Palette

> “The room where colour needed company has followed us here.”

This is a good recognition line.

The stored value really is numerically shared by swatch and floor cell while appearance remains relational.

---

### Do not remove the independent-clock idea from Paint simply because it is difficult

It connects Array/Disco, Trace and Change.

The issue is that the present artifact does not yet make the distinction experimentally available enough for a beginner.

Expose it or relocate its most specific consequence; keep the conceptual thread.

---

### Do not split Color Walls yet

The revised transition gives the room a strong internal argument:

> **coloured architecture**  
> → **colour represented as architecture/coordinates**  
> → **journey between colour values**

The more urgent issue is whether spatial placement delivers that order.

Fix the room before splitting the chapter.

---

### Do not shorten Chamber's closing synthesis

> “Across Colour, a value has needed a lamp, a nail, a neighbour, an address, a surface, a view. Now it arrives as a message, and the receiver decides what to do with it.”

This is a real sequence conclusion, not a recap for its own sake.

Each noun corresponds to a different operational role colour has acquired.

The manuscript has earned the list.

---

## 7. Reader-experience strengths to protect

### Discovery before technical naming

**Flashlight**

Move beams before `SpotLight3D` and albedo arrive.

**Rainbow**

Re-divide before band construction/code arrives.

**Grid Palette**

Write and return before storage is explained.

**Paint**

A painting is already underway before the visitor is told how.

**Chamber**

One shot produces a bundled result before the text separates operations.

---

### Prediction before explanation

**Nails**

Move one RGB axis, predict the next change.

**Rainbow**

Track a boundary before RE-DIVIDE.

**Pillar**

Walk directions before reading the field equation.

**Walls**

Look through the pane, then discover bodily route disagreement.

---

### Returns that change meaning

**Primitives / Transformation / Arrays → Context**

Earlier tools become compositional vocabulary.

**Transformation → Nails**

same value, different bodily scale.

**Arrays → Rainbow / Grid Palette**

list/address becomes colour assignment.

**Trace → Paint**

finite samples return as drawing resolution.

**Disco → Paint**

separate clocks return in a wet surface.

**Transformation → Walls**

same endpoints, different path.

**Polyhedra / Body → Walls / Chamber**

visible surface and bodily/collision account can disagree.

---

### Mechanism that increases rather than closes attention

**Rainbow**

Knowing “continuous = 48 HSV strips” gives the visitor seams and exclusions to inspect.

**Pillar**

Knowing the field equation gives a reason to look between samples.

**Grid Palette**

Knowing the modulo rule reveals the diagonal organisation and makes exception/overwrite more interesting.

**Chamber**

Knowing that multiple operations are bundled behind contact makes the resulting splash less self-evident, not more.

---

## 8. Questions for the author

### 8.1 How much discovery do you want before the Context plates are read?

The current plates are technically useful and visually substantial.

But they often state the rule the prose is asking the visitor to infer.

I would not automatically hide them. First watch several visitors.

If they consistently read the answer before comparing columns, then the plate's **timing**, not its content, needs work.

---

### 8.2 Is bodily colour meant to persist beyond Nails?

The primary controller source explicitly saves nail/hand colours through `GameManager`.

If this is intended to remain visible across halls, it is a powerful sequence-level device: the visitor literally carries a colour choice into Rainbow, Pillar and beyond.

If it is merely legacy persistence, the book should not build on it.

This is worth deciding deliberately.

---

### 8.3 Is the frame-dependent wet-paint behaviour part of the main Color research question?

If yes, give the visitor a way to compare it.

If no, keep the independent-clock distinction but move the specific rendering-performance consequence into technical documentation.

---

### 8.4 Is Color Walls intended to be walked office-first?

The manuscript now strongly benefits from that order.

If the current physical route gives navigator/interpolator first, I would change the room rather than the text.

---

### 8.5 Is `Biome_Ladder_Color` a coda/threshold?

Declared sequence ends at Chamber Color; museum-authored order appends `Biome_Ladder_Color`.

This repeats the pattern found after Primitives and Transformation.

If these ladder maps are intentional thresholds between curricular sequences, encode that as a distinct curricular role rather than leaving them as unexplained order mismatches.

---

## 9. Overall conclusion

This Color sequence has changed substantially from the early draft.

Its strongest development is that it no longer treats “colour” as a stable property awaiting explanation. Instead, the same familiar word repeatedly acquires a different operational role:

- a material assignment;
- a contribution of illumination;
- an editable bodily surface;
- a partition of a familiar order;
- a sampled field;
- mutable state at an address;
- an accumulating image;
- a spatial coordinate system;
- an interpolated path;
- a message whose receiver determines its consequence.

That is a coherent Ada argument.

The sequence also handles reader discovery particularly well in Flashlight, Rainbow, Grid Palette, Paint and Chamber: an event happens or a relation is noticed before the code names it.

The places that need work are therefore not primarily places with too much prose. They are places where:

1. **the artifact tells the answer too early** — Context plates;
2. **the promised receiver may not yet be wired** — Nails;
3. **the text names a technical consequence that the visitor cannot yet test** — Paint clocks;
4. **the room may physically stage the argument in the opposite order from the manuscript** — Walls;
5. **the source snapshot omits dynamically loaded pieces needed to verify the book** — Color DNA, Paint shader, Chamber projectile/target.

The reader-experience principle I would carry forward from Color is:

> **Let colour change something first. Name what kind of change it was second.**

And the artifact principle remains:

> **When the prose seems to be doing too much explanatory work, ask whether the room is revealing the relation at the right time.**
