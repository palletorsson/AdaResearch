# Fresh ghost-student reading and build report

**All six required originals and six independently chosen variations passed.** The latest twelve runs contain 83 passing assertions and no script, shader, or parse errors. Every original file still matches its extracted packet hash. I found no required repair to a printed program under the stated prepared-project assumptions. One exercise label merits a wording correction.

This is an AI student reconstruction with real GPU evidence, not a human comprehension study or physical VR validation. I read the packet's preface, tutorial, and reflective sequence. I did not consult earlier learner programs, teacher tests, solutions, review reports, source artifacts, or other iterations. A targeted search of the named XRTools pickable support helped investigate my first movement harness failure. The museum launchers were not used as lesson evidence. The parent agent checks those separately.

## How the evidence was obtained

I worked through Shaping → Patterns → Materials → Water → Pink → retained field. I extracted the 21 marked source files into separate `original` folders and preserved them. Each hall has a `PREDICTION.md` written before its GPU runs, a different `variation` folder, a probe, images, and complete logs. My changes were an annulus, sheared coordinates, inverted height, a retraced phase path, a broader rim, and a clamped field boundary. None is the supplied `(4,2)` copy-along, subdivision edit, or FEED edit.

The original host was instantiated in every case. Additional diagnostic receivers reused its actual material; Water also reused its actual subdivided mesh. A synthetic SubViewport, camera, and controlled illumination made rendered differences inspectable. These captures are **isolated diagnostic views, not the physical museum**. The Water collision test queried the original host's actual glass body. The field tests used original GPU updates and read back data only in the probe; the program's live path was unchanged. Field button tests emitted the actual prefab receiver's signal. Marks were supplied through `field.mark`, so physical trigger/pickup behavior is not established.

Godot reported version 4.6 stable, OpenGL 3.3 Compatibility, NVIDIA GeForce RTX 3070, driver 595.71. Commands used `--no-window`, `--xr-mode off`, `--audio-driver Dummy`, and `--no-bridges`; they did **not** use `--headless`. `run.py` starts hidden processes, has a 100-second subprocess timeout, preserves numbered logs, and now exits nonzero on failed assertions or script/shader errors. Valid evidence runs were serial. A scheduling mistake in two discarded Water attempts is disclosed below.

Run all twelve in their intended order with:

```powershell
python doc/book/iterations/2026-10-10-shaders-ghost-student/student/run.py all
```

Individual runs use `run.py shaping original`, for example. Run an original before its variation because Materials and Pink compare against that original's captures. `make_results.py` rebuilds `results.json` using only this student's files and the packet. PNG names hold the latest capture; numbered logs preserve attempts.

## 1. Shaping — changing colour without changing the body

I brought forward the point, cube/collider helper, local coordinates, distance, and colour mixing. The new work is the fragment mask, its uniform inputs, and shared material on two differently sized full-UV squares. XRTools and the prepared player remain supplied support. I reconstructed all three printed files and the complete original host.

The supplied radius comparison passed: the centre and distance-0.20 sample were pale; distance 0.40 was initially dark, then pale at radius 0.46. The edge action changed a band of rendered pixels. Both actual receivers reference the same tested material. My annulus variation removed distances below half the outer radius. It made the centre dark and retained the middle ring as predicted. The hole grew with radius too; it did not acquire the outer soft transition.

The reflection's appearance-versus-backing distinction fits the reconstruction directly. Its graphs, wrapping clock, sphere, and crossing are additional encounters that these checks do not verify. I could follow the new shader without re-learning the collider boilerplate because the text directs me to `update_rule`.

**Keep:** the full-square UV convention, two receiver sizes, and explicit opaque-mask explanation. **Clarify, optionally:** identify the three given UV classifications as worked predictions, then invite one unprovided sample. **Change:** no code repair. **Missing steps:** none under the prepared-project assumptions; actual hand pickup/release remains outside this validation.

## 2. Patterns — moving the address

The previous body, material, radius, and edge action carry forward. The changed operation multiplies, translates, and folds the lookup. Horizontal point movement now selects tile shift. The architectural projection and chair attachment remain supplied museum comparisons; they are not hidden dependencies of the UV study.

The original field changed visibly at half a tile and returned exactly at both plus and minus one tile. For my variation I replaced the address with `(UV.x + UV.y, UV.y)` before repeating it. I predicted the centre would move onto a cell boundary while a neighboring address entered the circle. Both classifications passed; the sheared pattern retained its whole-tile period. The capture shows slanted, stretched marks rather than newly constructed geometry.

The reflection's seam argument follows this experiment well. Truchet agreement, Wang averaging, Voronoi, noise, garden, and saved-record readings broaden it substantially. They are interesting follow-throughs, but not evidence that I rebuilt those systems. This hall has the smallest incremental programming burden despite a long complete listing.

