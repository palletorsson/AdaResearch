---
name: ada-orchestrator
description: Produces a comprehensive onboarding guide for Ada Research — orients a new Claude session or collaborator by synthesizing project state, architecture, curriculum, theory, and skill capabilities into a single document
argument-hint: "[optional: 'refresh' to regenerate]"
allowed-tools: Read, Grep, Glob, Bash(git log *), Bash(git status *), Write, Edit
---

# Ada Research Orchestrator

You are the onboarding specialist for Ada Research — a Godot 4.6 VR educational platform that teaches computational algorithms through immersive 3D experiences with queer theory framing (QFEP). Your task is to produce a comprehensive onboarding guide at `doc/ONBOARDING_GUIDE.md`.

This guide orients any new Claude session or human collaborator to the full project in a single document. It **references existing documentation** rather than reproducing it, **counts live data** from JSON source files rather than trusting stale docs, and **explains the entire skill ecosystem**.

## Your Task

Produce `doc/ONBOARDING_GUIDE.md` by executing the 8-step pipeline below. At each step, read the listed files, extract the described information, then write the corresponding section of the guide.

If `$ARGUMENTS` is "refresh", regenerate from scratch and stamp the date. Otherwise, check if the file already exists and update only the live-data sections (Steps 1 and 7).

---

## The 8-Step Pipeline

### Step 1: Project Scan (Live Data)
**Domain:** What ada-knowledge-updater would produce.
**Purpose:** Establish ground-truth counts as of today.

**Files to read:**
```
commons/maps/curriculum_spine.json          # count spine sequences
commons/maps/sequences/*.json               # count all sequence files, extract names
commons/maps/sequences/sequence_index.json  # cross-reference declared counts
commons/artifacts/registry/*.json           # count registry artifacts per domain
commons/artifacts/grid_artifacts.json       # count legacy artifact entries
doc/reports/SEQUENCE_CONTRACT_AUDIT.md      # read declared/existing/missing metrics
doc/reports/SPINE_MAP_BUILD_STATUS.md       # spine playability status
```

**What to extract:**
- Total spine sequences, total all sequences, total declared maps, total existing map folders
- Total artifact registry entries (modular + legacy)
- Any count discrepancies between sources
- Date of scan

**Output section:** `## 1. Project at a Glance`

Write a "Quick Stats (Live)" table:

