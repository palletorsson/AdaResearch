I’ve now done the source-aware pass on Transformation using the ZIP, without executing the project. The sequence is unusually coherent: the primary manuscript encounters and primary-role order agree almost everywhere, and the repetition of translation/rotation/scale is mostly **developmental recurrence**, not redundant explanation. The sequence intention itself is accurate: learn what each operation preserves, then ask how a changed relation alters passage for a body. 

The package also confirms that **none of these halls has recorded learner verification yet**, so source-supported behaviour and embodied success still need to be kept distinct. 

## 1. One line per hall

| Hall                   | What carries it / main gap / next useful revision                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Trans Pre**          | **Carries:** technical vocabulary arrives through cumulative addition rather than definition alone: collectible but still → translate → add rotation → add scale → finished pickup. Importantly, source makes the three demonstration cubes non-collectible while the first and later level cubes remain collectible, so “collection” and “transformation” really are separate operations. **Gap:** none substantial. **Next:** preserve the simplicity; runtime-test that a beginner actually notices the cumulative additions before approaching the final level.                                                                                                                             |
| **Trans Introduction** | **Carries:** transforms stop being properties to identify and become ways of making passage; MOVE THE BANK then holds the rotation constant while changing its surrounding agreement. “The crossing has lost one of its agreements” is the room's central discovery.  **Gap:** the core `tc/sc/rc` utilities are central to the text but their implementation sources are not included in this ZIP, so the quoted rider/collision behaviour cannot be source-verified from the supplied snapshot. **Next:** don't shorten the prose; verify the crossings in runtime and include utility implementation sources in future review packages.                                                      |
| **Trans Translation**  | **Carries:** axis directions become bodily journeys, then the door study distinguishes destination from permission. The return to displacement is deliberate: Primitives asked what endpoints forget; here the same vector becomes something a mechanism can permit or constrain. Source confirms the two exit doors really are `lift_lateral + rail` versus `free + ghost`, and the free door permits both freedoms at once. **Gap:** again, the seven `tc` carrier utilities are not in the source snapshot. **Next:** preserve; test the seven ride joins and door handling rather than simplifying the text.                                                                                |
| **Trans Rotation**     | **Carries:** this is a four-stage argument intentionally written into the map: **one centre / three axes → many centres / fixed angle field → repeated space → layered time**. The tunnel and carousel therefore are not extra demonstrations after the lesson; they change rotation from an object's operation into spatial composition and then temporal rate. **Gap:** one sentence currently states a runtime-specific collision result that source alone cannot prove: narrow body catches, wide body slides through. **Next:** test that exact comparison; only make the prose observational if the runtime result is not stable.                                                         |
| **Trans Scale**        | **Carries:** probably the cleanest room: perceived shrinking is produced by scaling the other side of the relation; then two physically equal doorways distinguish identical present dimensions from different histories.  **Gap:** not the text—the source metadata is stale. The configured `drink_me` encounter bypasses the legacy 100× animated `ScaleMe` behaviour and builds a dedicated 4× room with no timed reversal. **Next:** update source identity/comments, not the chapter. Headset-test the plate descent and tiny-door route.                                                                                                                                                 |
| **Trans Body**         | **Carries:** this is a genuine change of agency: previously the visitor watched transforms; here bodily approach is an input. Rotation, removal and scaling respond differently, and only removal persists. “The invitation has dimensions” earns its critical meaning from actual detector ranges, masks, tolerances and collision.  **Gap:** perceptual/runtime, not literary: all three scripts contain substantial work to recognise XR, desktop and museum walkers correctly. **Next:** preserve; runtime-test all three body implementations before touching the prose.                                                                                                                   |
| **Trans Pit**          | **Carries:** this is a deliberate return of the chapter's three operations with their meaning reversed: the former means of passage become moving boundaries, then the airlock recomposes all three into welcome. So the repetition is structural, not redundant. “The matrices did not become false…” is the critical pivot; the airlock then supplies the constructive answer.  **Gap:** some underlying source comments still describe older lethal/pit versions of these hazards even though the current map deliberately provides level ground and bypasses. **Next:** keep the chapter; update stale source descriptions and runtime-test the safe observation routes and airlock timing. |

