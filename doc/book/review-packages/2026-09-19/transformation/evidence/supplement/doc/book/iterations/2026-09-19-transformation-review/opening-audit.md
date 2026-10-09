# Transformation opening audit — 19 September 2026

Scope: live `Trans_Pre`, `Trans_Introduction`, and `Trans_Translation`; initial production audit followed by the narrow pickup registry correction recorded in section 6. Guidance: `doc/book/REVIEW_PRINCIPLES.md` and the frozen review and `DECISIONS.md` under `doc/book/review-feedback/2026-09-18/transformation/`. No manuscript, map, role, or runtime implementation was edited by this opening-hall work.

## Decision

Preserve all three opening manuscripts and their existing primary encounters. Their different uses of recurrence are supported by the live map and implementation. The consequential gap identified by the outside reviewer is incomplete review evidence: primary utility implementations and existing runtime results were omitted from the bundle. Repair that evidence path before proposing encounter or prose changes.

The local audit also confirmed stale pickup registry metadata, corrected in a subsequent narrow supporting-source edit. The correctly described contact-collection encounter remains unchanged. Full human traversal, tracked headset comfort, and learner understanding remain unverified.

| Hall | Present maturity | What is already supported | Appropriate intervention |
|---|---|---|---|
| Pre | Preserve: working manuscript and staged cumulative demonstration | Still collectible pickup; three retained moving demonstrations; four further collectible pickups; live source and earlier actual-museum physics evidence | Supply existing evidence; observe a novice distinguishing cumulative additions before changing anything |
| Introduction | Preserve, with targeted evidence repair | Three different crossing mechanisms and a movable bank; held crossing, bank control, gap and bypass physics reports; captures | Package utility dispatch and rider implementation. Keep timed crossing and physical control reach as separate human checks |
| Translation | Preserve, with targeted evidence repair | Seven authored vectors, thirteen pickup contacts, two door constraints; real XR body pickup report and broad transport regression | Package sources and test limits. Verify complete joins and return boarding without treating individually tested journeys as a full learner walkthrough |

## 1. Primary utilities were omitted from the review package

**Passage and purpose — TEXT.** Introduction `final.md:21–30` distinguishes the cube's displacement from the extra rider relation that makes transport. Its `final.md:40–66` distinguishes visible scale from collision and alignment from changed dimensions. Translation `final.md:35–44` returns to the same rider mechanism so carrying can meet pickup detection and leave a persistent absence. These are different consequences of a learned operation.

**Evidence — SOURCE.** `commons/data/artifact_roles.json:276–303` explicitly assigns Introduction's `tc/sc/rc/adjustable_landing` and Translation's `tc/pick_up_cube/translation_cube_demo` as primary. Primary order is at `:2120` and `:2142`; Pre's primary pickup is at `:1133` and `:2622`. The utility primaries are real map placements:

- `commons/maps/Trans_Introduction/map_data.json:477`: `tc:2:z:auto`.
- Same file `:566`: `sc:3:0.5:1:0#seat:deck`.
- Same file `:642`: `rc:90:y:4:0#profile:bridge#seat:deck`.
- `commons/maps/Trans_Translation/map_data.json:1052`, `:1205`, `:1281`, `:1349`, `:1519`, `:1579`, `:1647`: all seven carriers, including explicit deck heights and the down-forward and x/z diagonal directions.

The frozen `doc/book/review-packages/2026-09-18/transformation/sources/` contains the pickup and `rotation_studies/rotation_rider_deck.gd`, but lacks `UtilityRegistry.gd`, `GridUtilitiesComponent.gd`, and the tc/sc/rc implementations. This agrees with the assessment in the existing feedback `DECISIONS.md`. The utility implementations were not absent from the project.

**Missing layer.** Review packaging and access to already existing verification.

**Recovery.** Recover the utility registry, scene roots, dispatch and placement context, and the actual helper methods listed below. The existing utility role assignments already promote the right encounters; promoting another decorative or secondary artifact would not repair this gap.