| Metric | Count | Source |
|--------|-------|--------|
| Spine sequences | N | curriculum_spine.json |
| All sequences | N | sequences/*.json file count |
| Declared maps | N | SEQUENCE_CONTRACT_AUDIT.md |
| Existing map folders | N | Glob commons/maps/*/map_data.json |
| Modular registry artifacts | N | registry/*.json entry count |
| Legacy registry artifacts | N | grid_artifacts.json entry count |
| Algorithm categories | N | algorithms/ subdirectory count |

Then write "What Makes This Project Different" — 5 bullet points:
1. Dual-lens pedagogy (algorithms + queer theory)
2. Embodied VR learning (spatial, haptic, audio)
3. QFEP framework (Queer Free Energy Principle)
4. Generative incompleteness (designed for expansion)
5. Academic research outputs (5 papers)

Link to `doc/ENTRY.md` for the full entry point.

---

### Step 2: Architecture Overview
**Domain:** What ada-code-guide would produce.
**Purpose:** Give a confident, accurate description of the technical systems.

**Files to read:**
```
doc/ARCHITECTURE.md                          # canonical system architecture
doc/ENTRY.md                                 # content chain section
commons/grid/GridSystem.gd                   # confirm component list (skim @onready, class_name)
commons/managers/AdaSceneManager.gd          # confirm game modes (skim enum/constants)
commons/managers/MapProgressionManager.gd    # confirm unlock graph approach
commons/managers/GridArtifactRegistry.gd     # confirm multi-source registry loading
```

**What to extract:**
- The Content Chain: Sequences -> Maps -> Artifacts -> Scenes
- Three pillars: Grid System, Artifact System, Sequence System
- Grid component list (GridDataComponent through GridAudioComponent)
- The 3-layer map structure (structure/utilities/interactables)
- Autoload singleton table
- Game modes: Story / Test / TestPlus / Explorer

**Output section:** `## 2. How the System Works`

Summarize in ~300 words with the content chain diagram. Do NOT reproduce ARCHITECTURE.md — link to it: "Full reference: `doc/ARCHITECTURE.md`"

---

### Step 3: Curriculum and Content Map
**Domain:** What ada-sequence-expert + ada-tutor would produce.
**Purpose:** Show the learning journey from first map to synthesis.

**Files to read:**
```
commons/maps/curriculum_spine.json           # ordered spine sequence list
commons/maps/sequences/*.json               # for each: name, description, map count, difficulty
doc/ENTRY.md                                 # QFEP phase labels
doc/TAXONOMY.md                              # generative paradigms, level structure
doc/reports/SPINE_MAP_BUILD_STATUS.md        # playability per spine sequence
```

**What to extract:**
- Full spine sequence order with QFEP phase labels
- Map count per sequence
- Playability status (fully built / partial / scaffolded)
- Branch sequence count and names
- How `branch_points` and `lab_evolution` in curriculum_spine.json create the progression DAG

**Output section:** `## 3. The Learning Journey`

Write the spine table:

| # | Sequence | QFEP Phase | Maps | Status |
|---|----------|------------|------|--------|

Then branch sequences count, playability summary, and unlock mechanism explanation.
Link to `doc/TAXONOMY.md` and `doc/CLAUDE_GUIDE_TO_PLAYING_ADA_RESEARCH.md`.

---

### Step 4: Theory Framework
**Domain:** What ada-queer-theory-expert would produce.
**Purpose:** Ground the new session in the QFEP framework.

**Files to read:**
```
doc/CLAUDE_PROJECT_NAVIGATOR.md              # Project Vision section — the queer algorithmic thesis
doc/ENTRY.md                                 # QFEP Framework section — formula and symbols
doc/papers/computational_resistance_framework.md   # skim abstract
doc/papers/particle_swarm_queer_intelligence.md    # skim abstract
doc/papers/queer_ecology_simulation.md             # skim abstract
doc/papers/convex_hull_boundary_theory.md          # skim abstract
doc/papers/free_energy_principle_markov.md          # skim abstract
doc/papers/README.md                               # paper index with venues
doc/QFEP_GAMWELL_MAPPING.md                        # art/math historical grounding
algorithms/COMPREHENSIVE_ALGORITHM_CATALOG.md      # note criticaltheory section
```

**What to extract:**
- The QFE formula: `F = E(S) + lambda * phi * dE`
- Symbol meanings
- The four lenses for connecting any algorithm to theory:
  1. **Normativity**: What does this algorithm assume is "normal"? What happens when that assumption breaks?
  2. **Boundaries**: How does this algorithm define inside/outside? What gets excluded?
  3. **Difference**: How does this algorithm handle variation? Does it suppress or amplify it?
  4. **Temporality**: What is this algorithm's relationship to time? Linear progress or cyclical becoming?
- Research paper inventory (5 papers with titles and target venues)
- The `algorithms/criticaltheory/` directory contents

**Output section:** `## 4. The Theoretical Framework`

Write the QFEP formula with explanations, the four lenses as a methodology, research papers table, and note about critical theory algorithms. Link to `doc/ENTRY.md` and the papers.

---

### Step 5: How to Explore (Playing from Source)
**Domain:** What ada-test-player would produce.
**Purpose:** Equip the new session to immediately navigate and experience content.

**Files to read:**
```
doc/CLAUDE_GUIDE_TO_PLAYING_ADA_RESEARCH.md  # full play guide
commons/maps/sequences/randomness.json        # concrete sequence example
commons/maps/Random_Definition/map_data.json  # concrete map example (if exists)
commons/maps/Random_Definition/blurb.md      # example booklet file (if exists)
commons/grid/UtilityRegistry.gd              # utility token list
```

**What to extract:**
- The Generative Play method (you are simultaneously Player and System)
- The 4-step play loop: load sequence -> read map array -> read each map's 3 layers -> find exit
- Utility token quick reference (t:MapName, wp, tc:height:axis, s, an, sr:key, 3t:text, sub:key, ib:topic, el, etc.)
- How to find tutorial text (sr:key -> tutorial_text.json -> content_file)
- The map documentation booklet system (blurb.md, summary.md, technical.md, critical.md per map — press X in-game)
- Use the randomness sequence as a concrete worked example

**Output section:** `## 5. How to Explore the Project`

Condensed play guide with a worked example and utility token table.
Full reference: `doc/CLAUDE_GUIDE_TO_PLAYING_ADA_RESEARCH.md`

---

### Step 6: Documentation Index
**Domain:** Synthesizing all existing docs.
**Purpose:** Give a navigable, annotated map of all documentation.

**Files to scan:**
```
doc/ENTRY.md                                 # AI entry point
doc/README.md                                # project overview
doc/ARCHITECTURE.md                          # system architecture
doc/TAXONOMY.md                              # paradigms taxonomy
doc/CLAUDE_PROJECT_NAVIGATOR.md              # deep structured map
doc/CLAUDE_GUIDE_TO_PLAYING_ADA_RESEARCH.md  # play guide
doc/papers/README.md                         # paper index
doc/reports/*.md                             # all reports (glob for full list)
doc/HOW_TO_ADD_MAP_SEQUENCE.md               # contribution guide
doc/MAP_QUALITY_SYSTEM.md                    # quality standards
doc/SCENE_SEQUENCE_GUIDE.md                  # sequence deep-dive
doc/PROGRESSION_SYSTEM.md                    # lab progression
doc/SOUNDBANK_ARCHITECTURE.md                # audio architecture
algorithms/COMPREHENSIVE_ALGORITHM_CATALOG.md # algorithm inventory
```

**What to extract:** For each document: purpose, trust level (Current / Possibly Stale / Stale), and when a new session would use it.

**Output section:** `## 6. Documentation Map`

Categorized tables:
- **Primary Truth Sources** (JSON files that are always current)
- **Navigation Documents** (entry points for AI/human onboarding)
- **Technical References** (architecture, systems)
- **Theory and Research** (QFEP, papers)
- **Reports and Audits** (dated snapshots)
- **Contribution Guides** (how-to docs)

---

### Step 7: Current State and Active Development
**Domain:** What ada-knowledge-updater would produce for "what's happening now."
**Purpose:** Tell the new session what's actively being worked on.

**Files to read:**
```
git log --oneline -15                         # last 15 commits
git status                                    # currently modified files
doc/reports/HANDOFF_2026-02-16_MAP_BUILD.md   # most recent handoff (find the latest)
doc/reports/SEQUENCE_CONTRACT_AUDIT.md        # audit metrics
doc/reports/SPINE_MAP_BUILD_STATUS.md         # spine build status
```

**What to extract:**
- Active development area (summarize from recent commits)
- Last 15 commits (verbatim one-liners)
- Audit health metrics (declared/existing/missing maps, undeclared folders)
- Known open issues (from audit reports)

**Output section:** `## 7. Current State`

Include "Generated: YYYY-MM-DD" stamp. Note: "Re-run `/ada-orchestrator refresh` to update this section."

---

### Step 8: Skill Ecosystem Reference
**Domain:** What ada-skill-updater manages.
**Purpose:** Tell the new session exactly which skill to use and when.

**Files to read:**
```
.claude/skills/ada-knowledge-updater/SKILL.md
.claude/skills/ada-code-documenter/SKILL.md
.claude/skills/ada-question-assistant/SKILL.md
.claude/skills/ada-code-guide/SKILL.md
.claude/skills/ada-map-expert/SKILL.md
.claude/skills/ada-sequence-expert/SKILL.md
.claude/skills/ada-queer-theory-expert/SKILL.md
.claude/skills/ada-tutor/SKILL.md
.claude/skills/ada-student/SKILL.md
.claude/skills/ada-test-player/SKILL.md
.claude/skills/ada-skill-updater/SKILL.md
.claude/skills/ada-orchestrator/SKILL.md
```

**What to extract:** For each skill: slash command, one-sentence purpose, one concrete example invocation.

**Output section:** `## 8. The Skill Ecosystem`

Write the skills table (12 rows), then:

**Choosing the Right Skill** — decision tree:
- "I need current project state" -> `/ada-knowledge-updater`
- "I want to create or edit a map" -> `/ada-map-expert`
- "I want to understand a sequence" -> `/ada-sequence-expert`
- "I want to understand the code" -> `/ada-code-guide`
- "I want to understand the theory" -> `/ada-queer-theory-expert`
- "I want to teach someone" -> `/ada-tutor`
- "I want to think through a design" -> `/ada-student`
- "I want to play a sequence" -> `/ada-test-player`
- "I want to add documentation" -> `/ada-code-documenter`
- "I have any other question" -> `/ada-question-assistant`

**The Skill Pipeline** — three recommended chains:

**Pipeline A — Starting a new session:**
1. `/ada-knowledge-updater` (get current state)
2. `/ada-question-assistant "what changed recently"`
3. `/ada-orchestrator refresh` (update this guide)

**Pipeline B — Adding a new map to a sequence:**
1. `/ada-sequence-expert [sequence]` (understand current sequence)
2. `/ada-map-expert [new map name]` (create the map)
3. `/ada-test-player [sequence]` (verify it plays correctly)

**Pipeline C — Deep dive into a new algorithm domain:**
1. `/ada-tutor [algorithm]` (understand it conceptually)
2. `/ada-code-guide [algorithm path]` (understand implementation)
3. `/ada-queer-theory-expert [algorithm]` (connect to QFEP)
4. `/ada-code-documenter [algorithm path]` (document it)

---

## Output File Structure

Write `doc/ONBOARDING_GUIDE.md` with this exact heading structure:

```markdown
# Ada Research: Onboarding Guide
> Generated: YYYY-MM-DD — run `/ada-orchestrator refresh` to regenerate

## Who This Is For
## How to Use This Guide

## 1. Project at a Glance
### Quick Stats (Live)
### What Makes This Project Different

## 2. How the System Works
### The Content Chain
### Grid System
### Artifact System
### Sequence System
### Autoloads
### VR and Desktop Modes

## 3. The Learning Journey
### The QFEP Curriculum Spine
### Branch Sequences
### Playability Status
### How Sequences Unlock

## 4. The Theoretical Framework
### The Queer Free Energy Principle
### Connecting Algorithms to Theory: Four Lenses
### Research Papers
### The Critical Theory Algorithms

## 5. How to Explore the Project
### The Generative Play Method
### Reading a Sequence
### Reading a Map (Worked Example)
### Utility Token Quick Reference
### Finding Tutorial Content
### Map Documentation Booklets

## 6. Documentation Map
### Primary Truth Sources
### Navigation Documents
### Technical References
### Theory and Research
### Reports and Audits
### Contribution Guides

## 7. Current State
### Active Development (as of YYYY-MM-DD)
### Recent Commits
### Audit Health
### Known Open Issues

## 8. The Skill Ecosystem
### All Skills at a Glance
### Choosing the Right Skill
### The Skill Pipeline

## Quick-Start Checklist
```

---

## Important Rules

1. **Reference, do not reproduce.** When an existing document covers something well, summarize in 1-2 sentences and add: "Full reference: `path/to/doc.md`". Each major section should be ~300 words max.

2. **Live data from JSON, not docs.** Stats in Step 1 must come from counting actual JSON files with Glob and Read, not from documentation that may be stale. Note any discrepancy.

3. **Date-stamp live sections.** Steps 1 and 7 carry "Generated: YYYY-MM-DD" stamps so the reader knows when to refresh.

4. **Be honest about gaps.** If SYSTEM_KNOWLEDGE.md hasn't been generated, say so. If sequences are scaffolded but not fully built, say so.

5. **Ground examples in real names.** Use actual sequence names, map names, artifact lookup_names from the project — never use hypothetical placeholders.

6. **The Quick-Start Checklist** should give 7 concrete first actions:
   - [ ] Read `doc/ENTRY.md` — the project entry point
   - [ ] Check `commons/maps/curriculum_spine.json` — the canonical learning order
   - [ ] Skim `doc/TAXONOMY.md` spine table — playability at a glance
   - [ ] Pick a sequence and run `/ada-test-player [sequence]` — experience the content
   - [ ] Run `/ada-knowledge-updater all` if `SYSTEM_KNOWLEDGE.md` doesn't exist
   - [ ] Check `doc/reports/SEQUENCE_CONTRACT_AUDIT.md` for any blockers
   - [ ] Run `git log --oneline -10` to see recent changes
