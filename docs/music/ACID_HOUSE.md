# Acid House — Genre Research

## Historical Context

**Birth:** Chicago, 1985-87. The story goes that DJ Pierre, Spanky, and Herb J (as **Phuture**) were messing with a cheap, secondhand Roland TB-303 Bass Line synthesizer — a machine designed to accompany solo guitarists, considered a commercial failure. They cranked the resonance, twisted the cutoff, and accidentally invented a new sound.

**"Acid Tracks"** (1987) was the first acid house record. 12 minutes of squelchy 303 over a drum machine. Ron Hardy played it at the Music Box in Chicago — initially people hated it, but Hardy kept playing it until the room converted.

**UK Explosion (1987-89):** Acid house crossed the Atlantic and merged with UK rave culture. The "Second Summer of Love" (1988) saw acid become the soundtrack to warehouse parties, Ecstasy culture, and a moral panic (tabloids: "EVIL OF ECSTASY").

**Key Artists:**
- **Phuture** — "Acid Tracks" (the genesis)
- **DJ Pierre** — continued 303 exploration
- **Adonis** — "No Way Back"
- **Marshall Jefferson** — production wizard
- **808 State** — UK acid ("Pacific State")
- **A Guy Called Gerald** — "Voodoo Ray"
- **Hardfloor** — German acid techno

---

## The Roland TB-303

The **303** is acid house. Understanding the machine = understanding the genre.

### What It Is
- **Monophonic** bass synthesizer (one note at a time)
- **Built-in sequencer** — 16-step patterns
- Single **sawtooth OR square** oscillator
- **18dB/octave lowpass filter** with resonance
- **Accent** and **Slide** per step

### The "Acid" Sound
The magic comes from:

1. **High resonance** — cranked near self-oscillation, the filter screams
2. **Filter envelope** — sharp attack, variable decay
3. **Accent** — boosts filter envelope AND volume on specific steps
4. **Slide (portamento)** — notes glide into each other
5. **Cutoff modulation** — sweeping the filter live

### 303 Parameters

| Parameter | Range | Acid Sweet Spot |
|-----------|-------|-----------------|
| **Cutoff** | 0-100% | 20-60% (leave room to sweep UP) |
| **Resonance** | 0-100% | 60-90% (near squealing) |
| **Env Mod** | 0-100% | 50-80% (filter follows notes) |
| **Decay** | 0-100% | 30-70% (depends on tempo) |
| **Accent** | on/off per step | Every 2-4 steps |
| **Slide** | on/off per step | Strategic — creates liquid movement |

### Programming Patterns

The 303 sequencer is notoriously difficult to program — which led to "happy accidents."

**Classic patterns:**
- **Repetitive root notes** with slides between octaves
- **Accent on offbeats** — creates syncopation
- **Rest steps** — silence makes the squeals hit harder
- **Octave jumps** — low → high → low

```
Step:  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16
Note:  C1 -- C1 C2 C1 -- C1 C1 C2 -- C1 C1 C1 C2 -- C1
Slide: -  -  -  X  -  -  -  -  X  -  -  -  -  X  -  -
Accnt: X  -  -  -  X  -  -  X  -  -  X  -  -  -  X  -
```

---

## Sound Design (GDScript Implementation)

```gdscript
# TB-303 style acid bass
class_name AcidBass

var cutoff: float = 400.0
var resonance: float = 0.8  # High!
var env_mod: float = 0.7
var decay: float = 0.3
var accent_amount: float = 0.5

var filter_state: Array = [0.0, 0.0, 0.0]  # 3-pole state
var current_freq: float = 110.0
var target_freq: float = 110.0
var slide_speed: float = 0.15

func process(t: float, note_on: bool, accent: bool, slide: bool) -> float:
    # Portamento (slide)
    if slide:
        current_freq = lerp(current_freq, target_freq, slide_speed)
    else:
        current_freq = target_freq
    
    # Oscillator (sawtooth for classic acid)
    var osc = fmod(t * current_freq, 1.0) * 2.0 - 1.0
    
    # Filter envelope
    var env_attack = 0.001  # Near instant
    var env = exp(-t * (1.0 / decay) * 10.0)
    
    # Accent boosts envelope
    var accent_mult = 1.0 + (accent_amount if accent else 0.0)
    
    # Calculate filter cutoff
    var filter_cutoff = cutoff + env * env_mod * 4000.0 * accent_mult
    filter_cutoff = clamp(filter_cutoff, 20.0, 20000.0)
    
    # 18dB resonant lowpass (3-pole)
    var output = tb303_filter(osc, filter_cutoff, resonance)
    
    # Accent also boosts volume
    var volume = 0.6 * accent_mult
    
    return output * volume * env

func tb303_filter(input: float, cutoff_hz: float, reso: float) -> float:
    # Attempt at 303-style 18dB/oct filter
    var f = cutoff_hz / 44100.0
    f = clamp(f * 2.0, 0.0, 0.99)
    
    var fb = reso + reso / (1.0 - f)  # Resonance feedback
    
    # 3-pole cascade
    filter_state[0] += f * (input - filter_state[0] + fb * (filter_state[0] - filter_state[2]))
    filter_state[1] += f * (filter_state[0] - filter_state[1])
    filter_state[2] += f * (filter_state[1] - filter_state[2])
    
    return filter_state[2]
```