**Decision and completion condition.** Repair future package discovery and include the existing reports with explicit limits. Preserve the frozen package. This opening-hall pass is complete when a reviewer can resolve the primary tokens to the actual implementation and distinguish source, prior tests, and remaining human checks.

## 2. Exact utility dispatch and dependency chain

These are source-review dependencies, not a claim that a bounded source bundle is a standalone runnable Godot project.

| Layer | Exact live source and relevant lines | Why it belongs |
|---|---|---|
| Token → scene | `commons/grid/UtilityRegistry.gd:24` (`wp`), `:210` (`tc`), `:231` (`rc`), `:238` (`sc`), `:432–450` | Utility tokens do not resolve through ordinary artifact registries; scene directory is `commons/scenes/mapobjects/` |
| Cell parsing/configuration | `UtilityRegistry.gd:549`, `:614`, `:700`, `:732`, `:786` | Parses `#deck`, `#seat`, `#profile` and direction/size/rotation parameters; applies the configured behavior |
| Grid spawn and seating | `commons/grid/GridUtilitiesComponent.gd:365–426`, `:701–719`; `UtilityRegistry.gd:901–924` | Parameters are applied before `_ready`; geometry determines the standing top; `#deck` overrides an ambiguous lift socket |
| Grid floor origin | `commons/grid/GridCommon.gd` (`surface_world_y`); `commons/grid/GridStructureComponent.gd` (`find_highest_y_at`) | Explains deck coordinates and nearby-bank discovery |
| Source grid itself | `commons/grid/GridSystem.gd`, `commons/grid/grid_system.tscn` | Actual source maps build these grids; runtime studies are not merely flattened museum stamps |
| Actual museum embedding | `commons/scenes/endless_museum.gd:10921–10942`, `:11274–11295` | Instantiates live GridSystem with spawning disabled, puts deck tops at museum level, and widens transport detection for the museum walker |
| Stamped utility branch | `endless_museum.gd:7626–7630` | Shares `UtilityRegistry.apply_params`; useful context for grid/museum parity |
| Museum rider recognition | `UtilityRegistry.gd:655–664`, `:994–1014` | `make_carriable` adds layer 1 to Area masks; `carry_embedded_rides` applies this to existing embedded transport cubes and records ride cells |
| tc scene and behavior | `commons/scenes/mapobjects/transport_cube.tscn`, `transport_cube.gd:195–257`, `:272–302`, `:398–429` | Actual movement/carry, support acquisition, jump/step release, body recognition |
| tc inherited geometry | `commons/primitives/cubes/cube_scene.tscn` and `.gd` | The 1 m physical cube is a nested scene, so measuring an Area or assuming the parent is the collider is wrong |
| tc primitive helper | `commons/primitives/shared/solid_primitive_finish.gd` | Preloaded by `cube_scene.gd:3`; a traversal allowing only two hops from the utility scene can miss it |
| XR carry semantics | `addons/godot-xr-tools/player/player_body.gd:377–390`, `player_body.tscn` | `XRToolsPlayerBody.teleport()` applies an incremental target pose to the physical body and its origin together; transport uses this API, not an endpoint jump |
| XR rig lookup | `addons/godot-xr-tools/misc/xr_helpers.gd` | `player_body.gd:187–196` accesses `XRHelpers` as a class reference, which a quoted-resource-only scanner may miss |
| sc implementation | `commons/scenes/mapobjects/scale_cube.tscn` and `.gd:89–118` | Visible scale and BoxShape dimensions update together; maximum/minimum hold behavior is explicit |
| rc implementation | `commons/scenes/mapobjects/rotation_cube.tscn` and `.gd:55–56`, `:104–137` | Opt-in bridge is 3.6 × 0.2 × 1 m; collider follows mesh transform; step-and-pause mode is explicit |
| wp geometry and placement | `commons/scenes/mapobjects/walkableprism.tscn`; `GridUtilitiesComponent.gd:557–589` | Mesh and concave collider have matching local transforms; placement handles half-cube seating and yaw |
| Utility shaders | `commons/resourses/shaders/Grid.gdshader`, `SimpleGrid.gdshader` | Grid shader is dynamically loaded by sc/rc and used by the inherited tc scene; wp uses SimpleGrid |

