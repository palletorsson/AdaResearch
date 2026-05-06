# Development Start: Sequence and Map Pipeline

**Intent:** `Tutorial and Learning Sequences`
**Matched topic:** `sequence_map_pipeline`
**Pack slug:** `tutorial-sequences`
**Category:** `curriculum`
**Tags:** `sequences, maps, progression, pipeline, lab`
**Generated:** `2026-04-04T12:24:43+00:00`

This is the curriculum path from sequence definition to map flow to lab progression. Use this pack when the task is about building a new sequence, editing map progression, changing unlock order, or understanding how authored maps become playable curriculum.

## Trust Order
- repo files
- doc/ and docs/ contracts
- session handoffs and session summaries
- grounded wiki chat points and turns
- encyclopedia routes and source files
- DeepWiki overview

## Read First
- `doc/HOW_TO_ADD_MAP_SEQUENCE.md` — Practical sequence authoring guide and lab-chain rules.
- `doc/MAP_EDITING_PIPELINE.md` — End-to-end workflow from discovery through validation and VR review.
- `doc/PROGRESSION_SYSTEM.md` — Architecture-level explanation of lab progression and sequence rewards.
- `commons/managers/AdaSceneManager.gd` — Sequence loading and transition manager.
- `commons/managers/MapProgressionManager.gd` — Sequence-first progression state and unlock tracking.
- `commons/maps/curriculum_spine.json` — Explicit recommended sequence order and lab progression chain.

## Core Principles
- Sequence ownership comes from sequence JSON and registry metadata, not from folder names alone.
- The Lab progression chain should grow monotonically across post maps.
- Map authoring and curriculum progression are linked: a sequence is not just a list of maps, but a learning path with unlock logic.

