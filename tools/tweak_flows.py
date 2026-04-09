"""Add links_to, confidence, summary to all flows. Split macros into linked micros."""
import json
import os
import glob

FLOWS_DIR = os.path.join('.claude', 'flows')

# Define links, confidence, and summaries for each flow
TWEAKS = {
    "capture-debug": {
        "confidence": "verified",
        "summary": "Screenshot empty? 1) Disable artifact cameras. 2) Skip ground if scene has WorldEnvironment. 3) Check AABB — no mesh or wrong cull mode.",
        "links_to": ["capture-framing"]
    },
    "capture-framing": {
        "confidence": "verified",
        "summary": "3 zoom levels per angle. Default = far (1.4x). If artifact tiny, check camera override first.",
        "links_to": ["capture-debug"]
    },
    "artifact-visual-upgrade": {
        "confidence": "verified",
        "summary": "Read code → find story → emissive materials → trail → markers → label → capture → evaluate. If screenshot empty, load capture-debug.",
        "links_to": ["identity-writing", "capture-debug", "capture-framing"]
    },
    "metadata-enrich": {
        "confidence": "verified",
        "summary": "Find registry entry → read GDScript → extract @identity → draft 8 fields → edit JSON → validate → re-score.",
        "links_to": ["identity-writing", "qfep-classification"]
    },
    "artifact-creation": {
        "confidence": "verified",
        "summary": "Design → write .gd (extends Node3D, class_name, @identity, apply_grid_config) → write .tscn → register in JSON → test → capture.",
        "links_to": ["identity-writing", "metadata-enrich", "capture-framing"]
    },
    "identity-writing": {
        "confidence": "verified",
        "summary": "Read code → essence (math) → desire (experience) → critical_parameter (the one knob) → truth (poetic insight, the hard part).",
        "links_to": ["metadata-enrich", "qfep-classification"]
    },
    "sequence-improve": {
        "confidence": "verified",
        "summary": "Score all → pick smallest×lowest → read all code → batch metadata → batch identity → capture footprints → visual if needed → re-score → commit.",
        "links_to": ["heat-map-triage", "metadata-enrich", "artifact-visual-upgrade", "batch-parallel-agents"]
    },
    "sequence-audit": {
        "confidence": "extracted",
        "summary": "Horizontal: score all sequences. Vertical: deep-dive on worst. Classify artifacts DORMANT→SCATTERED→REACHING→GROWING→LIVING.",
        "links_to": ["heat-map-triage", "sequence-improve"]
    },
    "map-editing-pipeline": {
        "confidence": "verified",
        "summary": "DISCOVER (ada.py) → EDIT (web or JSON) → VALIDATE (pathfinder) → CAPTURE → REVIEW → BRIDGE (VR feedback) → ITERATE.",
        "links_to": ["pathfinder-validation", "capture-framing", "vr-feedback-bridge"]
    },
    "pathfinder-validation": {
        "confidence": "verified",
        "summary": "Run pathfinder check. Fails? Common: no spawn, unreachable artifact, teleporter not on void. Fix, re-run.",
        "links_to": ["map-editing-pipeline"]
    },
    "lod-context-loading": {
        "confidence": "verified",
        "summary": "Don't read everything. lod_query.py <topic> at the right depth: project → sequence → map → artifact → function.",
        "links_to": ["heat-map-triage"]
    },
    "heat-map-triage": {
        "confidence": "verified",
        "summary": "Score all. Sort by artifact_count × (8 - avg). Small×low = quick win. Large×low = batch job.",
        "links_to": ["sequence-improve", "sequence-audit"]
    },
    "qfep-classification": {
        "confidence": "verified",
        "summary": "primitives→F, randomness→E(S), fractals→λ, morphogenesis→φdE, forces→Classical F, CA→Edge of chaos.",
        "links_to": ["metadata-enrich"]
    },
    "scene-transition": {
        "confidence": "extracted",
        "summary": "load_scene → fade → instantiate → pass user_data → WAIT 3 FRAMES → GridSystem.load_map → scene_visible. The 3-frame wait is critical.",
        "links_to": ["grid-content-pipeline", "error-recovery"]
    },
    "grid-content-pipeline": {
        "confidence": "extracted",
        "summary": "map_data.json → 3 layers (structure, utilities, interactables) → GridSystem components → instantiate artifacts from registry.",
        "links_to": ["scene-transition", "error-recovery"]
    },
    "error-recovery": {
        "confidence": "extracted",
        "summary": "Scene fail → try fallback. Map missing → empty grid. Artifact missing → skip. Sequence broken → hide. Only staging failure crashes.",
        "links_to": ["scene-transition", "hidden-dependencies"]
    },
    "progression-state": {
        "confidence": "extracted",
        "summary": "sequence_completed signal → MapProgressionManager saves → LabManager reads unlock list → instantiate new artifacts → save lab state.",
        "links_to": ["scene-transition"]
    },
    "vr-input-mapping": {
        "confidence": "verified",
        "summary": "Left: joystick=strafe, trigger=grab. Right: joystick=turn, trigger=grab, AX=flight, pointer=UI. MovementCapabilityGate may disable flight.",
        "links_to": ["hidden-dependencies"]
    },
    "vr-feedback-bridge": {
        "confidence": "verified",
        "summary": "Read ada_run/desktop_feedback.md. Timestamped entries with map+artifact context. Bug→fix now, feature→backlog, visual→load visual-upgrade flow.",
        "links_to": ["map-editing-pipeline", "artifact-visual-upgrade"]
    },
    "hidden-dependencies": {
        "confidence": "verified",
        "summary": "VR weird? Check: camera override (multiple Camera3D), WorldEnvironment conflict, gaze pointer side effects, MovementCapabilityGate silently disabling input.",
        "links_to": ["capture-debug", "vr-input-mapping", "error-recovery"]
    },
    "batch-parallel-agents": {
        "confidence": "verified",
        "summary": "Do one by hand → extract pattern → spawn 4-5 agents with pattern + specific file → verify all succeeded.",
        "links_to": ["sequence-improve", "artifact-visual-upgrade"]
    },
    "coherence-writing-loop": {
        "confidence": "extracted",
        "summary": "Write docs → discover gap (concept mentioned, no artifact) → build missing artifact → update docs → capture to verify coherence.",
        "links_to": ["identity-writing", "artifact-creation"]
    },
    "session-handoff": {
        "confidence": "verified",
        "summary": "Commit → score baseline → save new flows from discoveries → update handover doc → update memory.",
        "links_to": ["heat-map-triage"]
    },
}

