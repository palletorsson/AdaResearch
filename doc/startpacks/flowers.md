# Development Start: Flowers

**Intent:** `Flowers`
**Matched topic:** `flowers`
**Pack slug:** `flowers`
**Category:** `nature`
**Tags:** `flowers, botanical, signals, morphology, artifacts`
**Generated:** `2026-04-04T11:50:52+00:00`

Flowers sit between the broader nature-system DNA route and standalone artifact route. Use this pack when you want to build new flowers or extend flower behavior specifically. The stable core is: flowers are parameterized signal organisms whose morphology, symmetry, and perception effects should remain legible to the learner.

## Trust Order
- repo files
- doc/ and docs/ contracts
- session handoffs and session summaries
- grounded wiki chat points and turns
- encyclopedia routes and source files
- DeepWiki overview

## Read First
- `algorithms/nature_system/morphology/flower_morphology.gd` — System-level flower morphology generator.
- `commons/artifacts/botanical_flower/botanical_flower.gd` — Standalone flower artifact implementation.
- `commons/artifacts/flower_lab/flower_lab.gd` — Flower-specific experiment surface.
- `commons/artifacts/water_flowers/water_flowers.gd` — Existing water flower artifact implementation.
- `commons/flora/botanical_flower.gd` — Core procedural flower generator with botanical taxonomy and presets.
- `doc/NATURE_SYSTEM_PLAN.md` — Design contract for flower meaning, toxicity, and transmutation.

## Core Principles
- Flowers are signal critters: they are meant to convey information, medicine, toxicity, attraction, or perception shifts, not just act as decoration.
- Morphology should stay parameter-legible: petal count, symmetry, curvature, stem height, color, and inflorescence should produce visible conceptual differences a learner can read.
- The core generator is anatomically structured: stem, leaves, sepals, petals, stamens, pistil, and inflorescence order matter more than arbitrary mesh styling.
- Use real botanical patterns when possible: radial vs bilateral symmetry, phyllotaxis, inflorescence type, and species-like presets are part of the teaching value.
- Standalone flower artifacts should stay thin wrappers over the core generator or morphology system, forwarding meaningful parameters rather than duplicating flower-building logic.
- Perception changes are part of the flower contract: pollen, color, and morphology can change what the player sees or understands, not only what the player looks at.

## Key Constraints
- Flowers are signal critters in the nature-system design, not just decoration.
- Flower changes can be either standalone artifacts or nature-system morphology work; decide which route you are taking.
- BotanicalFlower already exposes taxonomy-level controls such as flower form, symmetry, leaf placement, and inflorescence presets; prefer extending that model over inventing parallel parameter vocabularies.
- Flower Lab is already teaching the most impactful parameters through VR sliders, so new principles should remain teachable through a small set of high-leverage controls.

## Suggested First Moves
- Decide whether this flower belongs in commons/artifacts as a standalone scene or in algorithms/nature_system as generated morphology.
- If the flower should affect player perception or medicine/toxicity, align it with the transmutation model first.
- Check whether the desired change belongs in the core BotanicalFlower generator, the DNA-driven FlowerMorphology path, or only in a wrapper artifact.

## Relevant History
- `doc/sessions/2026-03-19-garden-session-summary.md` — # Garden Session — 2026-03-19
- `doc/sessions/2026-03-23-continued-session.md` — # Garden Session — 2026-03-19

## Related Docs
- `doc/LOD_TREE.json` — "flower_of_life_floor",
- `doc/NATURE_SYSTEM_PLAN.md` — - **Breed** it with a flower → hybrid organism → new ability
- `doc/ENTRY.md` — python tools/dev_start.py flowers
- `doc/reports/PROJECT_SPINE_WORLD_MAP_REPORT.md` — - MachineLearning_Evolving_Flowers

## Related Repo Paths
- `commons/testing/capture_botanical_flowers.gd`
- `commons/testing/capture_botanical_flowers.gd.uid`
- `algorithms/machinelearning/evolvingflowers/README.md`
- `algorithms/machinelearning/evolvingflowers/code_prompt.txt`
- `algorithms/machinelearning/evolvingflowers/evolvingflowers.gd`
- `algorithms/machinelearning/evolvingflowers/evolvingflowers.gd.uid`
- `algorithms/machinelearning/evolvingflowers/evolvingflowers.tscn`
- `algorithms/machinelearning/evolvingflowers/evolvingflowers_tutorial.gd`

## Grounded Wiki Chat Knowledge
- source project slug: `adaresearch-case-study`
- turn `531f69cf-2ddc-41b2-9bdb-3d1a36046289#493` (assistant): ...ll three facade editor improvements are done. Let me take a quick screenshot to verify, then pivot to the flower system: The facade editor looks great with all improvements - search bar, category count badges, keyboard shortcuts, zone labels with color pills, "Load Classical Preset" button, element counts, quick action...
- turn `531f69cf-2ddc-41b2-9bdb-3d1a36046289#498` (assistant): ...s session are all in place: Everything is in place. Let me also check the encyclopedia for blog posts and flower sequence: One missing map: `Flower_Water`. Let me create it quickly, then we can look at the full change summary: Now let me get a full picture of everything to commit across both repos: This is a massive se...
- turn `531f69cf-2ddc-41b2-9bdb-3d1a36046289#495` (assistant): The background capture agent for body progression maps couldn't get Bash permissions, but the flower system agent already successfully captured botanical flower images and copied them to the encyclopedia. All three major systems are now complete with blog posts and images. Here's the final tally of everything built thi...
- turn `531f69cf-2ddc-41b2-9bdb-3d1a36046289#450` (user): ...based system we need to continue to think and realize a facade system. We need to continue to work on the flower system. All this using multiagent. What is best to do now?

## Encyclopedia Surfaces
- Nature layer persistence API — source `src/app/api/game/save-nature-layer/route.ts` — Relevant if flower placement becomes part of painted map nature.

## DeepWiki
- Base: https://deepwiki.com/palletorsson/AdaResearch
- Suggested topic: Artifacts & Interactables
- Suggested topic: Map & Content Definition