## Key Constraints
- AdaSceneManager loads and merges sequences from commons/maps/sequences/*.json.
- MapProgressionManager now treats sequence files as canonical progression input.
- Lab post maps should preserve prior state while adding new rewards and routes.

## Suggested First Moves
- Decide whether the task belongs to sequence JSON, map_data.json authoring, scene-loading code, or lab progression.
- If the task changes unlock flow, inspect curriculum_spine.json before editing manager code.
- If the task creates a new sequence, validate both authoring docs and the runtime managers before testing.

## Relevant History
- `doc/SESSION_HANDOFF_2026-03-28.md` — # Session Handoff: March 23-28, 2026
- `doc/sessions/2026-03-23-continued-session.md` — Single session spanning ~14 hours. Started with renaming map folders, ended with 363 algorithms having identity, desire, and truth.
- `doc/sessions/2026-03-19-garden-session-summary.md` — Single session spanning ~14 hours. Started with renaming map folders, ended with 363 algorithms having identity, desire, and truth.

## Related Docs
- `doc/LOD_TREE.json` — "summary": "Ada Research: a Godot 4 VR/desktop game teaching algorithms through interactive 3D spaces. QFEP (Queer Feminist Enactivist Pedagogy) framework. Content chain: Sequence -> Map -> Artifact.",
- `doc/ONBOARDING_GUIDE.md` — This guide orients anyone arriving at the Ada Research project for the first time — a new Claude session picking up mid-project, a human collaborator joining the team, or an AI assistant asked a one-off question. It is t
- `doc/CONTRIBUTING.md` — Ada Research is a Godot 4.6 VR/desktop app that teaches algorithms through embodied interaction. You walk through rooms (maps), touch artifacts (algorithm visualizations), and progress through a curriculum organized by t
- `doc/ENTRY.md` — > **For new contributors and AI assistants: Start here.**
- `doc/HOW_TO_ADD_MAP_SEQUENCE.md` — # How to Add a New Map Sequence
- `doc/CURRICULUM_FLOW_ANALYSIS.md` — # Curriculum Flow Analysis

## Related Repo Paths
- `commons/maps/Lab/map_data_post_array_tutorial.json`
- `commons/maps/Lab/map_data_post_machinelearning.json`
- `commons/maps/Lab/map_data_post_randomness.json`
- `commons/maps/MachineLearning_Random_Walker_Machine/map_data.json`
- `commons/maps/RecursiveEmergence_Fibonacci_Sequences/map_data.json`
- `commons/maps/sequences/advancedlaboratory.json`
- `commons/maps/sequences/array_tutorial.json`
- `commons/maps/sequences/bodyprogression.json`

## Grounded Wiki Chat Knowledge
- source project slug: `adaresearch-case-study`
- point [principle] support=2: The map/sequence pipeline is AdaResearch's curriculum production loop. It does not just define map format; it defines how sequences, maps, tools, validation, and VR review stay in sync.
- point [principle] support=1: New sequence work should update sequence JSON, lab progression, validation/audit steps, and the authoring surfaces together rather than treating any one file as the whole pipeline.
- point [principle] support=1: Sequence JSON orders progression, `map_data.json` files hold map structure, `AdaSceneManager.gd` and `JsonMapLoader.gd` load them, and the documented loop carries them through edit, validation, capture, review, and iteration.
- point [principle] support=1: The map/sequence pipeline is the project's authoring spine, turning curriculum intent into playable maps and feeding VR feedback back into the same data.
- claim [principle] support=1: The map/sequence pipeline is AdaResearch's curriculum production loop. It does not just define map format; it defines how sequences, maps, tools, validation, and VR review stay in sync.
- claim [principle] support=1: The map/sequence pipeline is AdaResearch's curriculum production loop. It does not just define map format; it defines how sequences, maps, tools, validation, and VR review stay in sync.
- claim [principle] support=1: The map/sequence pipeline is the project's authoring spine, turning curriculum intent into playable maps and feeding VR feedback back into the same data.
- claim [principle] support=1: Sequence JSON orders progression, `map_data.json` files hold map structure, `AdaSceneManager.gd` and `JsonMapLoader.gd` load them, and the documented loop carries them through edit, validation, capture, review, and iteration.
- turn `12c4a6be-d651-49ff-9ec9-a4ca4d021cb1#366` (assistant): ... out how this would actually work - it's closer than you might think. ## The Autonomous Scene Improvement Pipeline ``` ┌─────────────────────────────────────────────────────────┐ │ YOU: walking around in VR, exploring, giving feedback │ └──────────────────────┬──────────────────────────────────┘ │ ┌────────────┴───────...
- turn `531f69cf-2ddc-41b2-9bdb-3d1a36046289#589` (assistant): ...ct that I wouldn't have touched otherwise: **GridSystem internals** - I now understand the initialization pipeline in detail: `_ready()` -> `call_deferred("_deferred_initialization")` -> data loading -> structure/utilities/interactables generation -> `map_generation_complete` signal. Before this I knew the GridSystem e...
- turn `12c4a6be-d651-49ff-9ec9-a4ca4d021cb1#368` (assistant): ...icating this. Let me be honest about what I actually have: **I can already do this. Right now.** ``` Read map_data.json -> I know what's in every room Take screenshot -> I see what it actually looks like Read encyclopedia -> I know what SHOULD be there Send you messages -> I can guide you through Get your voice back ->...
- turn `12c4a6be-d651-49ff-9ec9-a4ca4d021cb1#369` (user): * this is you talking in first person: * I read the sequence file -> know the map order * I go to scene -> I take a screenshot -> I see the Lab * I read Lab's map_data.json -> I know every artifact placement * I compare screenshot vs map data vs encyclopedia expectations and more over the full ontological potential * I...

## Encyclopedia Surfaces
- Map Builder — route `/map-builder` — source `src/components/map-builder/MapBuilderPage.tsx` — Primary web surface for composing and exporting map_data.json.
- Map Pipeline — route `/map-pipeline` — source `src/app/features/page.tsx` — Feature-level reference for the guided map workflow surfaces.
- Workflow — route `/workflow` — source `src/app/workflow/page.tsx` — Operational flow for orient-assess-build-verify-track work.

## DeepWiki
- Base: https://deepwiki.com/palletorsson/AdaResearch
- Suggested topic: Map & Content Definition
- Suggested topic: Overview
- Suggested topic: Artifact Registry System