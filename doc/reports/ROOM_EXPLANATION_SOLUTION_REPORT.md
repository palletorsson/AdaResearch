# AdaResearch Room Explanation Report

Date: 2026-02-05

## Problem Summary
AdaResearch has strong audio production workflows, but spatial creation and room explanation remain hard to communicate. The core challenges:

- Room logic is implicit: people can see a map, but cannot quickly explain how it works or why the layout is shaped that way.
- Scene knowledge is fragmented: many working scenes exist, but their purpose, interaction model, and spatial requirements are not standardized.
- Map reuse is under-leveraged: existing maps can be re-composed into larger sequences, but there is no shared grammar to do so.
- Skill boundaries are unclear: production requires multiple abilities (structure, space, scene understanding), but roles are not defined in a teachable way.

The result: rooms get built, but the explanation layer and design system are missing, so the system is harder to extend and teach.

---

## Proposed Solution Overview
Create a spatial production pipeline that mirrors music production:

Structure (map skeleton) + Instruments (scene cards) + Mix (spatial staging)

This is delivered through:
1. A shared vocabulary (Scene Cards + Room Briefs)
2. A small set of reusable spatial formulas
3. New skills (roles) that divide the work cleanly
4. A map utilization matrix to reuse existing content

---

## Core Roles (Skills)

### 1) Ada-Scene-Expert
Purpose: Understand every scene as a modular instrument.

Outputs:
- Scene Card with purpose, interaction type, scale, audio, constraints
- Known dependencies or spatial needs (floor, clearance, lighting)

### 2) Ada-Map-Producer
Purpose: Owns flow and sequencing.

Outputs:
- Skeleton layout (entry -> anchor -> pocket -> exit)
- Pacing and progression plan
- Reuse plan (which existing maps become modules)

### 3) Ada-Spatial-Designer
Purpose: Stage the room: spatial rhythm, sightlines, and experience.

Outputs:
- Artifact placement plan
- Scale transitions (small -> large -> small)
- Visibility and density strategy

### 4) Ada-Room-Narrator (optional but powerful)
Purpose: Make rooms explainable in 5 lines.

Outputs:
- A Room Brief that explains how the room works and how to approach it

### 5) Ada-Room-Scavenger
Purpose: Research spatial formulas from existing AdaResearch maps, landmark games, and architectural history.

Outputs:
- Formula Library entries (pattern, effect, best use)
- Source notes for reuse (map ID, game, or architectural reference)

---

## Shared Vocabulary

### Scene Card Template
```
scene_id:
purpose:
interaction: observe | light touch | full manipulation
scale: small | medium | large
footprint:
audio: none | ambient | musical
inputs:
outputs:
constraints:
attention_span:
tags:
```

### Room Brief Template
```
room_goal:
player_loop:
core_anchor:
side_pockets:
pacing:
sound:
```

---

## Spatial Formulas (Reusable)

Passage Formula
```
Entry -> Short passage map -> Teleporter
```
Use for transitions and orientation.

Workbench Formula
```
Entry -> Tool map -> Practice map -> Exit
```
Use for learning a single concept by doing.

Anchor Formula
```
Entry -> Anchor map -> Reflection pocket -> Exit
```
Use for major conceptual landmarks.

Challenge Formula
```
Entry -> Blocker -> Challenge map -> Teleporter
```
Use for gates and learning progression.

Level Formula
```
Level 1 (observe) -> Ramp or Elevator -> Level 2 (manipulate) -> Exit
```
Use to encode conceptual elevation in vertical space.

---

## Room Scavenger Method
The Room Scavenger builds a reusable Formula Library by mining three sources:

1. AdaResearch maps (what already works in the project)
2. Game spaces (Quake, Half-Life, Portal, Call of Duty)
3. Architecture history (functionalism, baroque, gothic, brutalism)

Example formula entries:
Formula: Processional Reveal
Pattern: long corridor -> turn -> large volume
Effect: anticipation -> release
Best use: anchors, major concept reveals

Formula: Problem Chamber
Pattern: single room + one new rule + reset loop
Effect: fast learning, clear mastery
Best use: Portal-style teaching beats

Formula: Vertical Escalation
Pattern: compact base -> ramp or elevator -> open deck
Effect: conceptual elevation
Best use: multi-level learning sequences

---

## Map Utilization Strategy
Use a Map Utilization Matrix to connect existing maps into sequences:

```
Sequence: WaveFunctions
Entry: WaveFunctions_Intro
Anchor: WavePaintings
Practice: Sine_Space
Exit: Teleporter
```

This allows reuse of working maps as modules in a larger experience.

---

## Example: WaveFunctions_Intro
Observed structure:
- Level 1 = intro and control surface
- Ramp (wp) = transition to Level 2
- Level 2 = deeper interaction (pendulum, SHM, spring)
- Teleporter = next sequence

This illustrates the Level Formula and makes the room explainable.

---

## Implementation Steps
1. Create Scene Cards for top 30 scenes (scene expert)
2. Write Room Briefs for existing key maps (room narrator)
3. Tag existing maps with role: entry, anchor, practice, exit
4. Build Map Utilization Matrix for each sequence
5. Build a Formula Library (room scavenger)
6. Teach the skills (ada-scene-expert, ada-map-producer, ada-spatial-designer, ada-room-scavenger)

---

## Deliverables
- Scene Cards (catalog)
- Room Briefs (1 page per map)
- Map Utilization Matrix (sequence planning)
- Formula Library (pattern catalog + sources)
- New skills documented in Codex skills format

---

## Outcome
This turns map making into a composable production system rather than one-off worldbuilding. It preserves existing work and makes future rooms explainable, consistent, and easier to scale.