My overall reading is:

> **Pre names the operations. Introduction makes them useful. Translation and Rotation differentiate them. Scale makes them relational. Body makes the visitor an input. Pit reverses and recomposes them.**

That is a strong sequence architecture.

---

# 2. Four high-value changes

I don't think five are justified. The new review rule is important here: most apparent repetition is actually doing different work.

### 1. Rotation — don't let an unverified solver outcome become the lesson

**Work performed:** technically, this compares the **same forward instruction** with two body widths; critically, it rejects the simplistic assumption that “larger body = worse access.” It is one of the sequence's strongest bodily propositions.

**Current text:**

> “You might expect wider to mean worse. Watch z before deciding. **Here the narrow body catches on a ridge; the wider one can slide sideways and continue.** Its changed route matters as much as its arrival.” 

**SOURCE:** `Trans_Rotation`, A2 `(19,25)`,
`rotation_array_compare:...#columns:2#rows:6#...#row_angle_step:18`

`commons/artifacts/rotation_studies/array_body_comparison.gd::_begin_pass()` really does construct two `CharacterBody3D`s with widths `0.44` m and `1.20` m, same height, speed, gravity, start and forward instruction. `_step_trial()` lets Godot's `move_and_slide()` determine lateral motion.

But source does **not** establish which one will catch on which authored row.

**Proposal:** first **RUNTIME TEST**, unchanged text if confirmed.

If the result varies or is less legible than expected, replace only the empirical sentence:

> You might expect wider to mean worse. Watch z before deciding. Compare where each body stops, slides sideways or continues. **If one finds a route where the other catches, width has changed the encounter without changing the array.** Its changed route matters as much as its arrival.

**Reason:** preserve the experiment's critical work while refusing to turn an intended collision outcome into a source-level fact.

---

### 2. Rotation carousel — fix the source comments, not the manuscript

**Work performed by the passage:** the carousel is not just another rotation example. After the tunnel distributes **angle through space**, the stacks distribute **angular speed through time**, while five profiles ask how the same speed relation inhabits different forms. 

The manuscript says:

> “They share heights and speeds. Walk between them and compare the room each leaves around itself.”

That is supported by the current configured instances.

**SOURCE:** five `carousel_cake` placements use `#gallery:clean` with `cake`, `column`, `ziggurat`, `spindle`, `flare`.

In `carousel_cake.gd::_generate_colliders()`:

```gdscript
var current_radius: float = _vis_radii[i] if _gallery_clean else layer_radii[i]
```

So **in this hall**, collision follows each displayed profile.

But older comments near the exported `profile` and `_generate_colliders()` still say the profile is “appearance only” and the colliders remain identical.

**Proposal — SOURCE maintenance:** revise those comments to distinguish:

* ordinary/default profile sweep: visual profile may be appearance-only;
* `gallery:clean`: collision deliberately follows `_vis_radii`.

**Reason:** the text is right and the executable branch is right; stale comments are now the misleading layer. Cutting “walk between them” would make the book less accurate.

---

### 3. Scale — update `ScaleMe`'s identity to describe the current configured encounter

**Work performed by the passage:** scale is made relational rather than presented as “make object larger.” The cut, relocation, descent and two equal door frames distinguish several operations that phenomenologically arrive together. 

**SOURCE:** `Trans_Scale`, A1 `(10,2)`:

`scale_me:0:0:1#encounter:drink_me#plinth:0`

`scale_me.gd::_ready()` sees `encounter=drink_me` and calls `_build_drink_me()`, which removes the legacy ScaleMe children and instantiates `drink_me_room.gd`.

That room defines:

```gdscript
const FACTOR := 4.0
...
room.scale = Vector3.ONE * FACTOR
...
var feet := table.to_global(landings[0]) + Vector3.UP*0.08
```

There is no 100× scale and no automatic timed return in this configured encounter.

Yet the top `@identity` in `scale_me.gd` still describes the legacy 100× world-scaling/timer behaviour.

**Proposal — SOURCE maintenance:** make the identity explicitly bifurcated:

> default ScaleMe: legacy timed world-scale encounter
> `encounter=drink_me`: authored fourfold furnished-room encounter, instant scale + visitor relocation, persistent for the visit

**Reason:** future audits should not “correct” an accurate book passage using metadata from a code path this map never executes.

---

### 4. Pit — clean the hazard metadata so it reflects the new experiment

**Work performed:** Pit intentionally turns the same transforms around. The visitor can choose to enter their envelope **after observing them**, and side routes mean difficulty is not being manufactured by trapping the player. Then the airlock demonstrates that the same operations can create access again. 

**SOURCE:** current `Trans_Pit` map description explicitly calls it a **level-floor study** with a passage around the demonstrations. The `grower_block` instances are configured:

`#min:0.3#max:3.5#speed:0.15#anchor:floor`

But `grower_block.gd` still opens with old identity comments such as:

> “grow(into_player) → pit(death)”
> “squeezes you into the pit”
> “Place in a corridor with pits…”

Those comments belong to an older use of the artifact, not this authored configuration.

**Proposal — SOURCE maintenance:** retain the general hazard history if useful, but distinguish the current floor-anchored study explicitly:

> default hazard lineage can push/squeeze; `anchor=floor` in Trans_Pit is staged on level ground with bypass routes to make occupied clearance observable without requiring failure.

**Reason:** again, the manuscript is not over-softening the hazard. The **map has changed its pedagogical use**. The metadata should acknowledge that development.

---

# 3. Source/artifact discrepancies

### The central transformation utilities are missing from this source snapshot

This is the biggest evidence limitation in the package.

`tc`, `sc` and `rc` are primary encounters in Introduction/Translation/Pit. The review state explicitly recognizes them as primary despite their being utilities rather than ordinary artifact placements. 

But the ZIP does not include the UtilityRegistry/GridUtilities/transport/scale/rotation implementation sources needed to verify passages such as:

```gdscript
_translate_rider(carried_player, movement_delta)
```

or the manuscript's exact scaling and rotating collision behaviour.

The text and older tutorial files contain those excerpts, but that is not independent source evidence.

**Next package:** include the utility registry plus the implementation scripts for `tc`, `sc`, `rc`, `wp`, and any relevant moving-platform rider helper whenever they are primary sequence encounters.

---

### `carousel_cake.gd` contains internally stale commentary

As above: comments say profile collision is unchanged, while `_gallery_clean` explicitly switches collision to `_vis_radii`.

This is not a runtime ambiguity. It is a comment/code discrepancy in the supplied snapshot.

---

### `scale_me.gd`'s headline identity describes the wrong branch for this hall

The configured map branches into `drink_me_room.gd`, making the book's fourfold cut accurate. Source metadata still foregrounds an older 100× tweened system.

---

### `grower_block.gd` still narrates pits/death that this map deliberately removed

The hall map and book have developed beyond the artifact's old identity text.

---

### Sequence order again has a coda discrepancy

Declared sequence:

`Trans_Pre → ... → Trans_Pit`

Museum-authored order adds:

`Biome_Ladder_Transformation`

after Pit. 

As with Primitives, I would not automatically make this an eighth Transformation chapter. If it is a biome ladder / threshold into Arrays, encode it explicitly as a **coda or transition map** in curriculum metadata.

---

### The Rotation footnote links to localhost

The turning-studies note currently points to:

`http://localhost:3003/research/possible-bodies/transformation-zoetrope.html`

and simultaneously says those studies are awaiting placement and headset encounter. 

That's fine for an internal research build, but if this text is becoming a distributable book, the link needs a public/repository destination or should simply identify the research-preview study without hyperlinking localhost.

---

# 4. Runtime questions

No runtime execution was performed.

