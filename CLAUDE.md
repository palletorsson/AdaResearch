# Ada Research — AI Quick Reference

> **Read this first.** This file is auto-loaded by Claude Code on session start.

## Start Here

| Document | Purpose |
|----------|---------|
| `doc/ENTRY.md` | Project overview, QFEP framework, content chain |
| `doc/MAP_AGENT_ONBOARDING.md` | Map workflow, CLI tools, validation, done criteria |
| `doc/ONBOARDING_GUIDE.md` | Comprehensive guide with all AI skills listed |
| `doc/MAP_EDITING_PIPELINE.md` | End-to-end map editing flow (7 steps) |
| `doc/ARCHITECTURE.md` | Technical system architecture |

## Core Rule

- **Grid system changes are allowed** (guard lifted 2026-07-08 — it was for older models). Discipline still applies: additive hooks gated by new data (a map without the new layer must be untouched), headless compile-check + live map-load test before commit, pathfinder extended in the same change, and a negative test proving the new behavior actually bites.

## The Sieve — three questions for substantial decisions

For any substantial design decision during a session, hold three questions. They are the operational form of the Self-Q recursion on QFEP (see `doc/ENTRY.md` § The Self-Q).

1. **Does this thicken the cognitive water?** (relational handles, ways of moving through, things made thinkable)
2. **What is foreclosed?** (thinking made harder under this structure)
3. **What lives in the dark spot?** (what the encoding hides — generative habitat or sterilising seal?)

Not a metric. A sieve. Q1 stops thin/optimised/scoreboard-shaped systems. Q2 stops confusing thick with good. Q3 stops over-specification.

