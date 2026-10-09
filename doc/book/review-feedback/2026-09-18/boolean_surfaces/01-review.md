# Boolean Surfaces — 01 Review

Source-aware editorial and reader-experience review of the **Boolean Surfaces** sequence.

Basis: `boolean_surfaces-book.md`, `boolean_surfaces-review.md`, and the supplied ZIP snapshot on branch `palm-scanner-door-entry`, captured 2026-09-18. No repository code was executed.

This review uses two linked lenses:

1. **Structural / technical:** what the implemented encounter actually supports, what each return does in the sequence, and where source, registry, map, manuscript and embodied claim disagree.
2. **Reader experience:** where curiosity builds, where the visitor can discover something before it is named, where explanation arrives too early, and whether the better intervention belongs to the artifact rather than the prose.

Before proposing any cut, the review asks what technical, poetic, critical, or structural work the passage performs. In this sequence especially, an implementation defect can be valuable evidence without automatically becoming a universal claim about CSG, solids, interiors or architecture.

The three-hall route is coherent and the declared sequence order agrees with museum-authored order:

> **Boolean Verbs → Boolean Gallery → Boolean Works**

The current sequence has an unusual and potentially powerful arc:

> **operator → metadata audit → embodied affordance audit**

A second formulation is:

> **The same negative can be represented as a set operation, a published vocabulary, a visible cavity, or a bodily passage. Those are not the same claim. A Boolean operation can be technically correct while its documentation, material provenance, collision, interaction or architectural promise fails somewhere else.**

That is the strongest version of this chapter.

The main editorial risk is that the forensic voice sometimes converts **this implementation’s failures** into an ontology of boundary representation itself. The current source strongly supports a critique of the project’s CSG artifacts; it does **not** support every universal conclusion the manuscript currently draws from them.

---

# 1. One line per hall

| Hall | What carries it / main gap / next useful revision |
|---|---|
| **Boolean Verbs** | **Carries:** an extremely strong controlled opening: the same box/sphere pair is subjected to union, intersection and difference in three visible bays. The manuscript productively compares CSG union with the earlier smooth-field/metaball join, exposes intersection’s measurement as another representation, and makes difference’s newly generated cavity surface visible. The closing `the_argument_of_solids` correctly discovers that operand order adds another dimension the three-value operator enum does not encode. **Gap:** several passages overgeneralise from specific implementation choices. The three verb demos themselves do not enable collision, so the opening claim that their “inside” is an agreement with physics is not true of these placed objects. The cavity wearing the box material is caused by this demo’s root `material_override`, not by an unavoidable law of boundary models. And the rendered `CSGSphere3D` does have a radius parameter even though its tessellation differs from the analytic sphere used by the gauge. **Next:** keep the forensic argument, but rewrite the ontology as a representation audit: same radius/solid-set intention, different discretisations/material/collision layers. |
| **Boolean Gallery** | **Carries:** a rare and valuable documentation experiment: each four-value artifact family stands beside the published registry order that museum tooling actually consumes. The chapter correctly finds code/registry order drift, wildcard defaults masquerading as named rungs, one duplicated numeric fallback inside an anti-drift design, a schematic z-fight that is not itself rendered by z-fighting, and one runtime vocabulary checker. **Gap:** the visitor cannot discover most of this from the 24 bodies alone. The hall is effectively a source/registry **audit**, while its physical layout silently uses the registry it is auditing. Leaving production registry values intentionally scrambled also propagates the mismatch into other tools. **Next:** make AUDIT mode explicit and display **EXECUTOR ORDER / PUBLISHED ORDER** as first-class evidence; repair production registries after preserving the discrepancy as an audit snapshot. |
| **Boolean Works** | **Carries:** the hall asks the right escalation question: when the negative becomes architectural in scale, does it become an affordance? The source audit finds a systematic gap between labels/promises and implemented interaction—unpickable “workbench,” visual-only wall cuts, table-scale cavern, inert grab-wrapped catalogue, non-Boolean Menger omission, and fracture algorithms grouped under a Boolean heading. This is valuable. **Gap:** the manuscript currently lets the negative result become almost total: “you cannot” inhabit any of it, then closes toward “what you can walk through, you were always going to walk through.” That is a strong audit of the current hall but a weak final claim about Boolean construction. The source already contains a more promising path: `csg_architecture_cavity` has an `interior` axis capable of adding returning wall runs, but no map places it and no CSG root enables collision. **Next:** repair one architectural subtraction into a genuine embodied control—preferably `interior:room` with collision and a real doorway—then keep the current visual-only version beside it. Let the visitor discover exactly what extra work turns a Boolean image into space. |

---

# 2. Sequence structure

Boolean Surfaces is only three halls, but it changes narrator mode more radically than most sequences.

That should be made deliberate.

## 1. Boolean Verbs — Encounter / Tutorial

The first room is still recognisably an Ada tutorial.

It holds:

- operands mostly constant;
- one operator changes;
- each operator has a clear local consequence;
- earlier Isosurface/Metaball knowledge is available for comparison.

This room should establish the usable vocabulary:

- union;
- intersection;
- difference;
- non-commutativity;
- disconnected union;
- cavity generation;
- representation differences.