The tc rider helper is inside `transport_cube.gd`; it is not a separate `XRRiderAnchor` script. A search including ignored files found no `XRRiderAnchor` class/reference under `commons/` or `addons/`. `rotation_studies/rotation_rider_deck.gd` is a separate helper for Rotation's upright decks and uses `XRToolsPlayerBody` too. It was already included in the frozen package; do not call all rider helpers missing.

`transport_cube.gd:281–290` also rebases its own XR moving-ground contact after explicit carry to avoid applying the same platform displacement twice. `player_body.gd:809–859` is the corresponding moving-ground estimation/application context. Supplying only the manuscript snippet loses this relationship.

## 3. Existing runtime evidence and its limits

The reports below were inspected in this audit; their original dates are retained. None is presented as a fresh successful run on 19 September.

| Existing report | Recorded outcome | What it measures | What it does not establish |
|---|---|---|---|
| `doc/space/transformation-refresh-2026-09-16/Trans_Pre-checks.json` | 8/8 | Actual museum grid; eight pickups; three non-collectible demonstrations; actual XRTools body contact collects first still pickup and awards exactly one point | Novice recognition; headset visit; complete ramp route |
| Same directory, `Trans_Introduction-checks.json` | 15/15 | Real embedded grid; sc/rc mesh/collider tops; 3.6 m plank; aligned 0.3 m overlaps; gravity capsule crosses both held openings | Timed four-second crossing; physical controller reach; tc ride in this specific check |
| `doc/space/transformation-experiments-2026-09-16/landing-checks.json` | 28/28 | Actual museum adjustable bank, slider/reset signals, held plank, 0.70 m seam at full displacement, support loss, bypass, full exit after reset | Ordinary plank timing and tracked hand reach |
| `doc/space/transformation-alignment-2026-09-17/Trans_Pre-museum.json` | 8/8 | Later arrival/observation and collection alignment | Human learner verification |
| Same directory, `Trans_Introduction-museum.json` | 4/4 | Arrival support, suppressed grid spawn, entrance alignment | All three crossings |
| Same directory, `Trans_Translation-museum.json` | 58/58 | Seven actual museum carriers, thirteen declared pickup locations/heights, actual XR body carried through detection volumes, collection of all thirteen | Complete walk between rides, boarding from each bank, all return joins; the probe creates a fresh rig on each platform and adjusts speed/delay |
| `doc/space/transformation-refresh-2026-09-16/translation-permissions-checks.json` | 19/19 | Both door modes, authored yaw, measured handle heights (about 1.30/1.28 m), pickup/drop signals, gated vs simultaneous directions, common destination/reset | Comfortable human reach/grab; live tracked controller input. The test freezes the knob and explicitly emits pickup/drop signals |
| `ada_run/transport-cube-vr-checks.json` | 116/116 | Real physics and XRTools body for ±x, ±z, up, exact down-forward direction; rotated/offset rig; desktop carry; return; once-only body/eye displacement; natural XR boarding; jump/step release; rejected side/below boarding | Each authored bank join, all player configurations, tracked headset or live controllers |
| `ada_run/translation_y_descent_checks.json` | 12 checks, no failures | Saved single-ride descent test output | The minimal report lacks per-check values and source hashes; inspect probe before generalizing it |

**Freshness check.** The current `transport_cube.gd` SHA-256 is `6309d0221cdaee631de109d40f230ad3c6be260df9758f37de70f8ced713db3d`, and current `probe_transport_cube_vr.gd` is `54ebc6870230abfa94fe329c11587312d8a25301014ffa4841575ad130009997`. Both exactly match the corresponding fields in the saved 116-check report. That strengthens attribution to current inspected code; it does not establish that every dependency/environment remains unchanged.

