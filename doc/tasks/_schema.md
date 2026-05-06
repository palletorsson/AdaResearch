# Task Schema

One JSON file per **goal**. Each goal contains many **tasks** that can be picked up independently. Tasks are picked by Codex, a human collaborator, or a subagent.

## File format

`doc/tasks/<goal_id>.json`

```json
{
  "goal_id": "remove_chambers",
  "goal_title": "Remove chamber maps and distribute the gaming layer",
  "why": "One-paragraph explanation of the strategic reason this goal exists",
  "success_criteria": [
    "All 17 Chamber_* maps removed from sequence JSONs",
    "Every teaching map has biome wiring",
    "Every sequence's catalyst mode activates in a non-chamber map",
    "All 500 maps still pass pathfinder"
  ],
  "prerequisites": ["audit_all_sequences"],
  "tasks": [
    {
      "id": "remove_chambers.001",
      "title": "Audit which chambers contain unique content not duplicated elsewhere",
      "spec": "Read each Chamber_*/map_data.json. List artifacts that appear only in the chamber and nowhere else. Output as markdown table in doc/tasks/_audits/chamber_unique.md.",
      "effort": "30min",
      "skill": "read",
      "depends_on": [],
      "status": "open",
      "claimed_by": null,
      "done_at": null,
      "artifact_refs": [],
      "map_refs": ["Chamber_Primitives", "Chamber_Color", "..."],
      "output": "doc/tasks/_audits/chamber_unique.md"
    }
  ]
}
```

## Task fields

| Field | Type | Required | Meaning |
|---|---|---|---|
| `id` | string | yes | `<goal_id>.NNN` — stable identifier |
| `title` | string | yes | One-line imperative description |
| `spec` | string | yes | Complete self-contained instruction. Must be executable without context. |
| `effort` | string | yes | Rough estimate: `10min`, `1h`, `half-day`, `multi-day` |
| `skill` | string | yes | `read`, `edit`, `design`, `build`, `verify`, `research` |
| `depends_on` | string[] | no | Task IDs that must be `done` before this starts |
| `status` | enum | yes | `open`, `claimed`, `blocked`, `done`, `cancelled` |
| `claimed_by` | string|null | no | "codex", "plix", agent name |
| `done_at` | string|null | no | ISO date when marked done |
| `artifact_refs` | string[] | no | Artifact lookup_names this task affects |
| `map_refs` | string[] | no | Map names this task affects |
| `sequence_refs` | string[] | no | Sequence IDs this task affects |
| `output` | string | no | File path(s) this task produces |
| `verification` | string | no | Command or check to verify done (e.g., `python tools/map_pathfinder.py check --all`) |

## Spec writing rules

A task spec is an instruction sent to a cold collaborator. It must:

1. **Name concrete files** — full paths, not "the registry"
2. **Name concrete commands** — `python tools/map_pathfinder.py check MyMap`, not "validate the map"
3. **State the output format** — markdown, JSON, GDScript, with location
4. **Name the verification step** — how to know it's done
5. **Not assume context** — link to references if needed

Bad: "Update the registry with new artifacts"

Good:
> Add `example_2_1_forces_vr` to `commons/artifacts/registry/physics_simulation.json`. Follow the schema used by `example_2_2_forces_mass_variation_vr` (around line 1502). Set `lookup_name`, `scene` path to `res://algorithms/forces/example_2_1_forces_vr.tscn`, `map_sequences: ["forces"]`. Verify with `python -c "import json; d=json.load(open('commons/artifacts/registry/physics_simulation.json')); assert 'example_2_1_forces_vr' in d['artifacts']"`.

## Goal vs Task

- **Goal** = strategic outcome ("Remove chambers"). Has `why` and `success_criteria`.
- **Task** = concrete action ("Delete Chamber_Primitives from primitives.json `maps[]`"). Has `spec` and `verification`.

A goal typically has 3-20 tasks. If more, split into sub-goals.

## Workflow

1. A human or AI reviews open goals in the encyclopedia `/tasks` page
2. Picks a task matching their skills and available time
3. Sets `status: claimed`, `claimed_by: <name>`
4. Reads the spec, executes the work
5. Runs the `verification` command
6. Sets `status: done`, `done_at: <date>`
7. Commits the change

If a task turns out to be wrong or blocked: set `status: blocked` and add a note in the task description explaining why.
