# Vowel Synthesis & Phoneme Cloud

This system provides a **parametric, formant-based speech synthesizer** designed for the Quest (running offline in Godot 4). It is not a sample player but a real-time DSP instrument.

## 1. Architecture

### The Engine (`vowel_synth.gd`)
*   **Source**: Band-limited sawtooth oscillator (simulating vocal fold buzz).
*   **Resonance**: 3 Parallel Biquad Bandpass Filters (`F1`, `F2`, `F3`).
    *   **F1**: Correlates to Jaw Openness (Low=Open, High=Closed).
    *   **F2**: Correlates to Tongue Position (Low=Back, High=Front).
*   **Noise**: High-passed White Noise generator for fricatives (s, sh, ch).

### Data (`vowels.json`)
Stores the formant frequencies for each vowel.
*   `/a/`: F1=800, F2=1150 (Open Back)
*   `/i/`: F1=270, F2=2290 (Closed Front)
*   `/u/`: F1=300, F2=870 (Closed Back)

## 2. "Saying Ada Research"

The Sequence in `test_vowel.gd` demonstrates dynamic control:

1.  **"Ada"**
    *   Sustain `/a/`.
    *   **Articulation**: Rapidly shift F1/F2 to the alveolar plosive locus (/d/ is implied by the rapid movement toward `F1=200`, `F2=1800`) + momentary silence (closure).
    *   Burst back to `/a/`.

2.  **"Research"**
    *   **"Re"**: Glide from `/r/` formants to `/i/` formants.
    *   **"s"**: Cut Voice Intensity, boost **Noise Intensity**. This creates the hiss.
    *   **"ear"**: Glide formants from `/er/` (Schwa) to `/r/` (coloring).
    *   **"ch"**: Silence (stop) followed by a short, sharp **Noise Burst**. The noise is high-passed to sound crisp rather than "thumpy".

## 3. Embodied Control (`vowel_instrument.gd`)

Maps physical VR hand position to the vocal tract:
*   **Hand Height (Y)** -> **F1** (Jaw)
*   **Hand Forward (Z)** -> **F2** (Tongue)
*   **Trigger** -> **Air Pressure** (Volume)

This allows you to "sculpt" the vowel sound in 3D space.
