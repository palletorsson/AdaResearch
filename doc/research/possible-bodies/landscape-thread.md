# What leaves? What remains?

[The sine encounter is now in the museum](sine-contact.html): a dedicated forecourt, contact tray and two primary book sections. The four-tray article apparatus remains the recorded research setup.

[Read the working article: What leaves? What remains?](landscape-article.html) — an 18-trial size series, its repeat discrepancy, and the question of what counts as passage.

[Descent](descent-landscape.html) · [Working route](index.html) · [Waves, Chance and Noise](../waves-chance-noise/index.html) · [Protocol and next actions](landscape-thread.json)

**A recurring experiment, with its first physical prototype.** Sine, independent random heights, Perlin and Worley receive the same batch of spheres. Change one condition and watch what passes through, what remains at the deadline and what leaves elsewhere. This is a standalone Godot workshop; museum placement and headset experience remain to be tested.

![Four physical trays in the Godot workshop](landscape_flow_overview.png)

## The experiment already has a history

Palle Torsson's [2021 project report](https://docs.google.com/document/d/1zMi54Mc2R5KfXsQ6iwol781FJSXEPtwST1ZyJNGTtEE/edit) describes four Blender surfaces imported into Unity. Each was tilted 20 degrees and received 3,600 spheres, with reported sizes between 0.1 and 0.3 units. The reported overflow counts were Voronoi 0, Perlin 45, Random 635 and Sine 3,284. These are counts from that setup; without a duration they are not rates. The paper reports repeated trials but does not provide a full per-run series.