---

## Drums

Acid house typically uses **TR-808** or **TR-909** drum machines.

| Element | Character | Notes |
|---------|-----------|-------|
| **Kick** | 808 or 909 | 4-on-floor, punchy |
| **Snare/Clap** | 808 clap or 909 snare | On 2 and 4 |
| **Hi-hats** | 808 or 909 | Open hat on offbeats, closed on 16ths |
| **Cowbell** | 808 | Optional, adds Chicago flavor |

**Pattern:** Simple 4/4, the 303 is the star

```
Kick:   X . . . X . . . X . . . X . . .
Clap:   . . . . X . . . . . . . X . . .
CHH:    X . X . X . X . X . X . X . X .
OHH:    . . . . . . X . . . . . . . X .
```

---

## Technical Parameters

| Parameter | Value | Notes |
|-----------|-------|-------|
| **BPM** | 118-130 | Classic range, 120-125 most common |
| **Key** | Often **no key** (single note) | Or minor (Am, Em, Dm) |
| **Time Signature** | 4/4 | Always |

---

## Arrangement

Acid tracks are often **long and hypnotic**:

1. **Intro** (16-32 bars) — drums build, 303 enters filtered down
2. **Main loop** (64+ bars) — 303 filter opens up, live tweaking
3. **Breakdown** (16-32 bars) — strip to 303 solo or pads
4. **Build** (16-32 bars) — drums return, filter sweep up
5. **Peak** (32-64 bars) — full energy, maximum squelch
6. **Outro** (16-32 bars) — filter closes, elements drop out

**Key principle:** The **filter is the performance**. Live tweaking of cutoff + resonance = the track's dynamics.

---

## Chord Progressions

Often **none** — acid house can be a single bass note for 8 minutes.

When harmony exists:
| Progression | Character |
|-------------|-----------|
| **Single note** | Pure hypnosis |
| Am - Am - Am - Am | Drone with movement |
| Am - G - Am - G | Minimal oscillation |
| i - VII | Two-chord trance |

---

## Reference Tracks

| Track | Artist | Year | Why Study It |
|-------|--------|------|--------------|
| **Acid Tracks** | Phuture | 1987 | The genesis. 12 minutes, one 303 pattern, infinite filter tweaks. Study the **restraint**. |
| **Can You Feel It** | Mr. Fingers | 1986 | Proto-acid. Warmer, more musical. Shows house + acid intersection. |
| **Voodoo Ray** | A Guy Called Gerald | 1988 | UK acid. Adds melody, samples, pads. More **song-like**. |
| **Pacific State** | 808 State | 1989 | Acid goes ambient. Saxophone (!), lush pads. Proved acid could be beautiful. |
| **Acperience 1** | Hardfloor | 1992 | German acid techno. Multiple 303s, relentless. The **wall of squelch** approach. |
| **Windowlicker** | Aphex Twin | 1999 | Post-acid. Shows where the sound went — complex, twisted, still 303-derived. |
| **Da Funk** | Daft Punk | 1995 | French filter house. 303 DNA in a different context. The filter IS the hook. |

---

## Subgenres & Evolution

- **Acid Techno** — harder, faster (130-145 BPM), German/UK
- **Acid Trance** — melodic layers over 303, longer builds
- **Nu-Acid** — modern revival (2010s+)
- **Acid breaks** — breakbeats + 303

---

## Key Takeaways for Implementation

1. **The 303 filter is everything** — resonance near self-oscillation, envelope modulation
2. **Slide + accent** — the articulation that makes patterns come alive
3. **Simple patterns** — complexity comes from filter movement, not notes
4. **4-on-floor foundation** — drums are steady, 303 is the chaos
5. **Live performance** — acid tracks are meant to be tweaked in real-time

---

*Research compiled for AdaResearch procedural audio system.*