It should not yet claim that CSG as such cannot contain a meaningful interior.

## 2. Boolean Gallery — Audit

The gallery is not mainly teaching Boolean operations.

It is teaching that an artifact exists in several representations at once:

- source enum;
- registry vocabulary;
- map placement;
- catalogue/sweep order;
- captured still;
- runtime object.

Those representations can drift.

That is an important book-level method.

The gallery is strongest if openly named as an **audit of the museum’s own claims**.

At present the prose already behaves that way; the physical room does not yet give the visitor all the evidence needed to conduct the audit independently.

## 3. Boolean Works — Embodied Audit / Repair

The final hall raises the stakes:

> a visual cavity becomes a claim about space.

This is exactly the right final question after Isosurfaces/RhizomeBody:

- can the negative be entered?
- can the object be grabbed?
- does the wall collide?
- is the cavity at floor level?
- does the published variation change bodily experience rather than only a still image?

The current hall gives a mostly negative answer.

That is useful **as a control condition**.

It should not be the final state of the sequence.

The highest-value future form of Boolean Works is:

> current failed architectural claims  
> **beside**  
> one repaired Boolean space whose collision, entrances and body scale genuinely agree with its label.

Then the hall becomes an experiment rather than an autopsy.

---

# 3. Reader-experience lens

## Boolean Verbs

### Curiosity

The spatial setup is excellent:

> same pair of operands, same material family, same central line, one changed word.

This is a very strong controlled room.

The visitor can visually compare all three verbs without losing the others behind walls.

### Discovery

The strongest discoveries are:

#### Union

The `distinct` state is more valuable than the manuscript currently lets it be.

A union of disjoint sets is still a lawful union.

The result can have two connected components.

That means:

> **union does not mean fusion.**

The manuscript calls this rung “awkward” because it looks like a stack.

I would invert that reading.

It is the strongest proof that the operation is about membership in `A ∪ B`, not about producing one connected blob.

Then:

- `necked`;
- `lobed`;
- `single`

show connectivity/topology changing as the operand offset changes.

This is an excellent comparison with smooth union.

#### Intersection

The “correct result can be nothing” point is strong.

The volume instrument adds another representation:

- CSG display;
- analytic point-in-box/sphere sampling at 48³;
- ghost sphere at higher tessellation.

That difference is worth protecting.

The current text, however, overstates it when it says:

> “The sphere on the plinth has no radius.”

It **does** have `sphere_radius = 0.55`.

The important finding is:

> one radius parameter is interpreted through different representations with different discretisations.

That is more accurate and more aligned with the book’s recurring epistemology.

#### Difference

The cavity surface is a particularly good place to ask:

> where did this new face come from?

The source shows:

- sphere is subtraction operand;
- root has one material override.

So the cut surface gets the root/body material.

The manuscript correctly notices that the subtracting sphere did not bring a visible cavity material into the final body.

But the claim:

> “a boundary model leaves you no choice”

is too strong.

This **artifact** leaves itself one material at the root.

Other material/provenance policies are conceptually possible; the source does not prove otherwise.

The better lesson is:

> **a Boolean cut requires the implementation to decide how newly exposed boundary is represented. This implementation inherits the root body material.**

That is both precise and interesting.

### Timing

The current chapter moves into “What a solid is here” before the visitor has completed the three verbs.

That is the one place where explanation may arrive too early.

The ontology reads as a conclusion before the local evidence has accumulated.

A stronger reading order would be:

1. same operands / three verbs;
2. union disconnected/connectivity transition;
3. intersection representation discrepancy;
4. difference cavity/material;
5. then a shorter “what counts as a solid here?” synthesis.

You do not need to rewrite the whole hall now.

But if the sequence is later tightened, move the strongest ontological synthesis **after Difference**, not before Union.

### Return

Isosurfaces returns immediately:

> boundary representation is generated from a relation, not found as pre-existing matter.

Metaballs return through joining.

Architecture returns through passage claims.

Very strong.

---

## Boolean Gallery

### Curiosity

The physical concept is excellent:

> a family is not one object; it is a set of published allowed variations.

The visitor has seen only defaults elsewhere.

Here all four values stand up.

That alone is a powerful curation idea.

### Discovery

The strongest potential discovery is:

> the museum’s description of an artifact can disagree with the artifact’s own executor.

The current source provides several concrete kinds of disagreement:

- same values, different order;
- a named value implemented only through wildcard/default;
- borrowed ratios plus a retyped fallback literal;
- diagrammatic simulation of a failure rather than the failure mechanism itself;
- runtime self-checking vocabulary;
- comments that disagree with later implementation.

This is genuinely rich.

### Timing problem

The visitor cannot infer most of those discrepancies from the objects alone.

For example, the union band physically appears:

> `lobed, distinct, necked, single`

because the room is built from registry order.

The canonical source ladder is:

> `distinct, necked, lobed, single`.

Without another visible reference, the visitor sees only one order.

The book tells them it is wrong.

That makes the hall reader-dependent on forensic prose rather than discoverable through the room.

### Artifact proposal

Turn the audit itself into an instrument.

For each band, provide two small rails or labels:

> **PUBLISHED**  
> lobed → distinct → necked → single

> **EXECUTOR**  
> distinct → necked → lobed → single

