# Synthesis Lab — changes and validation

- Complete three-file tutorial, continuing PointBody and LineSkin: five coefficients, weighted sine sum, shared phase, baseline copy. One independent odd-harmonic variation.
- Reflective text preserves the original slope, omission/threshold questions and Room Memory listening encounter; implementation blocks moved out of the main reading. Lucier and reverberation references verified.
- Retained all 26 authored placements in a 24x32m hall. Supported specimen benches and scaled spatial studies; reference sphere moved clear of the exit approach.
- Existing additive bench: only display lift changes, 1.75m to 2.15m. Mathematics, gains, controls and state preserved. The baseline's fifth row is now above the readout.
- Double helix: new optional max_trail_drop, set only here through trail_drop:4.8. The spatial bound prevents its falling trail from passing through the footing at slow frame rates. Original unconfigured behaviour unchanged.
- 26 exact printed-code checks pass; three deliberate faults rejected. 161 actual-museum checks pass. Images are native captures; the student program was installed temporarily for validation.
- Limits: teacher-authored tests; no independent student, headset comfort, full Room Memory travel or audio-quality validation. The selected tutorial is visual.

Reproduce from repository root:

```powershell
python -X utf8 tools/publish_wavefunctions_synthesis.py
python -X utf8 tools/test_wavefunctions_synthesis.py
python -X utf8 tools/capture_wavefunctions_synthesis.py
python -X utf8 tools/publish_wavefunctions_synthesis.py
```

Map arrangement is already saved. Original texts, map and changed production sources remain under before/. The editable execution-plan entry and durable context are updated; its decision remains draft for review. Next sequence: Randomness.
