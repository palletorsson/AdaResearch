# Dark Wave / Cold Wave — Drum Patterns

**Genre:** Dark Wave / Cold Wave / Post-Punk  
**Reference Artists:** She Past Away, Boy Harsher, Lebanon Hanover, Bauhaus, Siouxsie and the Banshees, Clan of Xymox  
**BPM:** 118 (typical dark wave tempo)  
**Time Signature:** 4/4  
**Swing:** 7% (minimal — cold but not robotic)  
**Humanize:** 4ms (slight timing drift — ghost of a human behind the machine)  

---

## Design Philosophy

This is NOT 4-on-floor dance music. This is post-punk drum machine programming — the kick is syncopated, deliberate, and creates tension by *avoiding* the predictable. Think of the Roland TR-606/TR-808 through a goth lens: programmed by someone who listened to Siouxsie and Joy Division, not Kraftwerk.

The **toms are the signature**. Tribal, repetitive, driving — they carry the hypnotic urgency that defines the genre. "Bela Lugosi's Dead" lives in those tom patterns.

Snare/clap: DRY. Gated. Sharp. No reverb tail — this isn't 80s pop, it's post-punk austerity.

Hihats: 8th notes, not 16ths. Sparse. The space between hits is part of the rhythm.

---

## Pattern 1: MAIN BEAT — "Ritüel"

The full driving pattern. Post-punk urgency meets cold wave precision.
Kick is syncopated — avoids beat 3 entirely, creates push-pull with the toms.

```gdscript
# MAIN BEAT — "Ritüel"
# The kick pushes against beats 1 and 2, skips 3, returns on the & of 4
# Toms carry the tribal pulse — low tom on offbeats, high tom accents the gaps
# Snare/clap: dry, gated, locked to 2 and 4

{
    "kick":     [2, 0, 0, 0,  0, 0, 1, 0,  0, 0, 0, 0,  0, 1, 0, 0],
    #            1  .  .  .   2  .  .  .   3  .  .  .   4  .  .  .
    #            BANG         skip    hit   ---empty---  &4 push

    "snare":    [0, 0, 0, 0,  2, 0, 0, 0,  0, 0, 0, 0,  2, 0, 0, 0],
    #            rest          CRACK                      CRACK
    #            Dry, gated. No reverb. Think Linn snare through a gate.

    "hihat":    [1, 0, 1, 0,  1, 0, 1, 0,  1, 0, 1, 0,  1, 0, 0.5, 0],
    #            8th notes, straight. Open hat ghost on &4 for subtle lift.
    #            Sparse. Cold. Mechanical.

    "tom_low":  [0, 0, 1, 0,  0, 0, 0, 0,  1, 0, 0, 0,  0, 0, 1, 0],
    #            Tribal pulse. Offbeat low tom drives the hypnotic feel.
    #            Think "Bela Lugosi's Dead" — repetitive, ritualistic.

    "tom_high": [0, 0, 0, 0,  0, 0, 0, 1,  0, 0, 1, 0,  0, 0, 0, 0],
    #            High tom fills the gaps left by kick and low tom.
    #            Creates a cascading tribal pattern across the two toms.

    "clap":     [0, 0, 0, 0,  1, 0, 0, 0,  0, 0, 0, 0,  1, 0, 0, 0],
    #            Layered with snare on 2 and 4. Dry, sharp, lower velocity
    #            than snare — adds width, not volume.
}
```

### Composite Rhythm Visualization (Main Beat)
```
Step:     1  .  .  .  2  .  .  .  3  .  .  .  4  .  .  .
Kick:     X              x                    x
Snare:                X                       X
Hihat:    x     x     x     x     x     x     x     ~
Tom Lo:         x              x              x
Tom Hi:                     x        x
Clap:                 x                       x
```

---

## Pattern 2: MINIMAL / INTRO — "Fog Machine"

Stripped back. Just the bones. Kick and hihat establish the cold pulse.
No toms yet — they enter later for impact. Sparse, ominous, building tension.

```gdscript
# MINIMAL / INTRO — "Fog Machine"
# Barely there. The kick hints at syncopation. Hihat is skeletal.
# A single ghost snare on the &4 suggests what's coming.

{
    "kick":     [1, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0.5, 0, 0],
    #            1                                         ghost &4
    #            Just beat 1 and a ghost kick. Minimal. Waiting.

    "snare":    [0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  1, 0, 0, 0],
    #            Single snare on beat 4 only. Not 2 and 4 — that comes later.
    #            Sparse. Tension.

    "hihat":    [1, 0, 0, 0,  1, 0, 0, 0,  1, 0, 0, 0,  1, 0, 0, 0],
    #            Quarter notes only. Cold, metronomic, distant.

    "tom_low":  [0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0],
    #            Silent. Waiting for the main section.

    "tom_high": [0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0],
    #            Silent.

    "clap":     [0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0],
    #            Silent. No clap in intro — too much presence.
}
```

