# Development Start: Nature System

**Intent:** `Nature System`
**Matched topic:** `nature_system`
**Pack slug:** `nature-system`
**Category:** `nature`
**Tags:** `nature, critters, dna, morphology, simulation`
**Generated:** `2026-04-04T11:51:06+00:00`

The nature system is a critter-based Q-FEP simulation layer spanning DNA, morphology, evolution, transmutation, and map-level nature painting.

## Trust Order
- repo files
- doc/ and docs/ contracts
- session handoffs and session summaries
- grounded wiki chat points and turns
- encyclopedia routes and source files
- DeepWiki overview

## Read First
- `doc/NATURE_SYSTEM_PLAN.md` — Main design contract for the system.
- `algorithms/nature_system/README.md` — Code-level entry point for the implemented nature system folder.
- `algorithms/nature_system/demo/nature_system_demo.gd` — Runnable demo surface tying the subsystems together.
- `algorithms/nature_system/dna/critter_dna.gd` — Core data structure for critter morphology and behavior.
- `algorithms/nature_system/morphology/flower_morphology.gd` — Starting point for flower shape generation.
- `algorithms/nature_system/systems/transmutation_manager.gd` — Relationship and state transformation logic.
- `commons/artifacts/registry/nature_system.json` — Registry truth for the demo artifact and current map-readiness state.

## Key Constraints
- The design principle is transmutation across a spectrum, not fixed friend/enemy categories.
- The demo artifact is registered but currently marked map_ready=false.
- The system spans all four kingdoms: tree, creature, flower, fungus.

## Suggested First Moves
- Choose whether the work is DNA-level, morphology-level, or map authoring before editing.
- If the goal is a new system behavior, start in algorithms/nature_system/systems/.
- If the goal is a new visible organism, start in morphology plus registry/demo wiring.

## Relevant History
- `doc/sessions/2026-03-23-continued-session.md` — # Garden Session — 2026-03-19
- `doc/sessions/2026-03-19-garden-session-summary.md` — # Garden Session — 2026-03-19
- `doc/SESSION_HANDOFF_2026-03-28.md` — Over six days, this session built the Naples-to-VR pipeline end-to-end: 42 procedural floor patterns from MANN museum photos, 27 facade presets from Italian buildings, 23 museum maps with floor plans, a floor plan editor

## Related Docs
- `doc/NATURE_SYSTEM_PLAN.md` — # Ada Research 46 — Nature System Plan
- `doc/FOLDING_CREATURE_SYSTEM.md` — # Folding Creature System — Design Document v2.1
- `doc/LOD_TREE.json` — "generated": "lod_tree_generator.py",
- `docs/noc_vr_translation_plan.md` — # Nature of Code VR Translation Plan
- `docs/design/ECOSYSTEM_TRAJECTORY_RAPPORT.md` — # Ecosystem Trajectory Rapport
- `docs/progress/progress_log.md` — # Nature of Code VR Progress Log

## Related Repo Paths
- `algorithms/nature_system/dna/critter_dna.gd`
- `algorithms/nature_system/dna/critter_dna.gd.uid`
- `algorithms/nature_system/dna/critter_trait_mapper.gd`
- `algorithms/nature_system/dna/critter_trait_mapper.gd.uid`
- `algorithms/nature_system/shaders/critter_dna.gdshader`
- `algorithms/nature_system/shaders/critter_dna.gdshader.uid`
- `algorithms/nature_system/dna/README.md`
- `algorithms/nature_system/entities/critter_entity.gd`

## Grounded Wiki Chat Knowledge
- source project slug: `adaresearch-case-study`
- turn `12c4a6be-d651-49ff-9ec9-a4ca4d021cb1#411` (assistant): Great research. Here's what stands out - the nature system has a full **DNA -> morphology pipeline** (`CritterDNA` -> `TreeMorphology`, `FlowerMorphology`, `FungusMorphology`, `CreatureMorphology`) but **zero interactive artifacts** exposing it to players. That's the gap. ## Top 3 Artifacts for the L-Systems Sequence #...
- turn `531f69cf-2ddc-41b2-9bdb-3d1a36046289#495` (assistant): The background capture agent for body progression maps couldn't get Bash permissions, but the flower system agent already successfully captured botanical flower images and copied them to the encyclopedia. All three major systems are now complete with blog posts and images. Here's the final tally of everything built thi...
- turn `531f69cf-2ddc-41b2-9bdb-3d1a36046289#498` (assistant): ...s session are all in place: Everything is in place. Let me also check the encyclopedia for blog posts and flower sequence: One missing map: `Flower_Water`. Let me create it quickly, then we can look at the full change summary: Now let me get a full picture of everything to commit across both repos: This is a massive se...
- turn `12c4a6be-d651-49ff-9ec9-a4ca4d021cb1#412` (user): yes and a new catalyst brunching gun for a special tree?

## Encyclopedia Surfaces
- Nature layer persistence API — source `src/app/api/game/save-nature-layer/route.ts` — Writes and reads nature_layer.json per map.
- Project context store — source `src/app/api/context/route.ts` — Good place to persist derived patterns and nature formulas.

## DeepWiki
- Base: https://deepwiki.com/palletorsson/AdaResearch
- Suggested topic: Overview
- Suggested topic: Artifact Registry System
- Suggested topic: Map & Content Definition