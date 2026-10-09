# Trans_Rotation: current encounter and evidence audit

Date: 2026-09-19. Scope: the current Rotation manuscript, map configuration, four encounter families, and the runtime evidence relevant to the received Transformation review. Read with [REVIEW_PRINCIPLES.md](../../REVIEW_PRINCIPLES.md), the preserved [source-aware review](../../review-feedback/2026-09-18/transformation/01-with-sources.md), and its [DECISIONS.md](../../review-feedback/2026-09-18/transformation/DECISIONS.md). This audit leaves those received documents intact.

**Intervention scope: preserve the hall; make two targeted maintenance repairs.** The body-width claim is supported by a fresh current-source collision run. The tunnel and carousels do distinct work after the axis lesson and should remain. Correct the carousel comments and the localhost footnote. A separate Godot cache fault discovered during verification was repaired by the parent pass; the compact hall probe then passed. It is not a reason to weaken the manuscript.

## Current encounter and recurrence

TEXT inspected: `commons/maps/Trans_Rotation/final.md`, `summary.md`, `critical.md`, and the relevant tutorial instructions. SOURCE inspected: `map_data.json`; rotation registry; `wall_crossings.gd`, `rotation_rider_deck.gd`, `array_compare.gd`, `array_body_comparison.gd`; `booleanTunnel.gd`, its scene and hollow-cube scene; and `carousel_cake.gd`.

The map remains 39 × 60, with eight actual placements and four primary encounter types:

| Placement | Current configuration | Work of this encounter |
|---|---|---|
| Blades `(19,11)` | Full-size Y/X/Z centre-pivot blades; 8.4 m length and 2.4 m width; upright X/Z endpoint decks | The visitor brings translation's passage to a fixed centre and discovers that an upright supporting surface is an additional rule. X carries forward/up; Z sideways/up. |
| Array `(19,25)` | Four bands, each two columns × six rows; 2 m centre spacing; 18° row increments; fixed X-then-Y-then-Z composition | Rotation becomes a static field the body traverses. Width changes the collision response while the array and forward instruction remain fixed. |
| Tunnel `(19,42)` | Five segments; 18° increments; `accrual:ramp`; vertical offset −0.65 m; full scale | Angle varies across architectural neighbours. Subtraction makes the openings; walking supplies the changing view. |
| Five carousel niches | Cake/column at `(6,43)`/`(32,43)`, ziggurat/spindle at `(6,49)`/`(32,49)`, flare at `(6,55)`; scale 0.4; all `gallery:clean` | Angular rate varies across eight layers through time. Five profiles hold heights and speed rules constant while changing the surrounding space. |

The tunnel's `spacing=3` and its hollow cube's 3 m depth support the manuscript's fifteen-metre run. Carousel layer rates are `0.5 * pow(1.2, i)` radians/s. The blade/deck source supports twelve-second holds, twelve-second half-turns at 15°/s, and return along the upper arc. These are SOURCE findings, not new headset observations.

The return from blade to array to tunnel to carousel changes centre, body action, spatial repetition and temporal rate. Consolidating these into one demonstration would remove those changes. No missing artifact capability or placement was established that warrants development in this pass.

## Body widths: retain the measured observation

**Passage and purpose.** “Here the narrow body catches on a ridge; the wider one can slide sideways and continue.” This rejects a simple larger-body/worse-access assumption and makes the change of route part of the result. The next paragraph already limits the claim: the capsules neither jump nor choose a detour, and a stopped trial has not exhausted the space.

**Evidence and freshness.** Before the comment repair, all six runtime scripts listed in the 2026-09-17 alignment record had exactly matching SHA-256 hashes. The two array scripts also match the comparison retained with the 2026-09-18 feedback. Hash equality does not establish an unchanged runtime environment, so the existing body probe was rerun against the current project.

RUNTIME TEST: a copy of `ada_run/probe_rotation_body_comparison.gd`, with only its output directory changed, ran in Godot 4.6 using `--headless --xr-mode off --audio-driver Dummy`. It exited 0 after 66.494 s within a 160 s bound: **40 checks, zero failures, zero script errors**. The dated reports were not overwritten.

| Z-band capsule | Result | Forward travel | Lateral displacement |
|---|---|---:|---:|
| Narrow, 0.44 m width | BLOCKED | 4.6619186401 m | 0.0437870026 m |
| Wide, 1.20 m width | ARRIVED | 14.0174846649 m | 1.1545791626 m |

Both Z records match the 2026-09-16 report exactly at its stored precision. All eight zero-angle control cases arrive. The probe also checks equal height/speed/input, collision masks and desktop-body exceptions, four simultaneous witnesses, and replay clearing/scheduling. Replay is verified by emitting the installed button's signal, not by a physical press or controller ray.

**Decision:** preserve the specific empirical sentence and its existing limitations. The source-only review's request for runtime evidence is satisfied for this bounded collision claim. The proposed conditional rewrite is unnecessary on this evidence.