For matching families, both rails coincide.

For mismatching families, disagreement is visible before prose explains why.

This is a better use of the gallery than leaving the production registry inconsistent merely so the room can exhibit its consequences.

### Production registry question

The current mismatch has value as history.

But the same registry feeds:

- gallery;
- sweep;
- deck;
- catalogue;
- other tooling.

Once the mismatch is understood, the production vocabulary should be repaired.

Archive the old published state as evidence.

Do not make ongoing metadata corruption the permanent artwork.

### Audit voice

This hall is where the forensic narrator belongs.

It should announce itself.

A small threshold text:

> **AUDIT — OBJECT / SOURCE / REGISTRY**

would solve a larger book-level narratorial problem.

The visitor understands that the museum has changed from:

> “here is how this operation works”

to:

> “here is how this project claims that its own operation works.”

That distinction is valuable.

### Return

Array/registry/address questions return at project scale.

The museum itself becomes the represented system.

This is a very strong conceptual move.

---

## Boolean Works

### Curiosity

The opening question is right:

> if a negative becomes large enough to stand in, can you stand in it?

This is exactly where the sequence should end.

### Discovery

The current hall supplies several negative findings.

They are useful, but they belong to different categories.

#### Workbench

Source claims:

> pick an operator with the catalyst bracelet.

Implementation contains:

- no input callback;
- no interaction signal;
- no bracelet reference beyond comments;
- only static rotating presets.

So the gap is **interaction**.

The `algebra` axis itself is interesting and real:

- triad;
- ordered;
- complete;
- atoms.

`complete` includes symmetric difference:

> `(A ∪ B) − (A ∩ B)`.

No current placement exposes it.

This is not a reason to condemn the algebra.

It is a reason to expose the axis or make the workbench genuinely selectable.

#### Subtraction Suite

The source’s claim that art/operator versions differ only by furniture/palette is undercut by:

```gdscript
art_mat.cull_mode = CULL_DISABLED
```

on one station only.

That is a real surface-rendering difference.

Excellent audit finding.

#### Sphere splitting

The hall title/placement invites a Boolean reading.

The source itself says the piece is about **five fracture algorithms**.

Only the CSG version uses CSG, and it uses intersection as a preprocessing/decomposition mechanism.

The chapter should keep this because it exposes another classification mistake:

> being in a Boolean hall does not make a work Boolean.

#### Recursive Boolean Cube

This is a particularly valuable anti-example.

The source:

```gdscript
if zeros >= 2:
    continue
```

never creates the “removed” cell.

No CSG subtraction happens.

The body still reads as if repeatedly carved.

That gives the sequence a powerful distinction:

> **negative form can be made by subtraction or by omission.**

This is not a lesser Boolean.

It is a different construction that produces a related appearance.

Protect it.

#### Architecture cavity

This is the artifact that most clearly shows where the sequence should go next.

The source already contains two axes:

**openwork**

- door
- sampler
- arcade
- screen

**interior**

- none
- corner
- court
- room

No map currently passes `interior`, so every existing placement remains `none`.

And no CSG root sets collision.

Thus the current hall shows a visual facade while the source already contains an unplaced **room topology**.

This is an extraordinary opportunity for an artifact-first repair.

#### SDF cavern

The source truth says:

> **CARVE THE FUNCTION, WALK THE HOLLOW**

But the artifact:

- has no collider;
- is lifted so the solid block’s bottom begins above the museum floor;
- has carved sphere centres/radii whose lowest air region does not naturally form a ground-level entrance;
- gently rotates the entire object, including its display floor.

The current book correctly sees a table model where the source label promises an inhabitable cavern.

Again, this is a specific implementation failure, not proof that implicit/Boolean cavities cannot be embodied.

#### Boolean variations

The object wraps each CSG result in the project’s pickable grab cube.

Then it replaces the grab-cube script with a generated `RigidBody3D` stability script.

So the pickable behaviour is removed.

This is a clean example of:

> **appearance of affordance ≠ affordance**.

The placeholder count is also real: many advertised variations route to another variation’s builder.

### Timing

The Works manuscript tells the entire failure story before the visitor has an opportunity to attempt some of these interactions.

For a reader, that is compelling.

For a museum visitor, it risks turning a potentially discoverable frustration into a narrated verdict.

I would preserve the book’s forensic detail but change the embodied staging:

- let visitor try workbench;
- let visitor walk into wall;
- let visitor approach cavern;
- let visitor reach for catalogue objects;
- only then expose the audit result.

This is exactly the sequence’s stated reader-experience method.

### Return

Everything returns here:

- collision;
- passage;
- grab;
- body scale;
- negative volume;
- representation versus affordance.

This can be a major sequence.

But it needs one positive repaired control.

---

# 4. Five high-value changes

## 4.1 Boolean Verbs — replace the universal “skin ontology” with a precise representation account

**Hall:** `Boolean_Verbs`

### Original

> “In this engine a solid is not a lump of material with an inside. It is a surface, and a rule for asking whether a point is on one side of it.”

> “The middle is an agreement between two systems — the renderer… and the physics…”

> “It is what a boundary model leaves you no choice about.”

> “The sphere on the plinth has no radius. It has twelve segments and six rings…”

