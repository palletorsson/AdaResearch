# SPIKE 06 — the config channel, and the three consumers that disagree about it

> **Note added by the orchestrator, and it is a retraction of my own commit.**
> This spike's LAW-1 finding lands on `1ac266bd2` ("read dna.fixture"), which I
> committed an hour before reading it. That commit merges the fixture into
> `room_dict["artifact_config"]` — and `artifact_config` **does not exist in
> HEAD's `DressingRoomBuilder.gd`** (0 occurrences; 3 in the working tree). It is
> another session's uncommitted work. So the fix is **inert against HEAD**: it
> writes a key nothing committed reads, and its commit message quotes that
> uncommitted code as though it were the codebase.
>
> That is the third time today I diagnosed the working tree instead of `HEAD` —
> after `doc/plans/capture_measure_faults.md`, retracted this morning for exactly
> this, and after quoting `CURRENT_STATE.md`'s opening warning about it back to
> Palle in between. Reading the sentence is not the same as running the command.
> `git show HEAD:<path>` belongs in the loop, not in the doctrine.
>
> The spike also corrects the brief I wrote for it. `GridInteractablesComponent`
> already carries the holder walk at HEAD (`:1695`, `:1716`), so the map path and
> the sweep bench both reach child-owned properties. `DressingRoomBuilder` is the
> only one of three consumers that does not — which means DNA gallery tiles and
> bite percentages are **not** implicated, only dressing-room staging captures. I
> had generalised one artifact into a broken channel. The agent's own census also
> failed once in the direction of its hypothesis (291 unreachable, from a regex
> matching the `id` inside `uid=`) and it caught that itself before reporting.

## QUESTION

`dna.fixture` and `dna.axes` are declarations an artifact makes about the state
it should be built in. Three separate pieces of code deliver that declaration to
the artifact. How many artifacts can actually *receive* it, and do the three
delivery paths agree?

## PROBE

- `laser_measure` — the artifact that exposed this today; fixture `{max_range: 0.25,
  tick_interval_m: 0.05}`, root is a `grab_stick` instance, script on a child.
- `rotating_cube` / `transformation_cube` — root *does* carry a handler, sole axis
  lives on a child. The case the brief did not anticipate.
- `library_rack` — root handler that renames keys into private vars. The case that
  makes a naive census lie.
- The marchingcave `Scenes/*.tscn` family — 14 tokens, scriptless `Node3D` roots.
- Whole corpus: every registry entry declaring `dna.axes` or `dna.fixture`.

## PIPELINE TRACE

Traversed, from source only (LAW 2 — Godot never launched):
registry `dna` → the three delivery call sites → `.tscn` root resolution
(including `instance=ExtResource` inheritance) → `extends` chain of the root
script → does the root own the handler or the key → if not, which descendant does
→ live map placements of the affected tokens → published report/measurement JSON.

**Not traversed: runtime.** Every claim below is static. The one runtime number
quoted (`aabb_size` Z = 50.071 m) is taken from commit `1ac266bd2`'s own message,
not re-measured here.

## BASELINE

