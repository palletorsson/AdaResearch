# Project Dashboard CLI — AI Onboarding Guide

## What Is This Project?

Ada Research is a **VR world where you learn algorithms through your body**. Built in Godot 4 (GDScript), it's an artistic research project asking: *Can we put Paul Klee's Pedagogical Sketchbook in Virtual Drag?*

The player walks through a landscape of algorithms — from basic geometry (points, lines) through fractals, cellular automata, machine learning, and chaos theory. Each algorithm becomes a physical space you inhabit in VR. The project has four deliverables: a **VR world**, a **book**, a **game wiki**, and **exhibited installations**.

The theoretical spine is **QFEP** — a queer-feminist framework for understanding how algorithms shape bodies and subjectivity:
- **F (Free energy / F_order)** — structure, geometry, organization
- **E (Entropy / E_entropy)** — randomness, noise, emergence from chaos
- **λ (Lambda edge / lambda_edge)** — boundaries, fractals, the edge between order and disorder
- **φΔE (Integration)** — connection, swarms, networks, things working together
- **Synthesis** — meta-reflection, foundations crisis, the whole picture

Six QFEP phases organize the 39 sequences: `F_order → oscillation → E_entropy → lambda_edge → integration → synthesis`.

The critical question running through everything: **What is the queer within the algorithm itself?** Not "queering" algorithms from outside, but finding the queer potential already present in mathematical and computational structures.

## What This Tool Is

The Project Dashboard CLI reads `sequence_requirements.json` and cross-references the actual filesystem to give you a live picture of project completeness. It tells you what exists, what's missing, and what to work on next.

**Use this tool at the start of every session to decide what to work on.**

### Project Structure

The project has **39 sequences** (19 spine + 20 branch), each containing maps. A map is a physical space (a room, a landscape, a puzzle). Maps are folders under `commons/maps/<MapName>/` containing `map_data.json` (the grid layout) and up to four `.md` files:

| File | Purpose | Feeds | Tone |
|------|---------|-------|------|
| `blurb.md` | Atmospheric intro (~1 paragraph). Tone and mood. | Wiki, Installations | Poetic, present-tense, evocative |
| `summary.md` | Spatial layout, key elements, learning sequence. | Wiki, Book | Structured, specific, spatial |
| `technical.md` | Code examples, GDScript implementation details. | Book | Tutorial, pedagogical, code-heavy |
| `critical.md` | Queer theory, philosophy, critical reflection. | Book | Theoretical, questioning, political |

A sequence is **book-ready** when all its maps have `technical.md` + `critical.md`.
A sequence is **wiki-ready** when all its maps have `blurb.md` + `summary.md`.

### Exemplar Files — Read These First

Before writing any .md files, read this complete set to understand the tone and depth expected:

```
commons/maps/Point_One/blurb.md      — ~1 paragraph, poetic
commons/maps/Point_One/summary.md    — structured spatial overview
commons/maps/Point_One/technical.md  — GDScript tutorial with code
commons/maps/Point_One/critical.md   — queer theory + philosophy (~120 lines)
```

These are the gold standard. Match their quality and voice.

## How to Run

```powershell
powershell -ExecutionPolicy Bypass -File commons/tools/project_dashboard_cli.ps1 -Mode <mode> [-Name <name>] [-Format <format>]
```

Always run from the project root: `C:\Users\palle\Documents\GitHub\AdaResearch_46`

## Modes

### `status` — Where are we?

Run this first in any session to orient yourself.

```
powershell -ExecutionPolicy Bypass -File commons/tools/project_dashboard_cli.ps1 -Mode status
```

Returns: total sequences, total maps, book/wiki readiness counts, missing .md counts by type, phase breakdown. This is your dashboard at a glance.

### `recommend` — What should we work on next?

**This is the primary decision-making tool.** Run it to get strategic recommendations.

```
powershell -ExecutionPolicy Bypass -File commons/tools/project_dashboard_cli.ps1 -Mode recommend
```

Returns five sections:

1. **Near Wins** — Sequences with the fewest missing files. Completing these gives visible progress for minimal effort. Color (3 files) before forces (75 files).

2. **Blurb-Complete** — Sequences where all blurbs exist but summary/technical/critical are missing. These are the best candidates for writing because the atmospheric context already exists — you know the tone.

3. **Phase Completion** — Which QFEP phase is closest to all-book-ready. Integration phase (50%) leads. Helps decide whether to push one phase to completion or spread effort.

