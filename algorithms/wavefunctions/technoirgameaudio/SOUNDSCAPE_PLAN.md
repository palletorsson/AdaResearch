# 10 Sci-Fi Lo-Fi Soundscapes - Master Plan

**Goal:** Create 10 full-feature procedural soundscapes for the game, ranging from pure ambient drones to full lo-fi beats with bass and rhythm.

## Current Status

**Completed:** ✅ **ALL 10 SOUNDSCAPES COMPLETE!**
- ✅ **John Cage Tech Noir** - Urban dystopia ambient
- ✅ **Space Station Isolation** - Deep space ambient
- ✅ **Abandoned Factory** - Industrial decay ambient
- ✅ **Quantum Lab** - Cerebral downtempo with Moog bass
- ✅ **Cyberpunk Night Market** - Urban lo-fi with rain and beats
- ✅ **Underwater Research Lab** - Submerged facility with sonar
- ✅ **Desert Outpost** - Arid wasteland with heat shimmer
- ✅ **Bio-Dome Greenhouse** - Organic meditative atmosphere
- ✅ **Neon Arcade** - Retro 8-bit chiptune vibes
- ✅ **Orbital Prison** - Dark industrial techno

**What We Need:**
- ❌ VR rack configs for soundscape parameter control

---

## Soundscape Categories

The 10 soundscapes are organized into 3 categories based on rhythmic complexity:

### Category A: Full Lo-Fi Beats (4 soundscapes)
**Complete with bass lines, drum patterns, and rhythmic elements**

| # | Name | BPM | Bass Style | Rhythm Style | Vibe |
|---|------|-----|------------|--------------|------|
| 1 | **Cyberpunk Night Market** | 85 | Sub bass (40Hz) + synth bass (80Hz) | Lo-fi hip-hop beat (kick, snare, hi-hat) | Chill, urban |
| 2 | **Neon Arcade** | 120 | 8-bit bass line (square wave) | Chiptune drums (4/4 house) | Energetic, retro |
| 3 | **Quantum Lab (After Hours)** | 95 | Moog-style bass | Downtempo breakbeat | Cerebral, groovy |
| 4 | **Orbital Prison (Rebellion)** | 110 | Dark techno bass | Industrial kick + metallic percussion | Aggressive, tense |

**Sound Layer Structure:**
```
Layer 1: Sub Bass Drone (continuous, 30-60 Hz)
Layer 2: Bass Line (rhythmic, follows musical pattern)
Layer 3: Drum Pattern (kick, snare, hi-hat, percussion)
Layer 4: Harmonic Pad (chords, atmosphere)
Layer 5: Ambient Texture (noise, environmental sounds)
Layer 6: Random Effect Events (7 types, 3 variations each)
```

---

### Category B: Rhythmic Ambience (3 soundscapes)
**Rhythmic elements but no traditional beats - pulses and patterns**

| # | Name | Pulse Pattern | Bass Element | Vibe |
|---|------|---------------|--------------|------|
| 5 | **Space Station Isolation** | Heartbeat-like pulse (60 BPM) | Ultra-low drone (30Hz) | Eerie, lonely |
| 6 | **Underwater Research Lab** | Sonar ping rhythm (irregular) | Pressure wave bass (35Hz) | Mysterious, fluid |
| 7 | **Bio-Dome Greenhouse** | Growth pulse (slow, organic) | Earthy sub frequency (45Hz) | Organic, meditative |

**Sound Layer Structure:**
```
Layer 1: Ultra-Low Drone (continuous, 30-50 Hz)
Layer 2: Rhythmic Pulse (non-musical timing, organic)
Layer 3: Ambient Texture (environmental sounds)
Layer 4: Random Effect Events (7 types, 3 variations each)
```

---

### Category C: Pure Ambient Drones (3 soundscapes)
**No rhythm - pure atmosphere like john_cage_tech_noir**

| # | Name | Drone Character | Ambient Character | Vibe |
|---|------|-----------------|-------------------|------|
| 8 | **John Cage Tech Noir** ✅ | 55Hz harmonic drone | City traffic | Urban dystopia |
| 9 | **Abandoned Factory** | 70Hz machinery rumble | Wind through pipes | Desolate, industrial |
| 10 | **Desert Outpost** | 90Hz heat shimmer drone | Sand wind | Arid, isolated |