### Composite Rhythm Visualization (Intro)
```
Step:     1  .  .  .  2  .  .  .  3  .  .  .  4  .  .  .
Kick:     X                                   ~
Snare:                                        X
Hihat:    x           x           x           x
```

---

## Pattern 3: BREAKDOWN — "Tribal Descent"

Toms only (plus ghostly hihat). This is the ritual moment.
Two toms interlock into a hypnotic tribal pattern. Everything else drops out.
Think the breakdown in "Bela Lugosi's Dead" — primal, repetitive, trance-inducing.

```gdscript
# BREAKDOWN — "Tribal Descent"  
# Everything drops except toms and a skeletal hihat.
# The two toms interlock into a tribal call-and-response.
# This is the moment the dancefloor becomes a ritual.

{
    "kick":     [0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0],
    #            No kick. The absence creates tension.

    "snare":    [0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0],
    #            No snare. Stripped to bone.

    "hihat":    [0.5, 0, 0, 0,  0, 0, 0.5, 0,  0, 0, 0, 0,  0.5, 0, 0, 0],
    #            Ghost hihats. Barely audible ticking. Cold metronome.

    "tom_low":  [2, 0, 0, 1,  0, 0, 2, 0,  0, 1, 0, 0,  2, 0, 0, 1],
    #            DRIVING. Accented tribal pulse. Relentless.
    #            This is the heartbeat of the breakdown.

    "tom_high": [0, 0, 1, 0,  1, 0, 0, 0,  1, 0, 0, 1,  0, 0, 1, 0],
    #            High tom weaves between the low tom hits.
    #            Together they create one continuous tribal roll.

    "clap":     [0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0],
    #            No clap. Pure percussion ritual.
}
```

### Composite Rhythm Visualization (Breakdown)
```
Step:     1  .  .  .  2  .  .  .  3  .  .  .  4  .  .  .
Tom Lo:   X        x        X        x        X        x
Tom Hi:         x     x        x        x        x
Hihat:    ~              ~                    ~
```

---

## Pattern 4 (BONUS): FILL / TRANSITION — "The Return"

A 1-bar fill that brings back the full kit. Tom roll builds into snare hit.

```gdscript
# FILL — "The Return"
# Brings the full kit back from breakdown. Tom roll accelerates.

{
    "kick":     [0, 0, 0, 0,  0, 0, 0, 0,  1, 0, 0, 0,  2, 0, 0, 0],
    #            Kick re-enters on beat 3, accented hit on 4.

    "snare":    [0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 1, 2],
    #            Snare roll into the downbeat. Last two 16ths.

    "hihat":    [0, 0, 0, 0,  0, 0, 0, 0,  1, 0, 1, 0,  1, 1, 1, 1],
    #            Hihats build from 8ths to 16ths in the last beat.

    "tom_low":  [2, 0, 1, 0,  2, 0, 1, 0,  1, 0, 0, 0,  0, 0, 0, 0],
    #            Tribal toms in first half, yield to kick/snare.

    "tom_high": [0, 1, 0, 1,  0, 1, 0, 1,  0, 1, 0, 0,  0, 0, 0, 0],
    #            High tom interlocks, then drops out.

    "clap":     [0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 2],
    #            Single accented clap on the very last 16th. SNAP.
}
```

---

## Velocity Dynamics

```gdscript
# VELOCITY PROFILE: "cold_wave"
# Cold, precise, but not completely dead. The slight variation
# is what separates dark wave from pure industrial.
{
    "base": 0.75,       # Strong but not maxed — gated, controlled
    "accent": 1.0,      # Accents hit hard (kick on 1, snare on 2/4)
    "ghost": 0.35,      # Ghost notes: felt, barely heard (hihat ghosts, kick ghosts)
    "variation": 0.06,  # 6% random variation — cold but not robotic
}
```

### Per-Instrument Velocity Notes

| Element | Base Velocity | Character | Processing Notes |
|---------|--------------|-----------|-----------------|
| **Kick** | 0.8 | Punchy, mid-focused, NOT sub-heavy | Short decay (~150ms). Think TR-606 or LinnDrum kick. Not boomy. |
| **Snare** | 0.85 | DRY, gated, sharp transient | Tight gate (50-80ms decay). No reverb tail. Compressed hard. |
| **Hihat** | 0.65 | Thin, metallic, cold | Filtered — mostly high end. Consistent velocity on 8ths. |
| **Tom Low** | 0.8 | Deep, resonant, tribal | Longer decay than kick (~200ms). Some room tone but controlled. |
| **Tom High** | 0.7 | Tight, pitched up, percussive | Shorter decay than low tom (~120ms). Cuts through the mix. |
| **Clap** | 0.7 | Dry, layered under snare | Gated. Adds width to snare hits. Lower in mix than snare. |

---

## Groove Notes

