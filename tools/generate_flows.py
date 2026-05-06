"""Generate 20 flows for .claude/flows/ from session knowledge, DeepWiki, and blog patterns."""
import json
import os

FLOWS_DIR = os.path.join('.claude', 'flows')
os.makedirs(FLOWS_DIR, exist_ok=True)

flows = [
    # === FROM BLOG / PROJECT EXPERIENCE (10) ===
    {
        "id": "map-editing-pipeline",
        "title": "Map Editing Pipeline",
        "description": "The 7-step loop: DISCOVER, EDIT, VALIDATE, CAPTURE, REVIEW, BRIDGE, ITERATE. The core development cycle for Ada Research maps.",
        "triggers": ["edit map", "create map", "map pipeline", "build map", "fix map"],
        "granularity": "macro",
        "model_version": "opus-4.6",
        "created": "2026-04-08",
        "updated": "2026-04-08",
        "earned_from": "MAP_EDITING_PIPELINE.md, blog: map-pipeline-rules",
        "nodes": [
            {"id": "discover", "type": "start", "label": "DISCOVER project state", "detail": "Run ada.py overview OR project_dashboard_cli -Mode status. Know what exists before editing."},
            {"id": "edit_choice", "type": "decision", "label": "Edit method?", "detail": "Visual editor at localhost:3003/map-builder OR direct JSON edit of map_data.json"},
            {"id": "edit_web", "type": "action", "label": "Use Map Builder web editor", "detail": "localhost:3003/map-builder — 3 layers: structure (heights), utilities (spawn/teleporter), interactables (artifacts)"},
            {"id": "edit_json", "type": "action", "label": "Edit map_data.json directly", "detail": "commons/maps/{MapName}/map_data.json — structure, utilities, interactables layers"},
            {"id": "validate", "type": "action", "label": "VALIDATE with pathfinder", "detail": "python tools/map_pathfinder.py check <MapName> --verbose. Checks spawn reachable, teleporter reachable, all artifacts reachable.", "code": "python tools/map_pathfinder.py check <MapName> --verbose"},
            {"id": "valid", "type": "decision", "label": "Pathfinder passes?"},
            {"id": "fix", "type": "action", "label": "Fix violations", "detail": "Common fixes: add floor under teleporter, add ramp to unreachable artifact, ensure spawn exists"},
            {"id": "capture", "type": "action", "label": "CAPTURE screenshots", "detail": "godot --xr-mode off --no-window --script capture_multi_angle.gd -- --mode=map --target=<MapName>"},
            {"id": "review", "type": "action", "label": "REVIEW screenshots + simulate", "detail": "View multi_shots/<MapName>/. POST /api/game/simulate for AI pathfinding trace."},
            {"id": "bridge", "type": "action", "label": "BRIDGE — read VR feedback", "detail": "Check ada_run/desktop_feedback.md for player comments from VR overlay."},
            {"id": "done", "type": "end", "label": "Map complete — commit"}
        ],
        "edges": [
            {"from": "discover", "to": "edit_choice"},
            {"from": "edit_choice", "to": "edit_web", "label": "visual"},
            {"from": "edit_choice", "to": "edit_json", "label": "precise"},
            {"from": "edit_web", "to": "validate"},
            {"from": "edit_json", "to": "validate"},
            {"from": "validate", "to": "valid"},
            {"from": "valid", "to": "capture", "label": "yes"},
            {"from": "valid", "to": "fix", "label": "no"},
            {"from": "fix", "to": "validate"},
            {"from": "capture", "to": "review"},
            {"from": "review", "to": "bridge"},
            {"from": "bridge", "to": "done"}
        ]
    },
    {
        "id": "sequence-audit",
        "title": "Sequence Audit Playbook",
        "description": "Horizontal audit across sequences then vertical deep-dive on artifacts. Finds gaps, duplicates, and quality issues.",
        "triggers": ["audit sequence", "check sequence quality", "find gaps", "sequence health"],
        "granularity": "macro",
        "model_version": "opus-4.6",
        "created": "2026-04-08",
        "updated": "2026-04-08",
        "earned_from": "blog: sequence-audit-playbook, garden session",
        "nodes": [
            {"id": "start", "type": "start", "label": "Begin audit"},
            {"id": "horizontal", "type": "action", "label": "HORIZONTAL: Score all sequences", "detail": "Run scoring one-liner. Sort by avg. Identify worst sequences and biggest gaps."},
            {"id": "pick", "type": "decision", "label": "Pick sequence to audit"},
            {"id": "vertical", "type": "action", "label": "VERTICAL: Deep dive on artifacts", "detail": "Read every .gd file. Check @identity, class_name, apply_grid_config. Assess 7 layers: essence, code, expression, interaction, feedback, edge cases, performance."},
            {"id": "classify", "type": "action", "label": "Classify each artifact", "detail": "DORMANT (no identity), SCATTERED (identity but no code), REACHING (code but missing controls), GROWING (testing), LIVING (VR-verified)"},
            {"id": "report", "type": "action", "label": "Generate health report", "detail": "python tools/garden_listener.py --diagnosis. Shows percentages by state."},
            {"id": "done", "type": "end", "label": "Audit complete — triage queue ready"}
        ],
        "edges": [
            {"from": "start", "to": "horizontal"},
            {"from": "horizontal", "to": "pick"},
            {"from": "pick", "to": "vertical"},
            {"from": "vertical", "to": "classify"},
            {"from": "classify", "to": "report"},
            {"from": "report", "to": "done"}
        ]
    },
    {
        "id": "identity-writing",
        "title": "Write @identity Blocks",
        "description": "How to write the 8-field identity block for an artifact. The poetic truth is the hardest part — it's what the algorithm MEANS, not what it does.",
        "triggers": ["write identity", "add @identity", "artifact identity", "write truth"],
        "granularity": "meso",
        "model_version": "opus-4.6",
        "created": "2026-04-08",
        "updated": "2026-04-08",
        "earned_from": "13 identity blocks written for joints + biological_growth",
        "nodes": [
            {"id": "read", "type": "action", "label": "Read the full GDScript", "detail": "Understand what _ready() builds and _process() animates. Note exports, signals, base class."},
            {"id": "essence", "type": "action", "label": "Write essence (1 line)", "detail": "The mathematical core in one line. 'p += v; v += g; if(wall) v *= -e' or 'anchor + pin + bob. One constraint, one body.'"},
            {"id": "desire", "type": "action", "label": "Write desire (1 line)", "detail": "What does this artifact WANT the learner to experience? Not what it does — what it wants."},
            {"id": "critical", "type": "action", "label": "Write critical_parameter", "detail": "The ONE number that changes everything. 'elasticity (0.9)' or 'CRACK_THRESHOLD (0.30)'."},
            {"id": "rest", "type": "action", "label": "Write triggers, emerges, needs, relationships", "detail": "triggers: what starts it. emerges: what you see that isn't coded. needs: [has] and [missing]. relationships: connects to what."},
            {"id": "truth", "type": "action", "label": "Write truth (the hard part)", "detail": "The poetic insight. NOT a description. 'A pendulum is a clock that runs down.' 'The forest does not exist — it is generated around you.' This is what makes the identity block worth reading."},
            {"id": "place", "type": "action", "label": "Place before extends line", "detail": "The @identity block goes at the top of the file, before the extends line. 8 comment lines starting with # @identity."},
            {"id": "done", "type": "end", "label": "Identity written"}
        ],
        "edges": [
            {"from": "read", "to": "essence"},
            {"from": "essence", "to": "desire"},
            {"from": "desire", "to": "critical"},
            {"from": "critical", "to": "rest"},
            {"from": "rest", "to": "truth"},
            {"from": "truth", "to": "place"},
            {"from": "place", "to": "done"}
        ]
    },
    {
        "id": "heat-map-triage",
        "title": "Heat Map Triage",
        "description": "Decide what to work on next using the heat map and scoring system. Smallest × lowest = quickest win.",
        "triggers": ["what should I work on", "next task", "priorities", "heat map", "triage"],
        "granularity": "micro",
        "model_version": "opus-4.6",
        "created": "2026-04-08",
        "updated": "2026-04-08",
        "earned_from": "baseline scoring revealed joints(0.5) as best target over randomness(2.0, 114 artifacts)",
        "nodes": [
            {"id": "score", "type": "action", "label": "Run scoring across all sequences", "detail": "python tools/heat_map_generator.py OR the inline scoring one-liner from baseline."},
            {"id": "sort", "type": "action", "label": "Sort by: artifact_count * (8 - avg_score)", "detail": "This gives impact score. Small sequences with low scores are quickest wins."},
            {"id": "pick", "type": "decision", "label": "Quick win or big impact?", "detail": "Quick win: 3-10 artifacts at 0-1/8. Big impact: 50+ artifacts at 1-2/8 (needs batch processing)."},
            {"id": "quick", "type": "action", "label": "Load sequence-improve flow", "detail": "Small sequence: do it all in one session. Read code, batch metadata, visual upgrade, commit."},
            {"id": "big", "type": "action", "label": "Use /ada-artifact-improver auto", "detail": "Large sequence: run the improver skill in batch mode. Process 10-20 per session."},
            {"id": "done", "type": "end", "label": "Working on highest-impact target"}
        ],
        "edges": [
            {"from": "score", "to": "sort"},
            {"from": "sort", "to": "pick"},
            {"from": "pick", "to": "quick", "label": "quick win (< 15 artifacts)"},
            {"from": "pick", "to": "big", "label": "big impact (> 15 artifacts)"},
            {"from": "quick", "to": "done"},
            {"from": "big", "to": "done"}
        ]
    },
    {
        "id": "session-handoff",
        "title": "Session Handoff",
        "description": "Prepare for the next session or model. Commit, score, document what was learned, update flows.",
        "triggers": ["end session", "handoff", "prepare for next session", "wrap up"],
        "granularity": "meso",
        "model_version": "opus-4.6",
        "created": "2026-04-08",
        "updated": "2026-04-08",
        "earned_from": "multiple session handoffs, ARTIFACT_IMPROVEMENT_HANDOVER.md pattern",
        "nodes": [
            {"id": "commit", "type": "action", "label": "Commit all work with descriptive message", "detail": "Include before/after scores in commit message. Separate commits for different concerns."},
            {"id": "score", "type": "action", "label": "Run baseline scoring", "detail": "Save to doc/reports/baseline_scores_YYYY-MM-DD.json. This is the proof of progress."},
            {"id": "flows", "type": "decision", "label": "Did you discover new thinking paths?", "detail": "Any debugging pattern, workflow optimization, or decision tree you built during the session."},
            {"id": "save_flow", "type": "action", "label": "Save new flows to .claude/flows/", "detail": "POST /api/flows with the new flow JSON. Update INDEX.md."},
            {"id": "handover", "type": "action", "label": "Update handover doc", "detail": "doc/VISUAL_IMPROVEMENT_HANDOVER.md or doc/ARTIFACT_IMPROVEMENT_HANDOVER.md. What's done, what's next, what was learned."},
            {"id": "memory", "type": "action", "label": "Update memory if needed", "detail": "Save to .claude/projects/*/memory/ if there are persistent facts the next session needs."},
            {"id": "done", "type": "end", "label": "Session complete — next model can pick up"}
        ],
        "edges": [
            {"from": "commit", "to": "score"},
            {"from": "score", "to": "flows"},
            {"from": "flows", "to": "save_flow", "label": "yes"},
            {"from": "flows", "to": "handover", "label": "no"},
            {"from": "save_flow", "to": "handover"},
            {"from": "handover", "to": "memory"},
            {"from": "memory", "to": "done"}
        ]
    },
    {
        "id": "qfep-classification",
        "title": "QFEP Classification",
        "description": "Map an artifact to its position in E = F + lambda * phi * dE. Category determines the QFEP connection string.",
        "triggers": ["qfep connection", "classify artifact qfep", "which term", "E = F"],
        "granularity": "micro",
        "model_version": "opus-4.6",
        "created": "2026-04-08",
        "updated": "2026-04-08",
        "earned_from": "artifact-improver skill QFEP mapping table",
        "nodes": [
            {"id": "read", "type": "action", "label": "Read the artifact category and algorithm type"},
            {"id": "decide", "type": "decision", "label": "Which QFEP term?"},
            {"id": "f_pure", "type": "action", "label": "Pure F — predictable, structured", "detail": "primitives, transforms, geometry. Form that yields behavior."},
            {"id": "f_classical", "type": "action", "label": "Classical F — force as law", "detail": "forces, physics, joints. Constraint rules producing motion."},
            {"id": "es", "type": "action", "label": "E(S) — entropy as source", "detail": "randomness, noise. Raw disorder filtered through structure."},
            {"id": "lambda", "type": "action", "label": "Lambda — tuning between order and chaos", "detail": "fractals, L-systems. The parameter that controls complexity."},
            {"id": "phi", "type": "action", "label": "Phi*dE — rate of change", "detail": "morphogenesis, swarm, growth. How systems evolve over time."},
            {"id": "edge", "type": "action", "label": "Edge of chaos — critical lambda", "detail": "cellular automata, emergence. The phase transition between order and disorder."},
            {"id": "done", "type": "end", "label": "Write qfep_connection string"}
        ],
        "edges": [
            {"from": "read", "to": "decide"},
            {"from": "decide", "to": "f_pure", "label": "primitives/transforms"},
            {"from": "decide", "to": "f_classical", "label": "forces/physics/joints"},
            {"from": "decide", "to": "es", "label": "randomness/noise"},
            {"from": "decide", "to": "lambda", "label": "fractals/lsystems"},
            {"from": "decide", "to": "phi", "label": "morphogenesis/swarm"},
            {"from": "decide", "to": "edge", "label": "cellular automata"},
            {"from": "f_pure", "to": "done"},
            {"from": "f_classical", "to": "done"},
            {"from": "es", "to": "done"},
            {"from": "lambda", "to": "done"},
            {"from": "phi", "to": "done"},
            {"from": "edge", "to": "done"}
        ]
    },
    {
        "id": "artifact-creation",
        "title": "Create New Artifact",
        "description": "The 3-file pattern: .gd + .tscn + registry entry. Procedural in _ready(), grid-configurable, identity-documented.",
        "triggers": ["create artifact", "new artifact", "build artifact", "add artifact"],
        "granularity": "meso",
        "model_version": "opus-4.6",
        "created": "2026-04-08",
        "updated": "2026-04-08",
        "earned_from": "CLAUDE.md artifact creation pattern, 600+ artifacts in registry",
        "nodes": [
            {"id": "design", "type": "action", "label": "Design the algorithm + interaction", "detail": "What does it teach? What can the learner control? What's the critical parameter?"},
            {"id": "write_gd", "type": "action", "label": "Write <token>.gd", "detail": "extends Node3D, class_name PascalCase, @identity block, procedural in _ready(), apply_grid_config(config: Dictionary)"},
            {"id": "write_tscn", "type": "action", "label": "Write <token>.tscn", "detail": "Minimal: [gd_scene format=3], ext_resource for script, root Node3D"},
            {"id": "register", "type": "action", "label": "Add registry entry", "detail": "commons/artifacts/registry/<category>.json. Include lookup_name, scene path, map_sequences, tags."},
            {"id": "test", "type": "action", "label": "Test in Godot", "detail": "Load scene, verify _ready() builds correctly, check for errors."},
            {"id": "capture", "type": "action", "label": "Capture screenshot", "detail": "capture_multi_angle.gd --mode=artifact --target=<lookup_name>"},
            {"id": "done", "type": "end", "label": "Artifact ready for maps"}
        ],
        "edges": [
            {"from": "design", "to": "write_gd"},
            {"from": "write_gd", "to": "write_tscn"},
            {"from": "write_tscn", "to": "register"},
            {"from": "register", "to": "test"},
            {"from": "test", "to": "capture"},
            {"from": "capture", "to": "done"}
        ]
    },
    {
        "id": "vr-feedback-bridge",
        "title": "VR Feedback Bridge",
        "description": "Read player feedback from VR desktop overlay. Comments are written to ada_run/ during gameplay.",
        "triggers": ["vr feedback", "bridge listener", "desktop feedback", "player comments"],
        "granularity": "micro",
        "model_version": "opus-4.6",
        "created": "2026-04-08",
        "updated": "2026-04-08",
        "earned_from": "ada-bridge-listener skill, DesktopMapSwitcherOverlay.gd",
        "nodes": [
            {"id": "check", "type": "action", "label": "Read ada_run/desktop_feedback.md", "detail": "Timestamped entries with map, sequence, artifact context + user comment."},
            {"id": "has_new", "type": "decision", "label": "New feedback since last check?"},
            {"id": "parse", "type": "action", "label": "Parse feedback entries", "detail": "Each entry has: timestamp, map name, sequence, artifact list, comment text."},
            {"id": "classify", "type": "decision", "label": "What kind of feedback?", "detail": "Bug report, feature request, visual issue, or general comment."},
            {"id": "act", "type": "action", "label": "Create task or fix directly", "detail": "Bug: fix now. Feature: add to backlog. Visual: load artifact-visual-upgrade flow."},
            {"id": "done", "type": "end", "label": "Feedback processed"}
        ],
        "edges": [
            {"from": "check", "to": "has_new"},
            {"from": "has_new", "to": "parse", "label": "yes"},
            {"from": "has_new", "to": "done", "label": "no"},
            {"from": "parse", "to": "classify"},
            {"from": "classify", "to": "act"},
            {"from": "act", "to": "done"}
        ]
    },
    {
        "id": "pathfinder-validation",
        "title": "Map Pathfinder Validation",
        "description": "Validate map reachability rules. Every map must have reachable spawn, reachable teleporter, reachable artifacts.",
        "triggers": ["validate map", "pathfinder check", "map rules", "reachability"],
        "granularity": "micro",
        "model_version": "opus-4.6",
        "created": "2026-04-08",
        "updated": "2026-04-08",
        "earned_from": "doc/MAP_EDITING_PIPELINE.md, map_pathfinder.py",
        "nodes": [
            {"id": "run", "type": "action", "label": "Run pathfinder", "code": "python tools/map_pathfinder.py check <MapName> --verbose"},
            {"id": "pass", "type": "decision", "label": "All rules pass?"},
            {"id": "diagnose", "type": "action", "label": "Read violation details", "detail": "Common: spawn missing, teleporter unreachable, artifact on island, teleporter not on void."},
            {"id": "fix_spawn", "type": "action", "label": "Fix: add spawn point (sp)", "detail": "Place 'sp' in utilities layer at a floor cell."},
            {"id": "fix_reach", "type": "action", "label": "Fix: add ramp or transport cube", "detail": "Connect unreachable area with 'r' (ramp) or 'tc' (transport cube) in utilities."},
            {"id": "fix_tp", "type": "action", "label": "Fix: teleporter placement", "detail": "Teleporter must stand on void (height 0) with floor behind it in +z direction."},
            {"id": "rerun", "type": "action", "label": "Re-run pathfinder"},
            {"id": "done", "type": "end", "label": "Map valid"}
        ],
        "edges": [
            {"from": "run", "to": "pass"},
            {"from": "pass", "to": "done", "label": "yes"},
            {"from": "pass", "to": "diagnose", "label": "no"},
            {"from": "diagnose", "to": "fix_spawn", "label": "no spawn"},
            {"from": "diagnose", "to": "fix_reach", "label": "unreachable"},
            {"from": "diagnose", "to": "fix_tp", "label": "teleporter wrong"},
            {"from": "fix_spawn", "to": "rerun"},
            {"from": "fix_reach", "to": "rerun"},
            {"from": "fix_tp", "to": "rerun"},
            {"from": "rerun", "to": "pass"}
        ]
    },
    {
        "id": "lod-context-loading",
        "title": "LOD Context Loading",
        "description": "Load exactly the right amount of context for your task. Don't read everything — use fractal depth.",
        "triggers": ["load context", "understand artifact", "what is this", "lod query", "find context"],
        "granularity": "micro",
        "model_version": "opus-4.6",
        "created": "2026-04-08",
        "updated": "2026-04-08",
        "earned_from": "LOD_TREE.json, tools/lod_query.py",
        "nodes": [
            {"id": "what", "type": "decision", "label": "What level of detail do you need?"},
            {"id": "overview", "type": "action", "label": "Project overview", "code": "python tools/lod_query.py"},
            {"id": "sequence", "type": "action", "label": "Sequence detail", "code": "python tools/lod_query.py <sequence_id>"},
            {"id": "map", "type": "action", "label": "Map detail", "code": "python tools/lod_query.py <MapName>"},
            {"id": "artifact", "type": "action", "label": "Artifact detail", "code": "python tools/lod_query.py <lookup_name>"},
            {"id": "function", "type": "action", "label": "Function detail", "code": "python tools/lod_query.py <lookup_name>._function_name"},
            {"id": "done", "type": "end", "label": "Context loaded at right depth"}
        ],
        "edges": [
            {"from": "what", "to": "overview", "label": "what exists?"},
            {"from": "what", "to": "sequence", "label": "what's in this sequence?"},
            {"from": "what", "to": "map", "label": "what's in this map?"},
            {"from": "what", "to": "artifact", "label": "what does this artifact do?"},
            {"from": "what", "to": "function", "label": "how does this function work?"},
            {"from": "overview", "to": "done"},
            {"from": "sequence", "to": "done"},
            {"from": "map", "to": "done"},
            {"from": "artifact", "to": "done"},
            {"from": "function", "to": "done"}
        ]
    },
    # === FROM DEEPWIKI (10) ===
    {
        "id": "scene-transition",
        "title": "Scene Transition Flow",
        "description": "How VR scene loading works: AdaSceneManager → VRStaging → GridSystem. Critical timing: wait 3 frames after instantiation.",
        "triggers": ["scene loading", "transition", "load scene", "scene not loading", "black screen"],
        "granularity": "meso",
        "model_version": "opus-4.6",
        "created": "2026-04-08",
        "updated": "2026-04-08",
        "earned_from": "DeepWiki: VR Staging Scene Loading Choreography",
        "nodes": [
            {"id": "trigger", "type": "start", "label": "Scene transition triggered", "detail": "AdaSceneManager calls load_scene(path, user_data)"},
            {"id": "fade", "type": "action", "label": "XRToolsStaging fades out current scene"},
            {"id": "instantiate", "type": "action", "label": "New scene instantiated"},
            {"id": "metadata", "type": "action", "label": "Pass user_data to scene", "detail": "Try scene.set_scene_user_data(data), fallback to set_meta('scene_user_data', data)"},
            {"id": "wait", "type": "action", "label": "Wait 3 process frames", "detail": "CRITICAL: await get_tree().process_frame x3. All _ready() must complete before grid operations."},
            {"id": "grid", "type": "action", "label": "GridSystem.load_map(map_name)", "detail": "Reads map_data.json, instantiates structure + utilities + artifacts"},
            {"id": "visible", "type": "action", "label": "Emit scene_visible signal"},
            {"id": "done", "type": "end", "label": "Player can interact"}
        ],
        "edges": [
            {"from": "trigger", "to": "fade"},
            {"from": "fade", "to": "instantiate"},
            {"from": "instantiate", "to": "metadata"},
            {"from": "metadata", "to": "wait"},
            {"from": "wait", "to": "grid"},
            {"from": "grid", "to": "visible"},
            {"from": "visible", "to": "done"}
        ]
    },
    {
        "id": "grid-content-pipeline",
        "title": "Grid System Content Pipeline",
        "description": "How map_data.json becomes a 3D scene: JsonMapLoader → GridSystem → Components → Instantiation.",
        "triggers": ["grid system", "how maps load", "artifact instantiation", "GridSystem", "map_data.json"],
        "granularity": "meso",
        "model_version": "opus-4.6",
        "created": "2026-04-08",
        "updated": "2026-04-08",
        "earned_from": "DeepWiki: Grid System Architecture",
        "nodes": [
            {"id": "load", "type": "start", "label": "JsonMapLoader.load_map(name)"},
            {"id": "parse", "type": "action", "label": "Parse map_data.json", "detail": "3 layers: structure (heights 0-5), utilities (sp/t/r/tc/m), interactables (artifact:rotation:y_offset)"},
            {"id": "structure", "type": "action", "label": "GridStructureComponent builds geometry", "detail": "Floors, walls, heights from structure layer. cube_size and gutter from config."},
            {"id": "utilities", "type": "action", "label": "GridUtilitiesComponent places utilities", "detail": "Spawn points, teleporters, ramps, transport cubes, labels from utilities layer."},
            {"id": "artifacts", "type": "action", "label": "ArtifactRegistry instantiates artifacts", "detail": "lookup_name → scene path → load(path).instantiate() → position on grid → apply_grid_config()"},
            {"id": "done", "type": "end", "label": "Grid fully populated"}
        ],
        "edges": [
            {"from": "load", "to": "parse"},
            {"from": "parse", "to": "structure"},
            {"from": "structure", "to": "utilities"},
            {"from": "utilities", "to": "artifacts"},
            {"from": "artifacts", "to": "done"}
        ]
    },
    {
        "id": "error-recovery",
        "title": "Error Recovery Chain",
        "description": "Godot's fallback chain: missing assets skip silently, missing maps create empty grids, only VR staging failure crashes.",
        "triggers": ["error", "crash", "missing asset", "scene won't load", "artifact missing"],
        "granularity": "meso",
        "model_version": "opus-4.6",
        "created": "2026-04-08",
        "updated": "2026-04-08",
        "earned_from": "DeepWiki: Error Recovery & Fallback Chain",
        "nodes": [
            {"id": "error", "type": "start", "label": "Error encountered"},
            {"id": "what", "type": "decision", "label": "What failed?"},
            {"id": "scene_fail", "type": "action", "label": "Scene load failed", "detail": "Try fallback path → try main_scene → if all fail: black screen + error text."},
            {"id": "map_fail", "type": "action", "label": "map_data.json missing", "detail": "Log warning, create empty grid (0 artifacts). Scene loads but empty."},
            {"id": "artifact_fail", "type": "action", "label": "Artifact lookup_name not in registry", "detail": "Log warning, skip instantiation. Visual gap but no crash."},
            {"id": "sequence_fail", "type": "action", "label": "Sequence has broken map references", "detail": "Log on startup, skip sequence. UI hides it."},
            {"id": "done", "type": "end", "label": "Error handled — check logs"}
        ],
        "edges": [
            {"from": "error", "to": "what"},
            {"from": "what", "to": "scene_fail", "label": "scene path"},
            {"from": "what", "to": "map_fail", "label": "map data"},
            {"from": "what", "to": "artifact_fail", "label": "artifact"},
            {"from": "what", "to": "sequence_fail", "label": "sequence"},
            {"from": "scene_fail", "to": "done"},
            {"from": "map_fail", "to": "done"},
            {"from": "artifact_fail", "to": "done"},
            {"from": "sequence_fail", "to": "done"}
        ]
    },
    {
        "id": "progression-state",
        "title": "Progression State Management",
        "description": "How sequence completion flows through the system: GridScene → MapProgressionManager → LabManager → artifact unlock.",
        "triggers": ["progression", "sequence complete", "unlock artifacts", "lab state", "save state"],
        "granularity": "meso",
        "model_version": "opus-4.6",
        "created": "2026-04-08",
        "updated": "2026-04-08",
        "earned_from": "DeepWiki: Sequence Completion → Lab State Update Chain",
        "nodes": [
            {"id": "complete", "type": "start", "label": "Player completes all maps in sequence"},
            {"id": "signal", "type": "action", "label": "GridScene emits sequence_completed"},
            {"id": "save", "type": "action", "label": "MapProgressionManager saves to user://map_progression.json"},
            {"id": "lab", "type": "action", "label": "LabManager reads lab_artifact_system.json", "detail": "Finds which artifacts to unlock for this sequence completion."},
            {"id": "unlock", "type": "action", "label": "Instantiate unlocked artifacts in lab"},
            {"id": "persist", "type": "action", "label": "Save new lab state"},
            {"id": "done", "type": "end", "label": "Lab updated — new content visible"}
        ],
        "edges": [
            {"from": "complete", "to": "signal"},
            {"from": "signal", "to": "save"},
            {"from": "save", "to": "lab"},
            {"from": "lab", "to": "unlock"},
            {"from": "unlock", "to": "persist"},
            {"from": "persist", "to": "done"}
        ]
    },
    {
        "id": "vr-input-mapping",
        "title": "VR Input Mapping",
        "description": "Which button does what in VR. Left hand = movement, right hand = turn/fly/point. Know this before debugging input.",
        "triggers": ["vr controls", "button mapping", "input", "which button", "controller"],
        "granularity": "micro",
        "model_version": "opus-4.6",
        "created": "2026-04-08",
        "updated": "2026-04-08",
        "earned_from": "DeepWiki: Hand Controller Input-to-Action Mapping, hidden dependencies clause",
        "nodes": [
            {"id": "which", "type": "decision", "label": "Which hand/input?"},
            {"id": "left_stick", "type": "action", "label": "Left joystick → strafe movement (MovementDirect)"},
            {"id": "left_trigger", "type": "action", "label": "Left trigger → grab/pickup (FunctionPickup)"},
            {"id": "right_stick", "type": "action", "label": "Right joystick → turn (MovementTurn)"},
            {"id": "right_trigger", "type": "action", "label": "Right trigger → grab/pickup"},
            {"id": "ax_button", "type": "action", "label": "AX button → flight (MovementFlight)", "detail": "WARNING: MovementCapabilityGate may disable this by stage. Flight is now ungated."},
            {"id": "by_button", "type": "action", "label": "BY button → voice (disabled)"},
            {"id": "pointer", "type": "action", "label": "Right pointer laser → UI interaction (FunctionPointer)"},
            {"id": "done", "type": "end", "label": "Input mapped"}
        ],
        "edges": [
            {"from": "which", "to": "left_stick", "label": "left joystick"},
            {"from": "which", "to": "left_trigger", "label": "left trigger"},
            {"from": "which", "to": "right_stick", "label": "right joystick"},
            {"from": "which", "to": "right_trigger", "label": "right trigger"},
            {"from": "which", "to": "ax_button", "label": "AX button"},
            {"from": "which", "to": "by_button", "label": "BY button"},
            {"from": "which", "to": "pointer", "label": "pointer laser"},
            {"from": "left_stick", "to": "done"},
            {"from": "left_trigger", "to": "done"},
            {"from": "right_stick", "to": "done"},
            {"from": "right_trigger", "to": "done"},
            {"from": "ax_button", "to": "done"},
            {"from": "by_button", "to": "done"},
            {"from": "pointer", "to": "done"}
        ]
    },
    {
        "id": "hidden-dependencies",
        "title": "Hidden Dependencies Debugging",
        "description": "When VR behavior is wrong, check these hidden coupling points. System A and B modify the same resource without knowing about each other.",
        "triggers": ["weird behavior", "hidden dependency", "why does this break", "systems conflict", "vr bug"],
        "granularity": "meso",
        "model_version": "opus-4.6",
        "created": "2026-04-08",
        "updated": "2026-04-08",
        "earned_from": "Memory: clause_hidden_dependencies.md",
        "nodes": [
            {"id": "symptom", "type": "start", "label": "Unexpected VR behavior"},
            {"id": "check", "type": "decision", "label": "What's affected?"},
            {"id": "input", "type": "action", "label": "Check input conflicts", "detail": "AX=flight, BY=voice(disabled), trigger=grab, grip=close, stick=walk. MovementCapabilityGate may silently disable flight/climb."},
            {"id": "env", "type": "action", "label": "Check WorldEnvironment conflicts", "detail": "Multiple WorldEnvironments conflict — only one should be active. Scene + capture script both add one."},
            {"id": "gaze", "type": "action", "label": "Check gaze pointer side effects", "detail": "Gaze pointer has side effects even when invisible — disable it completely if not needed."},
            {"id": "camera", "type": "action", "label": "Check camera override", "detail": "Multiple Camera3D with current=true — last one wins. Artifact cameras override capture cameras."},
            {"id": "done", "type": "end", "label": "Hidden dependency identified — fix the coupling"}
        ],
        "edges": [
            {"from": "symptom", "to": "check"},
            {"from": "check", "to": "input", "label": "input not working"},
            {"from": "check", "to": "env", "label": "lighting/background wrong"},
            {"from": "check", "to": "gaze", "label": "phantom clicks"},
            {"from": "check", "to": "camera", "label": "wrong camera angle"},
            {"from": "input", "to": "done"},
            {"from": "env", "to": "done"},
            {"from": "gaze", "to": "done"},
            {"from": "camera", "to": "done"}
        ]
    },
    {
        "id": "batch-parallel-agents",
        "title": "Batch Processing with Parallel Agents",
        "description": "When N similar artifacts need the same treatment, do one by hand then send agents for the rest.",
        "triggers": ["batch process", "parallel agents", "many artifacts same fix", "scale up"],
        "granularity": "micro",
        "model_version": "opus-4.6",
        "created": "2026-04-08",
        "updated": "2026-04-08",
        "earned_from": "5 joint demo agents ran in parallel, each got the pattern from ChainSwing",
        "nodes": [
            {"id": "prototype", "type": "action", "label": "Do one artifact by hand", "detail": "Full treatment: read, identity, materials, trail, markers, capture. This establishes the pattern."},
            {"id": "extract", "type": "action", "label": "Extract the reusable pattern", "detail": "What's the base class? What code is shared? What varies per artifact?"},
            {"id": "spawn", "type": "action", "label": "Spawn 4-5 agents in parallel", "detail": "Each agent gets: the pattern (from prototype), the specific file path, and clear instructions to Write the complete file."},
            {"id": "verify", "type": "action", "label": "Verify all agents succeeded", "detail": "Run Godot capture on each. Check for parse errors. Fix any that failed."},
            {"id": "done", "type": "end", "label": "Batch complete"}
        ],
        "edges": [
            {"from": "prototype", "to": "extract"},
            {"from": "extract", "to": "spawn"},
            {"from": "spawn", "to": "verify"},
            {"from": "verify", "to": "done"}
        ]
    },
    {
        "id": "coherence-writing-loop",
        "title": "Writing Discovers Gaps",
        "description": "Writing documentation reveals what's missing in code. The doc-code-screenshot loop where writing is generative, not documentary.",
        "triggers": ["write docs", "blurb", "critical.md", "writing reveals", "coherence"],
        "granularity": "meso",
        "model_version": "opus-4.6",
        "created": "2026-04-08",
        "updated": "2026-04-08",
        "earned_from": "blog: coherence-refactor, writing-grows-artifacts",
        "nodes": [
            {"id": "write", "type": "action", "label": "Write critical.md or blurb.md for a map", "detail": "Read the sequence context, artifact list, and @identity blocks. Write about what the learner experiences."},
            {"id": "gap", "type": "decision", "label": "Did writing reveal a gap?", "detail": "A concept mentioned but no artifact represents it. A relationship described but not visible."},
            {"id": "build", "type": "action", "label": "Build the missing artifact", "detail": "Load artifact-creation flow. The writing told you what's needed."},
            {"id": "update", "type": "action", "label": "Update the doc with the new artifact", "detail": "The artifact changes what's true about the map. Rewrite to include it."},
            {"id": "screenshot", "type": "action", "label": "Capture to verify the new whole", "detail": "The map should now tell the story the doc describes."},
            {"id": "done", "type": "end", "label": "Doc and code are coherent"}
        ],
        "edges": [
            {"from": "write", "to": "gap"},
            {"from": "gap", "to": "build", "label": "yes — concept missing"},
            {"from": "gap", "to": "done", "label": "no — everything represented"},
            {"from": "build", "to": "update"},
            {"from": "update", "to": "screenshot"},
            {"from": "screenshot", "to": "done"}
        ]
    },
    {
        "id": "capture-framing",
        "title": "Capture Framing Guide",
        "description": "How to get the right camera distance and angle for artifact screenshots. Three zoom levels, pick the best.",
        "triggers": ["capture framing", "screenshot too far", "screenshot too close", "camera angle"],
        "granularity": "micro",
        "model_version": "opus-4.6",
        "created": "2026-04-08",
        "updated": "2026-04-08",
        "earned_from": "capture pipeline fixes: 2.0x→1.0x, zoom sweep, camera override",
        "nodes": [
            {"id": "run", "type": "action", "label": "Run capture_multi_angle.gd", "detail": "Outputs 3 zoom levels per angle: _far (1.4x), _mid (1.0x), _close (0.65x). Default = far."},
            {"id": "check", "type": "decision", "label": "Is the default (far) good?", "detail": "Should fill 40-70% of frame. If artifact is tiny, something is wrong."},
            {"id": "camera_bug", "type": "action", "label": "Check: artifact creating own Camera3D?", "detail": "JointDemoBase, many demos create Camera3D with current=true. The capture script disables these — if not, the artifact camera overrides."},
            {"id": "pick_zoom", "type": "action", "label": "Pick best from 3 zoom levels", "detail": "far = catalog shot (whole artifact), mid = hero shot (fills frame), close = detail (texture/mechanism)"},
            {"id": "done", "type": "end", "label": "Good screenshot captured"}
        ],
        "edges": [
            {"from": "run", "to": "check"},
            {"from": "check", "to": "pick_zoom", "label": "yes — looks good"},
            {"from": "check", "to": "camera_bug", "label": "no — artifact tiny"},
            {"from": "camera_bug", "to": "run"},
            {"from": "pick_zoom", "to": "done"}
        ]
    }
]