The [presentation draft](https://docs.google.com/document/d/1-ezkt4cZ9ZAKsr7Ufwxu8_sML9lSkGE1ba4ow-BmQFA/edit) connects this experiment with compression, recognition, possible movement and the possibility of hiding or disappearing. Its theoretical references remain research leads; the numerical experiment does not by itself establish those wider claims.

The new prototype carries the question forward. Its meshes, release pattern, uniform sphere size, population and observation window are newly specified. Its numbers must not be presented as a reproduction of the 2021 results.

## Take a turn

1. Before RELEASE, predict which tray will let most spheres leave.
2. Release 32 spheres per tray. Follow one body, then compare the counts.
3. PAUSE to inspect the scene; resume the same trial.
4. Repeat with just TILT, RELIEF, SIZE, SEED or WINDOW changed. A setting change clears the previous trial. RESET keeps settings; RELEASE starts a fresh batch.
5. Reveal RULE after observing. Read how the samples became collision geometry and how the deadline defines the observation.

The outlet is the open lower end, marked in gold. Exited spheres are moved to a collection display and stop colliding; they no longer influence the remaining trial. Other exits are counted separately and shown grey. At the deadline all bodies freeze. STILL IN means present at that time, not permanently trapped or settled.

![Surfaces, collection displays and standing controls](landscape_flow_detail.png)

## A first observation

Seed 1729; tilt 20 degrees; peak-to-trough relief 0.3 m; radius 0.075 m; 12 seconds at 60 physics ticks/s. Gravity 9.8 m/s². Surface and sphere friction 0.45, bounce zero; sphere mass 0.1 kg and explicit linear/angular damping 0.05. Side/back rims retain their ordinary collider material defaults.

| Surface | Outlet | Still in | Other exit |
|---|---:|---:|---:|
| PERLIN | 32 | 0 | 0 |
| RANDOM HEIGHTS | 0 | 32 | 0 |
| SINE | 2 | 30 | 0 |
| WORLEY F1 | 32 | 0 | 0 |

This is one recorded run, not a ranking of generators. A second run in the report exercises another seed and a different window; because two settings change, it is a functional check rather than evidence for the isolated effect of seed. Field samples replay from a seed; contact trajectories may vary. Repeat trials before describing a stable relationship.

## What is actually shared?

Every tray is two by 3.2 metres, sampled into 20 by 32 cells and triangulated. Each field is independently rescaled to the same height range and uses the same low-to-high colour mapping. That controls overall relief while changing the original numerical amplitude; it does not equalise slopes, wavelengths or basin counts.

Sine uses a product of two spatial sines. RANDOM HEIGHTS uses independent seeded values at vertices, then joins them with triangles. PERLIN explicitly selects the Perlin basis. WORLEY F1 uses the nearest-feature Euclidean distance from the cellular generator. A stepped box surface or cell-ID rendering would be another construction and remains future work.

The release grid belongs to the tilted tray: four columns by eight rows, all at local height 1.1 m. Each tray gets identical local release coordinates. Gravity stays world vertical. This corrects an early setup error where a world-horizontal release put some bodies outside the tilted tray before contact.

These bodies have velocity, contacts and friction. The Descent point changes its address using a sampled gradient. Comparing the two requires keeping those different update rules visible.

## Carry the question through the book

| Hall | Question | Concrete continuation |
|---|---|---|
| [FormFinding_Descent](/necklace/thread?map=FormFinding_Descent&role=primary) | Where does a local downhill rule take you? | Carry the distinction between a numerical position update and physical motion into every terrain trial. |
| [WaveFunctions_Sine_Space](/necklace/thread?map=WaveFunctions_Sine_Space&role=primary) | When does repetition direct or obstruct a body? | Place and verify a compact physical sine tray as a supporting comparison; keep the corridor primary. Inspect the existing basin and circulation before choosing its location. |
| [Random_Space_Geometry](/necklace/thread?map=Random_Space_Geometry&role=primary) | What does a relationship between neighbouring heights change? | Repeat the sphere trial with independent vertex heights, then a shared sampled field; declare triangular versus stepped surfaces. |
| [Random_Space](/necklace/thread?map=Random_Space&role=primary) | What changes when variation is layered? | Use as a cross-reference for scale and normalisation; do not promise a walkable random landscape here. |
| [Noise_Space_10](/necklace/thread?map=Noise_Space_10&role=primary) | What becomes a route, and for which body? | Freeze seed/start/goal and review a real player route; compare it with sphere passage and measured line-of-sight. Add Perlin/cellular choices only through explicit tested controls. |
| [Noise_Perlin_Simplex](/necklace/thread?map=Noise_Perlin_Simplex&role=primary) | Which difference belongs to the generator and which to its presentation? | Compare a continuous Worley F1 surface with a stepped/cell-labelled rendering separately. Keep normalisation and sampling visible. |
| [ML_Gradient_Landscape](/necklace/thread?map=ML_Gradient_Landscape&role=primary) | Who supplied the meaning of a good arrival? | Return to the terrain experiment explicitly: axes now mean model parameters, height means loss. Inspect training versus held-out evaluation before promising generalisation controls. |

The current museum still passes through the remaining Form Finding halls before Waves. This research thread is a set of returns across chapters, not a route reorder. In Sine Space, the existing corridor stays primary: its visual walls have no collision. A physical tray would add a deliberate comparison between an apparent barrier and a surface that changes a body's motion.

For a future walkable terrain, hold the player start, destination, body dimensions and locomotion settings fixed. For concealment, specify the observer, target and their heights, and test occlusion separately. For optimisation, name the objective and stopping rule. No one measurement stands in for all three.

## A voice to carry forward

> We counted those that came out. Then we looked at those that remained. Had the landscape failed to let them through, or succeeded in holding them?
>
> Change the size of the body. Leave the landscape alone. Watch what your earlier answer can no longer explain.

This is a new passage proposal, not a quotation from the old drafts. The book can let the action come before the distinction: what counts as a useful outcome depends on what we ask the space to do. Retention becomes shelter only when a further relation makes it shelter.

## Evidence and next action

45 checks pass in the standalone Godot workshop: seed replay, shared relief, upper-face collision, equal releases, pause/resume, finite observation windows, separate exit accounting, resets and standing control heights. The images are actual Godot renders. Hall placement, a physical player crossing, measured concealment and headset usability are not yet verified.

[Runtime report](landscape-flow-check.json) · [Source/protocol snapshot](landscape-thread.json) · [Page source](landscape-thread.md)

**Next actionable step:** continue the halls from the completed sine contact encounter; keep headset review pending. A full-size walking or concealment receiver needs its own body, task and observation protocol.
