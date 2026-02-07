# Song Identities - Building Blocks & Research

Each song needs a distinct sonic identity based on genre-specific production techniques, historical context, and technical parameters.

---

## 1. Ambient Works (Aphex Twin - SAW85-92 Style)

### Historical Context
*Selected Ambient Works 85-92* (1992) was recorded on cassette 4-track between ages 14-21. Lo-fi by necessity, warm by aesthetic choice. The album bridges acid house energy with Brian Eno's ambient philosophy.

### Core Identity
**Emotion:** Nostalgic, dreamlike, melancholic warmth
**Era:** Late 80s bedroom production
**Character:** Tape-degraded, intimate, haunted

### Technical Parameters
| Parameter | Value | Notes |
|-----------|-------|-------|
| **BPM** | 85-100 | Slow, contemplative groove |
| **Key** | Minor keys (Am, Em, Dm) | Melancholic, introspective |
| **Time Signature** | 4/4 | Occasionally 6/8 for dreamier tracks |

### Sound Design Elements

#### Pads (Primary Texture)
- **Oscillators:** 2-3 detuned saws (±5-15 cents)
- **Filter:** Low-pass at 800-1500Hz, slow LFO modulation (0.05-0.2Hz)
- **Character:** Warm, wooly, slightly unstable
- **Effects:** Long reverb (3-5s decay), subtle chorus

```gdscript
# SAW85-style warm pad
func ambient_pad(t: float, freq: float) -> float:
    var detune = [0.985, 1.0, 1.015]
    var output = 0.0
    for d in detune:
        output += sawtooth(freq * d * t)
    output /= 3.0
    
    # Tape-style drift
    var drift = sin(t * 0.1) * 0.003
    output *= (1.0 + drift)
    
    # Warm lowpass with slow modulation
    var cutoff = 1200.0 + sin(t * 0.15) * 400.0
    return lowpass(output, cutoff) * 0.4
```

#### Drums (Lo-fi Breakbeats)
- **Source:** Sampled breakbeats, heavily processed
- **Processing:** Bitcrushing (8-12 bit), tape saturation
- **Pattern:** Shuffled, humanized, often half-time feel
- **Key sounds:** 
  - Kick: Muffled, warm (60-80Hz body)
  - Snare: Crackly, compressed
  - Hats: Rolled off highs, tape hiss blended

```gdscript
# Lo-fi drum parameters
var breakbeat_settings = {
    "bit_depth": 10,
    "sample_rate_reduction": 0.7,  # Simulate lower sample rate
    "tape_saturation": 0.3,
    "high_shelf_cut": -6.0,  # dB at 8kHz
    "shuffle": 0.15  # Swing amount
}
```

#### Bass (Acid-Influenced)
- **Type:** TB-303 or Moog-style monosynth
- **Pattern:** Simple 8th notes, occasional slides
- **Filter:** Resonant lowpass, envelope-controlled
- **Resonance:** Moderate (0.4-0.6), not aggressive

#### Melodic Elements
- **Style:** Simple, repetitive phrases (2-4 notes)
- **Timbre:** Detuned pulse waves, gentle attack
- **Processing:** Heavy reverb, delay (dotted 8th)

### Chord Progressions
| Progression | Character |
|-------------|-----------|
| Am - G - F - E | Classic minor descent |
| Em - C - G - D | Hopeful melancholy |
| Dm - Am - Em - Am | Circular, hypnotic |
| i - VI - III - VII | Natural minor flow |

### Arrangement
- **Structure:** Loose, evolving (no strict verse/chorus)
- **Duration:** 4-8 minutes
- **Development:** Gradual layering, filter sweeps as transitions
- **Dynamics:** Subtle, tape compression levels everything

### Reference Tracks
- "Xtal" - Dreamy pads, breakbeat, melancholic
- "Pulsewidth" - Hypnotic bass, minimal changes
- "Ageispolis" - Bright acid line over warm pads

---

## 2. Detroit Techno (Juan Atkins, Derrick May, Kevin Saunderson)

### Historical Context
Born in Detroit 1985-88. "The Belleville Three" (Atkins, May, Saunderson) created a sound mixing Kraftwerk's machine music with Parliament-Funkadelic's soul. Dystopian optimism - machines as liberation.

