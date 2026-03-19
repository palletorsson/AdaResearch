# Intent.md Writing Guide

## What is intent.md?

Each map folder can have an `intent.md` file that describes the map's design intent — why it exists, what role it plays in its sequence, and what's missing. This is not a teaching document (that's `blurb.md`) or a technical reference (that's `technical.md`) — it's a design document for the map's creators and maintainers.

## Format

Six sections, each on one line (can be long), prefixed by the section name:

```
Concept: [What this map is about — one or two sentences]
Sequence role: [Where it sits in the sequence, what comes before/after, what difficulty, what QFEP phase]
Technical angle: [The algorithms, data structures, or techniques demonstrated]
Critical angle: [What this concept reveals about computation, knowledge, or reality — the QFEP/critical theory reading]
Key artifacts: [Which artifacts are placed and what each one demonstrates]
Gap: [What's missing — what artifact or interaction would improve this map]
```

## How to Write Each Section

### Concept
- One or two sentences describing the core idea
- Should be specific enough to distinguish from neighboring maps
- Not "this map teaches X" but "X manifests here as Y"

### Sequence role
- Name the sequence and this map's position in it (e.g., "Third map in Fractals, lambda_edge phase")
- What the learner carries in from the previous map
- What this map prepares the learner for in the next map
- The difficulty level and why it's set there
- The QFEP phase and how this map serves it

### Technical angle
- The specific algorithms, equations, or techniques implemented
- Reference actual artifact names and what they compute
- Be concrete — "Verlet integration with dt² position update" not "physics simulation"

### Critical angle
- What this concept says about the nature of computation or reality
- How it connects to QFEP (F_order, E_entropy, lambda_edge, phi_emergence)
- The queer theory or critical theory reading — what does this normalize? What does it challenge?
- Not forced — if the critical angle is weak for this map, say so honestly

### Key artifacts
- List each teaching artifact (skip dark_sphere, catalyst_target, proximity_spawner)
- One clause per artifact explaining what it demonstrates
- If artifacts have @identity blocks, use their `truth` field as thematic material

### Gap
- What's missing from this map that would improve it
- Be specific: "needs a VR slider for stiffness" not "needs more interactivity"
- If nothing is missing, say "No gap identified"
- Check the @identity `needs` fields — artifacts often know what they're missing

## Data Sources

When writing intent.md for a map, read:
1. `map_data.json` — name, title, description, dimensions, artifacts in interactables layer
2. `blurb.md` — the learner-facing narrative (your intent should be consistent with this)
3. The sequence JSON — to understand position in the arc
4. The @identity blocks in artifact .gd files — for truth statements and needs

### Reading @identity blocks remotely

If you can't read .gd files directly, the Ada Encyclopedia API exposes identities:

```
GET /api/garden?mode=identity&name=<artifact_name>
GET /api/garden?mode=search&q=<search_term>
GET /api/garden?mode=truths
```

### Reading map data remotely

```
GET /api/maps?name=<MapName>
GET /api/game/context?format=markdown
```

## Quality Rules

- **Voice**: Direct, specific, not academic. Write like you're explaining to a collaborator, not a committee.
- **Honesty**: If the critical angle is weak, say so. If the gap is real, name it. Don't force connections.
- **Grounding**: Every claim should trace to something in the code or the map layout. Don't invent features.
- **Brevity**: Each section is one paragraph. The whole file should be readable in 60 seconds.

## Maps Missing intent.md

Run this to find them:
```bash
python -c "
import json, os
from pathlib import Path
for seq_file in sorted(Path('commons/maps/sequences').glob('*.json')):
    d = json.load(open(seq_file, encoding='utf-8'))
    for name, seq in d.get('sequences',{}).items():
        for m in seq.get('maps',[]):
            ip = Path(f'commons/maps/{m}/intent.md')
            if not ip.exists() or ip.stat().st_size < 20:
                print(f'[{name}] {m}')
"
```
