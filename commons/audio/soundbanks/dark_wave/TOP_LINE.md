# Dark Wave / Cold Wave — Top Line Specification

**Genre:** Dark Wave / Cold Wave
**Key:** D minor (D3 = MIDI 50)
**BPM:** 118
**Scale:** D Natural Minor — D E F G A Bb C (with occasional Phrygian borrowing: Eb)
**Reference Artists:** She Past Away, Boy Harsher, Lebanon Hanover, Bauhaus, Siouxsie and the Banshees, Clan of Xymox

---

## Scale Reference — MIDI Note Map

```
D  Natural Minor: D  E  F  G  A  Bb C
Semitones:        0  2  3  5  7  8  10
MIDI (octave 3):  50 52 53 55 57 58 60
MIDI (octave 4):  62 64 65 67 69 70 72
MIDI (octave 5):  74 76 77 79 81 82 84

Phrygian borrowing: Eb (MIDI 51/63/75) replaces E (MIDI 52/64/76) for extra darkness
```

---

## 1. Main Chord Progression (A-Section / Verse)

### `i → v → VI → v` — **Dm → Am → Bb → Am**

**Harmonic rhythm:** 1 chord per bar (4 bars = 1 cycle)

| Bar | Chord | Roman | Notes | MIDI (octave 3) | Scale Degrees |
|-----|-------|-------|-------|-----------------|---------------|
| 1 | Dm | i | D F A | 50 53 57 | 0 2 4 |
| 2 | Am | v | A C E | 57 60 64 | 4 6 1* |
| 3 | Bb | VI | Bb D F | 58 62 65 | 5 0 2 |
| 4 | Am | v | A C E | 57 60 64 | 4 6 1* |

*\*E natural (MIDI 64) is diatonic to D natural minor — the v chord (Am) is naturally minor.*

**Voicing (recommended for pad/synth strings):**

```
Bar 1 — Dm:   D3(50)  F3(53)  A3(57)  D4(62)
Bar 2 — Am:   A2(45)  C3(48)  E3(52)  A3(57)
Bar 3 — Bb:   Bb2(46) D3(50)  F3(53)  Bb3(58)
Bar 4 — Am:   A2(45)  C3(48)  E3(52)  A3(57)
```

**GDScript scale degree indices:** `[0, 4, 5, 4]`

### Why this works:
- **Dm → Am** — Moving to the minor dominant (v, not V) avoids the leading tone resolution. The progression *sinks* instead of resolving. She Past Away's "Ritüel" lives here.
- **Am → Bb** — A half-step root movement (A→Bb) creates the quintessential cold wave chill. This semitone shift is the sound of dread.
- **Bb → Am** — Returns via the same half-step but descending. The progression oscillates between Am and Bb like a pendulum that never reaches home. Dm is stated once and then *abandoned*.
- **No resolution to Dm at the end** — The cycle restarts on Dm creating an eternal loop of tension. The listener is always being pulled forward.

---

## 2. Alternative / B-Section Progression

### `VI → VII → i → i` — **Bb → C → Dm → Dm**

| Bar | Chord | Roman | Notes | MIDI (octave 3) | Scale Degrees |
|-----|-------|-------|-------|-----------------|---------------|
| 1 | Bb | VI | Bb D F | 58 62 65 | 5 0 2 |
| 2 | C (no 3rd) | VII | C G | 60 67 | 6 3 |
| 3 | Dm | i | D F A | 50 53 57 | 0 2 4 |
| 4 | Dm | i | D F A | 50 53 57 | 0 2 4 |

**Voicing:**

```
Bar 1 — Bb:       Bb2(46) F3(53)  Bb3(58) D4(62)
Bar 2 — C5 (no3): C3(48)  G3(55)  C4(60)  G4(67)
Bar 3 — Dm:       D3(50)  A3(57)  D4(62)  F4(65)
Bar 4 — Dm:       D3(50)  A3(57)  D4(62)  F4(65)
```

**GDScript scale degree indices:** `[5, 6, 0, 0]`