### Core Identity
**Emotion:** Cold but soulful, futuristic longing
**Era:** Mid-to-late 1980s
**Character:** Machine precision with human feeling

### Technical Parameters
| Parameter | Value | Notes |
|-----------|-------|-------|
| **BPM** | 120-130 | Steady, driving 4/4 |
| **Key** | Minor (Cm, Gm, Dm) | Melancholic futurism |
| **Time Signature** | 4/4 | Rigid, unwavering |

### Sound Design Elements

#### Drums (TR-909 Foundation)
- **Kick:** Punchy 909 (100-150Hz thump, 50Hz sub)
- **Snare:** Crisp 909, slightly reverbed
- **Hi-hats:** Open/closed 909, rides for texture
- **Claps:** Layered with snare on 2 and 4

```gdscript
# 909-style kick
func detroit_kick(t: float) -> float:
    var pitch_env = exp(-t * 40.0)
    var freq = 50.0 + pitch_env * 100.0
    var body = sin(2.0 * PI * freq * t) * exp(-t * 10.0)
    var click = sin(2.0 * PI * 3000.0 * t) * exp(-t * 200.0)
    return body * 0.8 + click * 0.2
```

#### Strings/Pads (Emotional Core)
- **Source:** Roland Juno-106, JP-8
- **Character:** Lush, detuned, melancholic
- **Processing:** Chorus, slow filter movement
- **Role:** Provides the "soul" against machine rhythm

```gdscript
# Detroit string pad
func detroit_strings(t: float, chord: Array) -> float:
    var output = 0.0
    for midi in chord:
        var freq = midi_to_freq(midi)
        # PWM for movement
        var pw = 0.3 + sin(t * 0.5) * 0.15
        var pulse = pulse_wave(freq * t, pw)
        output += lowpass(pulse, 2000.0)
    return output / chord.size() * juno_chorus(t)
```

#### Bass
- **Type:** Synth bass, often Minimoog-style
- **Pattern:** Hypnotic, repetitive (1-2 notes)
- **Character:** Warm, round, supportive (not aggressive)

#### Leads/Stabs
- **Type:** Sharp, FM-style bells or filtered squares
- **Usage:** Sparse, punctuation rather than melody
- **Processing:** Reverb, delay

### Chord Progressions
| Progression | Character |
|-------------|-----------|
| Cm - Ab - Eb - Bb | Epic, cinematic |
| Gm - Eb - Bb - F | Hopeful minor |
| Dm - Am - G - F | Introspective |
| i - VI - VII - i | Circular progression |

### Arrangement
- **Structure:** 8-16 bar loops with gradual evolution
- **Builds:** Filter sweeps, element addition/subtraction
- **Breakdowns:** Strip to kick + pads, rebuild
- **Duration:** 6-10 minutes (DJ-friendly)

### Reference Tracks
- Juan Atkins "No UFOs" - Electro-techno blueprint
- Derrick May "Strings of Life" - Emotional strings + 909
- Kevin Saunderson "Big Fun" - Soulful vocal techno

---

## 3. Moroder Disco (Giorgio Moroder - "I Feel Love" Style)

### Historical Context
1977's "I Feel Love" (Donna Summer) was the first entirely synthesized disco record. The sequencer as motor. The synth as sexual pulse. Changed everything.

### Core Identity
**Emotion:** Hypnotic ecstasy, mechanical desire
**Era:** Late 1970s Munich
**Character:** Repetitive, pulsing, relentless

### Technical Parameters
| Parameter | Value | Notes |
|-----------|-------|-------|
| **BPM** | 120-130 | 4-on-floor, unwavering |
| **Key** | Major or Mixolydian | Euphoric, bright |
| **Time Signature** | 4/4 | Machine precision |

### Sound Design Elements

#### The Sequencer Line (Signature)
- **Pattern:** 16th notes, constant motion
- **Waveform:** Filtered sawtooth
- **Filter:** Resonant lowpass, slight envelope
- **Character:** Hypnotic, motorik