All three current `final.md` byte hashes match `doc/space/transformation-alignment-2026-09-17/text-map-alignment.json`. Pre and Translation map hashes match that record. Introduction's byte hash differs, but its current map has no line-content differences against the 18 September frozen map; do not describe the earlier byte hash as current. The evidence index beside this report records fresh hashes and bundle presence.

**Available probes.** `commons/testing/probe_transformation_opening.gd` runs Pre/Introduction in the actual museum. `probe_adjustable_landing.gd` isolates the bank variable. `probe_transformation_alignment.gd:132–174` performs the seven pickup rides. `probe_translation_permissions.gd` exercises the two door modes. `probe_transport_cube_vr.gd:267–305` runs the broad carry regression. `probe_transport_cube_parity.gd` verifies shared parser/scene configuration; `probe_embedded_grid_rides.gd` verifies layer widening and known ride spans. `probe_translation_course.gd` additionally measures each authored ferry endpoint and uses a gravity capsule to step off each stopped ferry onto its landing. These tests answer different questions; parser parity is not a traversal test.

**Initial fresh run attempt — INCONCLUSIVE.** A copy of `probe_translation_course.gd` with only report destinations redirected is retained as `probes/opening-probe-translation-course.gd`. It was launched with Godot 4.6 `--headless --xr-mode off --audio-driver Dummy --path ... --script ...`. The owned process remained nearly idle, produced an empty `evidence/opening-translation-course.log`, and created no report. It was stopped after checking its exact PID/name/start time. This was an inconclusive launch. No original probe or historical report was overwritten.

**Fresh retry — RUNTIME TEST, partial support and stale assertions.** After the main agent isolated archived review sources from Godot's script cache, the same copied course probe ran to completion with an explicit workspace `--log-file`. It recorded **85 checks, 17 failed assertions** in `evidence/opening-translation-course-checks.json`; full output is `evidence/opening-translation-course-retry.log`. This is not an all-pass test. All seven carrier starting heights, target heights, translation-only settings, rider detection, carried arrival positions, and arrival surface heights passed. The down-forward, vertical-lift, and reverse-x step-off assertions also passed.

- Thirteen failures compare the **instantaneously bobbing** pickup positions with the authored fixed mean positions at a 0.01 m tolerance (`probe_translation_course.gd:65–69`). The later actual-museum alignment probe correctly checks `original_y` and weak references instead. The old course probe's later collection assertions also select pickups by their current position and can therefore pass vacuously; do not rely on them alone. The fresh runtime log independently records thirteen real `PickupCube: Collected! Adding 1 points` calls and no script errors, but the dated 58-check actual-museum report is the stronger per-cell collection evidence.
- Four failures are the combined short step-off assertion: more than 1.4 m forward, no loss of support, and ending exactly at the terrace's base height after 48 physics frames. They occur at `z_first`, `x_sideways`, `z_high`, and `xz_diagonal`, whose destination terraces retain `wp` ramps. A measurement-only diagnostic copy, `probes/opening-probe-translation-diagnostic.gd`, reran `--ride=z_first`: start `(3,0.01,10)`, final `(3,0.442878,11.33196)`, minimum Y `0.000935`. The capsule stays supported and climbs the retained ramp, while the assertion expects Y = 0 and slightly greater forward travel. See `evidence/opening-translation-diagnostic.log` and `opening-translation-diagnostic_z_first_checks.json` (14 checks, 3 failed assertions, including the two animated-position checks). This first measured failure does not demonstrate falling or a missed landing. The other three were not separately instrumented.

The fresh result identifies an old probe's assumptions that need updating before using it as an all-joins certificate. It does not justify deleting the ramps, weakening the transport passage, or claiming all return joins work. Any probe maintenance should compare saved pickup means and retained object references, then separate landing support from the subsequent authored ramp traversal. Preserve this run as evidence rather than rewriting its failed checks.

## 4. What the text, roles and placements already do

### Pre: cumulative additions survive curation

