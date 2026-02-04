# Live Session

Real-time performance environment for AdaResearch. 909 kick, 909 hats, TB-303 acid bass.

## Quick Start

Open `LiveSession.tscn` in Godot and run it.

## Controls

### Transport
- **SPACE** - Play/Stop

### DJ Moves
- **T** - Build Tension (filter closes, pattern intensifies)
- **D** - DROP (filter opens, accent maxes)
- **B** - Breakdown (kill kick/hats, solo 303)
- **R** - Bring It Back (restore energy)

### Live Control
- **↑** - Filter sweep up
- **↓** - Filter sweep down
- **N** - Generate new acid pattern
- **1** - Mute/unmute kick
- **2** - Mute/unmute hats
- **3** - Mute/unmute acid

## Architecture

```
LiveSession.gd/tscn  ← The full environment (open this)
    │
    ├── LiveRack.gd      ← State machine: patterns, params, sequencer
    │
    └── LiveAudioEngine.gd  ← Real-time synthesis via AudioStreamGenerator
```

## The Signal Flow

```
┌─────────────────────────────────────────────────────────────┐
│                      LIVE SESSION                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   ┌──────────┐    ┌──────────┐    ┌──────────────────┐     │
│   │  909     │    │  909     │    │  TB-303          │     │
│   │  KICK    │    │  HATS    │    │                  │     │
│   │          │    │          │    │  SAW ──┐         │     │
│   │ SINE─┐   │    │ 6xSQ ─┐  │    │        ▼         │     │
│   │      ▼   │    │       ▼  │    │    ┌──────┐      │     │
│   │  PITCH   │    │    HPF   │    │    │18dB  │      │     │
│   │   ENV    │    │          │    │    │DIODE │◀─RES │     │
│   │      │   │    │          │    │    │FILTER│      │     │
│   │      ▼   │    │          │    │    └──┬───┘      │     │
│   │   +CLICK │    │          │    │       │◀─ENV    │     │
│   │      │   │    │      │   │    │       ▼         │     │
│   │      ▼   │    │      ▼   │    │    ACCENT       │     │
│   └────[VOL]─┘    └────[VOL]─┘    │       │         │     │
│         │              │          │       ▼         │     │
│         │              │          └────[VOL]────────┘     │
│         │              │                │                  │
│         └──────────────┴────────────────┘                  │
│                        │                                   │
│                        ▼                                   │
│                 ┌────────────┐                             │
│                 │  MASTER    │                             │
│                 │  24dB LPF  │                             │
│                 │  + DRIVE   │                             │
│                 └─────┬──────┘                             │
│                       │                                    │
│                       ▼                                    │
│                   SPEAKERS                                 │
└─────────────────────────────────────────────────────────────┘
```

## The 303 Acid Line

### How It Works
1. **Sawtooth oscillator** (or square) at note frequency
2. **18dB diode ladder filter** - the signature 303 sound
3. **Decay-only envelope** controls filter cutoff
4. **Accent** boosts envelope depth AND resonance
5. **Slide** creates portamento between notes

### The Secret Formula
```
ACCENT + SLIDE + OCTAVE JUMP = MAXIMUM SQUELCH
```

When an accented note slides up an octave, the filter envelope fires hard while resonance spikes. That's the scream.

### Pattern Generation
- **Wildness** slider controls note density and variation
- Patterns auto-mutate every 4 bars based on intensity
- Press **N** to generate a completely new pattern

## The 909 Drums

### Kick
- **Pitch envelope**: 150Hz → 55Hz in ~20ms (the punch)
- **Click transient**: Short high-frequency burst
- **Decay**: How long the body sustains

### Hats
- **6 square wave oscillators** at non-harmonic ratios
- Creates metallic, inharmonic shimmer
- Open hat = longer decay

## Performance Tips

### Building a Set

1. **Start sparse** - Kick only, hats at low level
2. **Bring in acid** slowly - Level up over 16 bars
3. **Filter closed** initially - Let it breathe
4. **Build tension** - T key, wait 32 bars
5. **DROP** - D key on the 1

### Reading the Room (Even If It's Just You)

- **Tension needs time** - Don't rush the drop
- **Breakdowns reset energy** - Use them to extend the journey
- **Filter sweeps are phrases** - 8, 16, 32 bars
- **Mutes are punctuation** - Kill the kick for 4 bars, bring it back harder

### The 4AM Vibe

The goal isn't peak-time bangers. It's:
- Lock into a groove
- Let it hypnotize
- Small changes over long periods
- When the filter finally opens, it's earned

## Technical Notes

- Audio generated in real-time via `AudioStreamGenerator`
- 44.1kHz sample rate
- All synthesis is procedural (no samples)
- Filter states persist between notes for proper resonance behavior
- Timing synced to BPM via sample-accurate step triggering

## Files

```
commons/audio/live/
├── LiveSession.gd/tscn    ← Open this
├── LiveRack.gd            ← Sequencer + state
├── LiveAudioEngine.gd     ← Real-time synthesis
├── LiveDeck.gd/tscn       ← Alternative UI (standalone)
└── README.md              ← This file
```