### Why this works:
- **Bb → C → Dm** is the classic Aeolian cadence (VI → VII → i), the backbone of goth rock since Bauhaus. It approaches the tonic from below via whole step — blunt, forceful, inevitable.
- **C is played as a power chord (no 3rd)** — Avoids the major third (E) which would momentarily brighten the harmony. The open fifth keeps it cold and ambiguous.
- **Two bars of Dm** — The tonic is finally allowed to breathe, but only briefly. This gives the B-section a sense of arrival that the A-section deliberately withholds. Clan of Xymox uses this exact emotional arc in "A Day" and "Jasmine and Rose."
- **Contrast with A-section:** A never resolves; B resolves but with weight. The toggle between unresolved and resolved sections creates a hypnotic push-pull.

---

## 3. Bass Line Pattern (16-Step Grid)

### A-Section Bass (follows Dm → Am → Bb → Am)

All notes are root notes of the current chord, played in octave 1-2 range for maximum sub weight.

```
Step:  | 1  2  3  4 | 5  6  7  8 | 9  10 11 12 | 13 14 15 16 |
       |beat1       |beat2       |beat3        |beat4        |

Bar 1 (Dm):
Note:  | D2 .  .  . | .  .  .  . | D2 .  .  .  | .  .  D3 .  |
MIDI:  | 38 -  -  - | -  -  -  - | 38 -  -  -  | -  -  50 -  |
Grid:  | 1  0  0  0 | 0  0  0  0 | 1  0  0  0  | 0  0  1  0  |

Bar 2 (Am):
Note:  | A1 .  .  . | .  .  .  . | A1 .  .  .  | .  .  A2 .  |
MIDI:  | 33 -  -  - | -  -  -  - | 33 -  -  -  | -  -  45 -  |
Grid:  | 1  0  0  0 | 0  0  0  0 | 1  0  0  0  | 0  0  1  0  |

Bar 3 (Bb):
Note:  | Bb1.  .  . | .  .  .  . | Bb1.  .  .  | .  .  Bb2.  |
MIDI:  | 34 -  -  - | -  -  -  - | 34 -  -  -  | -  -  46 -  |
Grid:  | 1  0  0  0 | 0  0  0  0 | 1  0  0  0  | 0  0  1  0  |

Bar 4 (Am):
Note:  | A1 .  .  . | .  .  .  . | A1 .  .  .  | .  .  A2 .  |
MIDI:  | 33 -  -  - | -  -  -  - | 33 -  -  -  | -  -  45 -  |
Grid:  | 1  0  0  0 | 0  0  0  0 | 1  0  0  0  | 0  0  1  0  |
```

**Canonical bass pattern (single bar):**
```
[1, 0, 0, 0,  0, 0, 0, 0,  1, 0, 0, 0,  0, 0, 1, 0]
```

- Hits on steps 1, 9, 15 — beat 1, beat 3, and the "& of 4" (anticipation)
- Step 15 is the octave jump — one octave up, creates the classic dark wave bass "kick"
- This mirrors She Past Away's "Kasvetli Kutlama" bass pattern almost exactly
- The step-15 anticipation note pulls the ear forward into the next bar — creates momentum without complexity

### B-Section Bass (follows Bb → C → Dm → Dm)

```
Canonical B-section pattern (single bar):
[1, 0, 0, 0,  1, 0, 0, 0,  1, 0, 0, 0,  1, 0, 0, 0]
```

- Straight quarter notes — more driving, urgent
- When B-section hits, the bass locks to 4-on-the-floor with the kick
- This contrast from the syncopated A-section bass creates a physical lift

---

## 4. Arp Pattern (16th Note Sequence)

### Monotone Cycling Arpeggio — Locked to Current Chord

The arp cycles through chord tones in 16th notes (every step of the 16-step grid). It never stops. It is the heartbeat.

**Pattern type:** Up → Down → Up (triangle), cycling through root-3rd-5th-octave