**Limits:** source-grid CharacterBody3D trials with GodotPhysics3D, 1.6 m height, 2 m/s constant forward input, gravity 9.8 m/s², 45° floor limit and 0.15 m snap. This is one fresh repetition of a dated result, not a solver/version stress study, autonomous route search, full museum traversal, headset test or evidence of learner comprehension. UID/root-certificate startup errors and registry/environment warnings remain in the log; no script errors occurred in this successful run.

Evidence: [current results](rotation/rotation-body-comparison-checks.json), [run command and timing](rotation/body-probe-run.json), [output log](rotation/body-probe-output.log), [machine-readable verification](rotation/verification.json).

## Carousel comments: targeted repair applied

**Passage and purpose.** “Walk between them and compare the room each leaves around itself.” The five configured `gallery:clean` placements support this comparison: `_generate_colliders()` chooses `_vis_radii` for that branch and `layer_radii` otherwise.

**Missing layer:** source commentary. Two older comment blocks described every profile as appearance-only with unchanged colliders. Both now distinguish the default collider radii from the clean-gallery branch. Executable code, map placement and manuscript were not changed by this repair.

The [before snapshot](rotation/before/carousel_cake.gd) preserves the working copy before editing. Removing only full comment lines leaves byte-identical remaining content, with SHA-256 `913534c320d391956f467ebd3976d2e2f88563011e4b9b8ad5f0c7ea4b7a0f80` before and after. The proof is recorded in [verification.json](rotation/verification.json).

This maintenance corrects the current branch's explanation. It does not establish that a person has walked between every profile or felt the moving upper layers in VR.

## Footnote: durable repository target

**Missing layer:** distribution link. The localhost URL requires the author's local server. The existing `doc/research/possible-bodies/transformation-zoetrope.html` contains the described twelve-pose rotating drum and axial sweep, including the cube/cylinder and triangular-profile/cone distinction. Its JavaScript and CSS are inline; no network assets or fetch/import calls were found. Its only linked local resource is its sibling `index.html`.

**Proposal supplied to the parent pass:** from `commons/maps/Trans_Rotation/final.md`, use `../../../doc/research/possible-bodies/transformation-zoetrope.html`. This resolves to the existing repository page and removes the server dependency for local/repository reading. Standalone book/export output should include or rebase this resource; a repository-relative link alone does not prove every distribution format resolves it. The footnote's own “awaiting placement” and headset caveats remain appropriate. The proposed link change is handled by the parent pass, not this agent.

## Remaining runtime boundary and infrastructure finding

The retained [2026-09-16 ride report](../../../space/rotation-passages-2026-09-16/rotation-rides-checks.json) has 53 passing checks using an actual XRTools rig in the actual endless-museum grid. It covers body/camera transport, acquire/release and sampled body clearance, but uses 60°/s turns and 0.7-second holds. The accompanying notes record 1,638 capsule poses. This is existing executable evidence, not a fresh run or tracked headset/comfort test. The current source hashes match the later alignment record. The retained compact report has 42 passing checks including tunnel capsule sweep and still-aisle support; it is also dated evidence.

A fresh copy of the existing compact probe, with only output paths redirected and `--quick`, exited 1 after 6.498 s. Four parser checks and grid-build detection passed, but encounter discovery failed. The log shows global-class parse conflicts for AudioSynthesizer, HangarKit, ModifierStack, CubeScene, BooleanTunnel and CarouselCake. At inspection, `.godot/global_script_class_cache.cfg` resolved all six names to frozen `doc/book/review-packages/2026-09-18/.../sources/` copies instead of live sources. The earlier successful body probe had no such script errors. The quick probe reached no tunnel-sweep or carousel assertions, so no fresh success is claimed for those checks.

**Decision and resolution:** preserve the failed [run metadata](rotation/compact-probe-run.json) and [log](rotation/compact-probe-output.log) as infrastructure evidence. The parent pass added review-package isolation and repaired the cache, then authorized one rerun. `doc/book/iterations/.gdignore` already excludes this audit's snapshots from global-class discovery.

RUNTIME TEST after that repair: **33 checks, zero failures, exit 0 in 11.135 s** within a 60 s bound, with zero script errors. The [fresh report](rotation/after-isolation/rotation-compact-quick-checks.json) confirms all eight placements/four encounter types, the configured 2 × 6 arrays, five profiles with eight visible and collider layers each, a clear standing-capsule sweep through the tunnel, and continuous supported/clear still aisles at source x=12 and x=26. All three sweep results are `[1.0, 1.0]`. The test checks collider counts; the profile-radius choice is additionally established by source inspection. The quick mode does not rerun moving-ride cases or the longer capsule walks. UID/root-certificate startup errors and two empty-registry warnings remain in the [fresh log](rotation/after-isolation/compact-probe-output.log); no remaining class-conflict errors occurred. Do not infer a geometry defect from the earlier failed run.

For future human verification, check natural boarding and departure at normal ride timing, readable row labels and replay controls from the aisle, tunnel traversal without snagging, and comfortable movement among the profiles. These remain proposed checks; this audit makes no claim of headset verification.
