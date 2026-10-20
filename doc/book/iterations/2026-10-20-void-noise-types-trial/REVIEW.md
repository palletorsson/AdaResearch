# Independent review — Noise trial

Claude Code built the separate `noise` trial. Codex reviewed the native test
records, editor save test, exported models and rendered encounter.

- Native desktop + synthetic XR: 129 checks passed.
- Mobile synthetic XR run: 69 checks passed.
- Editor: 12 checks passed, including a live bench move/save/reload/Desktop
  mirror and restoration of the authored arrangement.
- Active-floor review capture: 4 checks passed; no engine script errors.
- All six museum artifacts have independent placement records and real model
  previews in the lab editor. Related Weather remains one artifact containing
  its three coordinated walls; its internal walls are not separate editor props.
- No physical headset session or headset performance measurement was performed.

The initial capture run photographed floor 1 after the player had descended.
Streaming hid the exhibits. Those images remain in `images/` as run evidence,
but are not published as encounter views. `capture_review.py` keeps the player
on floor 1, runs the weather to expose its changing apertures, and captures the
active artifacts into `review-images/`.

Published and visually inspected: bench arrival, bench close, galleries,
weather corridor, weather lane. The wide view is pillar-obscured and the
controls view sees the back of the panel, so neither is used in the report.
The first arrival view also shows a work light overlapping the surface's
readout from that particular viewpoint; the editable light can be repositioned
during curation.

The review changed capture/report files only. It did not change the trial
layout, artifact algorithms, chapter texts, or player controls.

Open the lab editor:
http://localhost:3003/lab-editor?mode=void&trial=noise&floor=1

Play: Main menu → Void trials → Noise.