```
For Dm (D F A):
Step:  | 1   2   3   4  | 5   6   7   8  | 9   10  11  12 | 13  14  15  16 |
Note:  | D4  F4  A4  D5 | A4  F4  D4  F4 | A4  D5  A4  F4 | D4  F4  A4  D5 |
MIDI:  | 62  65  69  74 | 69  65  62  65 | 69  74  69  65 | 62  65  69  74 |
Grid:  | 1   1   1   1  | 1   1   1   1  | 1   1   1   1  | 1   1   1   1  |

For Am (A C E):
Step:  | 1   2   3   4  | 5   6   7   8  | 9   10  11  12 | 13  14  15  16 |
Note:  | A3  C4  E4  A4 | E4  C4  A3  C4 | E4  A4  E4  C4 | A3  C4  E4  A4 |
MIDI:  | 57  60  64  69 | 64  60  57  60 | 64  69  64  60 | 57  60  64  69 |

For Bb (Bb D F):
Step:  | 1   2   3   4  | 5   6   7   8  | 9   10  11  12 | 13  14  15  16 |
Note:  | Bb3 D4  F4  Bb4| F4  D4  Bb3 D4 | F4  Bb4 F4  D4 | Bb3 D4  F4  Bb4|
MIDI:  | 58  62  65  70 | 65  62  58  62 | 65  70  65  62 | 58  62  65  70 |
```

**Arp interval pattern (generic, index into chord array):**
```
[0, 1, 2, 3, 2, 1, 0, 1, 2, 3, 2, 1, 0, 1, 2, 3]
where: 0=root, 1=3rd, 2=5th, 3=octave
```

**Character notes:**
- Constant 16th notes at 118 BPM = 7.87 notes per second — fast enough to blur into texture
- Triangle pattern (up-down) creates a hypnotic wave motion — think Clan of Xymox "A Day"
- The arp should be **filtered** — low-pass around 2-4 kHz with slight resonance, creating that characteristic dark wave "shimmer under glass" sound
- No velocity variation — machine-like, cold, relentless
- **Sound:** Saw wave through low-pass filter with moderate resonance. Think Juno-106 or SH-101.

---

## 5. Lead Melody — Main Section (Chorus/Hook)

### "The Haunting" — Sparse, Vocal-Range Melody

The lead appears **only in the main/chorus section**. It uses narrow intervals (minor 2nds, minor 3rds) and lots of space. The silence between notes is as important as the notes themselves.

**Plays over A-section progression: Dm → Am → Bb → Am**

```
4-bar phrase (one full progression cycle):

Bar 1 (over Dm):
Step:  | 1   2   3   4  | 5   6   7   8  | 9   10  11  12 | 13  14  15  16 |
Note:  | D5  .   .   .  | .   .   .   .  | F5  .   .   E5 | .   .   .   .  |
MIDI:  | 74  -   -   -  | -   -   -   -  | 77  -   -   76 | -   -   -   -  |
Dur:   | ---- 8th note -|--- rest -------|-- 8th - 8th ---|---- rest ------|

Bar 2 (over Am):
Step:  | 1   2   3   4  | 5   6   7   8  | 9   10  11  12 | 13  14  15  16 |
Note:  | .   .   .   .  | .   .   .   .  | A4  .   .   .  | .   .   .   .  |
MIDI:  | -   -   -   -  | -   -   -   -  | 69  -   -   -  | -   -   -   -  |
Dur:   |---- rest ------|---- rest -------|- dotted quarter|---- rest ------|

Bar 3 (over Bb):
Step:  | 1   2   3   4  | 5   6   7   8  | 9   10  11  12 | 13  14  15  16 |
Note:  | Bb4 .   .   .  | .   .   A4  .  | .   .   .   .  | .   .   .   .  |
MIDI:  | 70  -   -   -  | -   -   69  -  | -   -   -   -  | -   -   -   -  |
Dur:   |---- dotted qtr-|------- 8th ----|---- rest ------|---- rest ------|

Bar 4 (over Am):
Step:  | 1   2   3   4  | 5   6   7   8  | 9   10  11  12 | 13  14  15  16 |
Note:  | .   .   .   .  | .   .   .   .  | .   .   .   .  | .   .   .   .  |
MIDI:  | -   -   -   -  | -   -   -   -  | -   -   -   -  | -   -   -   -  |
Dur:   |----------- complete silence — let the arp and space breathe ------|
```