### Evidence

**SOURCE**

The three primary verb scripts create CSG shapes but do not set collision/use-collision and do not create physics bodies.

The difference demo explicitly sets:

```gdscript
_root_csg.material_override = mat
```

which explains why the cavity receives the same body material in this specific artifact.

The intersection demo still has:

```gdscript
sphere_radius = 0.55
```

while its numeric instrument evaluates a mathematical sphere of that same radius on a 48³ sampling lattice and its ghost rendering uses a 24×12 sphere.

### Proposal

Replace the universal claim with something like:

> **These demonstrations use CSG primitives to define solid-set operations, but what we encounter visually is a generated boundary. In this hall the three verb objects do not enable collision, so their inside is not yet a bodily obstacle. The same radius parameter is also realised through several representations: a tessellated CSG sphere, a denser ghost sphere and an analytic point-in-sphere test used by the volume gauge. They agree on a parameter without becoming the same object.**

For Difference:

> **This implementation applies one material at the CSG root, so the newly exposed cavity surface inherits the body’s material. The cut therefore has to invent a visible boundary, and this artifact chooses to dress it as the body being cut. Another material-provenance rule would make another claim.**

### Reason

The current version turns excellent implementation evidence into claims the source does not support.

The proposed version actually strengthens the book’s recurring thesis:

> representation is productive and partial.

---

## 4.2 Union — reinterpret `distinct` as evidence that union does not imply connection

**Hall:** `Boolean_Verbs`  
**Artifact:** `csg_union_demo`

### Original

> “Which makes the first rung of its own ladder awkward.”

> “The artifact's stated desire is to show that joining is not stacking, and a quarter of its primary axis is a stack.”

### SOURCE

`fusion = distinct` resolves to an operand offset large enough that the box and sphere do not overlap.

Both remain children of one union CSG.

This is a lawful union of two disconnected sets.

### Proposal

Replace the “awkward rung” reading with:

> **The first rung is useful precisely because nothing fuses. Union does not promise connectedness. When A and B are disjoint, A ∪ B still contains both of them as two components. The word “joining” is therefore the misleading part: the operator combines membership before it combines space. Only when the operands meet does the connected-component count change.**

Then retain the comparison to metaball smooth union:

> **The same four visual states can therefore describe two very different mechanisms: one changes a blend relation continuously; the other changes overlap and connectivity without a smoothing band.**

### Reason

This avoids treating a mathematically informative state as an implementation embarrassment.

It also makes union more rigorous and less dependent on the metaphor of “fusion.”

---

## 4.3 Boolean Gallery — repair production registries and make the mismatch itself an explicit audit instrument

**Hall:** `Boolean_Gallery`

### Original

> “Walk this band left to right and you get `lobed, distinct, necked, single` — the registry's order…”

> “The argument is gone, because the argument was the monotonicity.”

### Evidence

**SOURCE / MAP**

Union executor:

```gdscript
["distinct", "necked", "lobed", "single"]
```

Gallery placement from registry:

```text
lobed, distinct, necked, single
```

Intersection executor:

```gdscript
["unanimous", "broad", "narrow", "token"]
```

Gallery begins with registry default:

```text
broad, unanimous, narrow, token
```

Coincident-face source:

```gdscript
["clear", "hairline", "coincident", "inverted"]
```

Gallery places the shipped failure/default first.

### Proposal

Do two things.

#### Production fix

Repair registry order where order is supposed to encode a conceptual ladder.

Do not leave stale/default-first order in production solely so the audit hall has something to expose.

#### Audit preservation

Store the old published order as an audit record and make both visible in the hall:

> **PUBLISHED ORDER**  
> lobed → distinct → necked → single

> **EXECUTOR ORDER**  
> distinct → necked → lobed → single

Matching bands show one aligned pair.

Mismatching bands visibly fork.

Add an explicit threshold sign:

> **AUDIT — OBJECT / SOURCE / REGISTRY**

### Reason

This makes the visitor capable of performing the audit instead of merely reading its result.

It also prevents a known metadata error from continuing to contaminate catalogue/sweep/deck tooling.

---

## 4.4 Boolean Works — build one genuinely inhabitable Boolean subtraction as a control

**Hall:** `Boolean_Works`  
**Artifact:** `csg_architecture_cavity`

### Original

> “The question this hall asks… when the negative gets big enough to stand in, can you stand in it?”

> “You cannot. Not in any of them.”

### SOURCE

`csg_architecture_cavity.gd` already has:

```gdscript
INTERIORS = ["none", "corner", "court", "room"]
```

and can build:

- front wall;
- one side;
- two sides;
- back wall.

No map currently configures `interior`, so all placements stay `none`.

No CSG root enables collision.

The shipped porthole also has its centre at y=1.4 against a half-height 1.3 wall, making it a top-edge scallop rather than a full porthole.

### Artifact proposal

Preserve the current visual-only wall as **CONTROL A**:

> **BOUNDARY IMAGE / COLLISION OFF / INTERIOR NONE**

Beside it, build **CONTROL B**:

- `interior:room`;
- `openwork:door` or corrected sampler;
- enable CSG collision on all runs;
- fix the porthole vertical placement if it is retained;
- verify the ground slab;
- ensure one real doorway aligns with floor;
- test body passage.