```gdscript
# Moroder 16th-note sequencer
func moroder_sequence(t: float, bpm: float, root: int) -> float:
    var step_dur = 60.0 / bpm / 4.0
    var step = int(t / step_dur) % 16
    
    # Arpeggio pattern (root, 3rd, 5th, octave)
    var pattern = [0, 4, 7, 12, 7, 4, 0, 4, 7, 12, 7, 4, 0, 4, 7, 12]
    var midi = root + pattern[step]
    var freq = midi_to_freq(midi)
    
    var saw = sawtooth(freq * t)
    var env = exp(-fmod(t, step_dur) / step_dur * 4.0)
    var cutoff = 600.0 + env * 1500.0
    
    return lowpass_resonant(saw, cutoff, 0.5) * env
```

#### Kick
- **Style:** 4-on-floor, every beat
- **Character:** Punchy but not overpowering
- **Frequency:** 60-80Hz fundamental

#### Bass
- **Pattern:** Follows sequencer root notes
- **Waveform:** Simple sine or filtered saw
- **Role:** Foundation, not featured

#### Pads
- **Character:** Spacey, floating above the pulse
- **Processing:** Long reverb, chorus
- **Movement:** Slow filter sweeps

### Chord Progressions
| Progression | Character |
|-------------|-----------|
| I - I - I - I | Pure hypnosis (single chord) |
| I - IV - I - IV | Simple movement |
| I - V - vi - IV | Pop euphoria |
| I - bVII - IV - I | Mixolydian drive |

### Arrangement
- **Structure:** Long builds (32-64 bars)
- **Principle:** Minimal harmonic change, maximal repetition
- **Dynamics:** Filter automation, element drops
- **Duration:** 8-15 minutes

### Reference Tracks
- "I Feel Love" - The blueprint
- "From Here to Eternity" - Driving pulse
- "Chase" - Cinematic tension

---

## 4. Pop Generative (Modern Pop Production)

### Historical Context
Contemporary pop production (2010s-present) combines digital precision with emotional hooks. Max Martin, Jack Antonoff, Finneas aesthetics. Structure is king.

### Core Identity
**Emotion:** Immediate, emotional, catchy
**Era:** 2010s-present
**Character:** Polished, dynamic, hook-driven

### Technical Parameters
| Parameter | Value | Notes |
|-----------|-------|-------|
| **BPM** | 100-128 | Varies by sub-genre |
| **Key** | Major/minor, often relative | Emotional flexibility |
| **Time Signature** | 4/4 | Standard |

### Sound Design Elements

#### Drums
- **Kick:** Punchy, sidechained (ducking elements)
- **Snare:** Layered (acoustic + clap + snap)
- **Hats:** Crisp, programmed
- **Production:** Parallel compression

```gdscript
# Modern pop drum mix
func pop_drums(kick: float, snare: float, hat: float) -> float:
    var sidechain = calculate_sidechain(kick)
    
    # Layer snare with clap
    var snare_layer = snare * 0.7 + clap_sample() * 0.3
    
    return kick + snare_layer * sidechain + hat * sidechain * 0.6
```

#### Synths
- **Pads:** Lush, wide, often Serum/Massive
- **Bass:** Sine sub + mid-layer (separate)
- **Leads:** Supersaw for energy, bells for hooks

#### Piano/Keys
- **Role:** Emotional anchor
- **Style:** Intimate, close-mic'd
- **Processing:** Gentle compression, subtle verb

### Song Structure (Critical)
| Section | Bars | Character |
|---------|------|-----------|
| Intro | 4-8 | Sparse, hook hint |
| Verse 1 | 8-16 | Minimal, vocal focus |
| Pre-Chorus | 4-8 | Build tension |
| Chorus | 8-16 | Full energy, hook |
| Verse 2 | 8-16 | Added elements |
| Pre-Chorus | 4-8 | Bigger build |
| Chorus | 8-16 | Repeat with variations |
| Bridge | 8 | Different, breakdown |
| Final Chorus | 8-16 | Maximum energy |
| Outro | 4-8 | Hook repetition, fade |

### Chord Progressions
| Progression | Character |
|-------------|-----------|
| I - V - vi - IV | "Axis of Awesome" (most pop songs) |
| vi - IV - I - V | Emotional, minor start |
| I - IV - vi - V | Bright, hopeful |
| i - VI - III - VII | Minor pop anthem |

