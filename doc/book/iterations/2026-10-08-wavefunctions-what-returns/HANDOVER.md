# Wavefunctions — start with the cube

Author correction, 8 October: “here we start with cube.” This supersedes the previous pendulum-first lesson.

The active opening script is `doc/book/studies/wavefunctions-lineage/01_cube_return.gd`. It continues Transformation with one BoxMesh, elapsed time and a vertical sine function. Teach amplitude, frequency/period and phase; build independent instances for comparison. No hand-release mechanism or companion class in this opening.

Canonical Intro tutorial and final both begin with the cube. The execution-plan Intro and Pendulum summaries, hall description, learning objectives and sequence description reflect that correction. All artifact placements and production artifact code are retained.

The pendulum remains an existing comparison in Intro and develops in the next hall. Next task: distinguish the responding swing from the cube's prescribed cycle and reuse Trace for named timestamped records, sampling intervals and bounded history. Do not assume that the learner already built the superseded pendulum study.

Validation: 23 native checks on the exact printed cube program, two deliberate faults rejected, 15 real-hall placement/display/capture checks. Teacher-authored checks; no independent ghost-student or headset claim. The original 28/17 pendulum results are historical, archived under `superseded-pendulum`.

The authored entrance still uses the museum's safe fallback. Full passage and headset validation remain open. The existing cube demonstration shares a crowded area with other exhibits; this text correction has not rearranged that area.

To publish, edit `intro-tutorial.md`, `intro-final.md` and `01_cube_return.gd` beside one another. Then run:

```powershell
python -X utf8 tools/publish_wavefunctions_opening.py
python -X utf8 tools/test_wavefunctions_opening.py
python -X utf8 tools/capture_wavefunctions_lessons.py after WaveFunctions_Intro
python -X utf8 tools/publish_wavefunctions_opening.py
```

Form Finding remains paused. The eleven remaining Wavefunctions lessons are plans, not newly validated programs. Read ROUTE.md before continuing.