### Swing
- **Amount:** 7% (range: 5-10%)
- **Application:** Applied to even-numbered 16th notes (steps 2, 4, 6, 8, 10, 12, 14, 16)
- **Character:** Just enough to avoid pure machine feel, but NOT groovy. This is cold. The swing is more like "imprecise drum machine programming" than "funk."

### Humanization
- **Timing:** 3-5ms random offset per hit
- **Applied to:** All elements except kick (kick stays locked for punch)
- **Character:** The humanization should feel like someone programmed these patterns on hardware with slightly loose MIDI timing — NOT like a live drummer.

### Ghost Note Philosophy
- Ghost notes (velocity 0.5) are used sparingly
- Hihat ghost on &4 in main pattern creates subtle lift before the bar loops
- Kick ghost on &4 in intro pattern hints at the syncopation to come
- These should be *felt* in the overall rhythm, not consciously heard

### The Cold Wave Rule
> **Everything is slightly held back.** Where other genres push into the groove, dark wave pulls back. The kick doesn't land early — if anything, it's a hair late. The snare doesn't crack with joy — it snaps with precision. The toms don't roll with warmth — they pound with ritual insistence. The humanization isn't "feel" — it's "imperfection in the machine."

---

## Integration: SoundbankGenerator.gd Format

Ready to paste into `PATTERNS`, `BASS_PATTERNS`, `SWING`, `VELOCITY`, and `STRUCTURES`:

```gdscript
# ── PATTERNS ─────────────────────────────────────────────────────────
# Dark Wave / Cold Wave: Post-punk drum machine — NOT 4-on-floor
# Reference: She Past Away "Ritüel", Bauhaus "Bela Lugosi's Dead"
# 118 BPM, syncopated kick, tribal toms, gated snare, sparse 8th hats
"dark_wave": {
    "kick":     [2,0,0,0, 0,0,1,0, 0,0,0,0, 0,1,0,0],  # Syncopated — skips beat 3 entirely
    "snare":    [0,0,0,0, 2,0,0,0, 0,0,0,0, 2,0,0,0],  # DRY gated crack on 2 and 4
    "hihat":    [1,0,1,0, 1,0,1,0, 1,0,1,0, 1,0,0.5,0],  # 8ths, ghost open hat on &4
    "tom_low":  [0,0,1,0, 0,0,0,0, 1,0,0,0, 0,0,1,0],  # Tribal pulse — the genre signature
    "tom_high": [0,0,0,0, 0,0,0,1, 0,0,1,0, 0,0,0,0],  # Fills gaps between low tom
    "clap":     [0,0,0,0, 1,0,0,0, 0,0,0,0, 1,0,0,0],  # Dry, layered under snare
},

# ── BASS_PATTERNS ────────────────────────────────────────────────────
"dark_wave": {
    "pattern": [1,0,0,0, 0,0,1,0, 0,0,0,0, 0,1,0,0],  # Follows kick — syncopated, pulsing
    "style": "sustained",  # Dark, sustained synth bass (Doepfer / SH-101 style)
},

# ── SWING ────────────────────────────────────────────────────────────
"dark_wave": 7.0,  # Cold but not dead — imprecise drum machine, not funk

# ── VELOCITY ─────────────────────────────────────────────────────────
"dark_wave": {
    "base": 0.75,      # Controlled, gated
    "accent": 1.0,     # Accents hit hard
    "ghost": 0.35,     # Felt, not heard
    "variation": 0.06, # Slight — cold wave precision with a ghost of humanity
},

# ── STRUCTURES ───────────────────────────────────────────────────────
"dark_wave": {
    "sections": ["intro", "build", "main", "breakdown", "main", "outro"],
    "bars": [8, 8, 16, 8, 16, 8],
},
```

---

## Section Sound Mapping (for brief.json)

```json
{
    "sections": {
        "intro": ["pad", "hihat"],
        "build": ["pad", "bass", "hihat", "kick"],
        "main": ["kick", "snare", "hihat", "tom_low", "tom_high", "clap", "bass", "pad"],
        "breakdown": ["tom_low", "tom_high", "hihat", "pad"],
        "outro": ["pad", "hihat"]
    }
}
```

### Section-to-Pattern Mapping

| Section | Pattern Used | Notes |
|---------|-------------|-------|
| **intro** | Minimal / "Fog Machine" | Sparse kick, quarter-note hats, single snare on 4 |
| **build** | Minimal → Main transition | Intro pattern with bass entering, kick gaining syncopation |
| **main** | Main / "Ritüel" | Full kit — tribal toms, syncopated kick, driving 8th hats |
| **breakdown** | Breakdown / "Tribal Descent" | Toms only + ghost hats. The ritual. |
| **main (reprise)** | Main / "Ritüel" | Return with fill transition. Full intensity. |
| **outro** | Minimal / "Fog Machine" | Strip back to intro sparseness. Fade. |

---

*Created for AdaResearch procedural audio system — Dark Wave / Cold Wave soundbank*
*BPM: 118 | Swing: 7% | Humanize: 4ms | Velocity profile: cold_wave*