4. **Post-Lab Gaps** — Sequences without a post-lab map. These block the Lab forest progression system.

5. **Suggested Next Session** — A concrete recommendation: which sequence, how many files, in what order, and where to find context.

### `nearwin` — Ranked completion table

```
powershell -ExecutionPolicy Bypass -File commons/tools/project_dashboard_cli.ps1 -Mode nearwin
```

Full table of all incomplete sequences sorted by fewest missing files. Each row shows blurb/summary/technical/critical gaps separately. Use this to pick your target.

### `sequence` — Deep dive into one sequence

```
powershell -ExecutionPolicy Bypass -File commons/tools/project_dashboard_cli.ps1 -Mode sequence -Name cellularautomata
```

Returns: coverage per .md type, all layer statuses, and **the exact list of missing file paths**. Use this after picking a sequence from `recommend` or `nearwin` to get the specific file paths you need to create.

### `context` — Everything you need to write .md for a map

```
powershell -ExecutionPolicy Bypass -File commons/tools/project_dashboard_cli.ps1 -Mode context -Name CA_1
```

Returns: which sequence this map belongs to, its position in the sequence, previous/next maps, existing files, missing files, QFEP context (phase, contribution, builds_on), nature context (element, forest note), capability context (perception, capability, relation), queer dimension, and algorithm source file locations.

**This is the context-gathering step before writing.** It tells you everything you need to know about a map before creating its .md files.

### `tasks` — Full task list sorted by priority

```
powershell -ExecutionPolicy Bypass -File commons/tools/project_dashboard_cli.ps1 -Mode tasks
```

Every missing .md file as a separate task, sorted CRITICAL (0% coverage) → PARTIAL → WARNING (post-lab gaps). Use `-Format json` for machine-readable output.

### `missing` — Flat list of all missing file paths

```
powershell -ExecutionPolicy Bypass -File commons/tools/project_dashboard_cli.ps1 -Mode missing
```

One file path per line. All 878 missing .md files. Use `-Format csv` for `SEQUENCE|MD_TYPE|MAP_NAME|FILE_PATH` columns.

### `postlab` — Post-lab map status

```
powershell -ExecutionPolicy Bypass -File commons/tools/project_dashboard_cli.ps1 -Mode postlab
```

Shows which sequences have post-lab maps and which don't.

### `phase` — QFEP phase breakdown

```
powershell -ExecutionPolicy Bypass -File commons/tools/project_dashboard_cli.ps1 -Mode phase
```

Sequences grouped by their QFEP phase with book/wiki readiness indicators.

## Session Workflow

Here is how an AI session should use the CLI to decide what to work on and execute it:

### Step 1: Orient

```
powershell -ExecutionPolicy Bypass -File commons/tools/project_dashboard_cli.ps1 -Mode recommend
```

Read the output. Note the suggested sequence and the near-win list.

### Step 2: Choose a target

Either follow the suggestion, or pick from the near-win list based on what the user wants to focus on. Ask the user if unsure.

### Step 3: Get the map list

```
powershell -ExecutionPolicy Bypass -File commons/tools/project_dashboard_cli.ps1 -Mode sequence -Name <chosen_sequence>
```

This gives you the exact missing file paths.

### Step 4: Gather context for each map

```
powershell -ExecutionPolicy Bypass -File commons/tools/project_dashboard_cli.ps1 -Mode context -Name <map_name>
```

Then also read:
- The map's `map_data.json` — gives grid layout, interactables, utilities, scene references
- The map's `blurb.md` (if it exists) — gives tone and atmosphere
- Algorithm README files listed in the context output — gives implementation details
- The algorithm `.gd` scripts — gives the actual code for technical.md
- Previous/next map's .md files — gives continuity

### Step 5: Write the files

Write in this order within each map:

1. **blurb.md** first (if missing) — 1 paragraph, atmospheric, poetic. Sets the mood. See existing blurbs for tone.
2. **summary.md** second — structured overview with sections: Overview, Spatial Layout, Key Elements, Atmosphere, Learning Sequence, Design Intent, Connection to Sequence. Read `map_data.json` for spatial data.
3. **technical.md** third — code tutorial with GDScript examples. Read the algorithm `.gd` files. Include working code snippets. Explain what's happening in the map technically.
4. **critical.md** last — philosophical/theoretical reflection. Connect to queer theory, the QFEP framework, the application's research questions. This requires understanding all the other layers.

