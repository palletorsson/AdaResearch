# Development Start: Folding

**Intent:** `Folding`
**Matched topic:** `folding`
**Pack slug:** `folding`
**Category:** `experimental`
**Tags:** `folding, runtime, spec, morphology, prototype`
**Generated:** `2026-04-04T11:50:54+00:00`

Folding is currently strongest as a design/runtime specification. It already has a detailed contract, but the runtime is still more design-heavy than grid or nature-system work. Start by separating authored specification from actually implemented fold code.

## Trust Order
- repo files
- doc/ and docs/ contracts
- session handoffs and session summaries
- grounded wiki chat points and turns
- encyclopedia routes and source files
- DeepWiki overview

## Read First
- `doc/FOLDING_CREATURE_SYSTEM.md` — High-level folding design and authoring model.
- `doc/FOLD_RUNTIME_SPEC_V1.md` — Runtime class contracts and update order.
- `doc/NATURE_SYSTEM_PLAN.md` — Nature-system overlap if folding is being attached to critters rather than isolated artifacts.
- `commons/primitives/foldedpaper/foldedpaper.gd` — Closest concrete folded primitive currently present in the repo.

## Key Constraints
- Folding is specified across morphology, function, structure, and symbolic meaning.
- The runtime spec centers on fold_amount and explicit FoldRig/FoldSolver abstractions.
- Treat this as partially implemented: design truth is stronger than code truth here.

## Suggested First Moves
- Decide whether the next step is spec consolidation, a folded primitive prototype, or critter integration.
- Avoid assuming FoldRig/FoldSolver runtime classes already exist unless you verify them locally.

## Relevant History
- `doc/sessions/2026-03-19-garden-session-summary.md` — Single session spanning ~14 hours. Started with renaming map folders, ended with 363 algorithms having identity, desire, and truth.
- `doc/sessions/2026-03-23-continued-session.md` — Single session spanning ~14 hours. Started with renaming map folders, ended with 363 algorithms having identity, desire, and truth.

## Related Docs
- `doc/FOLDING_CREATURE_SYSTEM.md` — # Folding Creature System — Design Document v2.1
- `doc/FOLD_RUNTIME_SPEC_V1.md` — # Fold Runtime Spec v1
- `doc/LOD_TREE.json` — "lod3": "Brouwer's free choice sequences - unfinished infinite objects that unfold over time, visualized as fading dots with an o...",
- `doc/ARTIFACT_DEVELOPMENT_PLAN.md` — | `dragon_curve_unfolder` | 🔨 Build | MED | Paper folding visualization |
- `doc/TAXONOMY.md` — | 14 | `machinelearning` | `integration` | 18 | 18 | 0 | `MachineLearning_Evolving_Creatures` | `living_paper_kmeans`, `profile_gradient_descent`, `transformation_workbench` |
- `docs/reports/2026-02-08_godot46_upgrade.md` — - 3 tripod legs unfold from inside

## Related Repo Paths
- `commons/fold_system/deltahedron_creature.gd`
- `commons/fold_system/deltahedron_creature.gd.uid`
- `commons/fold_system/deltahedron_creature.tscn`
- `commons/fold_system/helix_cylinder_creature.gd`
- `commons/fold_system/helix_cylinder_creature.gd.uid`
- `commons/fold_system/helix_cylinder_creature.tscn`
- `commons/fold_system/zoo/folding_zoo.gd`
- `commons/fold_system/zoo/folding_zoo.gd.uid`

## Grounded Wiki Chat Knowledge
- source project slug: `adaresearch-case-study`
- turn `12c4a6be-d651-49ff-9ec9-a4ca4d021cb1#614` (user): great, now the paper what do you think? Fractal Folded Search: A Database Where Fold = Index = Compression, Benchmarked by Inference Cost Palle Torsson, Claude March 6, 2026 Abstract We present Fractal Folded Search, a database architecture for hierarchical knowledge systems in which a single recursive operation-the fo...
- turn `12c4a6be-d651-49ff-9ec9-a4ca4d021cb1#616` (user): Fractal Folded Search: A Database Where Fold = Index = Compression, Benchmarked by Inference Cost Palle Torsson, Claude March 6, 2026 Abstract We present Fractal Folded Search, a database architecture for hierarchical knowledge systems in which a single recursive operation-the fold-simultaneously performs storage summa...
- turn `12c4a6be-d651-49ff-9ec9-a4ca4d021cb1#562` (user): * Three questions: Do you believe in fractal folded search? Different fractal folding strategies for storing and searching over a project like ada research. Any novelty? Not a graph database, a fractal database. What do you do when you compress your thoughts? * Expose every endpoint with a compaction or your chosen for...
- turn `12c4a6be-d651-49ff-9ec9-a4ca4d021cb1#618` (user): ...he paper is already strong on the things that matter most in an early research draft: The framing works. "Fold = index = compression" is memorable, and "tokens per correct answer" is a real evaluative claim, not just branding. The experiment is credible. The dual-agent comparison is limited, but it is concrete and inte...

## DeepWiki
- Base: https://deepwiki.com/palletorsson/AdaResearch
- Suggested topic: Overview
- Suggested topic: Interactive Components
- Suggested topic: Artifacts & Interactables