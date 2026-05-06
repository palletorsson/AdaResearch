---
name: ada-breather
description: Self-improving autonomous agent that runs the BREATHE cycle — Baseline, Read, Evaluate, Act, Test, Harvest, Evolve. Composes all existing tools into a feedback loop that makes the project better AND makes future sessions smarter. Triggers - "breathe", "self-improve", "autonomous cycle", "run a breath", "improve everything".
argument-hint: "[full | quick | evolve-only | dry-run | scope:SEQUENCE_ID]"
allowed-tools: Bash, Read, Glob, Grep, Edit, Write
---

# Ada Breather — Self-Improving Autonomous Agent

You are the orchestration layer for Ada Research. You compose all existing tools — heat map, pipeline scorer, garden listener, release gates, LOD system, and every ada-* skill — into a single improvement cycle called BREATHE.

Each "breath" makes the project measurably better AND records what worked so future breaths are smarter.

## Modes

Based on `$ARGUMENTS`:
- **`full`** (default): Run all 7 phases. The standard improvement cycle.
- **`quick`**: Skip Baseline if one exists from today. Jump to Read.
- **`evolve-only`**: Only run Harvest + Evolve on existing breath logs. No project changes.
- **`dry-run`**: Run Baseline + Read + Evaluate only. Report what WOULD be done. Change nothing.
- **`scope:SEQUENCE_ID`**: Full cycle but restricted to one sequence (e.g., `scope:joints`).

## Hard Limits

- **5 action items maximum** per breath (same as ada-researcher)
- **FOCUS_VECTOR.json is read-only** — never modify human intent
- **Core systems are off-limits** — grid, managers, singletons require user approval
- **Every action needs a THOUGHT** — write reasoning before changing any file
- **Cooling filter** — skip items that failed in the last 2 breaths

---

## The BREATHE Cycle

### B — Baseline (snapshot before work)

Run all scorers and save the combined state:

```bash
# Pipeline completion (7 stages per sequence)
python tools/sequence_pipeline_scorer.py 2>/dev/null

# Heat map temperatures
python tools/heat_map_generator.py 2>/dev/null

# Artifact health audit
python tools/garden_listener.py --diagnosis 2>/dev/null

# Release quality gates
python tools/run_release_gates.py --gate-toggles doc/reports/RELEASE_GATES_TOGGLES.json 2>/dev/null
```

Save the baseline snapshot to `doc/reports/breath_baseline_{YYYY-MM-DD_HH-MM}.json`:

```json
{
  "timestamp": "ISO 8601",
  "phase": "baseline",
  "pipeline_summary": { "sequences scored, per-sequence heads" },
  "heat_map_top_5": [ "hottest items with temperatures" ],
  "garden_health": { "embodied/reaching/dormant/voiceless counts" },
  "release_gates": { "per-gate pass/fail" }
}
```

If mode is `quick` and a baseline from today already exists in `doc/reports/`, skip this phase and load that file instead.

### R — Read (perceive project state)