# Write all flows
for flow in flows:
    path = os.path.join(FLOWS_DIR, f"{flow['id']}.json")
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(flow, f, indent=2, ensure_ascii=False)

# Update INDEX.md
index_lines = [
    "# Flows Index\n",
    "Thinking paths that survive context death. Each flow is a small decision graph earned from practice.\n",
    "**Load a flow when its trigger matches your current situation.**\n",
    "## Capture & Screenshot",
]

categories = {
    "Capture & Screenshot": ["capture-debug", "capture-framing"],
    "Artifact Improvement": ["artifact-visual-upgrade", "metadata-enrich", "artifact-creation", "identity-writing"],
    "Sequence & Map Work": ["sequence-improve", "sequence-audit", "map-editing-pipeline", "pathfinder-validation"],
    "Navigation & Context": ["lod-context-loading", "heat-map-triage", "qfep-classification"],
    "System Architecture": ["scene-transition", "grid-content-pipeline", "error-recovery", "progression-state", "hidden-dependencies"],
    "VR & Input": ["vr-input-mapping", "vr-feedback-bridge"],
    "Process & Meta": ["session-handoff", "batch-parallel-agents", "coherence-writing-loop"],
}

index = "# Flows Index\n\nThinking paths that survive context death. Decision graphs earned from practice.\n\n**Load a flow when its trigger matches your current situation.**\n\n"

for cat, ids in categories.items():
    index += f"## {cat}\n"
    for fid in ids:
        flow = next((f for f in flows if f['id'] == fid), None)
        if flow:
            index += f"- [{flow['title']}]({fid}.json) \u2014 {flow['triggers'][0]}\n"
    index += "\n"

with open(os.path.join(FLOWS_DIR, 'INDEX.md'), 'w', encoding='utf-8') as f:
    f.write(index)

print(f"Generated {len(flows)} flows in {FLOWS_DIR}/")
print(f"Updated INDEX.md with {sum(len(v) for v in categories.values())} entries in {len(categories)} categories")