**TEXT/SOURCE.** `final.md:7`, `:17`, `:38–42` describes the still collectible, linear rise/fall, cumulative turn/scale, and four level pickups. `map_data.json:628`, `:650`, `:683`, `:716` configures exactly that four-stage sequence; `:771`, `:793`, `:804`, `:815` retains the final four collectibles. `pick_up_cube.gd:179–198` implements the quoted rotation/lerp/pulse; `:229–249` sets each motion variant and demonstration hold; `:320–348` guards demonstration collection and removes a collected cube. The three axis markers remain secondary; the `wp:0`/`wp:180` ramps remain in the map.

**Recovery candidates inspected.** `y_translation_cube`, `rotation_oscillation_cube`, `uniform_scale_marker`, and two `health_cross` placements remain. They support or accompany the cumulative pickup rather than replace a missing operation. No restoration/promotion is needed to support this manuscript.

**Verification remaining.** A novice should notice stillness before collection and identify the fourth stage's changing edge separation as scale. Existing physics evidence cannot settle that perceptual question.

### Introduction: operation becomes passage, then the background changes

**TEXT/SOURCE.** `final.md:21`, `:40`, `:66` numerical claims match the configured utility values and implementations. The 0.3 m bank overlap and 1 m travel at 0.25 m/s (`final.md:80–91`) match `commons/artifacts/adjustable_landing/adjustable_landing.gd:6–9`, `:77–87`. The manuscript already says the readout cannot decide what a body can do with the seam. Preserve that evidence boundary.

**CAPTURE.** This audit visually inspected `doc/space/transformation-experiments-2026-09-16/landing-controls.png` and `landing-gap.png`: the BANK control, aligned 0.70 m readout at +1 m, orange plank, shifted landing, and side aisles are visible in those saved views. Images establish the rendered configuration, not a new traversal or comfortable hand reach.

**Recovery candidates inspected.** Current map placements retain `matrix_4x4_viewer`, `z_translation_cube`, `transform_composition`, `rotation_gimbal`, and `balance_puzzle` as secondary. The closing mention of matrices and order of operations therefore has neighboring support. Roles also remember some unplaced older entries such as `invariants_demo` and `homogeneous_coordinates`; their role presence alone is not evidence of current placement. There is no need to promote them to solve the utility packaging omission.

**Verification remaining.** Cross the ordinary timed sc/rc openings with desktop and tracked XR bodies; approach/use bank controls physically; compare measured seam to the actual body's behavior. Existing held-state capsule tests intentionally isolate geometry.

### Translation: known displacement meets collection and permission

**TEXT/SOURCE.** The seven live tokens normalize their directions through `UtilityRegistry.transport_params` and the scene's movement setter. The downward vector `(0,-3,2)` with length `3.6055513` agrees with three metres down/two forward (`final.md:27`); the `(1,0,1)` direction with length `11.3137085` agrees with eight metres on both x and z (`:50`). No token adds `#rot` or `#scale`; explicit decks are retained. The route manifest is `map_data.json:2882–3062`.

The return of `_translate_rider` (`final.md:35–44`) adds an encounter with another system: carried body contact calls pickup `collect()`, and reversing transport does not recreate removed pickups. Do not cut it merely because Introduction already explained shared movement.

The door tokens at `map_data.json:2805` and `:2809` are `lift_lateral + rail` and `free + ghost`. `translation_cube_demo.gd:305–310` gives the free study both freedoms together; `constrained_door.gd:143–168` performs the guided projection/clamp. The torus described at `final.md:73` remains placed at `map_data.json:2347` and remains secondary. It supplies the promised transition to combining translation and rotation.

**Recovery candidates inspected.** Three axis markers and the torus remain secondary in both roles and current map. The archived predecessor rooms and compilation recipe are documented by `doc/space/translation-merge-2026-09-09/README.md`. Nothing found justifies rerunning the authoring compiler: it overwrites the combined map and is not a runtime hook.

**Verification remaining.** Walk between all seven rides, board naturally from both ends, and complete outbound/return landings at ordinary timing. The saved XR report strongly supports the carry mechanism; the actual museum pickup report proves contact collection along individual outbound trips, not the entire continuous course.

