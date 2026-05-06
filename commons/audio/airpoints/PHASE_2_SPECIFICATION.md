# AGENT A - ARCHITECTURE REVIEW & PHASE 2 SPECIFICATION
# Timestamp: 2025-11-29T08:40:00Z
# Agent: Agent-SoundArchitect (Agent A)

## PHASE 1 REVIEW: ✅ APPROVED

Agent B's implementation is solid and follows the architecture correctly. The AirPointListener and AirPointOscillator provide a clean foundation for spatial audio synthesis.

**Strengths:**
- Clean separation of concerns (Listener vs Generator)
- Proper signal smoothing to avoid clicks
- Multiple waveform support
- Real-time parameter mapping

**Testing Notes:**
The test scene should demonstrate distance-to-pitch mapping effectively.

---

## CRITICAL UPDATE: Teropa Systems Music Reference

After reviewing https://teropa.info/blog/2016/07/28/javascript-systems-music.html, we need to align our implementation with the **Discreet Music** approach, which uses:

### Synthesis Techniques from Teropa:
1. **DuoSynth Architecture**
   - Voice 1: Sawtooth wave (harmonically rich)
   - Voice 2: Sine wave (fundamental tone)
   - Combined for fuller sound

2. **Low-Pass Filtering**
   - Base frequency: 200 Hz
   - Octaves: 2 (passes up to ~800 Hz)
   - Creates "warm synth washes" instead of harsh tones

3. **ADSR Envelopes**
   - Attack: 0.1s (soft fade-in)
   - Release: 4s (long fade-out)
   - Release curve: Linear
   - Filter release: Very long (1000s) to prevent frequency drop

4. **Vibrato**
   - Rate: 0.5 Hz
   - Amount: 0.1 (subtle pitch modulation)

5. **Stereo Panning**
   - Left synth: -0.5 pan
   - Right synth: +0.5 pan
   - Allows spatial mixing

6. **Phasing Loop System**
   - Left loop: 34 measures (~68 seconds at 120 BPM)
   - Right loop: 37 measures (~74 seconds)
   - Different durations create evolving patterns
   - ~41 minutes before loops sync again

7. **Echo/Delay Effects**
   - Tape delay (Frippertronics style)
   - Feedback for sustained ambience

---

## PHASE 2 SPECIFICATION: Enhanced Synthesis

### Task 023: Create AirPointSynth (DuoSynth-style)
**Agent B: Implement the following:**

File: `commons/audio/airpoints/AirPointSynth.gd`

**Architecture:**
```
AirPointSynth (AudioStreamPlayer)
├─ Voice 1: Sawtooth Oscillator
│  ├─ Low-pass filter (200 Hz base, 2 octaves)
│  └─ ADSR (attack: 0.1s, release: 4s)
├─ Voice 2: Sine Oscillator
│  ├─ Low-pass filter (200 Hz base, 2 octaves)
│  └─ ADSR (attack: 0.1s, release: 4s)
├─ Vibrato LFO (0.5 Hz, 0.1 depth)
└─ Output → Stereo Panner → Echo/Reverb → Master
```

**Parameter Mapping (from AirPointListener):**
- `distance` → Base frequency (110-880 Hz, inverse)
- `proximity_factor` → Amplitude (0-0.7)
- `position.x` → Stereo pan (-1 to 1)
- `position.y` → Filter cutoff modulation (±200 Hz)
- `velocity.length()` → Vibrato rate modulation (0.3-0.8 Hz)
- `direction_vector.y` → Harmonicity (voice 1/voice 2 ratio)

**Key Features:**
1. Dual oscillator mixing (sawtooth + sine)
2. Low-pass filter with envelope
3. Smooth ADSR with long release
4. LFO-based vibrato
5. Soft clipping output

### Task 024: Create Phasing Loop System
**Agent B: Implement the following:**

File: `commons/audio/airpoints/AirPointPhasingSystem.gd`

**Architecture:**
- Multiple Air Points (minimum 2, up to 7 like Teropa)
- Each Air Point has its own loop duration
- Loop durations are prime-ish numbers (e.g., 34s, 37s, 41s, 43s)
- Each loop triggers note sequences
- Different loop lengths create phasing patterns

**Melodic Phrases:**
Define 7 melodic phrases (like Teropa's Discreet Music):
- Phrase 1: C5 → D5 (1:2 duration)
- Phrase 2: D5 → C5 (1:0 duration)
- Phrase 3: F5 (0:2 duration)
- Phrase 4: E5 → D5 (1:2 duration)
- Phrase 5: G5 (0:2 duration)
- Phrase 6: F5 → E5 (1:2 duration)
- Phrase 7: A5 → G5 (1:2 duration)

### Task 025: Add Echo/Delay Effect
**Agent B: Implement the following:**

File: `commons/audio/airpoints/AirPointEcho.gd`

**Tape Delay (Frippertronics-style):**
- Delay time: ~3-5 seconds
- Feedback: 0.6-0.7 (sustains but decays)
- Wet/Dry mix: 0.5
- Optional: Modulate delay time with Air Point movement

---

## MUSICAL STRUCTURE: Systems Music Principles

Following Teropa's approach:

1. **Minimal Rules, Emergent Complexity**
   - Simple melodic phrases
   - Spatial movement drives modulation
   - Phasing creates evolving patterns

2. **No Central Clock**
   - Each Air Point has independent loop
   - Loops drift in and out of phase
   - Spatial relationships create timing

3. **Continuous Modulation**
   - All parameters smoothly interpolated
   - No discrete events (except note triggers)
   - Movement creates timbral evolution

4. **Generative Duration**
   - System can run indefinitely
   - Patterns emerge and dissolve
   - ~41 minutes before full cycle (with 2 loops)

---

## IMPLEMENTATION PRIORITY

**Phase 1:** ✅ COMPLETE
- Basic distance oscillator working

**Phase 2:** IN PROGRESS
- Task 023: AirPointSynth (DuoSynth-style) - HIGH PRIORITY
- Task 024: Phasing Loop System - MEDIUM PRIORITY
- Task 025: Echo/Delay Effect - LOW PRIORITY

**Phase 3:** FUTURE
- Multi-point harmonizer
- Granular synthesis layer
- Visual feedback (particle systems)

---

Agent B: Please proceed with **Task 023** (AirPointSynth). This will replace the simple oscillator with a Teropa-style synthesizer that produces the warm, ambient sounds characteristic of Discreet Music.

The existing AirPointOscillator.gd can remain as a "simple mode" option, but AirPointSynth.gd should be the primary generator.

**Status:** Awaiting Agent B implementation of Task 023.
