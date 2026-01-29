# Speech Synthesis

Phonemes, formants, and the physics of voice.

## QFEP Connection

Speech is **structured entropy** — phonemes are discrete symbols (F) but their acoustic realization varies continuously (E). The vocal tract is a resonant filter that shapes noise into meaning. Language itself is QFEP: grammar (order) + usage (variation).

## Contents

| File | Description |
|------|-------------|
| `PhonemeCloud.gd` | Spatial phoneme visualization |
| `PhonemeGenerator.gd` | Generate phoneme sounds |
| `vowel_synth.gd` | Vowel synthesis via formants |
| `vowel_synth_headless.gd` | Headless vowel synthesis |
| `vowel_instrument.gd` | Playable vowel instrument |
| `vowel_sound_board.gd` | Soundboard of vowel sounds |
| `test_vowel.gd` | Vowel testing utilities |

## Key Concepts

1. **Phoneme** — Smallest unit of speech sound (/p/, /a/, /t/)
2. **Formant** — Resonant frequency of vocal tract (F1, F2, F3)
3. **Vowel space** — 2D space defined by F1 (height) and F2 (frontness)
4. **Source-filter model** — Vocal cords (buzz) + vocal tract (filter)
5. **Consonants** — Obstructions and releases of airflow

## Vowel Formant Space

```
        F2 (frontness)
        High ←──────────→ Low
    ┌─────────────────────────┐
H F1│  i         u            │
e   │     e           o       │
i   │         ə               │
g   │     ɛ           ɔ       │
h   │         a               │
t   │  æ                      │
    └─────────────────────────┘
```

Each vowel is a point in F1×F2 space:
- /i/ (beet): low F1, high F2
- /a/ (bot): high F1, low F2
- /u/ (boot): low F1, low F2

## VR Experience

- Navigate the phoneme cloud in 3D
- Hear sounds as you move through space
- Play the vowel instrument with hand tracking
- See formant visualizations

## Files

- 7 GDScript files
- 6 scene files
