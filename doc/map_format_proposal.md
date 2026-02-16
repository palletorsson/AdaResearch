# Map Format Proposal — Collaborative Spatial Interpretation

> Notes from conversation 2026-02-13. Speculative.

---

## The Problem Isn't Format — It's Shared Ground

Nobody has a complete reading of a map. The designer doesn't fully know what a space feels like until someone walks through it. An AI can't walk through it at all. We're both interpreting from partial information — different partial information.

This isn't a bug. It's the condition we work in. The question isn't "what format is most efficient" but **"what gives us the richest shared surface to disagree on."**

## Three Strategies (All Text, No Binary)

### 1. Minimize — Make the Data Readable

Current `map_data.json` is ~250 lines per map. Most of it is empty cells and JSON noise. This obscures spatial structure.

**Compact structure** — string grid, one char per cell:
```
1144444
4111114
4111114
4111114
4111114
4111114
4444414
```

**Sparse artifacts and utilities** — list only what's placed:
```
[2,3] dark_sphere (ambient)
[3,3] persian_rug:0:-0.49 (360° floor piece)
[11,2] line_network_ca (180° display)
```

**Why it matters:** Not just fewer tokens. A compact grid reads more like a *drawing* and less like *data*. It becomes something to interpret, not just parse.

### 2. Before — Offer a Reading

Before working on a map, produce an interpretation. Not a technical summary — a phenomenological reading. What does this space feel like? What does the player encounter?

```
You enter a walled room — five steps wide, open enough to breathe. 
A dark sphere hovers at center. Below it, a rug sunk into the floor, 
like something buried. Then the room closes to a single-cell corridor. 
Three rows of walking blind. When it opens again the space is 
different — irregular, pillared, less certain of itself.
```

This is deliberately ambiguous. It's one reading. The designer might say: "No — the corridor isn't blind, it's anticipation. And the second room isn't uncertain, it's a maze you have to earn." That correction IS the design process.

### 3. After — Compare Readings

After the interpretation, the gap between readings becomes visible:

| What I saw | What you intended |
|------------|-------------------|
| "Corridor feels blind" | "It's anticipation" |
| "Second room is uncertain" | "It's a maze to earn" |
| "Rug feels buried" | "It's a welcome mat" |

Neither reading is correct. The map becomes what emerges from the negotiation. The space changes because of what neither of us saw alone.

## The Process

```
1. Map exists (ambiguous)
2. AI offers a reading (situated, partial)
3. Designer offers a reading (situated, partial, different)
4. The friction between readings shapes the design
5. Neither reading "wins" — the space becomes the negotiation
```

This is QFEP at the workflow level. No stable ground — F can't go to zero. The productive thing is oscillation between interpretations, not convergence on one.

## RGB Observation

Each map cell stores 3 values across 3 layers:

| Layer | Encodes |
|-------|---------|
| Structure | Height (0-5) — the vertical dimension |
| Utilities | Movement verbs (wp, tc, t, m) |
| Interactables | Artifacts with placement params |

Three values per position. Like RGB per pixel. The map IS an image written as text. Color is 3D (R,G,B = a point in a cube), height grids are 3D (col, row, height). Both are 2D representations carrying 3D information in every cell.

Connection to **ARC-AGI** (arcprize.org) — Chollet's benchmark uses colored grids where color encodes spatial meaning. Same structure, different surface.

## Ceiling as Artifact

Currently ceiling is a separate JSON block (used in only 2 of 500+ maps). 

**Proposal:** Treat ceiling as an ambient artifact:
```
[0,0] ceiling#office:height:5.5:lights:sparse:spacing:3
```

- Three layers stays three layers — no special cases
- Different zones could have different ceilings
- No entry = open air (current default)
- A ceiling modifies the *experience* of every other artifact — enclosed space focuses attention, changes acoustic feel, changes how directionality reads
- Could have per-cell ceiling tiles for varied volumes

## Artifact Directionality

Every artifact claims a footprint of interaction space:

- **Full Circle (360°)** — grabbables, freestanding. Open space all around.
- **Half Circle (180°)** — displays, panels. Back against wall, front faces visitor.
- **Cone (~90°)** — screens, shaders. Project in one direction.
- **Corridor** — walk-throughs. The artifact IS the path.
- **Ambient** — atmosphere. No direction.

Rotation convention: 0=South, 90=West, 180=North, 270=East.

But directionality isn't just geometry. A display facing the "wrong" way might be intentional — forcing the player to discover it, or creating a comparison by facing two artifacts at each other. The rules describe defaults. The interpretation reveals intent.

## AI Spatial Ability — Honest

AI reasons about space **logically**, not **spatially**. Reading a grid means counting cells, checking adjacency, applying rules. Not seeing rooms, feeling enclosure, sensing flow.

What helps:
- Compact grids (reads more like a shape)
- Spatial narration (prime the reading before the data)
- Stated relationships ("artifact faces wall, player approaches from east")
- Images (vision gives *some* spatial intuition text doesn't)

What's hard:
- Sightlines, flow, scale, volume, enclosure
- The feel of a space vs the facts of a space

But this limitation is productive. An AI reading that misses the "feel" reveals something about what the feel depends on. The designer saying "no, that's wrong, it should feel like X" makes the design intention explicit — maybe for the first time.

## Open Questions

- How much should the compact format become the primary working format vs a conversation format?
- Could a visual editor render maps as colored grids (ARC-style) alongside the text?
- Should footprint types live in the artifact registry (declared once) or stay implicit?
- What other readings are possible beyond the designer and the AI? (Playtesters, critics, the engine itself?)

---

*Status: Speculative. The format details matter less than the process they enable.*
