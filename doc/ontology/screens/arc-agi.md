---
title: "ARC-AGI — Learnability as Primitive"
primitive: arc-agi
sequence: meta
phase: meta
lens: Learnability
question: "What makes a pattern learnable vs memorizable?"
insight: "Intelligence is not what you know — it's how fast you learn from exploration. The gap between static pattern matching and interactive reasoning is the gap between 2D and 3D."
qfep: "ARC-AGI measures the λ parameter directly — the efficiency of transformation from novel formalism to functional experience."
web_editor: null
godot_infoboard: null
tags: [intelligence, learning, grids, abstraction, reasoning, exploration, arc]
connections: [grid, arrays, random-walk, forces, filter-screen]
status: draft
---

# ARC-AGI — Learnability as Primitive

**Lens:** Learnability — *What makes a pattern learnable vs memorizable?*

## Discussion

ARC-AGI is the Abstraction and Reasoning Corpus — a benchmark that
measures intelligence not as knowledge but as **skill-acquisition
efficiency**. Not what you know, but how fast you learn.

Three versions trace an arc that mirrors Ada's own evolution:

- **ARC-AGI-1** (2019): Static grid puzzles. Given input→output pairs,
  infer the transformation rule. AI now scores 93%. This is pattern
  matching — 2D thinking.

- **ARC-AGI-2** (2024): Harder static puzzles. AI scores 68.8%. The
  patterns resist memorization. You need abstraction.

- **ARC-AGI-3** (2026): Interactive environments. No more static puzzles.
  You must **explore**, build a world model, discover goals, plan, and
  adapt. AI scores 13%. Humans score near-perfect. This is embodied
  reasoning — 3D thinking.

The 93% → 13% collapse is the most important number in AI right now.
It says: **pattern matching is not intelligence. Exploration is.**

### The Grid Connection

ARC has always been grid-based. So has Ada. This is not coincidence.
The grid is the minimal substrate for spatial reasoning — addressable
cells with values that can be transformed by rules.

Ada's 3-layer grid (structure / utilities / interactables) is richer
than ARC's single-layer grid, but the principle is the same: discrete
space with transformable contents. Every Ada map is an ARC-like
environment. Every ARC puzzle is a map without a body.

### The Exploration Gap

ARC-AGI-3 reveals that the hard part is not solving — it's learning
*what to solve*. The agent must:

1. **Explore** — move through the environment, observe effects
2. **Model** — build internal representation of how the world works
3. **Plan** — set goals based on discovered rules
4. **Adapt** — update beliefs when new evidence contradicts the model

This is exactly what a learner does in Ada's VR maps:

1. Walk into the room, look around (explore)
2. Interact with artifacts, see what they do (model)
3. Understand the learning objective (plan)
4. Realize the algorithm works differently than expected (adapt)

### Memory Compression and LOD

ARC-AGI-3 measures "memory compression" — how efficiently an agent
compresses experience into reusable knowledge. This is LOD applied
to learning itself:

- LOD 0: "there's a grid with colored cells" (glance)
- LOD 1: "cells change color when I step on them" (card)
- LOD 2: "the color change follows a modular arithmetic rule" (discussion)
- LOD 3: "I can predict the next state and plan a path" (deep)

Intelligence is knowing which level to operate at, and when to zoom
in or out. The LOD system we built for ontology IS the structure
of intelligence.

### Static vs Interactive: 2D vs 3D

The jump from ARC-AGI-1 to ARC-AGI-3 mirrors the jump from
web editors to VR:

| Static (ARC-1, 2D web) | Interactive (ARC-3, VR) |
|------------------------|------------------------|
| Given the pattern | Discover the pattern |
| One correct answer | Many possible paths |
| No time dimension | Learning over time |
| Observer | Participant |
| Matching | Understanding |

The Filter Screen makes this visible: you see the 3D world flattened
onto a 2D surface. The information lost in that projection is exactly
what ARC-AGI-3 tests — the difference between seeing a pattern and
understanding the world that generates it.

### What Ada Can Learn

1. **Test primitive understanding interactively** — don't just show
   a triangle, ask the learner to *discover* what a triangle is by
   exploring its properties. Give them vertices, let them find area.

2. **Measure learning efficiency** — how many interactions does it
   take for the learner to understand winding order? That's the λ
   parameter made measurable.

3. **Build ARC-like challenges into maps** — some maps could be
   grid puzzles where the learner must infer the transformation
   rule from examples, then apply it.

4. **The Science Screen as ARC display** — the Science Screen
   already renders grid data as colored pixels. It could display
   ARC-style input→output pairs, letting the learner reason about
   transformations while standing inside the 3D world.

## QFEP Connection

ARC-AGI measures the λ parameter directly — the efficiency of
transformation from novel formalism to functional experience.

A high λ means the learner quickly moves from "I see a pattern"
to "I understand the rule and can apply it." A low λ means they're
stuck in memorization. ARC-AGI-3's 13% score means current AI has
a very low λ for interactive environments — high formalism,
low experiential integration.

Ada's QFEP framework predicts this: you can't skip E (experience).
Static pattern matching is pure F (formalism). Interactive reasoning
requires F ↔ E oscillation — and that's exactly what current AI
can't do.

## Open Questions

- Can Ada's primitive editors be reformulated as ARC-AGI environments?
- What would an ARC puzzle look like in VR? (Walk through a grid world, discover the rule)
- Is the 93%→13% gap the same as the 2D→3D gap in understanding?
- Could the Science Screen display ARC puzzles as part of the curriculum?
- What does "memory compression" look like in embodied VR learning?
- Is there an ARC-equivalent for queer theory? (Discover the hidden rule of normativity by exploring its effects)
- The grid is both ARC's substrate and Ada's substrate — is the grid the primitive of intelligence itself?

## Connections

- **Grid** — shared substrate. ARC = grid puzzles. Ada = grid maps. The grid is where spatial reasoning happens.
- **Arrays** — ARC transformations are array operations. Map, filter, reduce on 2D grids.
- **Random Walk** — ARC-AGI-3 exploration is a biased random walk through state space. The agent must learn which directions are productive.
- **Forces** — the invisible rules of an ARC environment are like forces — you can't see them, only their effects on the grid.
- **Filter Screen** — projects 3D understanding onto 2D display. ARC-AGI-3 tests whether you can reverse that projection — going from 2D observations to 3D world models.