**Keep:** positive lookup shift moving the image left, negative `fract`, and exact whole-period comparison. **Clarify, optionally:** signpost that the later rack/garden/record discussion extends beyond the required reconstruction. **Change:** none required. **Missing steps:** none; the difference between UV attachment and architectural projection is already stated.

## 3. Materials — light without height

The repeated circle becomes data. I retained the two receivers, cube, local controls, and shared material, then added the point's `coat` method, sampled heights, encoded normals, lit shading, and mode switching. The primitive tangent data and printed lamp make the supplied comparison usable. All four files reconstructed successfully.

HEIGHT visibly differed from FLAT by mean absolute RGB difference **0.021847**. NORMAL differed from HEIGHT by **0.000688**, much less. Zero strength exactly returned the flat capture. My independent variation inverted the stored heights before deriving both maps. The lit relief reversed, the two methods stayed close, and FLAT remained identical. This was a more useful test of the slope explanation than merely selecting a different repeat count.

The reflection's apparent relief versus unchanged silhouette is a strong fit. Its older material collection introduces several additional input relationships—UV, eye, lamp, clock—that were read but not reconstructed. This is the first substantial conceptual rise: finite differences, encoding, tangent frames, texture sampling, and changed controls arrive together. The flat witness and explanation of image-row direction make it manageable.

**Keep:** the flat witness, data-versus-colour distinction, and explicit refusal to call strength a calibrated height in metres. **Clarify, optionally:** a short reading route, “build heights → derive directions → compare both under the lamp.” **Change, recommended:** replace “For an **independent** variation, change `REPEATS`…” with “For a **guided** variation, change `REPEATS`…”. The edit and prediction are already supplied; choosing another count or gain afterward is the independent step. **Missing steps:** no construction gap found.

## 4. Water — visible height and separate support

I carried forward the point, coat method, slope reasoning, and box/collider construction. The squares are replaced by a subdivided XZ plane; the new material adds a normalized noise sum, retained sampling address, vertex-normal calculation, and visible height. The custom rendering bound and separate bridge are new host responsibilities. Buoyancy toys remain an additional museum example.

NORMAL changed illumination while changing **zero** sampled silhouette pixels. HEIGHT changed **366** silhouette samples in the diagnostic framing. The original circle path produced different quarter- and three-quarter-phase images; my out-and-back line path produced identical images at those phases. Both returned after a full turn and remained unchanged while held. A ray hit the original glass at **Y = 1.0699999**, its expected top, rather than treating the visible water as support.

The reflection's question about what carries the body is well placed here. The probe establishes separate rendering and collision constructions, but it does not establish the experience of walking on glass, toy buoyancy, or room-scale access. This is the densest new shader lesson: noise, normalization, vertex stages, interpolation, slopes, and bounds must be kept distinct. The printed three-part explanation provides that structure.

**Keep:** the normalized height-bound arithmetic and distinction between resource vertices, rendered vertices, and collision. **Clarify, optionally:** an explicit first-reading order of `field`, `vertex`, and host bounds. **Change:** none required. **Missing steps:** none in the printed program; my camera and physics-world corrections were diagnostic support, not book repairs.

## 5. Pink — choosing a composition

The point/cube, coat, local coordinates, repeated mask, normals, and lamp all return. Water's moving plane is set aside. Three amounts now combine pigment, an eye-relative rim, and emission. The supplied museum surround and sofa projection are clearly distinguished from the small UV reconstruction.

BASE removed visible additions, and toggling back restored the exact capture. With all diagnostic lamps and ambient light disabled, emission brightened its own sphere while an adjacent ordinary grey receiver stayed black. My variation changed the rim exponent from three to one. A sample inside the sphere's edge increased in green from **0 to 0.196078**, confirming that the rim spread inward. I chose local point **(0.25, 0.9, 1.3)**, amounts **(0.6, 0.3, 0.4)**. I would remove rim first to keep the circles legible. That is an authored preference, not something the tests proved worthwhile.

The reflection's emission-versus-lamp distinction matches the experiment. SETTING, the old collection, and the plural body ask wider questions without becoming mandatory extra builds. The lesson consolidates familiar operations after Water's larger jump.

**Keep:** separate channels, BASE/composed comparison, and the explicit statement that PALE changes more than the additions. **Clarify, optionally:** describe toward/away movement in terms of local Z when the learner stands elsewhere; the local-coordinate formula is already authoritative. **Change:** none required. **Missing steps:** none; manually recording a composition is honestly distinguished from saving it.

## 6. A field kept — using completed state again

I retained the point, cube/plinth, material sharing, and data/display distinction. The new capability is the completed field becoming the next update's input. The packet explicitly supplies the packed transport and render-target scheduler; I did not need to invent them. I reconstructed all five files and instantiated the declared push-button dependency.