### Arrangement Principles
- **Sidechain compression:** Everything ducks to kick
- **Build-drop dynamics:** Pre-chorus → chorus energy shift
- **White noise risers:** Tension builders
- **Impacts:** Big hits on downbeats after drops

### Reference Tracks
- Billie Eilish "bad guy" - Minimal, punchy
- The Weeknd "Blinding Lights" - Synthwave-pop fusion
- Dua Lipa "Don't Start Now" - Disco-pop energy

---

## 5. 70s Prog Synth (ELP, Yes, Kraftwerk, Pink Floyd)

### Historical Context
1969-1979: The synthesizer as virtuoso instrument. Keith Emerson, Rick Wakeman, Klaus Schulze pushed the Moog as lead voice. Kraftwerk stripped it to motorik essence.

### Core Identity
**Emotion:** Epic, cerebral, exploratory
**Era:** Early-to-mid 1970s
**Character:** Virtuosic or minimal (two schools)

### Technical Parameters
| Parameter | Value | Notes |
|-----------|-------|-------|
| **BPM** | 80-140 | Varied (prog = tempo changes) |
| **Key** | Any, often modal | Dorian, Mixolydian common |
| **Time Signature** | 4/4, 7/8, 6/8, 5/4 | Odd meters are prog trademark |

### Sound Design Elements

#### The Minimoog Lead (ELP/Wakeman Style)
- **Oscillators:** 2-3 sawtooths, slightly detuned
- **Filter:** 24dB lowpass, high resonance (0.6-0.8)
- **Portamento:** ESSENTIAL - notes glide into each other
- **Expression:** Pitch wheel bends, filter sweeps

```gdscript
# Prog Moog lead with portamento
class ProgMoogLead:
    var current_freq: float = 440.0
    var target_freq: float = 440.0
    var glide_speed: float = 0.1
    
    func process(t: float) -> float:
        # Portamento
        current_freq = lerp(current_freq, target_freq, glide_speed)
        
        # Three oscillators
        var saw1 = sawtooth(current_freq * t)
        var saw2 = sawtooth(current_freq * 1.005 * t)
        var saw3 = sawtooth(current_freq * 0.5 * t)  # Sub
        
        var mix = saw1 * 0.4 + saw2 * 0.4 + saw3 * 0.3
        
        # Resonant filter with vibrato-controlled cutoff
        var vibrato = sin(t * 5.0) * 0.03
        var cutoff = 1500.0 + sin(t * 0.5) * 500.0
        
        return moog_filter_24db(mix, cutoff, 0.7)
```

#### The Motorik Beat (Kraftwerk)
- **Pattern:** Steady, unwavering 4/4
- **Character:** Mechanical, hypnotic
- **Source:** Early drum machines, precise
- **Philosophy:** Human as machine, machine as human

```gdscript
# Kraftwerk motorik pattern
func motorik_beat(t: float, bpm: float) -> float:
    var beat = fmod(t * bpm / 60.0, 4.0)
    var output = 0.0
    
    # Kick on every beat
    for i in range(4):
        if abs(beat - float(i)) < 0.05:
            output += electronic_kick(beat - float(i))
    
    # Snare on 2 and 4
    if abs(beat - 1.0) < 0.05 or abs(beat - 3.0) < 0.05:
        output += electronic_snare(fmod(beat - 1.0, 2.0))
    
    # 16th note hi-hat
    output += hihat(fmod(beat * 4.0, 1.0)) * 0.3
    
    return output
```

#### Sequencer Patterns (Tangerine Dream/Schulze)
- **Type:** 16th-note arpeggios
- **Character:** Hypnotic, evolving
- **Filter modulation:** Slow LFO sweeps
- **Layering:** Multiple sequences in polyrhythm

#### Orchestral Synth (Yes/ELP)
- **Mellotron:** String/choir samples
- **Hammond Organ:** Through Leslie speaker (modeled)
- **Role:** Orchestral weight without orchestra

### Chord Progressions
| Progression | Character |
|-------------|-----------|
| Modal vamps | Dorian, Mixolydian |
| Through-composed | Changing, no repetition |
| i - VII - VI - V | Descending drama |
| Power chords (5ths) | Rock energy |

### Arrangement
- **Structure:** Sections, not verse/chorus
- **Duration:** 10-25 minutes possible
- **Development:** Themes transformed, key changes
- **Dynamics:** Extreme quiet to extreme loud

