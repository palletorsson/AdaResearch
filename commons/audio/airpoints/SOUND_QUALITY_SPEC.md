# AGENT A - REFINED SOUND QUALITY SPECIFICATION
# Based on detailed Teropa article analysis
# Timestamp: 2025-11-29T09:50:00Z

## 🎵 CRITICAL SOUND QUALITIES FROM TEROPA'S DISCREET MUSIC

After re-reading the article, here are the **essential sound characteristics** we must achieve:

---

### 1. **"WARM SYNTH WASHES"** (Primary Goal)
The sound should NOT be harsh or sharp. It must be:
- **Muffled** and **soft**
- **Warm** and **organic**
- Like "synth washes" - smooth, flowing, ambient

**How to achieve:**
- Low-pass filter is CRITICAL
- Filter must "take out higher frequencies"
- Result: "very different, softer sound"

---

### 2. **DUAL OSCILLATOR CHARACTER**
Two voices working together:
- **Voice 0 (Sawtooth)**: Harmonically rich foundation
- **Voice 1 (Sine)**: Pure fundamental tone
- **Harmonicity = 1**: Both play the SAME note (not octaves)
- Mix creates "fuller sound" without being "eerie"

**Current Issue:** We might have harmonicity wrong - need to ensure both voices play same frequency

---

### 3. **"ALMOST IMPERCEPTIBLE" VIBRATO**
Emulates tape wow (analog flutter):
- **Rate**: 0.5 Hz (very slow)
- **Depth**: 0.1 (very slight)
- **Goal**: "You hear a difference but not so much that it draws attention to itself"
- Should feel like **warm analog flutter**, not obvious pitch wobble

**Current Status:** ✅ Implemented correctly

---

### 4. **ENVELOPE CHARACTERISTICS**

**Attack (0.1s):**
- Sound "ramps up" for a tenth of a second
- NOT abrupt - soft fade-in

**Release (4s, LINEAR curve):**
- VERY slow fading out
- Must be LINEAR (not exponential)
- Sound "lingers for a while before they go"
- Creates ambient sustain

**Filter Envelope:**
- Attack: 0 (instant)
- Decay: 0 (instant)
- Release: 1000s (essentially infinite - never drops)
- **Critical:** Filter must NOT drop during release

**Current Issue:** Need to verify filter envelope doesn't interfere with release

---

### 5. **ECHO / FEEDBACK DELAY**
Short echo for layering:
- **Delay Time**: 16th note (~0.1-0.2s at 120 BPM)
- **Feedback**: 0.2 (subtle repetition)
- **Purpose**: Layers sound on itself
- **Volume**: Reduce synth by -20dB to prevent distortion

**Current Status:** ❌ Not implemented yet

---

### 6. **TAPE DELAY (FRIPPERTRONICS)**
Long delay for ambient repetition:
- **Delay Time**: ~6 seconds (physical tape travel distance)
- **Feedback**: ~0.4-0.6 (gradual fade)
- **Character**: "Completely new sound that just happens to be a repetition"
- **Purpose**: Creates evolving ambient layers

**Current Status:** ❌ Not implemented yet

---

### 7. **VOLUME MANAGEMENT**
- Base synth: **-20dB** (to prevent distortion with echo)
- With delays, sound layers on itself
- Must avoid clipping/distortion

**Current Issue:** We're at 0dB, need to reduce

---

## 🔧 IMMEDIATE FIXES NEEDED (Agent B)

### Priority 1: SOUND QUALITY
```gdscript
# 1. Reduce base volume
volume_db = -20.0  # Critical for clean sound with delays

# 2. Verify harmonicity = 1 (both voices same frequency)
# Currently: harmonicity modulates 0.8-1.2
# Should be: harmonicity = 1.0 (fixed, or very subtle variation)

# 3. Ensure filter envelope doesn't drop during release
# Filter release should be VERY long (1000s) so it never affects sound
```

### Priority 2: ADD ECHO DELAY
```gdscript
# Short feedback delay (16th note)
# Delay: ~0.15s (at 120 BPM)
# Feedback: 0.2
# Creates subtle layering
```

### Priority 3: ADD TAPE DELAY (FRIPPERTRONICS)
```gdscript
# Long feedback delay (6 seconds)
# Delay: 6.0s
# Feedback: 0.5
# Creates ambient repetition
```

---

## 🎼 SOUND QUALITY CHECKLIST

From Teropa's descriptions, the sound should be:

- [ ] **"Warm"** - not harsh or bright
- [ ] **"Muffled"** - high frequencies filtered out
- [ ] **"Soft"** - gentle attack and release
- [ ] **"Fuller"** - dual oscillators blended
- [ ] **"Almost imperceptible vibrato"** - subtle tape wow
- [ ] **"Lingering"** - long release (4s)
- [ ] **"Layered"** - echo creates depth
- [ ] **"Ambient"** - tape delay creates evolving texture
- [ ] **"No distortion"** - proper volume management

---

## 📊 CURRENT vs TARGET

| Parameter | Current | Target (Teropa) | Status |
|-----------|---------|-----------------|--------|
| Voice 0 | Sawtooth | Sawtooth | ✅ |
| Voice 1 | Sine | Sine | ✅ |
| Harmonicity | 0.8-1.2 (modulated) | 1.0 (fixed) | ⚠️ |
| Filter Base | 200 Hz | 200 Hz | ✅ |
| Filter Octaves | 2 | 2 | ✅ |
| Filter Attack | 0 | 0 | ✅ |
| Filter Decay | 0 | 0 | ✅ |
| Filter Release | ? | 1000s | ⚠️ |
| Amp Attack | 0.1s | 0.1s | ✅ |
| Amp Release | 4s | 4s (linear) | ✅ |
| Vibrato Rate | 0.5 Hz | 0.5 Hz | ✅ |
| Vibrato Depth | 0.1 | 0.1 | ✅ |
| Volume | -8dB | -20dB | ❌ |
| Echo Delay | None | 16n (~0.15s) | ❌ |
| Echo Feedback | None | 0.2 | ❌ |
| Tape Delay | None | 6s | ❌ |
| Tape Feedback | None | 0.5 | ❌ |

---

## 🎯 AGENT B TASKS (IMMEDIATE)

### Task 026: Fix Sound Quality
**Priority: CRITICAL**

1. Set `volume_db = -20.0` in synth
2. Fix harmonicity to 1.0 (or very subtle variation ±0.05)
3. Verify filter doesn't interfere with release
4. Test that sound is "warm" and "muffled", not harsh

### Task 027: Add Echo Delay
**Priority: HIGH**

Create `SystemsMusicEcho.gd`:
- Short FeedbackDelay (16th note)
- Delay time: 0.15s
- Feedback: 0.2
- Insert between synth and output

### Task 028: Add Tape Delay (Frippertronics)
**Priority: MEDIUM**

Create `SystemsMusicTapeDelay.gd`:
- Long FeedbackDelay (6 seconds)
- Delay time: 6.0s
- Feedback: 0.5
- Creates ambient repetition

---

## 🎨 THE GOAL SOUND

Teropa describes it as:
> "Warm synth washes"
> "Almost imperceptible vibrato"
> "Sound lingers for a while"
> "Completely new sound that just happens to be a repetition"

The sound should feel:
- **Ambient** and **spacious**
- **Organic** (like analog tape)
- **Evolving** (delays create layers)
- **Gentle** (no harsh attacks or distortion)
- **Hypnotic** (slow vibrato, long delays)

---

**Agent B: Please implement Task 026 immediately to fix the sound quality. The current sound is likely too harsh/bright. We need "warm synth washes".**

**Status:** Awaiting Agent B implementation