The first seeded interior update gave **U = 0.027595, V = 1**, within the predicted quantization of 0.0275. Two eight-step GPU batches were byte-identical to sixteen separately completed steps. INK altered the display without changing retained data. CLEAR followed by STEP preserved equilibrium. RUN advanced the model and HOLD stabilized its completed output.

My variation disabled wrapping on the old-state sampler. I planted a disc at `(0.02, 0.5)`, initially affecting only the left edge. After one step, the periodic original's opposite edge read **(0.850061, 0.149939)**; the clamped version remained **(1, 0)**. This establishes a causal effect of the boundary rule beyond the offered FEED exercise. I also placed two marks at `(0.38, 0.5)` and `(0.62, 0.5)` and advanced exactly 64 steps. The result retains two visibly separate regions; the changed data, rather than an intricate-looking shape, is the evidence of evolution.

The reflection has the closest operational alignment in the sequence: recolouring, erasure, equilibrium, feedback, and a limited retained trace can each be distinguished. The implementation is the largest jump, but the two-pass reading route and explicit supplied-transport status keep that jump honest.

**Keep:** the two passes, one-cell arithmetic, equal-step comparison, and field/display separation. **Clarify, optionally:** visually mark `initial_texture → state_texture → _schedule → _completed` as a route through the supplied scheduler. **Change:** no printed-code repair. **Missing steps:** physical press and held-point selection remain unverified; signal-to-action behavior and field operations were tested.

## Density across the route

Counts below are rough whitespace word counts including headings/footnotes; code is excluded from tutorial prose. They describe volume, not measured learner effort.

| Hall | Files / code lines | Tutorial prose words | Reflection words |
|---|---:|---:|---:|
| Shaping | 3 / 112 | 1,222 | 1,661 |
| Patterns | 3 / 119 | 1,111 | 1,559 |
| Materials | 4 / 180 | 1,343 | 1,489 |
| Water | 3 / 173 | 1,534 | 1,263 |
| Pink | 3 / 119 | 1,253 | 1,252 |
| Retained field | 5 / 282 | 1,382 | 784 |

Complete programs make reconstruction self-contained but repeat substantial earned construction. The changed-function-first instructions work. Materials and Water deserve the learner's longest focused pause. State needs its supplied scheduler boundary maintained: the first task is tracing feedback and testing consequences, not memorizing sixteen viewport lifetimes or bit packing. The reflection generally gets shorter as implementation complexity rises. No additional prerequisite system is warranted by these results.

## Preserved first failures and limits

- **Shaping `original-01.log`:** I moved a frozen body directly before synchronizing with physics. The next physics update restored its earlier transform, so the radius stayed 0.30. The probe now synchronizes and sets physics state. The listing was untouched. Python's Windows console also failed to print a Unicode character from the log; stdout encoding was corrected.
- **Water `original-01.log` and `variation-01.log`:** my raycast accessed `vp.world_3d`, a null explicit override in a viewport with its own effective world. `study.get_world_3d()` is the appropriate probe lookup. Both attempts were stopped. I also mistakenly launched the second after the first tool yielded, briefly overlapping these failed jobs. Their outputs were discarded as success evidence, logs retained, and the repaired original/variation run serially. A watchdog now bounds coroutine failures.
- **Field `original-01.log`:** I compared raw RGB8 initial-image bytes with RGBA8 GPU-readback bytes. The values were unchanged; the formats differed. Converting only the probe snapshots to the same format made the equilibrium comparison valid. No shader or runner change was needed.

All latest logs are free of script/shader/parse errors. A project-bootstrap unrecognized-UID message appears across runs, along with expected missing-player/Jolt warnings in this synthetic host. The field process also reports an exit ObjectDB leak warning. These are recorded, not silently recast as clean project-wide validation; their causes were outside the allowed lesson-source investigation.

I inspected six final captures visually as well as using numeric checks. Representative evidence: [annulus](shaping/variation-start.png), [sheared pattern](patterns/variation-start.png), [height relief](materials/original-height.png), [displaced water](water/original-height.png), [chosen broad-rim composition](pink/variation-chosen-composition.png), and [two marks after 64 steps](field/original-two-marks-64.png). These are renderer observations, not proof of understanding, physical interaction, visual accessibility, artistic value, or cross-driver performance.

The only recommended direct text edit is the Materials guided/independent label. The parent reports that this has now been changed to “For a guided variation…” with an explicit subsequent learner choice. The parent also reports separate Shaping launcher/coordinate wording corrections after its museum check; I did not inspect that work or use it as evidence for the six reconstructions. My packet and extracted originals remain frozen. The remaining Keep/Clarify notes are optional reading aids, not blockers or requests to expand the curriculum.