### Reference Tracks
- ELP "Lucky Man" - Moog solo benchmark
- Kraftwerk "Autobahn" - Motorik sequencing
- Yes "Roundabout" - Complex prog structure
- Pink Floyd "On the Run" - Sequencer-based

---

## 6. Rave (90s Breakbeat Hardcore / Happy Hardcore)

### Historical Context
1990-1994 UK rave culture. The Prodigy, SL2, Altern-8. Breakbeats + hoovers + pianos + samples = euphoric chaos. Warehouse energy.

### Core Identity
**Emotion:** Euphoric, aggressive, ecstatic
**Era:** Early 1990s UK
**Character:** Raw, energetic, slightly chaotic

### Technical Parameters
| Parameter | Value | Notes |
|-----------|-------|-------|
| **BPM** | 140-160 | Fast and driving |
| **Key** | Minor (Am, Em) | Dark euphoria |
| **Time Signature** | 4/4 | Relentless |

### Sound Design Elements

#### The Hoover (Signature Sound)
- **Source:** Roland Alpha Juno "What The" patch
- **Character:** Screaming, aggressive, slides
- **Components:** Saw + PWM, portamento, resonant filter

```gdscript
# Hoover/rave stab
func hoover_bass(t: float, freq: float) -> float:
    # Oscillator mix
    var saw = sawtooth(freq * t)
    var pw = 0.3 + sin(t * 3.0) * 0.2
    var pulse = pulse_wave(freq * t, pw)
    
    var mix = saw * 0.6 + pulse * 0.4
    
    # Portamento (handled by caller)
    
    # Aggressive resonant filter
    var cutoff = 800.0 + sin(t * 4.0) * 600.0
    var filtered = lowpass_resonant(mix, cutoff, 0.75)
    
    # Distortion for grit
    return tanh(filtered * 1.8)
```

#### Breakbeats
- **Source:** Sampled funk breaks (Amen, Think, Funky Drummer)
- **Processing:** Timestretched, chopped, layered
- **Tempo:** Pushed to 140-160 BPM
- **Character:** Frantic energy

```gdscript
# Breakbeat pattern (programmed approximation)
func rave_break(t: float, bpm: float) -> float:
    var step = int(t / (60.0 / bpm / 4.0)) % 16
    
    # Syncopated pattern
    var kick_steps = [0, 3, 6, 10, 12, 15]
    var snare_steps = [4, 8, 11, 14]
    var hat_steps = [0, 2, 4, 6, 8, 10, 12, 14]
    
    var output = 0.0
    if step in kick_steps:
        output += kick_sample() * 0.8
    if step in snare_steps:
        output += snare_sample() * 0.9
    if step in hat_steps:
        output += hat_sample() * 0.4
    
    return output
```

#### Piano Stabs
- **Source:** M1 piano, house piano samples
- **Pattern:** Offbeat stabs, rhythmic punches
- **Processing:** Reverb, slight delay
- **Role:** Euphoric lift

#### Vocal Samples
- **Usage:** Chopped, pitched, timestretched
- **Character:** Rave MC shouts, diva samples
- **Processing:** Heavy reverb, delay throws

### Chord Progressions
| Progression | Character |
|-------------|-----------|
| Am - G - F - E | Euphoric minor descent |
| Am - Am - G - G | Hypnotic oscillation |
| i - VII - VI - VII | Building tension |
| i - VI - VII - i | Classic rave |

### Arrangement
- **Structure:** Builds to drops, breakdowns
- **Energy:** Constant high energy
- **Breakdowns:** Strip to beat + stabs, rebuild
- **Duration:** 5-8 minutes

### Reference Tracks
- The Prodigy "Charly" - Hoover bass benchmark
- SL2 "On a Ragga Tip" - Breakbeat + stabs
- Altern-8 "Activ-8" - Piano rave anthem

---

## 7. Synthwave (Kavinsky, Gunship, The Midnight)

### Historical Context
2000s-2010s nostalgia for 1980s that never existed. Film scores (Tangerine Dream, Vangelis) + 80s pop (Depeche Mode) + modern production. Neon aesthetics.

### Core Identity
**Emotion:** Nostalgic, cinematic, driving
**Era:** Retrofuture 1980s
**Character:** Lush, wide, emotional

