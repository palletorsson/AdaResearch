# Flows Index

Thinking paths that survive context death. Search: `python tools/flow_query.py <trigger>`

## Capture & Screenshot
- [+] [Debug Empty Screenshot](capture-debug.json) — Screenshot empty? 1) Disable artifact cameras. 2) Skip ground if scene has WorldEnvironment. 3) Check AABB — no mesh or wrong cull mode.
- [+] [Capture Framing Guide](capture-framing.json) — 3 zoom levels per angle. Default = far (1.4x). If artifact tiny, check camera override first.

## Artifact Improvement
- [+] [Make a Dead Artifact Alive](artifact-visual-upgrade.json) — Read code → find story → emissive materials → trail → markers → label → capture → evaluate. If screenshot empty, load capture-debug.
- [+] [Enrich Registry Metadata from Code](metadata-enrich.json) — Find registry entry → read GDScript → extract @identity → draft 8 fields → edit JSON → validate → re-score.
- [+] [Create New Artifact](artifact-creation.json) — Design → write .gd (extends Node3D, class_name, @identity, apply_grid_config) → write .tscn → register in JSON → test → capture.
- [+] [Write @identity Blocks](identity-writing.json) — Read code → essence (math) → desire (experience) → critical_parameter (the one knob) → truth (poetic insight, the hard part).

## Sequence & Map Work
- [+] [Improve a Whole Sequence](sequence-improve.json) — Score all → pick smallest×lowest → read all code → batch metadata → batch identity → capture footprints → visual if needed → re-score → commit.
- [~] [Sequence Audit Playbook](sequence-audit.json) — Horizontal: score all sequences. Vertical: deep-dive on worst. Classify artifacts DORMANT→SCATTERED→REACHING→GROWING→LIVING.
- [+] [Map Editing Pipeline](map-editing-pipeline.json) — DISCOVER (ada.py) → EDIT (web or JSON) → VALIDATE (pathfinder) → CAPTURE → REVIEW → BRIDGE (VR feedback) → ITERATE.
- [+] [Map Pathfinder Validation](pathfinder-validation.json) — Run pathfinder check. Fails? Common: no spawn, unreachable artifact, teleporter not on void. Fix, re-run.

## Navigation & Context
- [+] [LOD Context Loading](lod-context-loading.json) — Don't read everything. lod_query.py <topic> at the right depth: project → sequence → map → artifact → function.
- [+] [Heat Map Triage](heat-map-triage.json) — Score all. Sort by artifact_count × (8 - avg). Small×low = quick win. Large×low = batch job.
- [+] [QFEP Classification](qfep-classification.json) — primitives→F, randomness→E(S), fractals→λ, morphogenesis→φdE, forces→Classical F, CA→Edge of chaos.

## System Architecture
- [~] [Scene Transition Flow](scene-transition.json) — load_scene → fade → instantiate → pass user_data → WAIT 3 FRAMES → GridSystem.load_map → scene_visible. The 3-frame wait is critical.
- [~] [Grid System Content Pipeline](grid-content-pipeline.json) — map_data.json → 3 layers (structure, utilities, interactables) → GridSystem components → instantiate artifacts from registry.
- [~] [Error Recovery Chain](error-recovery.json) — Scene fail → try fallback. Map missing → empty grid. Artifact missing → skip. Sequence broken → hide. Only staging failure crashes.
- [~] [Progression State Management](progression-state.json) — sequence_completed signal → MapProgressionManager saves → LabManager reads unlock list → instantiate new artifacts → save lab state.
- [+] [Hidden Dependencies Debugging](hidden-dependencies.json) — VR weird? Check: camera override (multiple Camera3D), WorldEnvironment conflict, gaze pointer side effects, MovementCapabilityGate silently disabling input.

## Catalyst & Building
- [+] [Minecraft Cube Placer](minecraft-cube-placer.json) — Look with head, trigger to place, double-trigger to remove. Cardinal neighbors, 2 cells out. Ghost cube preview.
- [+] [Catalyst Pedestal Pickup](catalyst-pedestal-pickup.json) — Pedestal in lab, grab bracelet, cage fades. Survives map changes (in-memory). Fresh each game.

## Death & Hazards
- [+] [Death → Restart Flow](death-restart-flow.json) — DangerZone/laser → GameManager → DeathEffect: red flash, shake, particles, fade, map reload. Fire: 35dmg/0.3s. Laser: 100dps.
- [+] [Ecology Progression](ecology-progression.json) — Biome ring + living organisms grow across 19 sequences. density 0→1.0, kingdoms unlock, EvolutionSystem + TransmutationManager in late maps.

## VR & Input
- [+] [VR Input Mapping](vr-input-mapping.json) — Left: joystick=strafe, trigger=grab. Right: joystick=turn, trigger=grab, AX=flight, pointer=UI. MovementCapabilityGate may disable flight.
- [+] [VR Feedback Bridge](vr-feedback-bridge.json) — Read ada_run/desktop_feedback.md. Timestamped entries with map+artifact context. Bug→fix now, feature→backlog, visual→load visual-upgrade flow.

## Process & Meta
- [+] [Session Handoff](session-handoff.json) — Commit → score baseline → save new flows from discoveries → update handover doc → update memory.
- [+] [Batch Processing with Parallel Agents](batch-parallel-agents.json) — Do one by hand → extract pattern → spawn 4-5 agents with pattern + specific file → verify all succeeded.
- [~] [Writing Discovers Gaps](coherence-writing-loop.json) — Write docs → discover gap (concept mentioned, no artifact) → build missing artifact → update docs → capture to verify coherence.

## Confidence
- [+] verified — tested across multiple artifacts/sessions
- [~] extracted — from docs/wiki, not yet tested
- [?] scaffolded — template only
