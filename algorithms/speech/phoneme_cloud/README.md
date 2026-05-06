# Vowel Synthesis: "The Field"

This system implements the **Ada Research Vowel Theory**, treating vowels not as audio samples but as **Resonant Field Configurations**.

> "The Vowel is a Field Configuration constraining a Harmonic Source."

## 1. Core Architecture (`vowel_synth.gd`)

The synthesizer implements the **Minimal Vowel Model**:
*   **Source**: Band-Limited Sawtooth Oscillator (Harmonic richness).
*   **Topology**: **Parallel** Band-Pass Filters.
*   **Parameters**:
    *   **F1 (Openness)**: Vertical axis (200Hz - 900Hz).
    *   **Delta (Identity)**: Horizontal axis (F2 - F1). This single parameter effectively distinguishes vowels (e.g., /i/ vs /u/).
    *   **Drift (Life)**: Parameters are never static; slight LFO modulation prevents "synthy" death.

### The Anchor Points
We navigate this field using 5 primary anchors (hardcoded):
*   `/i/`: F1=240, Delta=2160 (Closed, Front)
*   `/e/`: F1=390, Delta=1910
*   `/a/`: F1=850, Delta=760  (Open, Back)
*   `/o/`: F1=360, Delta=280
*   `/u/`: F1=250, Delta=345  (Closed, Back)

## 2. The Sound Board (`vowel_sound_board.tscn`)

A 3D interface for embodied exploration of the vowel space.
*   **Interface**: Uses `ValueMapper3D` (Cube).
    *   **X-Axis**: Delta (Vowel Color).
    *   **Y-Axis**: F1 (Jaw Height).
    *   **Z-Axis**: Intensity.
*   **Visualization**:
    *   **Anchors**: Visible 3D labels (`/i/`, `/a/`) show the phoneme locations in the field.
    *   **Trace**: A glowing magenta line trails the cursor, allowing you to "read" the geometric shape of words in the air (e.g., "Ada" forms a triangle).

## 3. Automation ("Ada Research")

The `vowel_sound_board.gd` script includes an **Ambient Loop**:
1.  **"Ada"**: A sequence of tweened field configurations (Start A -> Plosive Shift -> Return A).
2.  **"Research"**: A complex glide sequence (R -> i -> S-gap -> er -> ch-cut).
3.  **"Now and Then"**: The sequence repeats with a 4-second pause, acting as an installation piece.

## 4. Theory
See [theory_vowel_field.md](theory_vowel_field.md) for the philosophical basis of the "Point, Line, Trace" mapping.