### Technical Parameters
| Parameter | Value | Notes |
|-----------|-------|-------|
| **BPM** | 80-128 | Often 100-118 (driving but not frantic) |
| **Key** | Minor (Am, Fm, Cm) | Melancholic nostalgia |
| **Time Signature** | 4/4 | Standard |

### Sound Design Elements

#### Gated Reverb Drums (The 80s Sound)
- **Snare:** Big, roomy, gated reverb
- **Kick:** Punchy, electronic
- **Toms:** Huge, tribal
- **Processing:** Gate cutting reverb tail abruptly

```gdscript
# Gated reverb snare
func gated_snare(t: float) -> float:
    var snare = snare_sample() * exp(-t * 8.0)
    
    # Add reverb
    var reverb = reverb_process(snare, decay=1.5)
    
    # Gate it (cut tail after threshold)
    var gate_time = 0.15  # 150ms
    if t > gate_time:
        reverb *= exp(-(t - gate_time) * 50.0)  # Fast cutoff
    
    return snare * 0.6 + reverb * 0.4
```

#### Arpeggiated Synths
- **Pattern:** 16th-note arpeggios
- **Waveform:** Saw or pulse
- **Processing:** Delay (dotted 8th), reverb
- **Character:** Driving, hypnotic

```gdscript
# Synthwave arpeggio
func synthwave_arp(t: float, chord: Array, bpm: float) -> float:
    var step_dur = 60.0 / bpm / 4.0
    var step = int(t / step_dur) % chord.size()
    
    var midi = chord[step]
    var freq = midi_to_freq(midi)
    
    var saw = sawtooth(freq * t)
    var env = exp(-fmod(t, step_dur) / step_dur * 3.0)
    
    # Dotted 8th delay
    var delay_time = step_dur * 3.0
    var delayed = delay_buffer.read(delay_time) * 0.4
    
    return lowpass(saw * env + delayed, 3000.0)
```

#### Supersaw Pads
- **Oscillators:** 5-8 detuned saws
- **Detune spread:** ±20-40 cents
- **Processing:** Chorus, reverb
- **Character:** Massive, wide, emotional

```gdscript
# Synthwave supersaw
func supersaw_pad(t: float, freq: float) -> float:
    var num_voices = 7
    var detune_spread = 0.03
    var output = 0.0
    
    for i in range(num_voices):
        var detune = 1.0 + (float(i) / num_voices - 0.5) * detune_spread
        output += sawtooth(freq * detune * t)
    
    output /= num_voices
    
    # Warm lowpass
    return lowpass(output, 4000.0 + sin(t * 0.2) * 1000.0) * 0.4
```

#### Bass
- **Type:** Fat analog-style
- **Waveform:** Saw + sub sine
- **Pattern:** Often root notes, occasional octave jumps
- **Processing:** Light saturation

#### Lead Synth
- **Character:** Detuned, expressive
- **Processing:** Reverb, delay
- **Style:** Soaring melodies, emotional bends

### Chord Progressions
| Progression | Character |
|-------------|-----------|
| Am - F - C - G | Cinematic minor |
| Fm - Db - Ab - Eb | Dark, epic |
| i - VI - III - VII | Natural minor flow |
| i - iv - VII - III | Darker variant |

### Arrangement
- **Structure:** Clear sections (intro, verse, chorus, bridge)
- **Builds:** Filter sweeps, layer addition
- **Drops:** Strip to arp + kick, rebuild
- **Duration:** 4-6 minutes (song-length)

### Reference Tracks
- Kavinsky "Nightcall" - Driving, vocal, cinematic
- Gunship "Tech Noir" - Epic, layered
- The Midnight "Sunset" - Emotional, saxophone

---

---

## K-Bass (Korean Bass Music Export)

### Historical Context
Emerging 2023-2024 from Seoul's underground club scene, K-Bass is Korean bass music explicitly framed as export culture — UK-rooted rhythmic systems (jungle/DnB/UKG/dubstep) treated as modular tools, carried by Korean producers' sensibilities. The ENTER THE K-BASS Vol.1 compilation (SCR × ScreaM Records, 2024) documents this movement ahead of SXSW London.