**Sound Layer Structure:**
```
Layer 1: Harmonic Drone (continuous, 30s loop, 40-90 Hz base)
Layer 2: Ambient Texture (10-15s loop, environmental)
Layer 3: Random Effect Events (7 types, 3 variations each)
```

---

## Detailed Soundscape Designs

### 1. Cyberpunk Night Market
**Theme:** Neon-lit streets, street vendors, hover bikes, holographic ads
**BPM:** 85 (Lo-fi hip-hop tempo)
**Key:** A minor

**Continuous Layers:**
- **Sub Bass Drone** (30s loop): 40Hz pure sine, subtle LFO modulation
- **Bass Line** (8-bar loop): Synth bass pattern in A minor
  - Pattern: A1, A1, E1, A1, C#1, A1, E1, A1 (root, root, fifth, root, third, root, fifth, root)
  - Envelope: Attack 0.01s, Decay 0.15s, Sustain 0.3, Release 0.1s
  - Waveform: Sine + slight saw layer for warmth
- **Lo-Fi Drums** (4-bar loop at 85 BPM):
  - Kick: On beats 1 and 5, occasional ghost note on 3.5
  - Snare: On beats 3 and 7, lo-fi filtered
  - Hi-hat: Eighth notes with swing (60% strength, varied velocity)
  - Vinyl crackle: Continuous layer at -30dB
- **Neon Pad** (16-bar loop): Chord progression with soft synth pad
  - Chords: Am → F → C → G (i, VI, III, VII)
  - Each chord: 4 bars duration
  - Voicing: Close position triads (220-392 Hz range)
  - Filter: Slow LPF sweep (500Hz-2000Hz over 16 bars)

**Random Effect Sounds (7 types, 3-7s duration):**
1. **Vendor Shout** - Filtered noise burst with formant-like resonances
2. **Motorcycle Pass** - Doppler pitch shift (300Hz → 150Hz over 2s)
3. **Hologram Glitch** - Digital artifacts (bit-crushing + pitch jumps)
4. **Advertisement Jingle** - Short 4-note melody (major pentatonic)
5. **Cash Register** - Mechanical bell ding + drawer slide noise
6. **Drone Flyby** - Whirring with spatial panning and doppler
7. **Food Sizzle** - Filtered noise burst with exponential decay

**Audio Bus Routing:**
- Bass Line → LowPass (200Hz cutoff) → Reverb (room_size: 0.3)
- Drums → Compressor (ratio: 4:1) → Light distortion
- Pad → Reverb (room_size: 0.7, wet: 0.4)
- Effects → Delay (300ms) → Reverb (room_size: 0.5)

---

### 2. Neon Arcade
**Theme:** Retro arcade, 8-bit games, coin sounds, electronic bleeps
**BPM:** 120 (Upbeat house/chiptune tempo)
**Key:** C major

**Continuous Layers:**
- **Sub Bass Drone** (30s loop): 50Hz square wave (8-bit style)
- **Bass Line** (4-bar loop): Arpeggio pattern
  - Pattern: C2, E2, G2, E2, C2, G2, E2, C2
  - Waveform: Square wave (pure 8-bit)
  - Gate time: 50% (staccato)
- **Chiptune Drums** (4-bar loop at 120 BPM):
  - Kick: Square wave punch (80Hz → 40Hz over 0.05s)
  - Snare: White noise burst (0.08s) + square wave (200Hz)
  - Hi-hat: Filtered white noise (8kHz+), 16th notes
  - Tom fills: Descending square wave tones on bar 4
- **Lead Melody** (8-bar loop): Catchy chiptune melody
  - Scale: C major pentatonic
  - Waveform: Alternating square/pulse waves
  - Vibrato: 5Hz LFO, depth 0.1 semitones

**Random Effect Sounds (7 types, 2-5s duration):**
1. **Coin Insert** - Metallic clink (2kHz ring)
2. **Joystick Click** - Short mechanical click
3. **High Score Fanfare** - Ascending arpeggio (C-E-G-C)
4. **Game Over** - Descending chromatic scale with reverb
5. **Token Dispenser** - Mechanical rattle + coins
6. **Pinball Bumper** - Elastic bounce with bell
7. **Button Mash** - Rapid click sequence

**Audio Bus Routing:**
- All layers → Bit Crusher (8-bit, sample rate reduction)
- Lead → Delay (dotted 8th, 375ms)
- Effects → Reverb (room_size: 0.4, short decay)

---

