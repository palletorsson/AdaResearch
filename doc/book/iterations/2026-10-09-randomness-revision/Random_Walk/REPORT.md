# A point keeps its steps

**Seventh of fourteen Randomness halls revised.** The familiar PointBody gains a sampled displacement. The existing Trace cylinder joins its accepted positions. One point, one planar rule, one retained path.

## What travels forward

Random Rotate accumulated turns. Random Walk accumulates displacements. Coordinates supplies the local frame; Wavefunctions supplies sine and cosine; Trace supplies the positions list and connecting cylinders. The learner changes what an existing object does, rather than learning another construction for a sphere.

The lesson asks what depends on the path so far. Each new heading ignores the trail. The endpoint nevertheless depends on the current position, and the enclosure can change a proposal. A record can remember something without participating in the next decision.

The student holds the point to pause, releases it to choose a new planar start, or presses its trigger before release to replay from the previous start. Ordinary release clears the old run. This is stated before the code: the hand supplies a starting place here, rather than continuously drawing the trace.

## What the tutorial now contains

Three complete printed files: the new walker, unchanged PointBody, and unchanged LineSkin from Point Trace. The prepared museum supplies its player, camera, lighting and XR Tools. The script creates its table, boundary and labels; those display meshes are not collision bodies. Read the short `step()` function first, then its supporting construction.

The normal run contains 128 steps, 129 retained positions and 128 cylinders. It stops consuming random draws when complete. The trail joins accepted endpoints, so it does not draw contact with a wall. The boundary applies to the sphere's centre; this is a position rule, not a rigid-body simulation of a bounce.

The reconstruction was checked at hall-local (4, 0, 7), with no rotation and an approach on its positive-Z side. It is a temporary lesson station in the student's museum copy. The installed hall and artifacts have not been replaced.

## Three edits with different consequences

| Change | Prediction |
|---|---|
| Step 0.12 → 0.24 m | Same headings; doubled displacements before either path reaches a boundary. |
| Interval 0.25 → 0.5 s | Same path at equal step counts, reached more slowly. |
| Fold → clamp at the boundary | Same random draws, different accepted positions near an edge. |
| New starting position, same seed | Same proposals relative to the current position; different boundary encounters. |
| Erase the stored trail only | The next step is unchanged: it does not read that record. |

An independent exercise asks the learner to predict a corner overshoot and explain why the displayed chord is shorter than the proposed step. The next hall, Random Gaussian, groups samples by value: a histogram keeps counts while giving up the order visible in this path.

## What inspection established

The terrarium has five walkers sharing a private generator. ONE and ALL change emphasis without removing walkers or consuming draws. Planar steps consume one draw per walker; 3D consumes two; LONG STEP consumes three. The last mode samples a bounded length. It does not demonstrate an unbounded Lévy process or prove a better search strategy.

The installed cabinet retains a rolling window of 200 previous positions; the bead shows the current position. At step 300 those trail entries are positions 100–299. The learner program instead retains the start and every accepted endpoint for its short finite run. Both conventions are explicit.

Installed RESET restores the seed and positions but retains a partial step timer. The cabinet accepts at most five batches per rendered frame and drops excess time. Its clock still counts the supplied frame time. Our finite reconstruction clears its timer on restart and handles complete intervals up to the step budget. Replay comparisons therefore specify equal step counts and the same engine version, start and rule.

The other artifacts remain part of the hall: the rails compare fresh position with accumulated displacement; the held drawing dot combines a carried origin with a wandering tip; the lattice counts revisits; a small self-avoiding sculpture consults occupied cells. They extend the inquiry without making all their implementations compulsory here.

## What changed in the reflection

The existing question remains: **what does a trail remember that its next step does not use?** The writing still moves from the terrarium through the rails, drawing dot and raised field. Code excerpts become prose. Claims that long steps remedy revisiting or constitute better searching become questions the artifacts can support. A count of returns does not decide what a good walk should do.

A short closing passage connects the learner's point to that reflection. The tutorial explains and reconstructs the operation; the reflective text examines how we read the resulting movement and what the visible record leaves out.

## Test evidence

The exact printed program and three actual source edits each pass **30 Godot assertions**. Four faulty versions fail the expected checks: forgetting the previous position, omitting the boundary, losing the final record, and failing to reset the generator. Tests cover all 128 steps, cylinder geometry, replay, independent instances, local/world conversion, held time, corner folding, finite completion and frame partitioning.

The initial harness referenced an XR Tools class before its required autoload was available. All assertions printed PASS, but startup compile errors invalidated that run. The harness bootstrap was corrected and every variant rerun cleanly. The first log and harness are retained in `failed-first-run/`; they are not presented as accepted evidence.

The native museum run passes **32 checks**, including five capture-camera checks. It checks the installed terrarium's actual state, draw consumption and time policy, then reconstructs the extracted learner files. The station and body-sized approach have floor; the approach collision query is clear. Pickup/drop signals and the inherited action method exercise pause, release and replay. Additional checks confirm the sphere remains at its endpoint after rendering and physics frames.

The endpoint check found a real error after ordinary release: the frozen body returned to its previous physics pose while the trail recorded the new position. The study now assigns its saved position on physics frames when free and yields to the hand while held, including after a run finishes. The isolated headless check did not reproduce that fault; the museum did. Its failed native receipt is why the numerical checks alone are insufficient. The rejected receipt and printed code remain in `endpoint-check-first-run/`.

The first reconstruction photographs exposed dark text against a dark wall. A pale backing was added, then the printed variants and museum reconstruction were rerun. The earlier images remain in `first-capture-low-contrast/`.

## What these checks do not establish

This is an author-informed reconstruction, not an unfamiliar ghost student's reading or a physical-headset test. Pickup/drop events were supplied explicitly; the physical grab driver was not simulated. The station's table is a display, so the floor and approach checks are not a promise of collision against its tabletop.

Existing native diagnostics remain: an unknown UID, renderer compatibility warnings, and a safe fallback for a blocked authored entrance. Full walking, teleport transitions and headset readability still need a visit. Accepted runs contain no script, parse or signal-callback errors. No production artifact, map configuration or shared point/line class was edited for this lesson.

Native images were inspected directly. Printed-code parity, local links and ZIP contents are checked. Browser layout was not inspected because local file URLs were blocked earlier.

[Facing pages](parallel.html) · [Tutorial](tutorial.html) · [Reflection](final.html) · [Before/after](changes.html)

[Predictions](predictions.md) · [Code results](tests.json) · [Museum receipt](museum/report.json) · [Editable sequence plan](../../../course/randomness-revision/PLAN.md) · [Review ZIP](random-walk-review.zip)