### Core Identity
**Emotion:** Physical pressure, kinetic release
**Era:** 2024-present
**Character:** Textural, impact-driven, dramatic

### Technical Parameters
| Parameter | Value | Notes |
|-----------|-------|-------|
| **BPM** | 160-180 | DnB/jungle velocity |
| **Key** | Minor (Am, Dm, Em) | Tension-focused |
| **Time Signature** | 4/4 | Break-based phrasing |

### Sound Design Elements

#### Sub Bass (Lead Instrument)
- **Role:** Central, physical — this IS the hook
- **Style:** Reese bass, detuned saws into lowpass
- **Processing:** Saturation for harmonics, stereo width on mids only
- **Sub fundamental:** 40Hz for physical pressure
- **Movement:** Slow LFO on filter cutoff (0.5Hz)

```gdscript
# K-Bass reese sub
func k_bass_sub(t: float, freq: float) -> float:
    var detune = [0.992, 1.0, 1.008]
    var output = 0.0
    for d in detune:
        output += sawtooth(freq * d * t)
    output /= 3.0
    
    # Slow filter modulation for movement
    var lfo = sin(t * 0.5 * TAU)
    var cutoff = 150.0 + lfo * 70.0
    return lowpass(output, cutoff) * 0.8
```

#### Drums (Break-Led)
- **Source:** Chopped breaks (Amen, Think, Funky Drummer)
- **Processing:** Timestretching, granular, razor edits
- **Pattern:** Syncopated jungle patterns, not 4/4 monotony
- **Key sounds:**
  - Kick: Punchy break-derived, sub layer at 50Hz
  - Snare: Tight, minimal reverb
  - Hats: Rapid 16ths, metallic, rolling

#### Stabs (Textural Punctuation)
- **Role:** Impact moments, not melody
- **Character:** Metallic, FM-based, short decay
- **Usage:** Sparse, dramatic placement
- **Processing:** Distortion, short reverb

#### Arrangement Philosophy
- **Structure:** Drop-based, not verse/chorus
- **Dynamics:** Extreme contrast ratio
- **Negative space:** Compositional tool, silence as impact
- **Transitions:** Hard cuts, filter sweeps, snare rolls

### What K-Bass Is NOT
- Not K-Pop (no verse/chorus, no vocal hooks)
- Not melody-led songwriting
- Not 4/4 techno monotony
- Not Western producers sampling Korean aesthetics

### Reference Artists/Tracks
| Artist | Track | Character |
|--------|-------|-----------|
| yunji | ECHO (메아리) | DnB/jungle pillar |
| MAR VISTA | Modori (모도리) | Bass pressure |
| Coziest | Dokkaebi (도깨비) | Textural |
| h4rdy | teum (틈) | Negative space |
| 7ip7o3 | Seoul Metro (서울 메트로) | Urban kinetic |

### Scene Context
- **Seoul Community Radio (SCR):** Platform/curator
- **ScreaM Records:** Label partner
- **SXSW London:** International export showcase
- **Philosophy:** Korean emotion/sensibility → club-functional forms

---

## Summary Table

| Song | BPM | Key | Signature Sound | Emotion |
|------|-----|-----|-----------------|---------|
| Acid House | 118-130 | Am, Em (or none) | TB-303 squelch, resonant filter | Hypnotic squelch |
| Ambient Works | 85-100 | Am, Em, Dm | Warm detuned pads, lo-fi breaks | Nostalgic warmth |
| Detroit Techno | 120-130 | Cm, Gm, Dm | 909 drums, Juno strings | Cold soulfulness |
| K-Bass | 160-180 | Am, Dm, Em | Reese sub, chopped breaks, stabs | Physical pressure |
| Moroder Disco | 120-130 | C, G (major) | 16th-note sequencer | Hypnotic ecstasy |
| Pop Generative | 100-128 | Various | Sidechained synths, hooks | Immediate emotion |
| Prog Synth 70s | 80-140 | Modal | Moog lead, motorik beat | Epic exploration |
| Rave | 140-160 | Am, Em | Hoover bass, breakbeats | Euphoric chaos |
| Synthwave | 100-118 | Fm, Am, Cm | Gated drums, supersaws | Nostalgic cinema |

---

*Research compiled for procedural song generation in AdaResearch.*