**Melody summary (only the sounding notes):**

```
D5 → F5 → E5 → (rest) → A4 → (rest) → Bb4 → A4 → (silence)
74    77    76             69              70     69
```

**Interval analysis:**
- D5→F5: **minor 3rd up** (3 semitones) — the core dark interval
- F5→E5: **minor 2nd down** (1 semitone) — chromatic creep, unsettling
- E5→A4: **perfect 5th down** (7 semitones) — a drop into emptiness
- A4→Bb4: **minor 2nd up** (1 semitone) — the Phrygian touch, maximum dread
- Bb4→A4: **minor 2nd down** (1 semitone) — oscillating on the half-step, trapped

### Alternative Melody (Variation for 2nd Pass)

```
D5 → Eb5 → D5 → (rest) → C5 → (rest) → A4 → (rest) → (silence)
74    75     74             72              69
```

- Uses the **Phrygian Eb** (MIDI 75) for maximum darkness
- D→Eb→D is a classic Siouxsie melodic ornament — the note bends up a half-step and falls back
- Narrower range, more claustrophobic — suits a second verse or pre-chorus

### Character notes:
- **7 notes in 4 bars.** That's it. Dark wave melody is about absence.
- The melody hangs in octave 4-5 (vocal range: mezzo-soprano/baritone overlap)
- **No note lands on beat 1 of bar 2 or bar 4** — the melody breathes with the chord changes, not against them
- Bar 4 is completely empty — this is the "exhale," the void that Boy Harsher's "Pain" uses so effectively
- **Sound:** Square wave or narrow pulse with slow attack (50-80ms), moderate release (300ms), through chorus and delay (dotted 8th). The lead should feel like it's emerging from fog.

---

## 6. Harmonic Analysis — Why These Choices Work for Dark Wave

### The Emotional Architecture

Dark wave harmony is built on **three principles**:

#### Principle 1: Avoid Resolution

Traditional Western music creates tension (dominant) and resolves it (tonic). Dark wave **refuses to resolve**. The main progression Dm → Am → Bb → Am never provides a satisfying V → i cadence. The listener is held in permanent suspension — the musical equivalent of a held breath.