Label only after the visitor tries both:

> **same Boolean vocabulary, another bodily contract**

Optional later extension:

- `room + arcade`;
- `room + screen`.

### Reason

This is the sequence’s most important artifact-first intervention.

The current Works hall proves that labels and visual negatives do not create affordances.

The repaired control would show exactly **which additional relations** do:

- collision;
- enclosure;
- doorway placement;
- floor;
- body scale.

That is much stronger than ending with “Boolean negatives are pictures.”

---

## 4.5 Boolean Works — either implement the workbench affordance or rewrite the artifact identity; expose the dormant algebra axis

**Hall:** `Boolean_Works`  
**Artifact:** `csg_compose_workbench`

### Original source promise

> “stand at the bench… pick one with the bracelet, replicate the operation by hand.”

### Current source

No input handler, pickable, interaction volume or bracelet signal exists.

The artifact only:

- builds presets;
- rotates them;
- labels them.

But its `algebra` axis is conceptually rich:

- `triad`
- `ordered`
- `complete`
- `atoms`.

`complete` includes:

> `(A ∪ B) − (A ∩ B)`

and `ordered` places `B − A` beside `A − B`.

No current map configures that axis.

### Preferred artifact proposal

Make this a real **operator-set workbench**, even if freeform CSG editing remains deferred.

Add a simple physical/desk control:

> **ALGEBRA**

cycling:

1. triad;
2. ordered;
3. complete;
4. atoms.

Then, if feasible, allow the visitor to pick up **one static result** using the existing project pickable implementation without promising live operand composition yet.

Change the source identity from:

> “replicate the operation by hand”

to:

> **compare and select the operator-set representations; live player-built composition is not yet implemented.**

### Reason

The source already contains an excellent conceptual axis that is currently invisible in the museum.

Exposing it gives Works a positive interactive object immediately, while keeping the larger freeform-composition ambition honest.

---

# 5. Source / artifact discrepancies

## 5.1 The verb demos do not currently implement collision

No collision/use-collision logic appears in:

- `csg_union_demo.gd`
- `csg_intersection_demo.gd`
- `csg_difference_demo.gd`.

The manuscript’s opening account of renderer + physics agreement therefore does not describe these three placed objects as they currently exist.

This is the most important technical correction in Verbs.

---

## 5.2 Difference cavity material is an implementation choice

The root combiner receives one material override.

That is why cavity and exterior share material.

The source does not support the universal statement that a boundary representation must do this.

---

## 5.3 The visible CSG sphere does have a radius parameter

Intersection uses `sphere_radius`.

The important discrepancy is:

- same nominal radius;
- different tessellation/measurement procedures.

Do not replace representation critique with ontological denial of the parameter.

---

## 5.4 Union `distinct` is a lawful disconnected union

The source intentionally makes the operands disjoint under one union operator.

That is conceptually useful.

It demonstrates that:

> union ≠ connected fusion.

---

## 5.5 Intersection’s gauge is a separate analytic/sampled model

The `_volumes()` function evaluates:

- analytic axis-aligned box membership;
- analytic sphere membership;
- at 48³ cell centres.

That is not a measurement of the actual tessellated CSG mesh.

The manuscript correctly sees a representation difference.

The phrase “three spheres” is rhetorically useful but should be formulated as:

> three representations sharing the radius parameter.

---

## 5.6 Difference’s `centred` strike is implemented by wildcard/default

`_strike_fraction()` handles:

- raised;
- grazing;

and returns ZERO otherwise.

Thus `centred` works, but through fallthrough rather than an explicit branch.

The gallery’s forensic observation is source-supported.

---

## 5.7 Union registry ordering conflicts with source ladder ordering

Source:

> distinct → necked → lobed → single.

Gallery/map:

> lobed → distinct → necked → single.

This is real and affects physical reading order.

---

## 5.8 Intersection registry/default-first ordering similarly disrupts the source ladder

Source:

> unanimous → broad → narrow → token.

Gallery begins:

> broad → unanimous → narrow → token.

Again, this is a metadata/curation choice, not the operator’s own sequence.

---

## 5.9 Coincident Face is primarily a diagrammatic model of z-fight, not the renderer’s actual z-fighting behaviour

The visible contest band is made from alternating slivers:

```gdscript
color_a if i % 2 == 0 else color_b
```

The artifact does also place overlapping filled rectangles in the coincident setting, so there is a real coincident-depth condition behind the diagram.

The manuscript’s distinction is accurate.

Do not call the stripes themselves “pixel coin toss” without the diagram qualifier.

---

## 5.10 Removal Room’s header arithmetic is wrong for the Cantor-style scar implementation

The header generalises scar volume as:

> `0.22^3`.

But `_scar_size()` treats `third` differently:

```gdscript
Vector3(s.x, s.y * .22, s.z * .22)
```

so length is retained and only section is thinned.

The manuscript correctly notices this.

The file should fix its own header rather than leaving the contradiction indefinitely.

---

## 5.11 Compose Workbench has no implemented picking/bracelet affordance

The promise exists only in comments/identity.

The code builds static CSG presets and rotates them.

The `needs` line itself admits:

> live player-built composition surface missing.

