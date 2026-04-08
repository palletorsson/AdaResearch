---
name: ada-artifact-improver
description: Full-loop artifact improvement — documentation, code, and screenshot in one session. Reads code + registry + @identity, plans all three improvements, shows proposal, executes sequentially, captures new screenshot. Triggers - "improve artifact", "artifact improver", "enrich", "optimize artifact".
argument-hint: "[lookup_name | 'worst N' | 'registry:filename']"
allowed-tools: Bash, Read, Glob, Grep, Edit, Write, Agent
---

# Ada Artifact Improver — Full Loop

Improve an artifact in three dimensions — **documentation**, **code**, and **screenshot** — in a single Opus session. Read everything, plan everything, show the proposal, execute sequentially, capture the result.

## Core Rules

1. **Never edit without showing the proposal first.** SCAN → PLAN → show → STOP. Wait for approval.
2. **One session, three improvements.** Docs edit + code edit + Godot capture. Sequential, same context.
3. **@identity is the primary source.** 594 artifacts have rich identity blocks in GDScript. Extract and use them.
4. **Code changes are conservative.** Improve clarity, add missing patterns, fix obvious issues. Never rewrite working algorithms.

---

## Phase 1: SCAN

### Parse argument

- `/ada-artifact-improver randompoints` — single artifact (shows proposal, waits for approval)
- `/ada-artifact-improver auto randompoints` — single artifact, NO approval step (fully autonomous)
- `/ada-artifact-improver auto worst 5` — 5 lowest-scoring, fully autonomous loop
- `/ada-artifact-improver worst 5` — 5 lowest-scoring artifacts (with approval)
- `/ada-artifact-improver registry:randomness` — all in one registry file

### Gather data (parallel reads where possible)

1. **Find the artifact** in `commons/artifacts/registry/*.json`. Note which file.
2. **Read the registry entry** — all existing fields.
3. **Read the GDScript** — the `scene` field → `.tscn` → find the `.gd` in same directory.
4. **Extract @identity block** — grep `# @identity` and capture all 8 lines (essence, desire, critical_parameter, triggers, emerges, needs, relationships, truth).
5. **Extract signals** — grep `^signal ` in the `.gd`.
6. **Check screenshot** — does `/scene-catalog/{lookup_name}.png` exist in the encyclopedia?
7. **Read registry_info** — parent registry's theoretical_grounding and category.

### Score (0-8 documentation, + code + capture assessment)

**Documentation score:**

| # | Field | Present if... |
|---|-------|---------------|
| 1 | description | >20 chars, multi-sentence |
| 2 | qfep_connection | Non-empty |
| 3 | gamwell_reference | Non-empty |
| 4 | interactions | Array with >=1 entry |
| 5 | signals | Array with >=1 entry |
| 6 | capacity | Non-empty |
| 7 | tags | >=5 entries |
| 8 | footprint | [x,y,z] not all 1 |

**Code assessment:** Check for:
- Missing `@identity` block → can add one
- Missing `apply_grid_config()` → should have it for map placement
- Missing `class_name` → needed for registry
- Obvious issues (unused vars, dead code, missing type hints on exports)

**Capture assessment:**
- Screenshot exists? Current quality? Scene has own ground plane?
- Optimal camera: yaw, pitch, distance based on scene structure

---

## Phase 2: PLAN

Draft ALL three improvement categories at once.

### A. Documentation improvements

For each missing/weak field, draft the actual value:

**Description (5-layer):**
1. Phenomenological — what the learner experiences (from @identity desire/essence)
2. Algorithmic — what principle is demonstrated (from @identity critical_parameter)
3. Relational — prepares for / contrasts with (from @identity relationships)
4. QFEP-structural — where in E = F + λ·φ·dE (from category)
5. Capacity — what the learner can DO after (from @identity truth)

**QFEP mapping by category:**

| Category | Term | Pattern |
|---|---|---|
| primitives, transforms | F | "Pure F — predictable, structured..." |
| randomness, noise | E(S) | "E(S) — entropy as..." |
| fractals, lsystems | λ | "Lambda-tuning between order and chaos..." |
| morphogenesis, swarm | φ·dE | "The phi term — rate of change..." |
| cellular_automata | Edge | "Critical lambda ~ 0.3–0.5..." |
| forces, physics | F | "Classical F — force as law..." |

**Other fields:**
- gamwell_reference: from registry_info.theoretical_grounding
- interactions: from @identity needs/triggers lines
- signals: from GDScript signal declarations
- capacity: from @identity truth → "VERB what_it_does"
- tags: merge existing + category + interaction types (target 5-10)
- footprint: from footprint_report.json or estimate

### B. Code improvements (conservative)

Only propose changes that are:
- **Safe**: adding missing patterns, not rewriting logic
- **Standard**: following patterns already used in other artifacts

Typical improvements:
- Add `@identity` block if missing (from registry description + code analysis)
- Add `apply_grid_config(config: Dictionary)` stub if missing
- Add `class_name` if missing
- Add signal declarations discovered from code analysis
- Fix obvious type annotation gaps on @export vars

### C. Screenshot improvements

Based on the scene structure, propose capture parameters:
- `--ground=true/false` — does scene have its own floor?
- `--yaw=N` — rotation angle (default 0.4)
- `--pitch=N` — elevation angle (default 0.35)
- `--distance=N` — zoom (0 = auto)
- `--wait=N` — wait time for procedural scenes (default 3.0)
- `--lift=true/false` — lift camera to center on object

