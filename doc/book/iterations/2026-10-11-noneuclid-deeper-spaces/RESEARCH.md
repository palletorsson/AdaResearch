# A point in a world that will not fit

Endless Museum · NonEuclidean_Spaces · research and build plan · 11 October 2026

**Expand this hall into seven spatial encounters.** The current plane/sphere triangle is a useful beginning. The larger subject is what happens when the student carries that point, its direction and its trace into a world with different relations of distance and connection. Hyperbolic space should eventually surround the player.

This report contains research, a source-code audit, seven encounter designs, a small original Godot geometry kernel, a GPU stencil test and five geometry views. It does **not** claim seven installed VR rooms. The current museum, spine order and tested tutorial/final pair remain intact while this expansion is developed. The source plan is [BUILD-PLAN.json](BUILD-PLAN.json); this research text is editable as [RESEARCH.md](RESEARCH.md).

## What Godot actually gives us

Godot introduced stencil support in 4.5; Ada already targets 4.6. A doorway-shaped mask can select which otherwise overlapping geometry appears. This is useful for impossible interiors. It does not supply player transfer, recursive visibility, held-object continuity or a hyperbolic metric. The 4.6 API is marked experimental, and stencil reads require the transparent rendering pass. [Godot 4.5 release](https://godotengine.org/article/godot-4-5-making-dreams-accessible/), [Godot 4.6 spatial shaders](https://docs.godotengine.org/en/4.6/tutorials/shaders/shader_reference/spatial_shader.html).

I tested an original mask scene in **Compatibility, Mobile and Forward+**, using the installed Godot 4.6 and this PC's RTX 3070. All three pass the same four pixel checks: visible inside the opening, invisible outside it, occluded by a foreground object, and removed when the mask writer is disabled. These are desktop, single-view tests. They establish neither headset performance nor a seamless crossing.

The test uses an alpha-transparent writer with no depth writes and explicit render priority. The receiver has alpha 1 but participates in the transparent pass to read stencil. This is a small feature probe, not a solution to arbitrary ordering, shadows or many overlapping portal rooms. Start the museum implementation with one visible portal and an unshaded destination; add lighting and multiple masks only after crossing and stereo pass.

The relevant precedent is **Holonomy**, a hyperbolic VR environment. Its authors describe several virtual cells sharing a physical region, initially requiring multiple rendered portal views. They then use stencil polygons to reduce this cost. Its physical walking arrangement and hyperbolic cell structure are particularly relevant to Ada; its Unity implementation is not a Godot feature we can simply enable. [Holonomy, sections 4–5](https://arxiv.org/html/2409.05460v1).

A useful conventional portal reference is Donitzo's Godot 4 system: destination cameras, frame transforms, ray transfer and examples of body transfer. Its documented renderer does not nest portals; clipping and straddling bodies need deliberate handling. Treat it as a reference implementation to inspect, not as a verified XR drop-in. No external plugin has been installed or copied for this research. [Author's repository](https://github.com/Donitzo/godot-simple-portal-system).

## Three changes that must stay distinguishable

| Change | What changes for the student | What does not follow from it |
|---|---|---|
| A portal connects Euclidean rooms | Which place lies through a threshold | Negative curvature is not established |
| A flat corridor wraps | Global topology and the route back | A local triangle can still sum to 180° |
| A surface has intrinsic curvature | Lengths, geodesics, angles and parallel transport | The surrounding three-dimensional room need not be curved |
| H² × R | Horizontal hyperbolic geometry with ordinary vertical height | This is not isotropic hyperbolic 3-space |
| H³ | Constant negative curvature in every tangent two-plane | A Euclidean ball mesh or bent screen is not sufficient |

Here **hyperbolic** is the geometrical term. A hyperbola is a particular curve; building one does not by itself build hyperbolic space.

A cylinder is a useful control: it looks curved in ordinary 3D but is intrinsically flat locally. A standard saddle has negative curvature, but generally not constant curvature. For the existing saddle profile `y=c(x²−z²)`, Gaussian curvature is `−4c² / (1+4c²(x²+z²))²`; its variation matters. A bowl's concavity does not determine the sign of its intrinsic curvature. These distinctions should become a short comparison beside the lesson, not another vocabulary-heavy opening.

## What is already in Ada

| Existing source | Useful contribution | Limit or repair |
|---|---|---|
| `doc/book/studies/noneuclid-lineage/` | Tested carried point, line and triangle; plane/sphere measurements | Changes the study surface, not walking geometry; retain this verified baseline |
| `commons/scenes/em/em_portal_stream.gd` | Museum hall streaming, arrival placement and movement-state handling | It is a loading/transition system, not a recursive view-through renderer |
| `commons/scenes/em/em_portal_scene_base.gd` | Existing XR origin and arrival integration | Preserve its head-offset handling when adding a geometry chamber |
| `algorithms/alternativegeometries/noneuclideanspace/portal.gd` and `portal_manager.gd` | Earlier portal experiment and coordinate transfer | Static audit found no destination-view renderer; its body callback tests for XROrigin3D, which is not a PhysicsBody3D. Do not treat the old script as verified crossing logic |
| `commons/artifacts/poincare_disk/poincare_disk.gd` | Recognisable disk encounter and an existing exhibit to improve | Some arcs are decorative approximations; a triangle label is fixed at approximately 150°. Replace these with measured paths before using it as evidence |
| `commons/artifacts/hyperbolic_surface/hyperbolic_surface.gd` | Actual saddle and numerical surface-geodesic work | Useful local surface investigation; it is not complete H² or H³ |
| `commons/maps/NonEuclidean_Spaces/map_data.json` | Existing 17 × 15 map, stepped arrangement and museum lighting | Legacy bowl/dome text overstates the geometry and calls sphere-like work elliptic. S² and the projective elliptic plane are not interchangeable. Correct the metadata during installation |

A scoped search of `.gd`, `.gdshader`, `.tscn` and `.tres` files under `commons`, `algorithms` and `addons` found no existing `stencil_mode`, `stencil_reference` or `STENCIL_FLAG_READ` usage: 10,402 files searched. This is evidence about those patterns and roots, not proof that no related experiment exists elsewhere.

The full museum should remain the host. Keep the current triangle near its entrance. Use portal thresholds to reach larger child spaces rather than squeezing seven demonstrations around that table or pretending the existing floor already implements a different metric. Reuse the museum sign, plinths, pale architecture and black point. The visual continuity makes the changed relation legible.

## Seven encounters, one travelling object

The cards on the report page give one storyboard, hand action, learning subject, implementation boundary and acceptance test per encounter. They are also stored in BUILD-PLAN.json. Proposed visitor order:

1. **A room that will not fit.** Carry the point across a doorway into a larger interior. Learn what a connection changes.
2. **The corridor returns your ball.** A flat wrapped corridor returns the point and its trace. Separate topology from curvature.
3. **The point returns; its arrow does not.** Parallel transport around the sphere gives the journey a measurable consequence.
4. **The edge you cannot reach.** The same triangle enters H². Change its display without confusing the picture with distance.
5. **Five galleries around one corner.** Enter H² × R; follow and recover the sphere using a persistent cell address.
6. **The room curves upwards too.** Enter a full H³ chamber; measure vertical as well as horizontal triangles.
7. **Aim straight. Watch the path.** The catalyst launches the same point along a geodesic. Predict, act and compare.

These are seven encounters, not seven unrelated beginner scripts. **The principal tutorial object remains the point with its line, triangle, orientation and recorded route.** The sphere from earlier lessons is still recognisable. The catalyst acquires a geometry-aware action. Supporting models can remain museum artifacts without requiring a complete tutorial for each one.

For a first substantial build, encounters 1–4 establish the distinctions; encounter 5 supplies inhabited hyperbolic space. Encounter 6 is the full 3D goal and needs its own renderer/body milestone. Encounter 7 returns the research to purposeful play. Do not defer all actual curved navigation behind a collection of portal illusions.

## How H² × R and H³ can work

**H² × R is a good first inhabited chamber.** Hart, Hawksley, Matsumoto and Segerman describe this product geometry for VR, keeping an ordinary height coordinate above a hyperbolic plane. Their rendering construction uses the inverse exponential map; simply stretching a disk vertically does not give the right diagonal view. Ada's probe implements this distinction. [Non-Euclidean virtual reality II](https://arxiv.org/html/1702.04862v1).

**H³ is feasible, but it is a dedicated geometry layer.** The same authors describe hyperboloid coordinates, observer isometries and a Klein projection from a recentered observer. Ada's research kernel follows those mathematical constructions, using original code. It already draws a finite H³ scaffold externally and from a central inhabitant view. Neither view yet handles stereo hands, collisions or a populated endless world. [Non-Euclidean virtual reality I](https://arxiv.org/html/1702.04004v1).

There are two distinct gallery approaches worth testing. A continuous H² × R renderer preserves its declared metric. A Holonomy-style cell system arranges locally Euclidean physical regions through stencil portals according to hyperbolic adjacency. The latter offers a strong portal experience, but its local straight walls and transitions must not silently stand in for continuous H² measurements. Give both their own mode name and test contract.

Jeff Weeks identifies a crucial VR problem: moving head and hands independently through a curved world can make their relative placement drift. A common physical-space anchor and consistent mapping preserve body coherence. This belongs near the beginning of our implementation, before elaborate scenery. [Body coherence in curved-space virtual reality games](https://arxiv.org/html/2011.00510v2).

The point can be a real local grabbable object near that anchor, with a separate intrinsic record. At release, convert its local direction into a tangent of the chosen geometry. Beyond that local interaction zone, script its geometric motion. Do not ask an ordinary Euclidean rigid-body engine to integrate positions that merely look curved. **Jolt remains useful for the museum and declared local proxies; it does not become an H³ solver.**

HyperRogue's development notes offer another practical lesson: retain local cell coordinates and the transformations between cells instead of travelling indefinitely in huge global hyperbolic coordinates. Its model documentation also helps distinguish conformal Poincaré pictures from straight-geodesic Klein pictures. [HyperRogue development](https://roguetemple.com/z/hyper/dev.php), [models](https://roguetemple.com/z/hyper/models.php).

## A small mathematical contract

Use named types or explicit records; do not pass every position around as an undifferentiated Godot Vector3.

| Record | Meaning |
|---|---|
| `PointRecord.id` | Persistent identity of the teaching point |
| `model` and `curvature_radius` | Which geometry and which length scale define its measurements |
| `intrinsic_position` | A chart position or constrained hyperboloid point, according to the model |
| `tangent` and `orientation` | Direction in that point's tangent space |
| `cell_id` / `observer_isometry` | A local address and current viewing frame |
| `display_position` | Derived coordinates for Godot rendering, never the source of intrinsic distance |
| `trace` | Ordered intrinsic samples plus model/units; display copies do not rewrite it |

For the unit hyperboloid use `p=(x,y,z,w)`, `x²+y²+z²−w²=−1`, `w>0`. The kernel provides Lorentz products, distance, distance-parameterised geodesic interpolation and boosts. Its Poincaré and Klein conversions produce displays of the same record. A radius different from 1 changes the physical distance scale and curvature; the next implementation must declare that scale rather than hide it in mesh size.

The five numerical families already exercised are portal transfer, periodic addressing, spherical transport, H² distance/geodesics and H² × R/H³ observer calculations. The checks use closed-form cases and invariants, including a 90° spherical transport loop, radial distance `log((1+r)/(1−r))`, equal intrinsic path intervals and the hyperbolic cosine law for perpendicular unit legs. They validate this bounded code against those expectations, not a universal mathematical theorem.

## Implementation order and exit conditions

| Step | Deliverable in the existing museum | Done means |
|---|---|---|
| 1 · Portal crossing | One threshold, destination room, carried point, reset | Both-eye view, occlusion, head/hand straddling, inverse crossing and held-object continuity pass |
| 2 · Return and transport | Flat loop and extended spherical arrow study | A saved point survives a loop; topology and orientation tests remain distinguishable |
| 3 · Exact H² | Replace decorative disk paths/readouts; retain triangle IDs | All visible measurements come from the metric; model toggle preserves the record; boundary inputs are guarded |
| 4 · Walkable H² × R | Small gallery patch and persistent cell identities | Correct observer view, unchanged local height, supported approaches and return to the saved point; performance measured in headset |
| 5 · Full H³ | Finite volumetric chamber with coherent head and hands | Stereo geometry, intrinsic target tests, orientation, clipping and return are stable before enlarging it |
| 6 · Catalyst action | Aim, preview, release, hit and reflect | Intrinsic motion agrees with preview and predictions; the student's variation also works |
| 7 · Book and ghost student | Expanded tutorial.md, concise final.md and clean carried code | Fresh learner reconstructs from frozen text, predicts a new case and passes meaningful Godot assertions |

No engine installation is needed for the stencil step. Choose the renderer from measured results in the target headset; the three desktop passes do not establish Quest compatibility or a frame-rate budget. Limit visible portal depth and visible geometry explicitly. Keep an always-available return to the ordinary museum, and avoid automatically rolling the tracked camera during the first H³ trial.

The tutorial should expose the smallest complete new code at each step and name every supplied adapter. The student does not rebuild PointBody, the museum or XRTools. A future ghost-student packet must include the carried code and the declared host contract, not a hidden working implementation disguised as successful reconstruction.

## What the reflection can carry

The critical line stays close to actions: the wall promises an enclosure; a doorway changes its reach. A point returns but its direction does not. A picture offers an edge which the metric does not. A familiar floor makes a particular orientation seem inevitable. Aim supplies a prediction that the world answers.

These are grounds for interpretation, not demonstrations that every truth is optional. Geometry's exact assumptions and the player's experience can meet without becoming interchangeable claims. We should replace the old broad assertion that geometry is simply “a choice, not a truth” with the particular choices and invariant relations the student has actually tested.

## Systems to learn from, and how

| Source | What Ada can take from it |
|---|---|
| [Holonomy](https://arxiv.org/html/2409.05460v1) | Spatial address, physical walking and efficient stencil-mediated views; relevant to the gallery layout |
| [Non-Euclidean VR I](https://arxiv.org/html/1702.04004v1) and [II](https://arxiv.org/html/1702.04862v1) | Two distinct renderer contracts for H³ and H² × R |
| [Weeks: body coherence](https://arxiv.org/html/2011.00510v2) | Keep tracked body parts consistent while the virtual frame changes |
| [Curved Spaces](https://www.geometrygames.org/CurvedSpaces/index.html) | Explore topology and geometry as explicit constructions rather than decorative distortion |
| [HyperRogue / RogueViz](https://www.roguetemple.com/z/hyper/rogueviz.php) | Curved geometry used for navigation and play; inspect its representations and local-address strategy |
| [Hyperbolica](https://codeparade.itch.io/hyperbolica) | A creator's example of making curved-space play legible through familiar actions; inspiration, not Godot implementation evidence |
| [Donitzo's Godot portals](https://github.com/Donitzo/godot-simple-portal-system) | Frame transfer, destination cameras and the practical problem of objects halfway through a doorway |

Sources were checked on 11 October 2026. This research does not assert measured learning outcomes from Ada's proposed encounters. The next decisive evidence is a player carrying the same point through a correct stereo portal and then recovering it in the first inhabited hyperbolic gallery.
