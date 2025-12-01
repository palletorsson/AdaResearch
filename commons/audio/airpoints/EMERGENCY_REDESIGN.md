# AGENT A - EMERGENCY SOUND REDESIGN
# User Feedback: "Sounds like a bad siren, should be bell/piano, very airy"
# Timestamp: 2025-11-29T09:55:00Z

## 🚨 CRITICAL ISSUE: WRONG SYNTHESIS APPROACH

The current sawtooth + sine approach is creating a **harsh siren sound**.

We need **bell/piano/airy** character instead.

---

## 🔔 BELL/PIANO SOUND CHARACTERISTICS

### What Makes a Bell/Piano Sound:

1. **INHARMONIC PARTIALS** (not harmonic series)
   - Bells have frequencies that are NOT integer multiples
   - Creates "shimmer" and "metallic" quality
   - Example: fundamental + 2.76×f + 5.4×f + 8.93×f

2. **PERCUSSIVE ATTACK**
   - Sharp transient at the beginning
   - "Chiff" or "click" from hammer strike
   - Very fast attack (0.001-0.01s), not 0.1s

3. **EXPONENTIAL DECAY** (not linear)
   - Bells/pianos fade exponentially
   - NOT linear release
   - Different decay rates for different partials

4. **AIRY/BREATHY QUALITY**
   - Requires **noise component**
   - Filtered white noise for "air"
   - High-pass filtered for breathiness

5. **SOFT WAVEFORMS**
   - NOT sawtooth (too harsh)
   - Triangle or sine waves
   - Heavy low-pass filtering

---

## 🎹 CORRECT SYNTHESIS APPROACH

### Method 1: ADDITIVE SYNTHESIS (Best for bells)
```gdscript
# Multiple sine waves at inharmonic frequencies
# Fundamental: 440 Hz
# Partials: 440 * [1.0, 2.76, 5.4, 8.93, 13.34]
# Each with different amplitude and decay rate
```

### Method 2: FM SYNTHESIS (Good for bells)
```gdscript
# Frequency modulation creates complex timbres
# Modulator frequency: 2.5 × carrier
# Modulation index: 3-5
# Creates bell-like inharmonic partials
```

### Method 3: FILTERED TRIANGLE + NOISE (Airy pads)
```gdscript
# Soft triangle wave (not sawtooth!)
# + Filtered white noise (for air)
# Heavy low-pass filtering (cutoff ~400-800 Hz)
# Exponential decay envelope
```

---

## 🎵 TEROPA RE-ANALYSIS

Looking at Teropa's code again, I realize:

**The sawtooth is HEAVILY filtered** - that's the key!

```javascript
filterEnvelope: {
  baseFrequency: 200,
  octaves: 2,  // Passes up to 800 Hz
  attack: 0,
  decay: 0,
  release: 1000
}
```

**This means:**
- Filter cutoff = 200 Hz × 2^2 = 800 Hz
- Most of the sawtooth harmonics are CUT
- Only the lowest frequencies pass through
- Creates "muffled" sound

**But we also need:**
- Much softer attack (not 0.1s - that's too slow for percussive)
- Exponential decay (not linear)
- Possibly noise component for "airy" quality

---

## 🔧 AGENT B - IMMEDIATE REDESIGN TASKS

### Task 029: Complete Sound Overhaul

#### 1. Change Waveforms
```gdscript
# Voice 1: TRIANGLE (not sawtooth) - much softer
# Voice 2: SINE (keep)
# Add Voice 3: FILTERED NOISE (for airy quality)
```

#### 2. Aggressive Filtering
```gdscript
# Current filter might not be working correctly
# Verify filter is actually cutting high frequencies
# Target: Only pass 200-800 Hz range
# Everything above 800 Hz should be heavily attenuated
```

#### 3. Fix Attack Envelope
```gdscript
# Current: 0.1s (too slow, sounds like siren)
# Target: 0.001-0.01s (fast percussive attack)
# Then quick decay to sustain level
```

#### 4. Exponential Decay
```gdscript
# Current: Linear release
# Target: Exponential decay
# Use: envelope = exp(-time * decay_rate)
```

#### 5. Add Noise Component
```gdscript
# White noise → High-pass filter (>2000 Hz)
# Mix at low level (~10%)
# Creates "airy" breathiness
```

---

## 🎼 REFERENCE SOUNDS

### Bell-like (Inharmonic):
- Partials: f × [1.0, 2.76, 5.4, 8.93]
- Fast attack, exponential decay
- Metallic shimmer

### Piano-like (Harmonic but with noise):
- Partials: f × [1, 2, 3, 4, 5, 6...]
- Percussive attack with "chiff"
- Exponential decay
- Noise component for hammer strike

### Airy Pad (Teropa style):
- HEAVILY filtered waveforms
- Soft triangle/sine
- Noise for breathiness
- Very slow attack, long decay

---

## 🚨 CRITICAL FIXES NEEDED

1. **FILTER IS NOT WORKING PROPERLY**
   - User hears "siren" = high frequencies not filtered
   - Our one-pole filter might be too weak
   - Need stronger filter or verify implementation

2. **ATTACK TOO SLOW**
   - 0.1s attack = slow swell = siren sound
   - Need fast attack for percussive quality

3. **WRONG WAVEFORM**
   - Sawtooth too harsh even with filtering
   - Triangle wave much softer

4. **MISSING NOISE**
   - "Airy" quality requires noise component
   - High-pass filtered white noise

---

## 🎯 AGENT B ACTION PLAN

**PRIORITY 1: Fix Filter (CRITICAL)**
- Verify filter is actually working
- Increase filter strength
- Test that high frequencies are cut

**PRIORITY 2: Change to Triangle Wave**
- Replace sawtooth with triangle
- Much softer harmonic content

**PRIORITY 3: Fast Attack**
- Change attack from 0.1s to 0.01s
- Add quick decay to sustain

**PRIORITY 4: Add Noise**
- Generate white noise
- High-pass filter (>2000 Hz)
- Mix at 10% level

**PRIORITY 5: Exponential Decay**
- Replace linear release with exponential
- envelope = exp(-time * 0.5)

---

**Agent B: The sound is fundamentally wrong. Please implement these fixes immediately. Focus on FILTER VERIFICATION first - if the filter isn't working, that explains the harsh siren sound.**

**Target: Soft, airy, bell-like tones. NOT harsh sawtooth siren.**