### Output format

```
=== Artifact Improvement Proposal ===
Target: {lookup_name} ({registry_file})
Doc score: {N}/8 → {M}/8

@identity: YES/NO
Source: {gdscript_path}

--- A. DOCUMENTATION ---

1. [ADD/UPDATE] description: "{text}"
2. [ADD] qfep_connection: "{text}"
3. [ADD] gamwell_reference: "{text}"
4. [ADD] capacity: "{VERB text}"
5. [ADD] interactions: [...]
6. [ADD/SKIP] signals: [...]
7. [KEEP/UPDATE] tags: [...]
8. [ADD] footprint: [x,y,z]

--- B. CODE ---

1. [ADD] @identity block (8 lines)
   OR [SKIP] already present
2. [ADD] apply_grid_config() stub
   OR [SKIP] already present
3. [ADD] class_name ClassName
   OR [SKIP] already present
4. [other specific improvements]

--- C. SCREENSHOT ---

Command: godot ... --scene={path} --yaw=0.4 --pitch=0.35 --distance=0 --ground=true --wait=3.0
Rationale: {why these params}

Approve? (waiting for user)
```

**If `auto` mode:** Skip the approval step — proceed directly to Phase 3.
**Otherwise:** STOP HERE. Do not proceed without user approval.

---

## Phase 3: EXECUTE (sequential, same session)

After user approves, execute all three in order:

### Step 1: Documentation (Edit registry JSON)

Use the Edit tool directly. Group related fields into minimal edit calls.

### Step 2: Code (Edit GDScript)

Use the Edit tool directly. Add @identity block, apply_grid_config, class_name as needed.

### Step 3: Screenshot (Bash → Godot capture)

```bash
"C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe" --path "C:/Users/palle/Documents/GitHub/AdaResearch_46" --xr-mode off --no-window --script res://commons/testing/capture_tscn_shot.gd -- --scene={scene_path} --out=C:/Users/palle/Documents/GitHub/ada_encyclopedia/public/scene-catalog/{lookup_name}.png --ground={true|false} --yaw={N} --pitch={N} --distance={N} --wait={N}
```

If capture fails (scene needs runtime, shader compilation timeout, etc.), report the failure but don't block — docs and code improvements are still valid.

### Step 4: Update footprint from AABB (after capture)

The Godot capture script outputs the real AABB measurement:
```
capture_tscn_shot: AABB size=(3.899725, 3.899725, 10.2832) center=(0.0, 0.0, 5.141598) dist=20.6
```

**Parse this line** from the capture output. Extract the AABB size and compute the true footprint:
```
footprint_x = ceil(aabb_size_x)  # round up to grid cells
footprint_y = ceil(aabb_size_y)
footprint_z = ceil(aabb_size_z)
```

Then **edit the registry JSON again** to update the footprint with the real measured value. This replaces the estimated footprint from Phase 2 with ground truth from Godot.

Also classify `size_group` from the footprint area (x * z):
- 1 cell → "compact"
- 2-4 cells → "standard"  
- 5-9 cells → "large"
- 10+ cells → "xlarge"

---

## Phase 4: VERIFY

1. **JSON valid**: `python -c "import json; json.load(open('{registry_path}'))"`
2. **Re-score documentation**: should be higher
3. **Screenshot exists**: check the output file was created
4. **Log**: append to `commons/artifacts/improvement_log.json`

```
=== Verification ===
Documentation: {N}/8 → {M}/8
Code changes: {list or NONE}
Screenshot: CAPTURED / FAILED / SKIPPED
JSON valid: YES
```

---

## Batch Mode: `worst N`

1. Score ALL artifacts (Python one-liner, fast):
```bash
python -c "
import json, os, glob
results = []
for f in glob.glob('commons/artifacts/registry/*.json'):
    data = json.load(open(f))
    for key, art in data.get('artifacts', {}).items():
        score = 0
        if art.get('description','') and len(art.get('description','')) > 20: score += 1
        if art.get('qfep_connection',''): score += 1
        if art.get('gamwell_reference',''): score += 1
        if art.get('interactions') and len(art.get('interactions',[])) > 0: score += 1
        if art.get('signals') and len(art.get('signals',[])) > 0: score += 1
        if art.get('capacity','') or art.get('capacity_statement',''): score += 1
        if art.get('tags') and len(art.get('tags',[])) >= 5: score += 1
        fp = art.get('parameters',{}).get('footprint', art.get('footprint',[1,1,1]))
        if fp and isinstance(fp,list) and len(fp)>=3 and not(fp[0]==1 and fp[1]==1 and fp[2]==1): score += 1
        results.append((score, key, os.path.basename(f)))
results.sort()
for s, n, r in results[:20]:
    print(f'  {s}/8  {n}  ({r})')
"
```
2. Pick N worst, show all proposals
3. After approval, execute sequentially (docs + code per artifact, batch capture at end)
4. For batch capture, use Sonnet workers in parallel (one per artifact)

---

## Anti-Patterns

- **Never edit without proposal approval.**
- **Never rewrite working algorithm code.** Only add missing patterns (identity, grid config, class_name).
- **Never fabricate @identity.** If no identity block exists, draft one from the code structure and registry description — but mark it as AI-drafted.
- **Never change scene path, lookup_name, include_in_map_data.**
- **Code changes must be additive.** Add blocks, don't restructure. The artifact works — keep it working.
