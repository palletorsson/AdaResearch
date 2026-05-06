# Track Brief: [Scene/Track Name]

## Context

**Scene:** [What the player is doing - e.g., "Exploring abandoned space station"]

**Emotional Target:** [3 adjectives - e.g., "isolated, curious, uneasy"]

**Player State:** [exploration / combat / puzzle / transition / menu]

**Loop Duration:** [Target length - e.g., "2:00 loopable"]

---

## Identity

**Identity Token:** [What makes this track instantly recognizable]
> Example: "A detuned bell motif that returns every 16 bars"

**Do-Not-Do List:**
- [ ] [Cliché to avoid - e.g., "Generic cinematic brass hits"]
- [ ] [Another thing to avoid]
- [ ] 

---

## References (Triangulation)

| Aspect | Reference Track | What to Extract |
|--------|-----------------|-----------------|
| **Rhythm/Drive** | [Track A] | [Principle, not sound] |
| **Texture/World** | [Track B] | [Principle, not sound] |
| **Emotional Arc** | [Track C] | [Principle, not sound] |

---

## Palette Constraints

**Sound Families (max 6):**

| Family | Role | Character |
|--------|------|-----------|
| 1. Core Synth | Signature | |
| 2. Secondary Synth | Support | |
| 3. Bass | Foundation | |
| 4. Percussion | Rhythm | |
| 5. Texture/Air | Space | |
| 6. Signature Element | Identity | |

**Harmonic Palette:**
- Scale: [e.g., "D minor natural"]
- Allowed Chords: [e.g., "i, iv, VI, v"]
- Avoid: [e.g., "Major V, anything too bright"]

**Rhythmic DNA:**
- BPM: [e.g., "95-100"]
- Grid: [e.g., "16th with ~55% swing"]
- Signature Pattern: [e.g., "Kick avoids 1, snare on 3"]

---

## Frequency Strategy

| Band | Owner | Notes |
|------|-------|-------|
| Sub (20-60) | | |
| Bass (60-200) | | |
| Low-Mid (200-500) | Keep sparse | |
| Mid (500-2k) | | |
| Presence (2-5k) | Reserve for VO | |
| Air (5k+) | | |

---

## Arc Design

```
Time:    0:00 ──────── 0:30 ──────── 1:00 ──────── 1:30 ──────── 2:00
Energy:  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
Section: [Intro]       [Build]       [Main/Peak]   [Return]      [Loop]
```

**Macro Shape:** [flat / building / peak_middle / oscillating]

---

## Game Implementation

**Deliverables:**
- [ ] Stereo master (loopable)
- [ ] Stem: Bed/Atmosphere
- [ ] Stem: Rhythm
- [ ] Stem: Harmonic
- [ ] Stem: Lead/Motif
- [ ] Transition: In (riser)
- [ ] Transition: Out (downer)

**Adaptive Layers:**

| State | Active Stems | Notes |
|-------|--------------|-------|
| Exploration | Bed + Harmonic | Full |
| Tension | + Rhythm (filtered) | |
| Combat | All | |
| Transition Out | Bed only | Filter sweep |

**Loop Point:** [Timestamp where loop restarts cleanly]

**VO Safety Notes:** [Any ducking or frequency avoidance needed]

---

## Target Rubric Scores

| Dimension | Target | Notes |
|-----------|--------|-------|
| Identity Token | ≥4 | Critical for this track |
| Cohesion | ≥4 | |
| Controlled Variation | ≥3 | Can be static if ambient |
| Energy Arc | ≥3 | |
| Frequency Allocation | ≥4 | VO safety matters |
| Dynamic Contrast | ≥3 | |
| Spatial Clarity | ≥4 | |
| Loop Durability | ≥4 | Critical for game use |
| Implementation Ready | ≥4 | |
| Emotional Truth | ≥4 | Scene fit is key |

---

## λ Target

**Target λ:** [0.0-1.0 - e.g., "0.35 (controlled, not chaotic)"]

**Order Elements:** [What provides predictability]

**Chaos Elements:** [What provides surprise/variation]

---

## Pre-Flight Checklist

Before export, verify:

- [ ] Identity token recognizable in 2-second blind test
- [ ] Mute bass — track still reads
- [ ] Mute lead — identity remains
- [ ] Mono collapse test passed
- [ ] Loop 20x — no fatigue or seam annoyance
- [ ] Presence band checked for VO conflict
- [ ] All stems solo cleanly
- [ ] Transitions tested in engine
