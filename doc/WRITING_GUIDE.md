# Ada Research Writing Guide

Every map in Ada Research has four text files. Together they form a book readable along two trajectories: a technical tutorial and a critical reflection. The blurb is the hook, the summary is the index card.

## The four files

### blurb.md

50-150 words. Atmospheric, specific, minimal.

This is what the player reads first. It sets mood, not argument. Present tense. Second person when natural. Name the concept through concrete images, not abstractions.

Each blurb in a sequence should echo or advance the one before it. Read them in order as a poem.

**Exemplar** (Point_One):
> Before the point, infrastructure. The origin is not a point but a prerequisite — coordinate systems, render loops, the void made addressable. Point_One is the first mark: position without extension, existence without duration. You arrive late. The system was running.

**What to avoid:**
- "Welcome to a world where..." / "Step into the realm of..."
- "The player explores the fascinating concept of..."
- Generic atmosphere ("a vibrant environment", "an immersive experience")
- Explaining the algorithm — that is what technical.md does

### technical.md

2,000-3,000 words. Code-first, honest, progressive.

This is a tutorial chapter. GDScript examples from the actual codebase, not invented snippets. Structure: **Concept → Implementation → Why It Matters**.

Each technical.md in a sequence assumes knowledge from the previous one. Don't re-explain what was covered in the last map.

**Exemplar** (Point_One, opening):
> This chapter focuses on one thing: how a point becomes manipulable in VR while staying mathematically minimal.
>
> In Godot, a point is represented as a `Vector3` position. The vector is the data-model. Any visible sphere is only a proxy so bodies can see and grab that position.

**What to avoid:**
- "Points serve as a crucial foundation in the ever-evolving landscape of computational geometry"
- Invented code that doesn't match the actual scripts
- Teaching without code — paragraphs of explanation with no implementation
- Repeating material from the previous map's technical.md

### critical.md

2,000-2,500 words. Philosophical, questioning, cumulative.

This is a critical theory essay. Not a Wikipedia summary of queer theory — an argument built from what this specific map shows.

Structure: **What the map claims → What it assumes → What it erases → Queer alternative**

Cite specific theorists by name and work. Build on the previous map's critical.md — these are chapters, not standalone essays.

**Exemplar** (Point_One, opening):
> Euclid's definition: "A point is that which has no part."
>
> This is not just a mathematical statement - it is a declaration of atomicity, of fundamental indivisibility. The point cannot be broken down further. It is the minimal unit.
>
> But what does it mean to have "no part"?

**What to avoid:**
- "As Butler argues..." followed by something Butler never said
- "This connects to QFEP" without saying how
- "This algorithm queers the notion of..." — explain what norm is disrupted and how
- Reading like a Wikipedia article about queer theory rather than someone thinking through a problem

### summary.md

1,000-1,500 words. Structural, factual, connected.

This is a wiki entry. Sections: **Overview, Spatial Layout, Key Elements, Learning Sequence position, Design Intent, QFEP connection**.

Factual but contextualized. Connect the map to its sequence and to the broader curriculum.

**Exemplar** (Point_One, opening):
> Point One introduces the origin not as a geometric object, but as an infrastructural prerequisite. The map stages the moment before geometry, where spatial measurement becomes possible only through the establishment of a shared reference frame.

**What to avoid:**
- Promotional language ("this stunning map", "a groundbreaking experience")
- Restating the blurb
- Missing the sequence connection

---

## Writing by sequence

Each sequence is a chapter. Write the four texts map by map in sequence order. Before starting:

1. Run `python tools/map_text_writer.py audit <sequence>` to identify stubs and gaps
2. Run `python tools/map_text_writer.py context <map>` for each map to gather input
3. Read all existing texts in the sequence to lock in the voice

Write order within a sequence:
1. All blurbs first — establish the poetic arc
2. All technical — build the tutorial progression
3. All critical — layer the theoretical argument
4. All summaries — structural documentation once content is settled

## Humanizer checklist

Run `/ada-humanizer` on every text before saving. Key patterns to catch:

- **Significance inflation**: "pivotal", "crucial", "testament", "underscores". Say what it IS.
- **Promotional copy**: "vibrant", "stunning", "nestled", "in the heart of". Not tourism.
- **AI vocabulary**: "delve", "tapestry", "landscape" (abstract), "interplay", "intricate". Rewrite.
- **Vague attributions**: "Experts argue", "Some critics note". Name the person.
- **Rule of three**: Forced triads. Say only what needs saying.
- **Negative parallelisms**: "It's not just X; it's Y". Just say Y.
- **Em dash overuse**: One per paragraph max.
- **Chatbot residue**: "I hope this helps", "Let me know if". Delete.
- **Generic conclusions**: "The future looks bright". End with a specific claim or end sooner.

## QFEP phase and tone

The tone shifts across the curriculum spine:

| Phase | Sequences | Technical voice | Critical voice |
|-------|-----------|-----------------|----------------|
| F_order | primitives, transformation, color | Foundational. "Here is how this works." | "What does it mean to discretize? Whose space is made countable?" |
| oscillation | forces, arrays, wavefunctions | Mechanical. "Here is what happens when you apply force." | "Who gets to apply force? What resists?" |
| E_entropy | randomness, noise, CA | Generative. "Here is what emerges from disorder." | "Is disorder freedom or loss? Who decides?" |
| lambda_edge | fractals, L-systems, procgen | Recursive. "Here is how complexity grows from simple rules." | "Self-similarity: identity or conformity? What does the edge hold?" |
| integration | softbodies, swarm, ML | Emergent. "Here is what systems do when left to themselves." | "Collective intelligence: liberation or surveillance? Whose behavior emerges?" |
| synthesis | foundations crisis, QFEP lab | Reflexive. "Here is what we cannot formalize." | "Incompleteness as queer theory. The formula cannot close." |

## Gap handling for incomplete sequences

Later sequences may have stub maps (tiny grids, no artifacts, weak descriptions). Before writing text for these:

1. Run the audit — identify which maps are stubs
2. Record gaps in `doc/SEQUENCE_SUGGESTIONS.md`
3. Write text for stubs toward the *intended* final version
4. Note in SEQUENCE_SUGGESTIONS.md what artifacts/grid work the map needs