# Apply tweaks to all flows
updated = 0
for f in glob.glob(os.path.join(FLOWS_DIR, '*.json')):
    try:
        data = json.load(open(f, encoding='utf-8'))
    except Exception:
        continue

    fid = data.get('id', '')
    if fid in TWEAKS:
        tweak = TWEAKS[fid]
        data['confidence'] = tweak['confidence']
        data['summary'] = tweak['summary']
        data['links_to'] = tweak['links_to']

        with open(f, 'w', encoding='utf-8') as fh:
            json.dump(data, fh, indent=2, ensure_ascii=False)
        updated += 1

print(f"Updated {updated} flows with links_to, confidence, summary")

# Regenerate INDEX.md with summaries and confidence
flows = []
for f in glob.glob(os.path.join(FLOWS_DIR, '*.json')):
    try:
        flows.append(json.load(open(f, encoding='utf-8')))
    except Exception:
        pass

categories = {
    "Capture & Screenshot": ["capture-debug", "capture-framing"],
    "Artifact Improvement": ["artifact-visual-upgrade", "metadata-enrich", "artifact-creation", "identity-writing"],
    "Sequence & Map Work": ["sequence-improve", "sequence-audit", "map-editing-pipeline", "pathfinder-validation"],
    "Navigation & Context": ["lod-context-loading", "heat-map-triage", "qfep-classification"],
    "System Architecture": ["scene-transition", "grid-content-pipeline", "error-recovery", "progression-state", "hidden-dependencies"],
    "VR & Input": ["vr-input-mapping", "vr-feedback-bridge"],
    "Process & Meta": ["session-handoff", "batch-parallel-agents", "coherence-writing-loop"],
}

flow_map = {f['id']: f for f in flows}

index = "# Flows Index\n\nThinking paths that survive context death. Search: `python tools/flow_query.py <trigger>`\n\n"

for cat, ids in categories.items():
    index += f"## {cat}\n"
    for fid in ids:
        f = flow_map.get(fid)
        if f:
            conf = f.get('confidence', '?')
            conf_icon = {'verified': '+', 'extracted': '~', 'scaffolded': '?'}.get(conf, '?')
            index += f"- [{conf_icon}] [{f['title']}]({fid}.json) — {f.get('summary', f['triggers'][0])}\n"
    index += "\n"

index += "## Confidence\n- [+] verified — tested across multiple artifacts/sessions\n- [~] extracted — from docs/wiki, not yet tested\n- [?] scaffolded — template only\n"

with open(os.path.join(FLOWS_DIR, 'INDEX.md'), 'w', encoding='utf-8') as f:
    f.write(index)

print("Regenerated INDEX.md with summaries and confidence icons")