- The **v chord (Am)** is used instead of V (A major). In classical harmony, the raised 7th (C#) in A major would create a leading tone that pulls to D. By keeping C natural, the pull is weakened. The progression floats instead of landing.
- **Bb (VI)** is the "weight" — the lowest root note in the progression, sitting a half-step above A. This half-step relationship (A↔Bb) is the engine of unease.

#### Principle 2: Minimal Movement, Maximum Repetition

Dark wave is hypnotic music. She Past Away's "Kasvetli Kutlama" uses **two chords for the entire track.** Lebanon Hanover's "Gallowdance" barely moves harmonically. The genre trusts repetition to create trance states.

- Our A-section uses only **3 unique chords** (Dm, Am, Bb), with Am appearing twice
- The B-section introduces C but only as a passing chord (power chord, no third)
- Root movement is small: D→A (P5), A→Bb (m2), Bb→A (m2) — the progression barely moves

#### Principle 3: The Cold Intervals

The intervals that define dark wave's harmonic color:

| Interval | Semitones | Where It Appears | Effect |
|----------|-----------|-------------------|--------|
| **Minor 2nd** | 1 | A↔Bb root movement, melody (F→E, A→Bb) | Dread, claustrophobia |
| **Minor 3rd** | 3 | All minor chords, melody (D→F) | Sadness without sentimentality |
| **Perfect 5th** | 7 | Power chords, bass octaves | Hollow, medieval, cold |
| **Minor 7th** | 10 | Implied in chord extensions | Unresolved, floating |

The **minor 2nd** is the signature interval. It appears:
- Between Am and Bb (the chord roots oscillate by half-step)
- In the arp pattern when transitioning between chords (the 5th of Am [E] to the root of Bb — one semitone)
- In the lead melody (F→E, A→Bb)

This saturation of half-steps at every structural level creates a unified harmonic vocabulary of tension.

#### Principle 4: The Phrygian Shadow

The Phrygian mode (1 b2 b3 4 5 b6 b7) is the darkest of the common modes. We don't commit to full Phrygian (which would change the scale), but we **borrow its most distinctive note: the flat 2nd (Eb)**.

- In D Phrygian: D **Eb** F G A Bb C
- In D Natural Minor: D **E** F G A Bb C

By occasionally substituting Eb for E (MIDI 63/75 instead of 64/76), we access the "exotic darkness" of Phrygian without losing the natural minor foundation. This is used:
- In the alternative lead melody (D→Eb→D ornament)
- As an optional passing tone in the arp (E→Eb chromatic descent)
- In bass fills (rare, for transitions only)

Bauhaus used this technique extensively — "Bela Lugosi's Dead" hovers between natural minor and Phrygian throughout.

### Key/Scale Justification

**D minor** is the traditional key of darkness in Western music:
- Mozart's Requiem (K. 626) — D minor
- Beethoven's "Tempest" Sonata — D minor  
- Bach's Toccata and Fugue — D minor
- She Past Away's "Ritüel" — D minor
- Boy Harsher's "Pain" — D minor (approximately, depending on tuning)

At concert pitch (A=440Hz), D minor places the tonic at 293.66 Hz — a frequency that sits in the lower-mid vocal range, giving the key a "chest voice" quality that feels physically present and heavy.

### Tempo Justification

**118 BPM** is the sweet spot for dark wave:
- Slow enough to feel deliberate and heavy (not frantic like EBM at 130+)
- Fast enough to maintain a driving pulse (not ambient/shoegaze at 90-100)
- 16th notes at 118 BPM = ~7.87 Hz, which sits in the **theta-alpha brainwave boundary** — associated with meditative/trance states
- Most She Past Away tracks sit at 115-122 BPM
- Boy Harsher tends toward 110-120 BPM

---

## Summary for Implementation

### For `SoundbankGenerator.gd`:

**Progression (A-section):**
```gdscript
"dark_wave":
    return [0, 4, 5, 4]  # i - v - VI - v (Dm - Am - Bb - Am)
```

**Alt progression (B-section) — if multi-progression support exists:**
```gdscript
# B-section: [5, 6, 0, 0]  # VI - VII - i - i (Bb - C - Dm - Dm)
```

**Bass pattern:**
```gdscript
"dark_wave": {
    "pattern": [1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0],
    "style": "sustained",
}
```

**Drum pattern:**
```gdscript
"dark_wave": {
    "kick":  [1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0],  # 4-on-floor, relentless
    "snare": [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0],  # 2 and 4
    "hihat": [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0],  # 8ths, mechanical
    "arp":   [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],  # 16ths, never stops
}
```

**Swing:** `"dark_wave": 0.0` — Machine straight. No humanity.

**Velocity:**
```gdscript
"dark_wave": {
    "base": 0.75,
    "accent": 1.0,
    "ghost": 0.0,     # No ghost notes. Every hit is intentional.
    "variation": 0.05, # Almost none. Cold precision.
}
```

**Structure:**
```gdscript
"dark_wave": {
    "sections": ["intro", "verse", "chorus", "verse", "chorus", "breakdown", "chorus", "outro"],
    "bars": [8, 8, 8, 8, 8, 4, 8, 8],
}
```

### For `brief.json`:

```json
{
  "meta": {
    "id": "dark_wave",
    "name": "Dark Wave",
    "lineage": "She Past Away, Boy Harsher, Lebanon Hanover, Bauhaus, Siouxsie, Clan of Xymox",
    "era": "1979-present (post-punk/goth revival)",
    "bpm": { "min": 110, "max": 125, "typical": 118 },
    "lambda": 0.25
  },
  "identity": {
    "token": "Monotone 16th arp + driving bass + sparse haunting lead + 4-on-floor",
    "two_second_test": "Cold arpeggio, heavy kick, reverberant space — it's 2AM in an Eastern European club",
    "emotional_truth": "Beautiful despair. The romance of darkness. Dancing alone in a crowd."
  },
  "soundbank": ["kick", "snare", "hihat", "bass", "pad", "arp", "lead"],
  "forbidden": [
    "major_chords",
    "bright_supersaws",
    "uplifting_progressions",
    "swing",
    "humanization",
    "happy_arpeggios",
    "gated_reverb_snare",
    "vinyl_crackle"
  ],
  "rhythm": {
    "quantize": "strict",
    "humanize_ms": 0,
    "swing_pct": 0
  },
  "harmony": {
    "scales": ["minor", "phrygian"],
    "voicings": "cold_open_fifths"
  },
  "fx": {
    "sidechain": false,
    "reverb_style": "large_hall",
    "chorus": true,
    "delay_style": "dotted_eighth"
  },
  "transitions": {
    "crossfade_s": 3.0
  },
  "sections": {
    "intro": ["pad", "arp"],
    "verse": ["kick", "hihat", "bass", "arp", "pad"],
    "chorus": ["kick", "snare", "hihat", "bass", "arp", "pad", "lead"],
    "breakdown": ["pad", "arp"],
    "outro": ["pad"]
  }
}
```

### Layer Descriptions (for `_get_layers_for_song()`):

```gdscript
"dark_wave":
    return {
        "intro": [
            {"name": "Cold Pad", "type": "pad", "params": "saw × 3 | detune ±5¢ | LP 1.2kHz | large hall reverb"},
            {"name": "Arp", "type": "arp", "params": "saw | LP 3kHz Q=0.4 | 16th notes | triangle pattern"},
        ],
        "verse": [
            {"name": "Kick", "type": "drums", "params": "4-on-floor | tight 808-style | 50Hz fundamental"},
            {"name": "Hi-Hat", "type": "drums", "params": "8ths | mechanical | no variation"},
            {"name": "Bass", "type": "bass", "params": "saw + sub | root notes | octave jump step 15"},
            {"name": "Arp", "type": "arp", "params": "16th note chord tones | triangle cycle | filtered"},
            {"name": "Pad", "type": "pad", "params": "sustained minor chords | slow attack 200ms"},
        ],
        "chorus": [
            {"name": "Kick", "type": "drums", "params": "4-on-floor"},
            {"name": "Snare", "type": "drums", "params": "2 and 4 | tight | short reverb"},
            {"name": "Hi-Hat", "type": "drums", "params": "8ths mechanical"},
            {"name": "Bass", "type": "bass", "params": "driving root notes with octave anticipation"},
            {"name": "Arp", "type": "arp", "params": "16th triangle | slightly brighter filter (4kHz)"},
            {"name": "Pad", "type": "pad", "params": "wider voicing | add octave doubling"},
            {"name": "Lead", "type": "lead", "params": "square wave | attack 60ms | chorus + dotted 8th delay | sparse haunting melody"},
        ],
        "breakdown": [
            {"name": "Pad", "type": "pad", "params": "filtered down | long reverb tail"},
            {"name": "Arp", "type": "arp", "params": "filter sweep down to 800Hz | fading"},
        ],
        "default": [{"name": "Dark Wave", "type": "mix", "params": "118 BPM | Dm | cold wave"}]
    }
```

---

## Complete MIDI Note Reference Table

For copy-paste into any implementation:

```
=== CHORDS (all as MIDI arrays) ===

Dm  = [50, 53, 57]       or voiced: [50, 53, 57, 62]
Am  = [45, 48, 52] (inv) or voiced: [57, 60, 64, 69]
Bb  = [46, 50, 53] (inv) or voiced: [58, 62, 65, 70]
C5  = [48, 55]           or voiced: [60, 67]     (no third!)

=== BASS NOTES ===
D1=26  D2=38  D3=50
A1=33  A2=45  A3=57
Bb1=34 Bb2=46 Bb3=58
C2=36  C3=48

=== LEAD MELODY (main) ===
D5=74  Eb5=75  E5=76  F5=77  A4=69  Bb4=70  C5=72

=== ARP RANGE ===
Octave 3-4 (MIDI 50-74)
```

---

*Created by ada-top-liner for AdaResearch dark_wave soundbank*
*Scale: D Natural Minor with Phrygian borrowing | BPM: 118 | λ: 0.25*