### 3. Quantum Lab (After Hours)
**Theme:** Scientific facility at night, late-night research, contemplative
**BPM:** 95 (Downtempo, trip-hop feel)
**Key:** D minor

**Continuous Layers:**
- **Sub Bass Drone** (30s loop): 45Hz sine with subtle harmonic movement
- **Bass Line** (8-bar loop): Moog-style bass
  - Pattern: D1, _, D1, _, F1, _, D1, A0 (roots and fifths)
  - Envelope: Attack 0.05s, Decay 0.3s, Sustain 0.6, Release 0.2s
  - Waveform: Saw with resonant lowpass (cutoff: 200Hz, Q: 3)
  - Filter envelope: Moderate modulation
- **Breakbeat** (4-bar loop at 95 BPM):
  - Kick: On 1 and 3.5 (syncopated)
  - Snare: On 2.75 and 4 (delayed shuffle)
  - Hi-hat: Shuffle pattern with swing
  - Percussion: Shaker, rim shot accents
- **Pad Layer** (16-bar loop): Evolving ambient pad
  - Chords: Dm → Bb → F → Am (i, VI, III, v)
  - Texture: Slow attack (1s), wavetable synthesis
  - Movement: Filter sweep + chorus

**Random Effect Sounds (7 types, 4-8s duration):**
1. **Particle Collision** - Short burst with frequency sweep down
2. **Data Stream** - Rapid digital beeps (morse-code like)
3. **Keyboard Typing** - Mechanical keyboard (5-10 keypresses)
4. **Coffee Maker** - Gurgling water + steam hiss
5. **Whiteboard Marker** - Squeaky drawing sounds
6. **Test Alarm** - Short warning beep (1kHz, 3 pulses)
7. **Eureka Moment** - Ascending chime with reverb tail

**Audio Bus Routing:**
- Bass → Saturator (subtle warmth) → Reverb
- Drums → Compressor (heavy, ratio: 6:1)
- Pad → Chorus → Reverb (large room)
- Effects → Delay (dotted quarter note, 632ms) → Reverb

---

### 4. Orbital Prison (Rebellion)
**Theme:** Confined space station, tension, resistance, industrial
**BPM:** 110 (Industrial techno)
**Key:** E minor (dark)

**Continuous Layers:**
- **Sub Bass Drone** (30s loop): 35Hz sine with ominous modulation
- **Bass Line** (4-bar loop): Dark techno bass
  - Pattern: E1, E1, _, E1, _, G1, E1, D1
  - Waveform: Distorted saw wave
  - Envelope: Fast attack, short decay, no sustain (punchy)
  - Processing: Heavy distortion + sidechain compression
- **Industrial Drums** (4-bar loop at 110 BPM):
  - Kick: Four-on-floor + syncopated accents
  - Snare: Metallic clap + reverb
  - Hi-hat: Steady 16ths, filtered harshly
  - Percussion: Metal hits, industrial clangs
- **Tension Drone** (continuous): Dissonant high frequencies
  - Frequencies: 2.4kHz, 3.3kHz (non-harmonic)
  - Modulation: Slow beating (creates tension)

**Random Effect Sounds (7 types, 3-7s duration):**
1. **Cell Door Slam** - Heavy metal impact + reverb
2. **Metal Footsteps** - Rhythmic boots on metal grating
3. **Intercom Static** - Harsh noise burst + voice-like formants
4. **Alarm Siren** - Rising pitch sweep + pulsing
5. **Struggle Sounds** - Chaotic metal clangs + impacts
6. **Power Surge** - Electrical buzz + pitch drop
7. **Distant Laughter** - Eerie filtered laughter with reverb

**Audio Bus Routing:**
- Bass → Distortion (heavy) → Sidechain compression
- Drums → Compressor (ratio: 8:1) → Limiter
- Effects → Delay (quarter note, 545ms) → Reverb (metallic)

---

### 5. Space Station Isolation
**Theme:** Deep space, loneliness, mechanical ambience, hull sounds
**Pulse Pattern:** Heartbeat rhythm (60 BPM) - not musical beats

**Continuous Layers:**
- **Ultra-Low Drone** (30s loop): 30Hz sub bass (felt more than heard)
  - Harmonics: Very subtle 2nd and 3rd harmonics
  - Modulation: Extremely slow LFO (0.02 Hz)
- **Ice Pad** (20s loop): Cold, crystalline texture
  - Frequencies: High register (1-4kHz), sparse
  - Waveform: Filtered noise + bell-like partials
  - Movement: Random pitch drift (±5 cents)