## 5. Narrow supporting-source discrepancy and bounded follow-up

**Confirmed metadata discrepancy — SOURCE, before correction.** `commons/artifacts/registry/commons_artifacts.json:10760` called `pick_up_cube` a grab-and-carry object; `:10773–10774` promised grabbing/carrying and dropping onto targets. The exact original is retained at `before/pickup-registry/commons_artifacts.json`. The referenced scene is `commons/scenes/mapobjects/pick_up_cube.tscn`, whose `pick_up_cube.gd:320–363` collects on recognized body overlap, awards points, plays sound, and frees the pickup. Pre `final.md:7/42` correctly instructs walking into it; Translation `final.md:44` correctly describes Area contact. This misleading registry record was also copied into the frozen artifact index, which remains untouched.

**Missing layer / decision.** Registry metadata. The initial audit proposed describing contact collection, configurable motion, and retained demonstration mode while preserving manuscript and behavior. The main agent subsequently assigned that exact bounded correction; section 6 records its application and verification.

**Lower-priority implementation difference, not a demonstrated learning gap.** `GridUtilitiesComponent.gd:386–389` calls the parameter handler only for nonempty parameters; the `wp` half-cube seating correction is inside that handler at `:557–567`. Bare `wp` therefore differs from `wp:0`. Translation's six `wp` tokens are bare (`map_data.json:1171`, `:1247`, `:1485`, `:1732`, `:1808`, `:1817`) and sit on flat terraces in the inspected structure. Pre's real step ramps use explicit `wp:0/wp:180` and reach the correction branch. Source establishes the dispatch difference; the fresh first-ride diagnostic also measures the supported capsule rising on the bare ramp. Neither establishes a failed Translation join or a missing manuscript encounter. Do not change all ramps or rewrite the hall on this basis. If pursued separately, measure bare versus explicit prism tops in the real grid and identify a user-visible failing transition before selecting a repair.

No editorial cut, new artifact, or promotion is recommended from this opening audit.

## 6. Applied pickup registry correction

After the initial audit, only the `pick_up_cube` entry in `commons/artifacts/registry/commons_artifacts.json` was corrected. Its capacity, description, interactions, QFEP connection, and tags now describe collection through player-body contact, point/audio/removal consequences, configurable still/bob/turn/scale/composed motion, and a retained `hold:demo` specimen. The misleading `grabbable` tag became `collectible`.

The observation instruction asks the visitor to pause before approaching. It does not invent a timed collection delay: `pick_up_cube.gd:105–108`, `:247–252`, and `:320–323` show that `hold:demo` disables detection and guards `collect()`, retaining the demonstration. Motion variants and sine/lerp behavior are supported by `:80–103`, `:179–198`, and `:227–246`. The registry now names that distinction without changing the live encounter.

Before editing, the entire registry was copied byte-for-byte to `before/pickup-registry/commons_artifacts.json`. Eight string replacements were confined to the existing pickup entry; the file was not reformatted. Verification parsed the JSON, compared all other entries, checked the scene reference, and compared the exact file text outside the pickup entry. Results are in `evidence/pickup-registry-correction.json`:

- Valid JSON; 173 artifact entries before and after.
- All other 172 artifact entries unchanged.
- Text outside the pickup entry identical, with all 16,314 LF line endings retained.
- Only `capacity`, `description`, `interactions`, `qfep_connection`, and `tags` changed; scene and runtime source unchanged.
- Registry SHA-256 before: `76b2509e7406332a44e04662eb8b08a9a0883c64c3a332f17d14a279e7d61651`.
- Registry SHA-256 after: `6c8d90077c872a571be2cbab86c66ded0aa87be0e57fd08e0fa6740823a3bf1c`.

No new runtime test was necessary for this metadata-only correction. The earlier physics evidence and its limitations remain as recorded above. The fresh package should capture this corrected entry; the 18 September source package and its review remain historical evidence.