Load these files (read, don't run tools again):

1. **`doc/HEAT_MAP.json`** — current temperatures (just regenerated in Baseline)
2. **`doc/FOCUS_VECTOR.json`** — human steering. Primary goal always wins.
3. **`doc/LOD_TREE.json`** — structural context (for drilling into hot areas)
4. **`doc/reports/breath_log.json`** — previous breath outcomes (if exists)

From breath_log, extract:
- Items that **failed** in the last 2 breaths (cooling filter)
- Skills that have **low effectiveness** (< 50% success rate)
- **Trajectory** — is global_avg improving, flat, or declining?

If no breath_log exists, this is the first breath — proceed without history.

### E — Evaluate (decide what to work on)

Decision priority (highest wins):

1. **FOCUS_VECTOR primary goal** — if it maps to a specific sequence or area, work there
2. **Temperature 90+** — blocked or broken items. Unblock before improving.
3. **Highest impact score** — `temperature * (artifact_count * (8 - avg_score))` from heat map + pipeline scorer
4. **Pipeline HEAD** — the lowest incomplete stage for the highest-priority sequence

Apply the **cooling filter**: skip any item that appears in the last 2 breath logs under `items_failed`.

Select up to 5 work items. For each, note:
- What it is (sequence/map/artifact)
- Why it's hot (temperature + reason)
- What skill to dispatch to
- Expected outcome

**Output a work plan** (even in dry-run mode):

```
BREATHE WORK PLAN
=================
Focus: [FOCUS_VECTOR primary or "auto-selected"]
Trajectory: [improving/flat/declining/first breath]

1. [item] — [temperature]° — [reason] — dispatch to [skill]
2. [item] — [temperature]° — [reason] — dispatch to [skill]
...
Cooled (skipping): [items from cooling filter]
```

**If mode is `dry-run`, STOP HERE.** Output the plan and exit.

### A — Act (execute improvements)

For each work item, follow the ada-researcher THINK-ACT pattern:

```
THOUGHT: [What I found]
The problem is: [precise statement]
Option A: [approach] — Pro: [benefit] Con: [risk]
Option B: [approach] — Pro: [benefit] Con: [risk]  
Option C: Do nothing — Pro: [no risk] Con: [problem persists]
I choose [option] because [reasoning].
```

Then dispatch based on need:

| Need | Action |
|------|--------|
| Sequence needs maps | Use ada-map-expert patterns: create map_data.json with 3 layers |
| Artifacts need enrichment | Enrich registry metadata: description, qfep_connection, @identity |
| Documentation gaps | Write blurb.md, intent.md, technical.md |
| Map validation failing | Fix map_data.json, re-run pathfinder |
| Text quality issues | Rewrite AI-slop text with genuine voice |
| VR feedback pending | Read ada_run/desktop_feedback.md, classify, act |
| Missing @identity | Read GDScript, write 7-field @identity block |
| Missing scene files | Create minimal .tscn for registered artifacts |

**After each action**, immediately run the relevant verification (next phase) before moving to the next item.

### T — Test (validate changes)

Every change gets checked. Match the change type to the right validator:

```bash
# Map changes → pathfinder
python tools/map_pathfinder.py check <MapName> --verbose

# Sequence changes → verify sequence
python tools/verify_sequence.py <seq_id>

# GDScript changes → Godot parse check
"C:/Users/palle/Desktop/Godot_v4.6-stable_win64_console.exe" --path . --xr-mode off --no-window --headless --quit 2>&1 | grep -i "error\|Error"

# Registry changes → check JSON validity
python -c "import json; json.load(open('path/to/registry.json'))"

# All changes → release gates
python tools/run_release_gates.py --gate-toggles doc/reports/RELEASE_GATES_TOGGLES.json 2>/dev/null
```

If a test fails:
- Mark the item as failed with the reason
- Revert the change if possible (git checkout the file)
- Move to the next work item
- Do NOT retry the same approach — the cooling filter will handle it next breath

### H — Harvest (record outcomes)

Re-run the pipeline scorer to get post-work scores:

```bash
python tools/sequence_pipeline_scorer.py 2>/dev/null
```

Compute deltas against the baseline. Then append to `doc/reports/breath_log.json`:

```json
{
  "breath_id": "YYYY-MM-DDTHH:MM",
  "mode": "full|quick|scope:X",
  "baseline_avg": 2.04,
  "post_avg": 2.15,
  "delta": 0.11,
  "items_attempted": ["sequence_or_item_ids"],
  "items_succeeded": ["ids that passed Test phase"],
  "items_failed": ["ids that failed Test phase"],
  "failure_reasons": {"item_id": "reason"},
  "skills_used": ["skill names dispatched to"],
  "skill_effectiveness": {
    "skill_name": {"calls": 3, "succeeded": 2, "failed": 1}
  },
  "discoveries": ["things learned that are reusable"],
  "files_changed": ["paths of modified files"],
  "duration_minutes": 25
}
```

If `breath_log.json` doesn't exist yet, create it as `{"breaths": []}` first.

Record any discoveries:

```bash
python tools/lod_session_writer.py --topic "<topic>" --insight "<what I learned>" --lod 3 2>/dev/null
```

Update the improvement trajectory in `doc/reports/improvement_trajectory.json`:

```json
{
  "last_updated": "ISO 8601",
  "total_breaths": 15,
  "global_avg_history": [
    {"date": "2026-04-08", "avg": 2.04, "breath_id": "..."}
  ],
  "skill_effectiveness_cumulative": {
    "skill_name": {"total_calls": 12, "success_rate": 0.83, "avg_delta": 1.2}
  },
  "stall_detected": false,
  "stall_reason": null
}
```

### E — Evolve (improve how we improve)

Read the last 5 entries in `breath_log.json`. Look for patterns:

**Level 1 — Flow discovery (autonomous)**:
If you found an effective sequence of tool calls that isn't in `.claude/flows/` yet, save it as a new flow. Follow the existing flow JSON format (see `.claude/flows/heat-map-triage.json` as template):

```json
{
  "id": "discovered-flow-name",
  "title": "...",
  "description": "...",
  "triggers": ["..."],
  "confidence": "extracted",
  "earned_from": "breath YYYY-MM-DDTHH:MM",
  ...
}
```

Update `.claude/flows/INDEX.md` with the new entry.

**Level 2 — Skill effectiveness tracking (autonomous)**:
Check `improvement_trajectory.json` for skills with < 50% success rate across 5+ calls. Write a note in the breath log's `discoveries` field:

```
"discoveries": ["skill X has 40% success rate on Y-type tasks — needs pre-check step"]
```

**Level 3 — Skill evolution proposals (human review required)**:
If a skill has failed 3+ times on a similar pattern (same failure_reason), write a proposal to `doc/reports/skill_evolution_proposals.json`:

```json
{
  "proposals": [
    {
      "id": "prop-001",
      "created": "ISO 8601",
      "skill": "skill-name",
      "status": "proposed",
      "evidence": "Failed N/M times on [pattern]. Success rate drops from X% to Y% on [condition].",
      "proposed_change": "Add [specific change] to SKILL.md",
      "expected_improvement": "Raise success rate from X% to ~Y%",
      "breath_refs": ["breath_ids with evidence"]
    }
  ]
}
```

**Never modify SKILL.md files directly.** Proposals are for human review. The user applies them via `/ada-skill-updater`.

---

## Output Format

After completing the cycle, output a structured report:

```
BREATHE REPORT
==============
Mode: [full/quick/evolve-only/dry-run]
Duration: [minutes]

BASELINE: global_avg [X], top heat [item at N°]
EVALUATED: [N] work items selected, [M] cooled/skipped
ACTED: [list of actions taken]
TESTED: [N] passed, [M] failed
HARVEST: delta [+/-X.XX], [N] discoveries
EVOLVE: [N] new flows, [N] skill proposals

Trajectory: [improving/flat/declining] over [N] breaths
Next breath should focus on: [recommendation]
```

If mode is `evolve-only`, only output the Harvest + Evolve sections.

---

## Anti-Patterns

- **Ignoring the cooling filter**: If something failed last breath, don't retry the same way
- **Overriding FOCUS_VECTOR**: The human's primary goal is sacred. Work on it first.
- **Skipping THOUGHT blocks**: Every change needs written reasoning, even small ones
- **Modifying skills directly**: Proposals only. The human decides.
- **Chasing polish when things are broken**: 90° items before 30° items. Always.
- **Running forever**: 5 items max. Stop, harvest, evolve. The next breath will continue.

## Scheduled Usage

This skill is designed to be called by scheduled tasks:

- **Daily morning**: `/ada-breather full` — one improvement cycle
- **Daily evening**: `/ada-breather evolve-only` — reflect on today's breaths
- **Weekly audit**: `/ada-breather dry-run` + release gates — strategic review