### Step 6: Verify

After writing, run `sequence` mode again to confirm the counts updated:

```
powershell -ExecutionPolicy Bypass -File commons/tools/project_dashboard_cli.ps1 -Mode sequence -Name <sequence>
```

## Writing Guidelines

### blurb.md
- One paragraph, no headers
- Atmospheric, present-tense
- Describe what happens in this space, what you encounter
- Poetic but grounded — not vague, but evocative
- Example tone: "A grid of cells. Each cell looks at its neighbors and decides: alive or dead, on or off."

### summary.md
- Markdown with headers
- Start with `# Map Name - Map Summary`
- Sections: Overview, Spatial Layout (dimensions, architecture), Key Elements (interactables, utilities), Atmosphere (background, audio, lighting), Learning Sequence (numbered steps), Design Intent, Connection to Sequence
- Read `map_data.json` for grid dimensions, interactable positions, utility types
- Be specific about coordinates and layout

### technical.md
- Markdown with headers, code blocks
- Start with `# Map Name - Technical Tutorial`
- Include GDScript code examples from the actual algorithm scripts
- Explain what the code does and how it relates to what the player sees
- Build from simple concepts to complex ones
- Use `extends Node3D` / `extends XRToolsPickable` etc. — real Godot patterns

### critical.md
- Markdown with headers
- Start with `# Map Name - Critical Reflection`
- Connect the algorithm to queer theory, critical theory, philosophy
- Reference the QFEP framework (use the context command for the sequence's QFEP contribution)
- Ask questions — "What does it mean that...?"
- Draw connections between mathematical/computational concepts and political/social ones
- Reference the queer_dimension from the application context
- 500-1500 words typically

## Context Sources Reference

| Source | Path | What it provides |
|--------|------|-----------------|
| Map data | `commons/maps/<MapName>/map_data.json` | Grid layout, interactables, utilities, scenes |
| Existing blurb | `commons/maps/<MapName>/blurb.md` | Tone, atmosphere |
| Algorithm code | `algorithms/<sequence_name>/**/*.gd` | Implementation details for technical.md |
| Algorithm READMEs | `algorithms/<sequence_name>/**/README.md` | Algorithm documentation |
| Sequence requirements | `commons/maps/sequence_requirements.json` | QFEP, nature, capability, queer dimension |
| Sequence file | `commons/maps/sequences/<name>.json` | Map list and order |
| Infoboard | `commons/context/clipboard/infoboard_content.json` | Topic summaries |
| Complete exemplar | `commons/maps/Point_One/` | All four .md files as reference |

## Example: Complete a Near-Win

Say `recommend` suggests `color` with 3 missing files. Here's the full workflow:

```
# 1. Which files?
powershell -ExecutionPolicy Bypass -File commons/tools/project_dashboard_cli.ps1 -Mode sequence -Name color
# Output tells you: Color_Flashlight needs summary.md, technical.md, critical.md

# 2. Gather context
powershell -ExecutionPolicy Bypass -File commons/tools/project_dashboard_cli.ps1 -Mode context -Name Color_Flashlight
# Tells you: sequence position, QFEP context, algorithm locations

# 3. Read source materials
# Read commons/maps/Color_Flashlight/map_data.json
# Read commons/maps/Color_Flashlight/blurb.md
# Read algorithm code from algorithms/color/
# Read neighboring maps' .md files for continuity

# 4. Write the three files
# Write commons/maps/Color_Flashlight/summary.md
# Write commons/maps/Color_Flashlight/technical.md
# Write commons/maps/Color_Flashlight/critical.md

# 5. Verify
powershell -ExecutionPolicy Bypass -File commons/tools/project_dashboard_cli.ps1 -Mode sequence -Name color
# Should now show: Book ready: YES, Wiki ready: YES
```

## What the Tool Cannot Do (Yet)

- **Cannot check .md quality** — it only checks existence, not content. A 1-byte file counts as "done."
- **Cannot write files** — it's read-only. The AI writes; the tool reports.
- **Cannot talk to Oversight** — use the `/ada-task-manager` skill for that. The CLI and Oversight are separate systems.
- **Cannot detect anomalous post-lab maps** — it checks existence only. The `gap_summary` in `sequence_requirements.json` lists 4 anomalous maps with wrong content (cellularautomata, meshes, vectors, geometric).
- **Cannot update sequence_requirements.json** — if you add new sequences or change structure, the JSON must be manually updated.