- **Tool:** `python tools/sieve.py <target>` (or `--record` to log a pass to `doc/sieve_passes/`)
- **Skill:** `/sieve <target>` — conversation-routed
- **Background:** [/blog/2026-05-11-cognitive-water](http://localhost:3003/blog/2026-05-11-cognitive-water), [/blog/2026-05-11-self-colonial-recognition](http://localhost:3003/blog/2026-05-11-self-colonial-recognition)

## Session Bootstrap — Fold first, file-walk second

> *Five-minute rule: don't grep, don't glob, don't read 14 files when one fold answers the question. The fractal database is the project's compressed self-image.*

Before file exploration, query the encyclopedia's fractal API. It returns a compressed view of the entire project (1,500+ nodes) at any depth, through any of six lenses. One call replaces dozens of file reads.

```bash
# Project shape — start here on every session (~140 tokens)
curl -s "http://localhost:3003/api/fractal?strategy=structural&depth=1" | jq

# Drill into a domain
curl -s "http://localhost:3003/api/fractal/fractals?strategy=structural&depth=1"

# Search across the whole tree
curl -s "http://localhost:3003/api/fractal?strategy=semantic&search=koch&depth=2"
```

**Strategies (each compresses differently):**
- `structural` — counts, types, file paths. For navigation. *Best default for "what's in the project?"*
- `semantic` — descriptions, tags. For search by meaning.
- `pedagogical` — teaching path, complexity, sequences. For curriculum questions.
- `code` — class names, signals, scenes. For implementation work.
- `critical` — QFEP connections, theory. For analysis.
- `biome` — kingdom × substrate × sequence routing. For ecology / biome dispatcher work. *(2026-05-04, validation in progress — keyword detection over-fires "creature".)*

**The `/fractal` page** at `localhost:3003/fractal` is the same data with a UI. Click strategy pills, drill nodes, see token counts. Use it to scout before writing code.

**Hybrid pattern** (proven by `/blog/fractal-database`): fold-first navigation, source unfolds at depth 4 only when precision is needed. 5.9× fewer tokens than file-walking on benchmarked tasks. If you find yourself running grep for the third time in a session, you're agent-B. Switch to fold queries.

**For local CLI access** without the web server, `tools/lod_query.py <topic>` is the same idea — fractal-depth context lookup against the codebase. Works offline.

## Project Layout

Godot 4 VR/desktop project. Algorithms taught through maps and interactable artifacts.

**Content chain:** `Sequence JSON → Map JSON → Artifact Registry → Scene (.tscn/.gd)`

**3-layer grid** (in `map_data.json`):
- `structure`: geometry (floors/walls/void/heights)
- `utilities`: spawn, teleporter, ramps, transport cubes, labels
- `interactables`: artifacts by lookup name

**Scale (measured 2026-08-01):** 83 sequence files, 2049 maps, 2671 registry entries across
108 registry files, 24 spine sequences. The older figures here (42/503/752) were roughly a
quarter of the truth, so any "sweep the corpus" or "rename everywhere" estimate made from
them was off by 4x.

## CLI Tools

Run from repo root:

### Steering & Status
| Tool | Command | Purpose |
|------|---------|---------|
| **Pipeline Scorer** | `python tools/sequence_pipeline_scorer.py` | Score all 24 spine sequences through 7 completion stages |
| **Pipeline (single)** | `python tools/sequence_pipeline_scorer.py <seq_id>` | Score one sequence |
| **Dashboard** | `powershell -ExecutionPolicy Bypass -File commons/tools/project_dashboard_cli.ps1 -Mode status` | Project status, recommendations |
| **Heat Map** | `python tools/heat_map_generator.py` | Temperature-based priority scoring |

### Navigation & Context
| Tool | Command | Purpose |
|------|---------|---------|
| **LOD Query** | `python tools/lod_query.py <topic>` | Fractal-depth context lookup |
| **LOD Tree Gen** | `python tools/lod_tree_generator.py` | Regenerate LOD_TREE.json from codebase |
| **LOD Writer** | `python tools/lod_session_writer.py --topic X --insight Y --lod N` | Record session discoveries |
| **Ada Navigator** | `python tools/ada/ada.py overview` | Seq/map/artifact lookup |

### Validation & Quality
| Tool | Command | Purpose |
|------|---------|---------|
| **Pathfinder** | `python tools/map_pathfinder.py check <MapName> --verbose` | Reachability, rule validation |
| **Verify Sequence** | `python tools/verify_sequence.py <seq_id>` | Full sequence validation |
| **Workbench** | `python tools/spine_map_workbench.py status` | Sequence contracts, scaffolding |
| **Release Gates** | `python tools/run_release_gates.py --max-grade-c -1 --gate-toggles doc/reports/RELEASE_GATES_TOGGLES.json` | Launch-quality checks |

### Placement (2026-05-15 — auto-research output)
| Tool | Command | Purpose |
|------|---------|---------|
| **Place (ship)** | `python tools/place.py --map=<Name> [--engine=...] [--in-place] [--only-improve]` | Auto-selects engine (humanoid_walker / hybrid / sim_annealing) and applies it |
| **Place Research** | `python tools/placement_research.py --seeds=N` | Compare 11 placement strategies on toy scenario |
| **Place + Score** | `python tools/place_artifacts.py --map=<Name> --strategy=<name>` | Apply specific strategy, write sibling map |
| **Sync Footprints** | `python tools/sync_footprints.py --apply --cap=9` | Sync measured AABB → spatial_needs.footprint_cells |
| **Walk Evaluator** | `python tools/walk_evaluator.py [--map=<Name>]` | Score placement on walkability (detour, encounter order, backtrack) |
| **Trajectory Viz** | `python tools/placement_trajectory.py [--map=<Name>]` | Render humanoid_walker's walk path as SVG |

Auto-research findings: hybrid wins constraint score (deterministic, +0.04 mean on real maps); humanoid_walker wins walkability on real maps (perfect detour ratio + encounter order); simulated_annealing wins combined when compute budget allows. `place.py` picks the right one per map automatically. See `/blog/2026-05-15-no-base-algorithm-wins`.

### Content & Identity
| Tool | Command | Purpose |
|------|---------|---------|
| **Garden Listener** | `python tools/garden_listener.py --diagnosis` | Audit sequence/map/artifact health |
| **Query Identities** | `python tools/query_identities.py truths` | Find @identity truth statements |
| **Map Text Writer** | `python tools/map_text_writer.py` | Generate blurb/intent/technical docs |
| **Classify Artifacts** | `python tools/classify_artifacts.py` | Auto-classify artifacts by category |

### Past sessions are readable — including the other subscription's

Palle works this project from two Claude accounts and switches when one runs out of usage.
**Every past session is readable from either account**, because transcripts are account-blind
files under `~/.claude/projects/`, while each account's sidebar shows only the conversations
that account started (measured 2026-08-13: of 101 Ada conversations, 6 appear in one sidebar,
12 in the other, and **83 in neither**). Do not conclude that work is lost because you cannot
see it listed.

The `context-manager` MCP server reads all of them, registered at user scope so it is present
under both accounts. It needs no server running — it opens the cache directly.

| To do this | Call |
|---|---|
| See what exists | `list_sessions(project="C--Users-palle-Documents-GitHub-AdaResearch-46")` — use `title`, not `first_message`; most sessions open with identical boilerplate |
| Find by topic | `search_sessions(project=…, query="museum")` — matches titles and message text |
| Read what happened | `read_session_turns(session_id, include_thinking=true)` |
| Recover *why* | `read_session_reasoning(session_id)` — the reasoning behind past decisions |

Run `/pickup` to do the whole sweep at once. Sessions in worktrees live in their own project
dirs (`…AdaResearch-46--claude-worktrees-*`) — check those too when a topic seems missing.

### Companion Tools (separate repos)
| Tool | Location | Purpose |
|------|----------|---------|
| **Context Manager** | `C:\Users\palle\Documents\GitHub\claude_context_manager` | Session browser, clone, memory, working tree. Also the cross-account session reader — see above |
| **Encyclopedia** | `C:\Users\palle\Documents\GitHub\ada_encyclopedia` | Web editors, search, substrates, API |
| **Writer** | `C:\Users\palle\Documents\GitHub\ada_writer_pro` | Book writing tool |

### Sequence Completion Pipeline (7 stages)
```
1. Structure     — maps defined in sequence JSON
2. Documentation — blurb.md + intent.md per map
3. Artifacts     — every interactable has a scene file on disk
4. Maps          — map_data.json with 3 layers
5. Validation    — pathfinder passes
6. VR Testing    — walked in headset, feedback via bridge
7. Polish        — captures fresh, docs updated
```
HEAD = lowest incomplete stage. Work at the head. Move it forward.

## Godot Capture Pipeline

Godot exe: `C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe` (non-console — captures fine headless). The `_console.exe` variant is no longer on the Desktop; use the non-console v4.6 exe, or `Godot_v4.3-stable_win64_console.exe` if you need console stdout.

Note: captures land in `%APPDATA%/Godot/app_userdata/Ada Research Zero One/multi_shots/<target>/` (Roaming, **not** Local).

Always use `--xr-mode off` to suppress OpenXR popup. Add `--no-window` for headless.

**No capture may halt the pipeline (the 16-second rule).** Wrap headless Godot runs in the
watchdog — it kills the process tree if no result appears (grace 45s boot) or output stalls 16s:

```powershell
python tools/godot_watchdog.py --expect=<output-file-or-dir> -- <godot exe + args>
```

Known hang class: simulation artifacts (e.g. `boid_flocking`) never yield headless. Also: never
run two Godot instances at once — the second dies silently on the user:// lock; serialize runs.

```powershell
# Single artifact (4 angles)
godot_console --path . --xr-mode off --no-window --script res://commons/testing/capture_multi_angle.gd -- --mode=artifact --target=<lookup_name>

# Single map (4 angles)
godot_console --path . --xr-mode off --no-window --script res://commons/testing/capture_multi_angle.gd -- --mode=map --target=<MAP_NAME>

# Full batch with manifest-based skip
godot_console --path . --xr-mode off --no-window --script res://commons/testing/capture_all.gd -- --outdir=user://capture_output --sequence=<seq> --skip-unchanged
```

Output: `user://multi_shots/<target>/<angle>.png` + `capture_report.json`

## Encyclopedia Integration

The Ada Encyclopedia (`ada_encyclopedia/`) is a Next.js web app providing visual editors and API access.

**Required env var:** `ADA_RESEARCH_PATH` — absolute path to this repo.

**Web editors** (run `npm run dev` in encyclopedia, default port 3003):
- `/map-builder` — 3-layer map editor with AI generation and simulation
- `/voxel-editor` — 3D structural level editor
- `/grid-editor` — VR glass rack layout designer
- `/pattern-maker` — Wallpaper group pattern editor

**Key API routes:**
- `GET /api/game/context?format=markdown` — Full game context for AI
- `GET /api/ai/capabilities?format=markdown` — Tool inventory for AI
- `POST /api/game/generate` — AI map generation
- `POST /api/game/analyze` — Map validation
- `POST /api/game/simulate` — AI pathfinding simulation
- `GET /api/maps?name=<Name>` — Map data retrieval
- `GET /api/artifacts` — Artifact registry
- `GET /api/find?q=<query>&format=markdown` — **Agent search**: one call over every page/API URL (Slash Map) + full-text content (algorithms/artifacts/sequences/maps/shaders). The server-side twin of the nav search bar. `kind=all|routes|pages|api|content`, `limit=N`. Curl this to locate anything fast.

## Desktop ↔ AI Feedback Bridge

In VR, the DesktopMapSwitcherOverlay lets users type comments during gameplay. These are written to:
- `ada_run/desktop_feedback.md` (markdown entries with timestamp, map, sequence, artifacts)
- `ada_run/desktop_feedback.json` (structured JSON)
- `ada_run/codex_change_requests.md` (queued for AI)

AI reads feedback via the `/ada-bridge-listener` skill or direct file read.

## Map Editing Pipeline

```
1. DISCOVER  → ada.py overview / project_dashboard_cli.ps1 -Mode status
2. EDIT      → localhost:3003/map-builder  OR  direct JSON edit
3. VALIDATE  → map_pathfinder.py check <Name> --verbose  OR  POST /api/game/analyze
4. CAPTURE   → capture_multi_angle.gd --mode=map --target=<Name>
5. REVIEW    → View screenshots, POST /api/game/simulate, VR test
6. BRIDGE    → Read ada_run/desktop_feedback.md for VR session notes
7. ITERATE   → Apply feedback, return to step 2
```

See `doc/MAP_EDITING_PIPELINE.md` for detailed documentation.

## Key Paths (Truth Sources)

| What | Path |
|------|------|
| Curriculum spine | `commons/maps/curriculum_spine.json` |
| Sequence definitions | `commons/maps/sequences/*.json` |
| Map data | `commons/maps/{MapName}/map_data.json` |
| Artifact registries | `commons/artifacts/registry/*.json` |
| Legacy registry (deprecated) | `commons/artifacts/grid_artifacts.json.deprecated` |
| Grid system | `commons/grid/GridSystem.gd` |
| Utility registry | `commons/grid/UtilityRegistry.gd` |
| Hazard creatures | `commons/hazards/` — DangerZone, transformation blocks |
| Catalyst bracelet | `commons/hazards/becoming_catalyst/` — bracelet system |
| Nature system | `algorithms/nature_system/` — CritterDNA, morphology, evolution, spawner |
| Death effect | `commons/managers/DeathEffect.gd` — red flash, shake, reload |
| Ecosystem manager | `commons/managers/EcosystemManager.gd` — ecology progression |
| Soft stages | `commons/maps/soft_stages.json` — ecology density/kingdoms per sequence |

## AI Skills

| Command | Phase | Description |
|---------|-------|-------------|
| `/ada-dashboard` | orient | Coverage gaps, recommendations |
| `/ada-question-assistant` | orient | Answer project questions |
| `/ada-test-player` | assess | Walk sequences from source |
| `/ada-sequence-expert` | assess | Sequence design, progression |
| `/ada-code-guide` | understand | Deep GDScript walkthrough |
| `/ada-map-expert` | build | Create, edit, validate maps |
| `/ada-queer-theory-expert` | ground | QFEP and critical theory |
| `/ada-tutor` | ground | Teaching-level explanations |
| `/ada-bridge-listener` | verify | VR feedback → AI action |
| `/ada-humanizer` | document | Clean text for docs and UI |
| `/ada-code-documenter` | document | Generate code documentation |
| `/pickup` | orient | Resume work from past sessions, including the other subscription's |
| `/ada-task-manager` | track | Task management (plan/done/report) |
| `/ada-knowledge-updater` | track | Scan codebase, update knowledge |
| `/ada-orchestrator` | track | Session handoff, onboarding |

## Quick Context Loading

For targeted work, use the LOD query tool instead of reading everything:
```
python tools/lod_query.py <topic>
```

This returns only the relevant context at the right depth. The tree is generated from the actual codebase.

| Command | What you get |
|---------|-------------|
| `python tools/lod_query.py` | Project overview — stats, all sequences listed |
| `python tools/lod_query.py mosaicanalysis` | Sequence detail — maps, artifacts, truth statement |
| `python tools/lod_query.py MANN_Gallery_Museum` | Map detail — dimensions, artifacts placed |
| `python tools/lod_query.py pompeii_mosaic_floor` | Artifact detail — exports, key functions, file path |
| `python tools/lod_query.py pompeii_mosaic_floor._build_truchet_field` | Function detail |
| `python tools/lod_query.py meander` | Fuzzy search — finds all meander-related items |
| `python tools/lod_query.py --list sequences` | List all sequence IDs |

To record what this session discovered:
```
python tools/lod_session_writer.py --topic "meander" --insight "tiles repeat, mosaics don't" --lod 3
```

To regenerate the tree after codebase changes:
```
python tools/lod_tree_generator.py
```

## Map Building (IMPORTANT — read before making maps)

See `doc/MAP_BUILDING_GUIDE.md` for full details. Key points:

**Three layers:** structure (heights 0-5), utilities (sp/t/ds/r/m/an/3t), interactables (artifact:rotation:y_offset)

**Maps are narrative spaces with 5 phases:**
1. Entry (spawn + context)
2. Teaching (main artifact)
3. Exploration (related artifacts)
4. Reflection (text + darkness)
5. Exit (teleporter)

**Map Studio:** `/map-studio` in the encyclopedia — 3-layer visual editor built from scratch.

**Spine sequences are the priority** — 24 sequences forming the core curriculum.

## Heat Map

Run `python tools/heat_map_generator.py` to see what needs work.
The `/continue` skill reads this to pick the next task.

## Final Lap (thesis-landing readiness)

When working on final-arc sequences (`foundationscrisis`, `qfeplaboratory`, `postfoundationscrisis`), start with:

```
curl http://localhost:3003/api/final-lap?format=markdown
```

Returns underdeveloped maps, missing-map slots, unwalked maps, and recent VR feedback — context-enhancing at session start. Page: `localhost:3003/final-lap`. Scores live in `doc/final_lap_scores.json` — update at end of sessions that touch final-arc maps.

## Artifact Creation Pattern

3 files: `<token>.gd`, `<token>.tscn`, registry JSON entry.
- `extends Node3D`, `class_name PascalCase`, procedural in `_ready()`
- Include `apply_grid_config(config_data: Dictionary)`
- Register in `commons/artifacts/registry/<category>.json`
- Commit: `feat: add <token> artifact — description`

**The registry files are token-keyed DICTS, often at indent 1 with tabs. Edit them
surgically. One `json.dumps()` round-trip once reformatted 15,121 lines.**

## Artifact DNA — an artifact is a FAMILY, not one object

**184 of 2671 artifacts are "promoted": they declare `dna.axes` in the registry and carry
one or two named axes with 3-6 values each. 258 axes are declared.** A new artifact that
ships as a singleton is invisible to the sweep, the gallery and the bite reports.

An axis is the thing the artifact ARGUES, not how it is mounted — `exhibit_furniture.house`
(white_cube · wunderkammer · depot · forensic) or `godel_statement_plaque.outside`
(quotation · margin · breach · omission · habitat). Rules learned the hard way:

- **Visible in a STILL.** The evidence is one PNG per variant, so a rate, duration or decay
  is invisible to it. `info_board` was swept across all five of its duration exports and
  produced six identical tiles — a finished-looking experiment that answered nothing.
- **It must BITE.** Under 3% change in the hottest 5% of pixels is decoration.
- **Defaults are sacred.** These artifacts have up to 1077 live placements.

**DERIVE the declaration, never transcribe it.** `science_screen` shipped a hand-typed block
declaring `none|bezel|hooded|cabinet` against a code enum of `stand|wall|console|rig`. Nothing
failed loudly: the sweep set an invalid value, the artifact fell back to its default, sixteen
identical frames were published, and the critic reported the axis INERT at 0.69%. Every stage
green, and the verdict was a fact about a typo. So the chain runs Scene → Registry for axes,
the opposite direction from the content chain above.

| Tool | Command | Purpose |
|------|---------|---------|
| **Declaration gate** | `python tools/check_dna_declarations.py` | Diffs every declared axis against its code. Exit code = broken count, so it gates. |
| **Derive block** | `python tools/apply_dna_block.py --token=X --axes=a,b` | Writes the registry block FROM the code |
| **Sweep + gallery** | `python tools/build_dna_gallery.py --slug=S --tokens=a,b` | One PNG per variant + manifest; refuses a broken axis |
| **Bite critic** | `python tools/artifact_dna_critic.py --gallery=S` | Does each axis actually change the picture? |
| **Batch compile** | `godot --headless --path . --xr-mode off --script res://commons/testing/check_compile.gd -- --files=res://a.gd,res://b.gd` | Parses N scripts in ONE boot |

### Before you believe an INERT verdict, check the harness

Across nine promotion passes the critic has said INERT far more often about the CAPTURE than
about the design. Every one of these was measured, not guessed:

| symptom | cause | fix |
|---|---|---|
| all N frames identical, `focus ~= frame ~= 0.7%` | declared values are not the code's values | `check_dna_declarations.py` |
| `NO RENDER`, subject 0.00% | `_ready()` is gated and builds nothing standalone | registry `dna.fixture` sets the gate |
| two values `== 0.00%` to the byte | the geometry exists but is OCCLUDED or off-camera | change the fixture, not the axis |
| BIG subject share, TINY closest pair | the artifact's own furniture is IN FRONT of its marks | read the z-stack; **look at the PNG** |
| subject under ~6% of frame | the AABB is inflated by one big or far-flung mesh | `dna.framing`, or a `layers = 0` anchor |
| strong confident bite on a generative artifact | unseeded `randf` — five variants are five objects | seed export + `dna.fixture` pins it |
| axis real in world space, invisible in frame | fit-by-DIAGONAL on a wide flat or thin subject | `dna.framing` below 1.0 |
| `INERT` at 0.00%, or a one-faced subject | the axis is ANAMORPHIC — the camera is standing in the wrong place | `probe_anamorphic.py`; the critic now gates on it |

**A dead verdict is no longer yours to issue.** Every DNA tile ever published was shot from
ONE standpoint — `capture_config_sweep`'s yaw 0.62, pitch -0.26 — so `INERT` has only ever
meant *"this axis does not change what the camera at 0.62 happened to be facing."* Audited
across the corpus, **five of seven dead verdicts were false.** `artifact_dna_critic.py`
therefore refuses to convict without evidence from elsewhere, and emits three verdicts:
`INERT?` (nobody has looked from another angle — a to-do, and it prints the command),
`ANAMORPHIC` (flat here, alive from another standpoint), `INERT` (flat from all five).
Run `python tools/probe_anamorphic.py --token=X --axis=Y` to clear one; it writes
`doc/reports/anamorphic_<token>.json`, which is what the gate reads.

**PREDICT THE CLOSEST PAIR BEFORE THE CAPTURE, and write it into the registry as
`dna.predicted_degeneracy`** — which two frames will look most alike, the number, and the
arithmetic. It does not have to be right. `operations_gallery` named the wrong pair (second
of six) and was 1.8x low, and still caught a wall that photographed **blank**: its bezel was
built as a solid 24 mm slab enclosing the panel face and every mark the axis drew, so four
values were four photographs of one slab. It compiled, it passed the declaration gate, it
swept four frames, and the critic returned 0.09% with the subject at 70.3% of frame — which
reads exactly like an honest axis diluted by furniture. Predicted 4.18% against measured
0.09% is a factor of 46, and nothing else in the chain was going to object. **A prediction
that agrees with the sweep is worth nothing; one that disagrees is worth the whole pass.**

**THE PREDICTION IS A LOWER BOUND, WHICH IS WHAT MAKES IT A GATE.** Measured over four
predictions that each named a pair and a number, every one UNDER-predicted, by 1.5x
(`grasp_cabinet`), 1.7x (`operations_gallery`), 3.5x (`noise_quarry`) and 6.7x
(`removal_room`) — a Python rasteriser has one light, flat shading and no shadows, AO or
antialiasing, so it cannot see most of what separates two real renders. The factor is not
constant, so the number is not a forecast; it is a floor. **If the sweep comes back BELOW
the prediction, stop and investigate** — `operations_gallery` pre-repair measured 0.09%
against a 4.18% prediction, 0.02x, the only case in the corpus to land under its own
prediction and the only one that was broken.

**Diagnose with numbers, not by squinting.** `subject %` (pixels differing from the corner
background) separates "too small to measure" from "axis does nothing". `random_walk_collection`
moved 174 grey levels across 0.06% of frame — a huge change, invisible. But note which way
that cuts: `reaction_diffusion.inoculation` filled 62% of frame, moved 15 grey levels, and was
written down **in this file** as "genuinely inert" — a fact about the canonical camera. It is
20.32% from above. A big subject and a small number is not proof of a dead axis; it can equally
mean the difference is on a face you are not looking at.

**`commons/testing/probe_aabb_hogs.gd`** ranks an artifact's meshes by world diagonal and
prints the merged AABB; it needs a 0.35 s settle, because two process frames photographs a
half-built artifact and reports an identical mesh count for every value.

### Other things that cost a pass each

- **Godot visibility is hierarchical.** `visible = false` on a node hides every descendant.
  To hide one mesh and keep its children, use `layers = 0` (per-instance, does not propagate,
  leaves mesh and material alone — `material_override` would break a pickup highlight swap).
- **The capture AABB counts `MeshInstance3D` ONLY.** An artifact built from
  `MultiMeshInstance3D` measures as a 1 m box. Add a `layers = 0` anchor sized to the real
  extent — and do not overshoot, which is the same fault in the other direction.
- **Check the .tscn root carries the script.** `GridInteractablesComponent` sets `config_*`
  metadata and calls `apply_grid_config` on the ROOT; a scriptless root with logic on a child
  makes the axis declared but unreachable from any map token.
- **Check the file is tracked.** A promotion once landed 270 lines inside a gitignored addon;
  the declaration would have shipped for code not in the repo, and the gate cannot see it
  because it reads the working tree.
- **One scene, many registry names is the corpus's most common hidden family** — found five
  times (curation_station's three booleans, four grab spheres, the pickup cubes, the synth
  racks, the translation cubes). Identical export counts across sibling tokens is the tell.
  When a shared vocabulary is honest the siblings measure ALIKE, which is itself a check.

**KNOWN GAP, do not mistake it for done:** exactly ONE map (`Artist_Readymades`, six
`request_note` tokens) places any artifact at a non-default value. The families exist in the
source tree and on the test bench; outside that one map nobody has ever met a variant.

## Catalyst Bracelet System

Found on wireframe pedestal (bracelet, not crystal). 3 stones switch modes: cube (voxel block), wedge (walkable prism), off.
- Cardinal neighbor placement: 4 directions, 2 cells out from player
- trigger=place, grip=remove, bracelet rotation switches active stone
- Placed blocks persist in memory across maps within a session; fresh each game launch
- Source: `commons/hazards/becoming_catalyst/`

## Death System

DeathEffect is an autoload: red flash overlay, time freeze, camera shake, particles, haptic feedback, fade to black, then map reload.
- Fire hazard: 35 dmg per 0.3s tick. Lasers: 100 dps. `h:death`: instant kill.
- DangerZone utility codes in map_data.json: `h:fire`, `h:death`, `h:electric`, `h:toxic`, `h:vacuum`
- Source: `commons/managers/DeathEffect.gd`, `commons/hazards/`

## Ecology Progression

`soft_stages.json` defines creature density, kingdoms, and terrain per sequence stage.
- BiomeRingComponent spawns foliage and living CritterEntity organisms around maps
- NatureRenderer handles fog, sky color, and particles. EvolutionSystem + TransmutationManager drive self-generating behavior
- Progression: seq 1-2 grey/sterile, seq 3 first flowers, seq 11 creatures appear, seq 12+ full evolution
- Source: `algorithms/nature_system/`, `commons/managers/EcosystemManager.gd`