Update identity or implement interaction.

---

## 5.12 Compose Workbench has a strong unexposed `algebra` axis

The source can display:

- triad;
- ordered;
- complete;
- atoms.

No current placement names this config.

This is a missed opportunity rather than a bug.

---

## 5.13 Subtraction Suite’s two stations are not actually identical in surface rendering

Art station:

```gdscript
cull_mode = CULL_DISABLED
```

Operator station does not receive the same setting.

The manuscript’s audit is source-supported.

---

## 5.14 Sphere Splitting Showcase is mostly not Boolean

It compares fracture/decomposition methods.

Only one approach uses CSG, and there it uses CSG intersection to construct cut pieces.

Its inclusion is valuable as a classification challenge, but the hall should not imply all five are Boolean methods.

---

## 5.15 Recursive Boolean Cube contains no Boolean operator

It omits cells according to Menger-like index logic.

The source itself says:

> boolean-like subtraction through recursive geometry.

That is the accurate phrase.

---

## 5.16 Recursive Boolean Cube is also the most deterministic/reproducible object in Works

No RNG is used.

That contrast is conceptually useful:

> procedural omission can imitate carving without CSG and still be perfectly reproducible.

---

## 5.17 Architecture Cavity has an unplaced `interior` axis

Source supports:

- none;
- corner;
- court;
- room.

The museum places none of these explicitly, so all current instances remain `none`.

This should be promoted.

---

## 5.18 Architecture Cavity has no collision

Neither the CSG roots nor ground use physics/collision.

The visually cut doorway therefore does not function as the distinction between wall and passage for the body.

This is exactly the hall’s current negative finding.

---

## 5.19 The shipped “porthole” is a top-edge scallop

`porthole_offset.y = 1.4`.

Wall half-height = 1.3.

The source itself documents this.

Fix if the object continues to call it porthole in an architectural comparison.

---

## 5.20 SDF Cavern Room is a table-scale visual model, not an inhabitable cavern

Source:

- block half-size 2.6;
- object lifted by 2.75 m;
- no collision;
- room floor belongs to display;
- whole object gently yaws.

The label:

> CARVE THE FUNCTION, WALK THE HOLLOW

overpromises the implementation.

The artifact can remain as a visual SDF subtraction model if relabelled, or be rebuilt bodily.

---

## 5.21 Boolean Variations wraps results in a grab scene then replaces the pickable script

The source explicitly replaces the wrapper script with a generated RigidBody3D stability script.

Thus the pick affordance is removed.

The collision remains a coarse 2 m box around much smaller displayed CSG.

The current manuscript’s critique is source-supported.

---

## 5.22 Boolean Variations contains many placeholder cases

Numerous variation indices route to another builder and are marked `# Placeholder`.

The advertised distinct-variation count is therefore larger than the implemented design vocabulary.

The gallery should not claim all 25 are distinct until this is repaired.

---

# 6. Curation findings

## Verbs

`the_argument_of_solids` is a manuscript anchor but not a primary role.

It now performs significant closing work:

- enum closure;
- reverse difference;
- operator set critique.

Consider promoting it to primary/coda role.

## Gallery

Only:

- `csg_difference_demo`
- `removal_room`

are in primary role order.

The manuscript treats all six families as essential audit bands.

This role metadata is stale relative to the current hall.

Promote all six families as audit primaries or introduce an `audit_family` role.

## Works

Only:

- `csg_compose_workbench`
- `sdf_cavern_room`

are primary in role metadata.

But the manuscript devotes major arguments to:

- subtraction suite;
- sphere splitting;
- recursive cube;
- architecture cavity;
- boolean variations;
- coincident face.

If the forensic Works chapter remains as written, these are not secondary ambience.

Update roles so automated source/capture review follows the actual manuscript.

---

# 7. Runtime questions

No repository code was executed. Every hall still records `learner_verified: false`.

