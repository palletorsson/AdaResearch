# Chord Tension Spring

Translates harmonic tension into physical spring behavior: consonant chords relax, dissonant chords vibrate and strain. Teaches the concept of musical consonance and dissonance by making interval relationships visible and tangible through spring physics.

## How It Works

Four pitch nodes are arranged in a circle and connected by springs. Each spring's stiffness is derived from the consonance rating of its interval (based on simple frequency ratios). Consonant intervals produce relaxed, still springs; dissonant intervals produce tight, jittering springs that resist settling. The user can click nodes to cycle pitches or select preset chords (major, minor, dominant 7th, tritone, etc.). Real-time audio synthesis generates the chord tones, adding subtle noise proportional to tension. A QFEP audit note reminds users that consonance ratings encode Western music theory norms, not universal laws.

## Parameters

This artifact uses constants rather than `@export` variables. Key configurable values are defined as `const`:

- `NUM_NODES` = 4 (root, third, fifth, seventh)
- `BASE_RADIUS` = 0.35 (layout radius)
- `SPRING_K_MIN` / `SPRING_K_MAX` = 0.5 / 30.0 (spring stiffness range)
- `CONSONANCE` array maps semitone intervals 0--11 to consonance ratings

## Features

- Spring physics simulation driven by interval consonance ratings
- Eight chord presets: major, minor, dim, aug, dom7, maj7, sus4, tritone
- Real-time audio synthesis with sine + harmonic voices per pitch node
- Color-coded nodes (green = consonant, red = dissonant) and coil springs
- Tension percentage readout and automatic chord name detection
- VR-compatible with clickable preset buttons and node interaction
- QFEP-audited: acknowledges Western cultural bias in consonance ratings

## Files

- `chord_tension_spring.gd` -- Main script
- `chord_tension_spring.tscn` -- Scene file
