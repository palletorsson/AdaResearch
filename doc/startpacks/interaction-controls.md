# Development Start: Interactive Buttons and Sliders

**Intent:** `Interactive Buttons and Sliders`
**Matched topic:** `interaction_controls`
**Pack slug:** `interaction-controls`
**Category:** `interaction`
**Tags:** `interaction, vr-controls, buttons, sliders, panels`
**Generated:** `2026-04-04T11:51:01+00:00`

Use this pack for VR control surfaces: buttons, sliders, preset panels, and other parameter controls embedded in artifacts.

## Trust Order
- repo files
- doc/ and docs/ contracts
- session handoffs and session summaries
- grounded wiki chat points and turns
- encyclopedia routes and source files
- DeepWiki overview

## Read First
- `commons/interactables/push_button.tscn` — Current push-button scene used by artifacts.
- `commons/interactables/slider_horizontal.tscn` — Current slider scene used by artifacts.
- `doc/ARTIFACT_VR_REVIEW.md` — Current implementation pattern and ergonomics for VR control panels.
- `doc/ARTIFACT_IMPLEMENTATION_NOTES.md` — Examples of reset buttons, sliders, and control surfaces embedded in artifacts.
- `commons/artifacts/curvature_slider/curvature_slider.gd` — Concrete artifact-level slider example.

## Key Constraints
- Current standard is slider_horizontal.tscn for continuous parameters and push_button.tscn for discrete actions.
- Control panels are documented as slightly in front of and below the artifact, tilted ~30 degrees toward the viewer.
- Desktop keyboard controls are often preserved alongside VR controls.

## Suggested First Moves
- Copy the existing VR review panel pattern before inventing a new control panel layout.
- Decide whether you are adding a reusable interactable or a one-off artifact control.
- Check hand reach, spacing, and label readability as part of the starting contract.

## Relevant History
- `doc/sessions/2026-03-19-garden-session-summary.md` — Single session spanning ~14 hours. Started with renaming map folders, ended with 363 algorithms having identity, desire, and truth.
- `doc/sessions/2026-03-23-continued-session.md` — Single session spanning ~14 hours. Started with renaming map folders, ended with 363 algorithms having identity, desire, and truth.
- `doc/SESSION_HANDOFF_2026-03-28.md` — # Session Handoff: March 23-28, 2026

## Related Docs
- `doc/ARTIFACT_VR_REVIEW.md` — ## Status: ✅ VR Controls Implemented
- `doc/LOD_TREE.json` — "summary": "Ada Research: a Godot 4 VR/desktop game teaching algorithms through interactive 3D spaces. QFEP (Queer Feminist Enactivist Pedagogy) framework. Content chain: Sequence -> Map -> Artifact.",
- `doc/CompliteAlgorithms.md` — Tron grid navigation and spatial references
- `docs/nature_of_code_vr_translation_plan.md` — This plan outlines the translation of 200+ Nature of Code examples from 2D p5.js to 3D VR in Godot. The project will create an immersive educational platform for learning computational physics, artificial intelligence, a
- `doc/ARTIFACT_IMPLEMENTATION_NOTES.md` — - Slider: "Debias strength" shows how relationships change
- `doc/NEW_CAPACITY_ARTIFACTS.md` — **Description:** A grabbable tool that, when pressed against a homogeneous surface, injects local perturbation. Watch the Turing pattern cascade from your touch.

## Related Repo Paths
- `algorithms/joint/04_slider_press/README.md`
- `algorithms/joint/04_slider_press/SliderPress.gd`
- `algorithms/joint/04_slider_press/SliderPress.gd.uid`
- `algorithms/joint/04_slider_press/SliderPress.tscn`
- `algorithms/randomness/proceduralrandomness/geometrybased/randomsortpanel/README.md`
- `algorithms/randomness/proceduralrandomness/geometrybased/randomsortpanel/random_sort_panel.gd`
- `algorithms/randomness/proceduralrandomness/geometrybased/randomsortpanel/random_sort_panel.gd.uid`
- `algorithms/randomness/proceduralrandomness/geometrybased/randomsortpanel/random_sort_panel.tscn`

## Grounded Wiki Chat Knowledge
- source project slug: `adaresearch-case-study`
- turn `12c4a6be-d651-49ff-9ec9-a4ca4d021cb1#448` (user): ...oard visible. Clean introductory layout.", "severity": "info" }, { "angle": "above", "issue": "UI overlay panel partially visible in top-right corner - should be hidden during capture", "severity": "warning" } ], "humanComments": [ { "text": "give the artfact more of a lab space", "timestamp": "2026-03-05T13:51:20.046Z...
- turn `369f8742-09bd-440c-989f-dbc992996f1f#394` (user): ...pipes", "lab_items_horizontal", "facade_elements"] [ElementEditor] Plugin loaded! Connected Save Sequence Button Connected Save Map Data Button [MapSequenceEditor] Refreshed Tutorial Text Editor plugin loaded [ElementSubsetData] Already loaded, subsets: ["audio_rack", "glass_rack", "big_pipes", "lab_items_horizontal", ...
- turn `531f69cf-2ddc-41b2-9bdb-3d1a36046289#121` (assistant): ...inate labels, white point marker - **coupled_pendulums**: ✅ PASS - Red & blue pendulums from support bar, control panel with 4 dials - **cross_product_demo**: ✅ PASS - RGB axes, magenta result plane, control panel, display board - **curl_noise_particles**: ✅ PASS - Beautiful 300-particle flow in wireframe box, title + ...
- turn `12c4a6be-d651-49ff-9ec9-a4ca4d021cb1#58` (assistant): .... Now let me find where the sidebar renders for the I layer and add the inspector. I'll add the inspector panel between the artifact list and the bottom controls. When `movingFrom` is set, it shows the inspector with rotation and scale inputs. Now let me verify. No errors. Let me load a map and test the inspector by cl...

## DeepWiki
- Base: https://deepwiki.com/palletorsson/AdaResearch
- Suggested topic: Interactive Components
- Suggested topic: Artifacts & Interactables