| Hall / encounter | RUNTIME TEST |
|---|---|
| **Verbs — overall** | Can a visitor inspect the three operators from the central route without one rotating object/label dominating the others? |
| **Union — distinct** | Does the disjoint union visibly read as two connected components under one union result, supporting the “union ≠ connectedness” interpretation? |
| **Union — necked** | Does first contact produce the visible crease/discontinuous-normal effect the source describes, or does Godot tessellation obscure it? |
| **Intersection — numeral/gauge** | Compare displayed CSG body with the 48³ analytic/sample gauge. Are differences visible enough that “same radius, different representation” is perceptible rather than purely source-level? |
| **Difference — cavity material** | From inside the bite, does the root material genuinely make the cut surface visually continuous with the exterior under current renderer/culling? |
| **Verbs — collision** | Confirm that union/intersection/difference currently provide no artifact collision. If any museum wrapper supplies collision externally, record it before revising the “visual only” claim. |
| **Argument of Solids** | Is B−A visible/legible enough that visitors can discover difference non-commutativity before reading the closure critique? |
| **Gallery — physical order** | Walk each band left→right and verify the exact registry-derived order shown in space.json. |
| **Gallery — proposed audit labels** | Test whether paired PUBLISHED/EXECUTOR rails let a beginner understand drift without reading long source commentary. |
| **Gallery — coincident** | Does the genuine overlapping fill behind the alternating diagram actually z-fight on current hardware, or does rendering remain stable? |
| **Gallery — removal** | Does the runtime vocabulary checker produce any warnings/errors under current snapshot? |
| **Workbench** | Confirm no pick/bracelet interaction exists in the assembled museum despite any generic museum grab wrapper. |
| **Workbench — algebra** | Place/test triad/ordered/complete/atoms. Are B−A and XOR legible enough to justify exposing the axis? |
| **Subtraction Suite** | From the cavity mouth, does cull-disabled art station show inner faces while operator station culls them as source predicts? |
| **Sphere Splitting** | For each method, verify which actual script implements fracture after impact; the destructible `.gd` dependencies are not included in this bundle. |
| **Recursive Cube** | Verify current placement has no collision and behaves identically across repeated builds. |
| **Architecture Cavity — existing** | Confirm the current wall is entirely non-colliding and all museum placements remain `interior=none`. |
| **Architecture Cavity — proposed control** | With `interior=room` and CSG collision enabled, test door access, wall seams, internal collision, floor continuity and body clearance. |
| **Architecture Cavity — porthole** | After correcting vertical offset, confirm it reads as a full porthole rather than a top scallop. |
| **SDF Cavern** | Confirm no collider exists in assembled museum and that the lowest hollow remains above reachable floor level as the source geometry predicts. |
| **Boolean Variations** | Confirm whether any XR-tools interaction survives the script replacement at runtime. |
| **Boolean Variations** | Inspect its coarse 2 m collision box relative to the 0.1-scaled visible object; does the invisible collision volume create misleading contact even though picking is gone? |
| **Works — audit timing** | Let new visitors attempt reach/walk/grab before reading the failure text. Which failures do they discover independently? |

---

# 8. What I would not cut

## Do not cut the comparison with smooth/metaball joining

“Same four states, two ontologies of joining” is one of the best cross-sequence returns in the book.

Just make the CSG side precise:

> union changes set membership/connectivity without a smoothing parameter.

Keep it.

## Do not cut the `distinct` union rung

It is not an embarrassing stack.

It demonstrates that union can be disconnected.

This is technically useful.

## Do not cut the intersection measurement mismatch

The analytic/sampled gauge and tessellated display describe related but non-identical representations.

That is excellent Ada material.

Rephrase rather than remove.

## Do not cut the cavity-wall material observation

The cavity appearing in the body’s material is visually and conceptually strong.

Just locate the cause correctly in the root material policy.

## Do not cut B−A from the closure argument

Difference’s operand order is exactly the place where a “three verbs” vocabulary becomes incomplete as a complete expression grammar.

The hand-built reverse case is useful evidence.

## Do not cut the Gallery because it is “just metadata”

It is one of the few rooms where the museum can inspect its own documentation infrastructure.

That is valuable.

Make the audit physically legible.

## Do not preserve registry corruption forever merely because it became conceptually interesting

Archive the disagreement.

Fix the production system.

This distinction matters.

## Do not cut the wildcard/default rungs

They are important evidence about how names can become detached from explicit implementation.

But fix the source after documenting the finding.

## Do not cut Coincident Face because it is diagrammatic

A stable diagram of a hardware-dependent failure can be pedagogically better than forcing real z-fighting.

Keep the distinction:

> diagram of failure ≠ failure mechanism.

## Do not cut the Workbench’s XOR/atoms axis

It is a genuinely good idea:

> tooling primitives are not the same thing as the algebra we can derive from them.

Expose it.

## Do not cut Sphere Splitting merely because four methods are not Boolean

That mismatch itself asks a useful question:

> when is CSG a modelling operation inside another algorithm rather than the identity of the whole work?

Relabel the gallery relationship; keep the comparison.

## Do not cut Recursive Boolean Cube

It is a perfect anti-example:

> subtraction-like negative by omission rather than Boolean subtraction.

That distinction is central to the sequence.

## Do not cut the current failed Architecture Cavity

Once a repaired inhabitable control exists, the old non-colliding version becomes extremely useful evidence.

Keep both.

## Do not cut SDF Cavern’s current model form if a walkable version is built later

Again, it can become a control:

> visible hollow on a table  
> versus  
> body-scale navigable hollow.

That is better than pretending only one is legitimate.

## Do not cut the inert Boolean Variations rack

It is useful once the affordance failure is explicitly framed.

But it should not continue advertising itself as grabbable without either repair or visible audit label.

## Do not cut the Works hall’s negative finding

The finding is real:

> this project repeatedly promoted visual Boolean negatives before implementing bodily affordance.

That is important.

The change is to stop there being **only** negative evidence.

---

# 9. Reader-experience strengths to protect

## Discovery before naming

**Verbs**  
same operands / changed operator before theoretical synthesis.

**Intersection**  
empty result as a lawful result before a philosophical explanation.

**Difference**  
new cavity surface before source/material provenance is explained.

**Gallery**  
variant families before the registry/source disagreement is named—once the room provides both orders as evidence.

**Works**  
visitor reaches for, enters, or approaches promised affordances before audit text gives the verdict.

---

## Prediction before explanation