- **Hull Creaks** (15s loop): Metal stress sounds
  - Low frequency groans (60-150Hz)
  - Random timing, unpredictable
- **Air Recycling** (10s loop): Steady ventilation hum
  - Frequency: 120Hz (power hum)
  - Filtered white noise layer

**Rhythmic Element:**
- **Heartbeat Pulse** (60 BPM): Lub-dub rhythm
  - Not synchronized to musical grid
  - Slight tempo variation (±5 BPM drift)
  - Volume: Very quiet, subliminal

**Random Effect Sounds (7 types, 4-8s duration):**
1. **Airlock Hiss** - Pressure release + reverb tail
2. **Computer Beeps** - Isolated diagnostic tones
3. **Distant Footsteps** - Echoing metal steps
4. **Metal Stress** - Creaking, groaning metal
5. **Radio Static** - Burst of noise + voice fragments
6. **Oxygen Vent** - Gas release with resonance
7. **Alarm Pulse** - Single beep, occasional

**Audio Bus Routing:**
- All layers → Reverb (huge space, 3s+ decay)
- Effects → Delay (long, 1200ms+) → Reverb
- Ice Pad → HighPass (1kHz) → Reverb

---

### 6. Underwater Research Lab
**Theme:** Submerged facility, ocean pressure, sonar, marine life
**Pulse Pattern:** Sonar ping rhythm (irregular, 3-8s intervals)

**Continuous Layers:**
- **Pressure Drone** (30s loop): 35Hz ultra-low (simulates water pressure)
  - Very slow amplitude modulation (breathing quality)
  - Harmonics: Minimal, pure fundamental
- **Water Flow** (12s loop): Fluid movement
  - Filtered noise with liquid quality
  - Frequency: 200-800Hz band
  - Modulation: Slow sweeping filter
- **Equipment Hum** (continuous): Machinery sounds
  - Base: 60Hz electrical hum
  - Harmonics: 120Hz, 180Hz
  - Variable intensity

**Rhythmic Element:**
- **Sonar Pings** (irregular timing):
  - Timing: 3-8 second intervals (random)
  - Sound: 1kHz → 800Hz sweep (0.2s duration)
  - Reverb: Long tail (simulates underwater space)

**Random Effect Sounds (7 types, 5-12s duration):**
1. **Hull Groan** - Deep metal stress under pressure
2. **Pressure Release** - Valve opening + bubbles
3. **Dolphin Call** - High-pitched organic whistle
4. **Equipment Beep** - Short electronic tone
5. **Bubbles** - Rising bubbles with varied timing
6. **Whale Song (Distant)** - Low frequency organic call
7. **Metal Creak** - Structural stress sounds

**Audio Bus Routing:**
- All layers → LowPass (2kHz) → Reverb (large, wet)
- Effects → Chorus (underwater movement) → Reverb
- Sonar → Delay (long, 800ms) → Reverb

---

### 7. Bio-Dome Greenhouse
**Theme:** Organic technology, plant growth, living systems, natural rhythms
**Pulse Pattern:** Growth pulse (very slow, 30-40 BPM equivalent, organic)

**Continuous Layers:**
- **Growth Hum** (30s loop): 45Hz earthy drone
  - Organic quality (not pure sine)
  - Harmonics that slowly evolve
  - Warmth and life
- **Bird Chirps** (varies): Sporadic bird calls
  - 3-5 different bird types
  - Random timing, spatially positioned
- **Water Drip** (continuous): Irregular dripping
  - Randomized timing (1-4s intervals)
  - Pitch variation per drop

**Rhythmic Element:**
- **Growth Pulse** (30-40 BPM equivalent):
  - Not strict timing, organic feel
  - Very subtle, almost subliminal
  - Like a slow heartbeat of the dome

**Random Effect Sounds (7 types, 3-8s duration):**
1. **Sprinkler Activate** - Water spray starting
2. **Plant Rustle** - Leaves moving in breeze
3. **Bee Buzz** - Insect flight with doppler
4. **Door Open** - Airlock with pressure equalization
5. **Scanner Beep** - Diagnostic equipment tone
6. **Harvest Sound** - Cutting + collecting plants
7. **Growth Spurt** - Accelerated plant growth (whoosh)