| Hall                          | RUNTIME TEST                                                                                                                                                                                                                                                                  |
| ----------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Pre**                       | Can a novice distinguish the still collectible cube from the three non-collectible demonstrations? Does the fourth demo's scale read as scale rather than simply changing distance/lighting?                                                                                  |
| **Introduction**              | Do `tc`, `sc` and `rc` genuinely produce three usable crossings for XR and desktop? Does moving the bank beyond the 0.30 m overlap create the seam reported by the control, and when does each player body cease to cross it?                                                 |
| **Translation**               | Are all seven ride joins usable in both directions? Does the down+forward carrier arrive cleanly at its lower landing? Can both door handles be comfortably grabbed, and does the free path actually feel different from the two-stage rail?                                  |
| **Rotation — wall crossings** | Do the upright X/Z ride decks reliably acquire/release XR and desktop riders without double movement? Can the visitor safely remain aboard through the half-turn, as the text asks?                                                                                           |
| **Rotation — arrays**         | Does the 0.44 m body actually catch where the 1.20 m body laterally slides through in the Z band? Is that surprising result stable across runs? Are row labels visible from the still aisle?                                                                                  |
| **Rotation — tunnel**         | With `segment_vertical_offset:-0.65`, do the five hollow cubes meet the surrounding floor as a continuously usable corridor, and can a body actually walk inside each rotated opening without snagging?                                                                       |
| **Rotation — carousel**       | Because `gallery:clean` makes collision follow each visual profile, can visitors meaningfully move among all five forms? Do fast upper layers create collision behaviour consistent with their displayed rotation?                                                            |
| **Scale**                     | Can the bottle be reached before enlargement; does taking it reliably trigger the 4× cut; is the relocated landing on the top serving plate safe; can the 13-plate descent be completed; do both final 1.8×2.4 m openings read as comparable?                                 |
| **Body**                      | For XR, desktop player and museum walker separately: does the slat wall detect them, does carve_grid delete a usable shell, and does approach_scale open a shoulder-wide gap? Do the two reversible systems reliably regrow/close after leaving range?                        |
| **Pit**                       | Are the bypasses genuinely available around the timed studies despite the surrounding `h:fire` utilities? Does the airlock's large sensor keep it open for an intelligible “near” region, and does it close three seconds after the last visitor actually clears that region? |

The brief explicitly cautions that source cannot prove reach, visibility or traversability, and Transformation particularly depends on those bodily properties. 

---

# 5. What I would **not** cut

This sequence is a very good demonstration of why your new review instruction matters.

I would **not cut the second explanation of rider translation** in Translation merely because Introduction already introduced it. In Introduction, shared displacement answers:

> *what extra relation turns moving geometry into transport?*

In Translation it answers:

> *how can transport and pickup detection meet, while a return trip does not restore what was collected?*

Same mechanism, different work.

I would **not cut the rotation tunnel or carousel** because the basic axis lesson has already been established. They change the independent variable:

* blade: angle changes through **time** around one centre;
* array: angle changes through **space** across many centres;
* tunnel: angle **accumulates through a spatial sequence**;
* carousel: angular **rate differs through layers over time**.

That is a very coherent progression, and the map itself labels those shifts.

I would **not cut Pit as a repetition of the earlier transform halls**. It is the chapter turned around. The same invariant that was useful from outside is experienced as occupied clearance from inside. The airlock then avoids ending on critique by recomposing all three operations into a passage.

And I would definitely **not move or remove**:

> “The matrices did not become false when you entered the room. They became insufficient as descriptions of what the room allows.” 

The important thing is that the airlock follows it. The chapter does not reject formal understanding; it shows what has to be added before formal transformation becomes an affordance.

## Two questions for you

First, **is the narrow-versus-wide Z-band result intended to be a fixed authored surprise**, or do you want it to remain an open empirical comparison whose outcome can depend on the solver? That determines whether the manuscript should say “here the narrow body catches…” or ask the visitor to discover which one does.

Second, is `Biome_Ladder_Transformation` intentionally a **threshold/coda**, as the similar ladder appears to be after Primitives? If yes, I think both should be encoded as a distinct curricular role rather than appearing as unexplained differences between declared and museum-authored sequence order.

My strongest conclusion from this pass is that Transformation needs **less editorial cutting than Primitives**. Its repeated material is mostly doing exactly what a curriculum should do: returning to a known operation after the body, scale, environment, or use has changed, so the same technical fact acquires another consequence. The high-value work now is mostly source cleanup and embodied verification.