- Does disjoint union still count as one union result?
- What survives when the intersection approaches zero?
- Which material will the new cut face receive?
- Does B−A look like A−B?
- Which gallery band follows its executor order?
- Which “workbench” object can actually be picked up?
- Does a visual doorway stop the body?
- Is the cavern’s negative reachable from the museum floor?
- Which objects are really Boolean, and which only look subtractive?

These are excellent questions.

The Works hall currently answers too many of them in prose before the embodied attempt.

---

## Productive distinctions to protect

- union ≠ connectedness
- CSG union ≠ smooth field blend
- nominal radius ≠ one unique representation
- visual body ≠ measurement model
- newly exposed boundary ≠ previously stored interior wall
- operator set ≠ full expression grammar
- source vocabulary ≠ registry vocabulary
- published order ≠ executor order
- named rung ≠ explicitly implemented branch
- diagram of z-fight ≠ z-fight itself
- Boolean-looking hole ≠ Boolean subtraction
- fracture method ≠ CSG method
- visible doorway ≠ collision opening
- visual cavity ≠ inhabitable interior
- grab wrapper ≠ working pick interaction
- photographic variation ≠ bodily variation.

This list is the real Boolean Surfaces curriculum.

---

# 10. Questions for the author

## 10.1 Do you want this sequence to remain explicitly forensic?

I think yes.

The Gallery and Works manuscripts are too valuable to flatten back into ordinary tutorial prose.

But I would mark their narrator mode:

> **ENCOUNTER / AUDIT / EMBODIED AUDIT**

so the shift is intentional rather than a sudden change in the book’s voice.

## 10.2 Is “solid is a lie told by its skin” intended as a project-poetic proposition or a technical claim?

As poetry, it is strong.

As source-grounded technical description, it currently overreaches.

I would preserve a version of the line only after the manuscript has distinguished:

- solid-set semantics;
- generated boundary;
- material;
- collision.

Then the poetic sentence can return as interpretation rather than mechanism.

## 10.3 Should known registry disagreements be fixed after this review?

I recommend yes.

Preserve them as audit fixtures/snapshots, but do not let known bad order continue driving production tooling.

## 10.4 Which artifact should become the first actually inhabitable Boolean negative?

`csg_architecture_cavity` is the easiest conceptual candidate because it already has the `interior` axis and ground slab.

I would start there before rebuilding the cavern.

## 10.5 Do you want the CSG Compose Workbench to become a live composition tool?

If yes, that is a larger future project.

For the present sequence, exposing the already-implemented algebra axis and allowing selection/grab of fixed results would be enough to make it honestly interactive.

## 10.6 Is the current closing darkness the intended ending?

The last two paragraphs are powerful as an audit of the current project state.

Once one repaired embodied Boolean is added, I would change the final movement from:

> “the negative was supposed to become inhabitable; it became a sign”

to:

> **“Here is what the sign omitted; here is the extra machinery required before the negative becomes a place.”**

That would preserve the critique while restoring the sequence’s experimental forward motion.

---

# 11. Overall conclusion

Boolean Surfaces is one of the most intellectually distinctive sequences in the book.

Its unusual strength is that the source audit has become content.

The chapter discovers that a Boolean object exists in several overlapping systems:

- set/operator semantics;
- tessellated visual boundary;
- material policy;
- collision;
- interaction;
- registry vocabulary;
- catalogue order;
- captured still;
- map placement;
- visitor body.

Those systems can agree—and often do not.

That is a powerful Ada Research subject.

The sequence becomes weaker only when it converts those disagreements into universal claims too quickly.

The source supports:

> **this Boolean demo uses one root material;**  
not  
> **every boundary model must dress the cavity this way.**

It supports:

> **this CSG sphere and this analytic gauge realise the same radius through different representations;**  
not  
> **the rendered sphere has no radius.**

It supports:

> **this current architectural hall fails to turn visible negatives into bodily affordances;**  
not  
> **Boolean negatives cannot become inhabitable space.**

The highest-value revision strategy is therefore not to soften the forensic chapter.

It is to make the audit even more experimentally exact.

The strongest future sequence would be:

1. **Verbs:** learn the operations and their representation limits.
2. **Gallery:** audit object/source/registry disagreement with evidence visible in the room.
3. **Works:** encounter failed architectural promises, then compare one repaired Boolean negative whose collision, entrance and body scale actually agree.

That would turn the current “dark spot” into a method.

The highest-value work now is:

1. **rewrite Verbs’ universal skin/interior claims as precise representation-specific claims;**
2. **treat disjoint union as a useful lesson about connectivity, not an awkward failure;**
3. **repair production registry order while preserving old disagreement as an explicit audit artifact;**
4. **build one real inhabitable Boolean room using the existing `interior` axis plus collision;**
5. **make the Compose Workbench honestly interactive at the level it can currently support and expose its dormant algebra axis;**
6. **runtime-test the visitor’s actual failure/success sequence before the forensic text tells them the answer.**

The reader-experience principle I would carry forward from Boolean Surfaces is:

> **Let the visitor trust the hole once—then make them discover which layer produced the appearance, which layer produced the obstacle, and which layer was only a label.**

And the structural principle is:

> **A negative is not yet a place. Boolean syntax can define a region, but material, collision, enclosure, interaction and body scale decide whether that region becomes an inhabitable relation.**