**Audio Bus Routing:**
- Growth Hum → LowPass (300Hz) → Reverb
- Bird Chirps → Delay (varying, 200-600ms) → Reverb (natural space)
- Effects → Light Reverb (small room)

---

### 8. John Cage Tech Noir ✅ (COMPLETED)
**Theme:** Urban dystopia, neon rain, technology decay
**Already implemented** - See `john_cage_tech_noir.gd`

**Layers:**
- Endless Drone (30s loop, 55Hz base, 6 harmonics)
- City Ambience (10s loop, traffic rumble)
- 7 Effect Types × 3 Variations:
  - Distant siren, static burst, rain segment
  - Mechanical whir, typing segment, electric hum, heartbeat

---

### 9. Abandoned Factory
**Theme:** Industrial decay, rust, wind through broken windows, falling debris

**Continuous Layers:**
- **Machinery Rumble Drone** (30s loop): 70Hz base
  - Harmonics: 1.0, 1.5, 2.0, 3.0 (slightly dissonant)
  - Modulation: Irregular stuttering (broken machinery)
  - Noise layer: Metallic texture
- **Wind Through Pipes** (12s loop):
  - Howling wind (filtered noise)
  - Frequency: 200-1200Hz range
  - Resonant peaks (pipe harmonics)
  - Variable intensity

**Random Effect Sounds (7 types, 3-8s duration):**
1. **Dripping Water** - Single drops with long reverb
2. **Falling Debris** - Metal/concrete impacts
3. **Rat Scurry** - Quick pitter-patter on metal
4. **Door Slam (Distant)** - Heavy door + reverb
5. **Chain Rattle** - Hanging chains swaying
6. **Steam Release** - Pressure valve burst
7. **Glass Shatter** - Breaking glass with sparkle

**Audio Bus Routing:**
- Drone → Distortion (subtle grit) → Reverb (huge space)
- Wind → Reverb (long decay, 4s+)
- Effects → Delay (long, 1000ms+) → Reverb

---

### 10. Desert Outpost
**Theme:** Arid wasteland, heat, isolation, sand, sparse technology

**Continuous Layers:**
- **Heat Shimmer Drone** (30s loop): 90Hz base
  - Harmonics: Wavering (simulates heat distortion)
  - Frequency modulation: Slow, irregular
  - Texture: Grainy, sandy quality
- **Sand Wind** (15s loop):
  - Filtered noise (low-mid frequency)
  - Gusting pattern (swells)
  - Occasional howling resonance

**Random Effect Sounds (7 types, 4-10s duration):**
1. **Radio Chatter** - Distant voice fragments
2. **Generator Sputter** - Failing engine, irregular
3. **Metal Expansion** - Creaking from heat
4. **Sand Storm** - Intense wind + particle impacts
5. **Coyote Howl** - Animal call, distant
6. **Vehicle Approach** - Engine sound with doppler
7. **Flag Flap** - Fabric snapping in wind

**Audio Bus Routing:**
- Drone → Reverb (dry space, short decay)
- Wind → HighPass (150Hz) → Reverb
- Effects → Delay (medium, 500ms) → Reverb (dry)

---

## Technical Architecture

### New Components Required

1. **RhythmEngine.gd** - BPM, timing, quantization
2. **BassGenerator.gd** - Bass line patterns and synthesis
3. **DrumGenerator.gd** - Drum pattern generation
4. **ChordGenerator.gd** - Harmonic pad generation
5. **SciFiLoFiSoundscape.gd** (base class) - Common functionality

### Base Class Structure

```gdscript
# SciFiLoFiSoundscape.gd
extends Node3D

# Common to all soundscapes
var sample_rate = 44100
var rng = RandomNumberGenerator.new()
var generation_thread: Thread
var mutex: Mutex

# Audio players
var continuous_players = []  # Drones, bass, drums, etc.
var effect_players = []      # Random events

# Configuration
var soundscape_config = {
    "name": "Soundscape Name",
    "category": "beats",  # "beats", "rhythmic_ambient", "pure_ambient"
    "bpm": 0,            # 0 for non-rhythmic
    "key": "",           # Musical key (if applicable)
    "continuous_layers": [],  # Layer definitions
    "effect_sounds": []       # Effect sound definitions
}

# Virtual methods to override
func create_continuous_layers() -> Dictionary:
    pass

func create_effect_sounds() -> Dictionary:
    pass

func get_audio_bus_config() -> Dictionary:
    pass
```

### Integration Points