One documented trap ("a scriptless root with logic on a child makes the axis
declared but unreachable from any map token", CLAUDE.md), one artifact known to
hit it (`laser_measure`), and no count. CLAUDE.md states "184 of 2671 artifacts
are promoted"; the brief states "171 of 2743 declare `dna.fixture`".

## PREDICTION WRITTEN FIRST

Recorded before the census ran, so it can be scored:

1. **The brief's numbers.** 171 of 2743 declare `dna.fixture`; 184 promoted with
   `dna.axes`.
2. **Mine.** The unreachable set will be small — **10 to 20 tokens** — and will be
   dominated by a *wrapper family*: `grab_stick`, `pickup.tscn`, station mounts.
   That is the shape the brief proposes in (c), and it is the shape `laser_measure`
   has.
3. **Mine.** `GridInteractablesComponent` will have the same root-only assumption
   as `DressingRoomBuilder`, since the brief asks me to check it.

Scored: **(1) half right, (2) wrong in both magnitude and kind, (3) wrong.**
Details in F1–F5. Prediction 2 is the useful one: it was wrong by ~2x on count and
wrong about the mechanism, and chasing the wrapper hypothesis would have found
5 tokens and missed 32.

## FAILURES

### F1 — my census instrument was broken, and it failed *plausibly*

EXPECTED: a first-pass reachability count.
ACTUAL: 291 of 757 artifacts reported `KEYS_NOT_FOUND` with `root_script: None` —
a result that reads exactly like a corpus full of scriptless roots, i.e. like a
*much worse* version of the very fault I was sent to measure.
CAUSE: the `.tscn` `[ext_resource]` id regex was `id="?([^"\s\]]+)"?`, which
matches the `id` inside **`uid=`**. Every `ext_resource` line carrying a `uid`
(the majority) was indexed under `uid://…` instead of its real id, so every
`ExtResource("2_kc6u2")` lookup missed and every root script resolved to `None`.
FIX: `(?:^|\s)id="?…`. After it: 291 → 2.
file:line — scratchpad `census.py`, ext_resource parse.
GENERAL LESSON: the broken instrument's output was *directionally consistent with
the hypothesis I was testing*. Had I reported the first run, I would have
published "291 of 757 artifacts are unreachable" — a 8x overstatement, confirming
the brief, and wrong. The tell was that `root_script: None` appeared on *every*
row including ones I could see had scripts. **Spot-check the instrument against a
file you have read with your own eyes before believing any count.**

### F2 — the root-only assumption is NOT in `commons/grid/`. It was fixed there first.

EXPECTED (brief, task a): `GridInteractablesComponent` "sets `config_*` metadata
and calls `apply_grid_config`" with "the same root-only assumption".
ACTUAL: at HEAD it already has the holder walk. `_apply_artifact_config` calls the
root when the root has a handler, and otherwise falls through to `_config_holder`,
a breadth-first search for the first descendant that handles the call or declares
one of the keys.
file:line — `commons/grid/GridInteractablesComponent.gd:1643` (`_apply_artifact_config`),
`:1672` root branch, `:1695` fallback call, `:1716` (`func _config_holder`).
CAUSE: the fix already landed, with a comment at `:1679` reading **"THE BENCH
LOOKED HARDER THAN THE WORLD DID, and this closes that gap."**
GENERAL LESSON: **the brief's premise is inverted.** The world reaches; the bench
reaches; the *dressing room* does not. The comment at `:1679` is now out of date
in the other direction — the world looks harder than the museum does.

### F3 — the fault is in `DressingRoomBuilder`, and the line the brief quotes is not in HEAD

EXPECTED (LAW 1 check): the quoted `artifact_config` block at ~line 540.
ACTUAL: **that block does not exist at HEAD.** `git show HEAD:…DressingRoomBuilder.gd`
contains no `artifact_config` at all. It is uncommitted work in the working tree
of another live session.
file:line — working tree `commons/artifacts/catalog/DressingRoomBuilder.gd:540-542`;
absent from HEAD. (Not edited — LAW 3, and the brief's own instruction.)
SECOND, AND IN HEAD: there is a *second* root-only site in the same file for
staging props — `DressingRoomBuilder.gd:119-120`,
`if node.has_method("apply_grid_config") … node.apply_grid_config(cfg)`. So the
root-only assumption is committed, in the prop path, independent of the
uncommitted artifact path.
GENERAL LESSON: the fault has two call sites in one file, only one of which the
brief knew about, and the one it quoted is not yet in the repository.

### F4 — the unreachable set is not a wrapper family. It is scriptless demo roots.

EXPECTED (prediction 2): 10–20 tokens, dominated by `grab_stick` / `pickup` wrappers.
ACTUAL: **37 hard-unreachable**, of which **31 have no script on the scene root at
all** and only **6** have a root script without the handler. The wrapper hypothesis
accounts for 6 of 37 (`grab_sphere_point_with_color` ×5, `laser_measure` ×1).
The dominant family is the opposite shape — an *authored demo scene* whose root is
a bare `[node name="Node3D" type="Node3D"]` and whose logic hangs on a child:
14 tokens in `algorithms/proceduralgeneration/isosurfaces/marchingcave/Scenes/`
alone, plus the growth-systems, gaussian and forces demo scenes.
CAUSE: these scenes were authored as standalone demos with a scene-graph root used
purely as a container, then promoted to artifacts. Nothing in promotion checks the
root.
GENERAL LESSON: "wrapper family" and "scriptless container root" are opposite
causes with an identical symptom. Grouping by *wrapper* would have found 6; the
real grouping key is **"does the root carry a script at all"**.

### F5 — a root handler is not proof of reachability, and its absence is not proof of breakage

Two symmetrical errors, both found by hand-reading artifacts my census had
bucketed:

- **False negative.** `library_rack` has a root handler *and* the census flagged
  `collection`/`layout` as "not declared on root" — because the handler renames
  them into `_collection_name` / `_layout_file`
  (`commons/artifacts/library_rack/library_rack.gd:165-166`). Reachable. My
  "does the root declare `var <key>`" test is simply the wrong test whenever a
  handler exists.
- **False positive avoided.** `rotating_cube` / `transformation_cube` have a root
  handler (`commons/primitives/cubes/cube_scene.gd:129`) — but it does
  `set_meta("config_%s")` **on itself only** and then reads back exactly one key,
  `grain` (`:148-150`). Their sole declared axis is `travel`, which is an
  `@export` on the child `Travel` node
  (`commons/primitives/cubes/cube_bearing.gd:75`), whose own comment at `:12` says
  it "reads `config_travel` off its own meta" — meta the root never sets.
  **Genuinely broken, and invisible to a root-handler check.**

CONSEQUENCE: the 9 `HANDLER_BUT_KEY_ON_CHILD` rows cannot be counted either way
without reading each one. Sampled 5: **2 broken** (rotating_cube,
transformation_cube), **3 fine** (library_rack, and the two `forces` examples,
whose root already forwards — see PROPOSED FIX). I am reporting them as a
separate bucket rather than folding them into the headline, because folding them
either way would be a guess.

## EVIDENCE

Re-derived from `commons/artifacts/registry/*.json` (147 files) and every
referenced `.tscn`.

| quantity | brief / CLAUDE.md | measured | verdict |
|---|---|---|---|
| registry entries | 2743 | **2743** | confirmed |
| declare `dna.fixture` | 171 | **175 declare the key; 171 non-empty** | brief right for usable |
| declare `dna.axes` ("promoted") | 184 | **757** | CLAUDE.md stale ~4x |
| `dna.promoted` timestamps | — | 421 | — |
| entries with axes ∪ fixture | — | **757** (every fixture entry also has axes) | — |

The four empty ones are `dna.fixture: {}` — `csg_architecture_cavity`,
`field_room`, `pedagogical_sketchbook`, `subtraction_suite`.

**Reachability of the declaration from the scene root, all 757:**

| bucket | n | of which `dna.fixture` |
|---|---|---|
| `OK_ROOT_HANDLER` — root handles the call | 695 | 141 |
| `UNREACHABLE_NO_SCRIPT` — root carries no script | **31** | 21 |
| `UNREACHABLE_ROOT_SCRIPT` — root scripted, no handler, no key | **6** | 1 |
| `HANDLER_BUT_KEY_ON_CHILD` — needs per-artifact reading | 9 | 6 |
| `OK_ROOT_PROPS` — root declares the keys directly | 7 | 0 |
| `NO_SCENE` — sceneless `living.json` grammar tokens | 7 | 0 |
| `KEYS_NOT_FOUND` | 2 | 2 |

**Headline: 37 artifacts (4.9% of 757) cannot receive their own declaration
through a root-only channel. 28 of the 171 `dna.fixture` declarations (16.4%)
are affected** — fixture is hit ~3x harder than the corpus average, because
fixture is disproportionately declared on exactly these procedural demo scenes.

46 at-risk tokens resolve to **35 distinct scenes** — the corpus's one-scene-many-names
pattern again (`grab_sphere_point_with_color.tscn` carries 5 registry names:
`grab_sphere_E/_F/_lambda/_phi/_point_with_color`, all declaring `grasp`, which
lives on the child `MeshInstance3D` running `qfep_term_grasp.gd`).

Hand-verified against the `.tscn` text, not just the parser:
- `marchingcubes_cave.tscn:48` root `[node name="Node3D" type="Node3D"]`,
  script on child `Terrain` at `:52`. Scriptless root confirmed.
- `commons/interface/line.tscn:11` root `Line` scriptless; `line.gd` on child
  `lineContainer` at `:14`.
- `grab_laser_measure.tscn:12` root is a `grab_stick` instance (which resolves to
  `grab_cube.gd`, no `apply_grid_config`); `laser_measure.gd` on child at `:17-18`
  with `max_range = 50.0` hard-set at `:19`.

**Blast radius in live maps** (2418 `map_data.json` scanned): the 37
hard-unreachable tokens have **164 placements and ZERO carry a `#config`**. The
44 `#config` placements found on at-risk tokens are all `library_rack`, the false
positive. So the trap is armed, not sprung — and the map path is fixed anyway (F2).

**Where it actually bites:** all 37 appear in `doc/reports/*.json` /
`ada_run/*.json` — `artifact_dna_agenda.json`, `artifact_measurements*.json`, and
in one case `anamorphic_GaussianPaintSplatter.json`, i.e. the standpoint gate was
run to adjudicate an axis on an artifact whose root cannot receive that axis.

**But the DNA sweep is not implicated.** `capture_config_sweep.gd` uses
`_holder_of` (`:1452`, applied `:348`) *and reads the value back* (`:359-360`),
with an explicit comment at `:330-333` naming the `lineContainer` case. So gallery
tiles and bite percentages for these 37 were shot with the axis genuinely applied.
The invalid artefacts are the **dressing-room / museum staging** captures, not the
sweep. Three consumers, two reach, one does not.

## PROPOSED FIX (not applied)

`capture_temporal.gd:156` `_holder_of` is the right idiom and is already the
corpus standard — it exists in **three** places independently
(`capture_temporal.gd:156`, `capture_config_sweep.gd:1452`,
`GridInteractablesComponent.gd:1716` as `_config_holder`) and a fourth as a
forwarding walk inside an artifact (`algorithms/forces/forces_demo_root.gd:52-79`,
`_descendants()`). `DressingRoomBuilder` is the only consumer that never got it.

Port `_config_holder`'s exact semantics — **fallback-only, first match, never a
broadcast** — into `DressingRoomBuilder.gd` at both sites (`:119-120` prop path,
and the artifact path currently at working-tree `:540-542`). Fallback-only is
load-bearing: it guarantees an artifact whose root already handles config takes a
byte-identical path, which is what makes the change gated by construction.

**Two constraints the obvious patch violates:**

1. **Ordering.** The working-tree call applies config at `:542` and adds the node
   to the tree at `:543` — config *before* `add_child`. `forces_demo_root.gd:63-64`
   returns early when `not is_inside_tree()`, and `cube_scene.gd:136-138` returns
   early when `not _built`. A holder walk inserted at `:540` would therefore still
   deliver nothing to the forces family. **The walk must run after `add_child`, or
   set metadata as well as calling.** `GridInteractablesComponent` sidesteps this
   by using `call_deferred` throughout (`:1673`, `:1700-1703`); the Builder calls
   synchronously.
2. **Fallback-only does not close the 9.** `rotating_cube`'s root *has* a handler,
   so `_config_holder` is never consulted and `travel` stays unreachable. Those
   need forwarding inside the artifact's own `apply_grid_config` — the pattern
   `forces_demo_root.gd` already implements. Fallback-only closes **37 of 46**.

**What a fix would break.** Little, but not nothing:
- Maps: nothing. 164 placements, 0 with `#config`, and the map path already walks.
- **Broadcast would double-apply.** `forces_demo_root.gd:67-69` already forwards to
  every descendant. If the Builder broadcast rather than first-matched, that family
  gets the config twice; `cube_scene.gd:141-144` and `library_rack.gd:187` guard
  against no-op rebuilds, but not every handler does. First-match only.
- **Artifacts that rely on root-only config deliberately.** `library_rack` and
  `cube_scene` both document handlers written to *swallow* keys they don't own
  (`curation_station.gd` calls them with `{"emissive": false}` and an
  unconditional rebuild would discard framing). A walk that reached past those
  roots would hand `emissive` to a child that does rebuild. Fallback-only preserves
  them exactly, since both roots have handlers.
- **`DressingRoomBuilder.gd` is live in another session's working tree** and must
  not be edited now (LAW 1/3). The fix is blocked on that file settling.

Recommend also: extend `tools/check_dna_declarations.py` with a reachability
column, so a promotion that lands on a scriptless root fails the gate that already
exists rather than needing a new one.

## NEGATIVE TEST

Must **fail today** and **pass after**. Two parts; neither was run (LAW 2).

**T1 — behavioural, the real gate.** New `commons/testing/probe_config_channel.gd`,
headless, one boot, no capture:

1. Instantiate `res://commons/primitives/laser_measure/grab_laser_measure.tscn`.
2. Drive it through `DressingRoomBuilder.build` with
   `artifact_config = {"max_range": 0.25, "tick_interval_m": 0.05}` — i.e. exactly
   `laser_measure`'s own `dna.fixture`.
3. Settle 0.35 s (the documented AABB settle), then read `max_range` back off
   whichever node owns it, and merge the subtree AABB.

ASSERT `max_range == 0.25` **and** `aabb_size.z < 1.0`.
TODAY: `max_range` stays `50.0` (hard-set at `grab_laser_measure.tscn:19`), Z =
50.071 m — **FAIL**, and this is the number commit `1ac266bd2` measured before and
after its own fix, so it is a known-value regression test, not a fresh guess.
AFTER: Z ≈ 0.3 m — PASS.

Read-back is not optional: `capture_config_sweep.gd:334-345` records that
`Object.set()` on a mismatched typed export is rejected *in silence*, which
produced a green chain and a published verdict for `tier_terrarium`. Asserting on
the AABB as well as the property catches the case where the set is accepted but
drives nothing.

**T2 — the guard that must keep passing.** Same probe, `library_rack` with
`{"collection": "shaders", "layout": "rack_torus.json"}` (a config that exists in
11 live maps). ASSERT the resolved handler is the **root** and no descendant
received the call. Fails if the fix broadcasts instead of first-matching — which
is the specific way this fix breaks 44 live placements.

**T3 — static, cheap, no Godot.** Reachability census as a gate: exit code =
count of registry entries declaring `dna.axes`/`dna.fixture` whose keys cannot be
reached from the scene root *under the channel the Builder actually implements*.
Today: **37**. After a fallback-only fix: **0** for the scriptless/handler-less
buckets, with the 9 `HANDLER_BUT_KEY_ON_CHILD` rows reported separately as
"requires reading" rather than silently passed — because F5 proves that bucket
cannot be adjudicated mechanically.
