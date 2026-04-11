# Space Dystopia

A procedural audio artifact that generates a 10-track sci-fi album entirely from code. Each track uses a combination of custom DSP synthesizers -- a saxophone with formant filtering, an FM piano, wavetable synthesis, granular wind, and EpicSynthEngine patches -- orchestrated by a real-time sequencer.

## Concept Taught

**Procedural music composition and real-time audio synthesis** -- how complete musical pieces can be generated algorithmically using oscillators, filters, envelopes, and sequencing logic rather than pre-recorded audio. The system teaches several DSP concepts: PolyBLEP anti-aliased oscillators, biquad bandpass formant filters (simulating a saxophone's resonant body), ADSR envelopes, wavetable morphing, FM synthesis, Gerstner wave functions applied to sound, and Markov-chain-style note selection.

## How It Works

1. **SciFiSynth** (`SciFiSynth.gd`) is the orchestrator. It creates a reverb bus ("SpaceReverb" with large room, warm damping), instantiates all instrument nodes, and manages a state-machine sequencer. Each of the 10 tracks has a setup function (configures instruments and drones) and a sequencer function (called every frame to trigger notes based on timing and probability).

2. **SaxSynth** (`SaxSynth.gd`) implements a digital saxophone using sample-by-sample DSP:
   - **Oscillator**: PolyBLEP sawtooth wave with anti-aliasing
   - **Formant Filters**: Three biquad bandpass filters at 450Hz, 1900Hz, and 2800Hz (alto/tenor sax resonances)
   - **Breath Noise**: High-pass filtered white noise mixed with the oscillator
   - **Vibrato**: LFO-modulated pitch at 4.5Hz
   - **Growl**: 30Hz amplitude modulation for aggressive timbre
   - **Legato**: Smooth portamento glide between notes without re-triggering the envelope
   - **ADSR Envelope**: Slow attack (0.15s) for swelling sax character

3. **WavetableSynth** (`WavetableSynth.gd`) wraps a `WavetableGenerator` for morphable waveforms (sine through square). The wavetable position is automated per-track to create evolving timbres.

4. **SpaceDystopiaMain** (`SpaceDystopiaMain.gd`) provides a 2D Control UI with a dark sci-fi theme, track selection grid, and status display.

5. **SpaceDystopiaPopMain** (`SpaceDystopiaPopMain.gd`) is an alternative standalone player that generates complete audio buffers for each track using `AudioStreamGenerator` and `EpicSynthEngine` patches. It includes a full UI with track list, concept descriptions, progress feedback, and section labels.

### The 10 Tracks

| # | Title | Concept |
|---|-------|---------|
| 1 | Post-Singularity Drift | Sub-bass drone + sparse piano (Markov note selection) + granular wind |
| 2 | Interdimensional Gate | Evolving wavetable pad + digital rain blips |
| 3 | The Automated Foundry | Industrial metallic hits on a slow beat + dissonant drone |
| 4 | Augmented Noir | Saxophone solo with legato phrases + warm CS80 pad |
| 5 | Stellar Cathedral | Analog pad + choir ensemble + cold wavetable morph |
| 6 | Neon Rain | Jazz sax with rain ambience + random jazz piano voicings |
| 7 | Elegiac Skyline | Pedal steel drones in root+fifth + mournful sparse piano |
| 8 | Martian Bazaar | 120 BPM step sequencer with analog plucks + metallic percussion |
| 9 | Celestial Symphony | Solina string machine chords + bell-like FM lead melody |
| 10 | The Singularity Event | Sub-bass + string tension + fast wavetable glitch + random stabs |

## Parameters

### SaxSynth

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `output_bus` | String | "Master" | Audio bus for routing |
| `growl_amount` | float | 0.0 | Growl AM modulation depth (0.0--0.5) |

### WavetableSynth

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `output_bus` | String | "Master" | Audio bus for routing |
| `gain` | float | 0.5 | Output gain multiplier |

## Features

- Complete sample-by-sample DSP saxophone with PolyBLEP, formant filters, and legato
- Wavetable synthesis with real-time shape morphing
- 10 distinct procedural tracks with unique instrument configurations
- Probability-based note triggering (Markov-chain-lite)
- Global reverb bus with configurable room size and damping
- Step sequencer with 16th-note resolution (Track 8)
- Multiple synthesis engines: FM, subtractive, wavetable, granular
- Two UI frontends: simple grid player and full album player with concepts
- EpicSynthEngine integration for sub-bass, metallic hits, CS80 pads, pedal steel, string machine, choir, and analog plucks

## Files

| File | Description |
|------|-------------|
| `SciFiSynth.gd` | Orchestrator -- instrument setup, reverb bus, 10-track sequencer |
| `SaxSynth.gd` | Digital saxophone with PolyBLEP oscillator, formant filters, vibrato, growl |
| `WavetableSynth.gd` | Wavetable synth wrapper with gain and shape position control |
| `SpaceDystopiaMain.gd` | Simple 2D UI with track grid and status display |
| `SpaceDystopiaPopMain.gd` | Full album player with buffer generation, concepts, and section labels |