**SoundBankSingleton Integration:**
```gdscript
# Register soundscape
SoundBankSingleton.register_soundscape("cyberpunk_night_market", CyberpunkNightMarket)

# Get sound from soundscape
var sound = SoundBankSingleton.get_sound("cyberpunk_night_market.bass_line")
```

**Ambient Presets JSON:**
```json
{
  "cyberpunk_night_market": {
    "soundscape_class": "CyberpunkNightMarket",
    "continuous_layers": ["sub_bass", "bass_line", "drums", "pad"],
    "random_events": {
      "vendor_shout": {"interval_range": [5, 15], "volume_range": [-20, -10]},
      "motorcycle_pass": {"interval_range": [10, 30], "volume_range": [-15, -8]}
    }
  }
}
```

---

## Implementation Phases

### Phase 1: Foundation (Weeks 1-2)
- [x] Create base `SciFiLoFiSoundscape.gd` class ✅ (Revised: uses composition of existing generators)
- [ ] Implement `RhythmEngine.gd` *(Deferred - not needed for ambient soundscapes)*
- [ ] Implement `BassGenerator.gd` *(Deferred - will extend TrapBeatsGenerator when needed)*
- [ ] Implement `DrumGenerator.gd` *(Deferred - TrapBeatsGenerator already has drum sounds)*
- [x] Test with one example soundscape

### Phase 2: Beat-Driven Soundscapes (Weeks 3-4)
- [ ] Implement **Cyberpunk Night Market**
- [ ] Implement **Neon Arcade**
- [ ] Implement **Quantum Lab (After Hours)**
- [ ] Implement **Orbital Prison (Rebellion)**

### Phase 3: Rhythmic Ambient (Week 5)
- [x] Implement **Space Station Isolation** ✅
- [ ] Implement **Underwater Research Lab**
- [ ] Implement **Bio-Dome Greenhouse**

### Phase 4: Pure Ambient (Week 6)
- [ ] Refactor **John Cage Tech Noir** to use base class
- [x] Implement **Abandoned Factory** ✅
- [ ] Implement **Desert Outpost**

### Phase 5: Integration & Polish (Week 7-8)
- [x] Integrate all soundscapes with SoundBankSingleton *(Using ambient_presets.json instead)*
- [x] Create JSON presets for all soundscapes *(2 of 10 complete)*
- [ ] Build soundscape switcher UI
- [ ] Create VR rack configs for each soundscape
- [ ] Testing and balancing

---

## Testing Strategy

### Unit Testing
- Each generator (bass, drums, chords) tested independently
- Verify loop lengths match BPM calculations
- Check for clicks/pops at loop points

### Integration Testing
- Test soundscape layer mixing
- Verify thread safety
- Check memory usage during generation

### User Testing
- Playtesting each soundscape in-game
- Verify mood and atmosphere match theme
- Balance volume levels across soundscapes

---

## Performance Considerations

### Memory Management
- Pre-generate all loops during loading screen
- Cache generated sounds
- Stream long ambient textures if needed

### CPU Optimization
- Use background threads for generation
- Limit simultaneous effect sounds (5 players max)
- Use audio buses efficiently

### Audio Quality
- 16-bit PCM for all sounds (balance size vs quality)
- 44.1kHz sample rate (standard)
- Proper loop crossfading to avoid clicks

---

## Future Enhancements

### v2.0 Features
- Real-time parameter modulation via rack controls
- User-customizable soundscape mixing
- Crossfade transitions between soundscapes
- Dynamic intensity scaling based on gameplay

### v3.0 Features
- Generative melody system
- AI-driven event timing
- Spatial audio for VR (binaural)
- Multi-track recording/export

---

## References

- **John Cage Tech Noir:** `algorithms/wavefunctions/technoirgameaudio/john_cage_tech_noir.gd`
- **Audio Generators:** `commons/audio/generators/`
- **Sound Bank:** `commons/audio/SoundBankSingleton.gd`
- **Rack Configs:** `commons/audio/rack_configs/`
- **Ambient Presets:** `commons/audio/ambient_presets.json`

---

## Notes

- All soundscapes use **procedural generation** - no audio files required
- John Cage's **chance operations** philosophy applied to random events
- **Lo-fi aesthetic** maintained through subtle imperfections (vinyl crackle, slight detuning, etc.)
- Each soundscape should be **non-repetitive** over 30+ minutes of listening
- Target **sci-fi game atmosphere** while remaining musical and engaging
