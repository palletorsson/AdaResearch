# Fold, fall, again — 2026-10-04

Implemented in the existing Point_Animatedcube net at grid (4,10).
Six original faces fold into a cube; a rigid body falls onto the real floor;
the cube settles, waits 2.2 seconds, rises and reopens. No separate replacement cube.
Native checks: 24 passed, two complete cycles. Physical headset untested.
Main text, museum companion, technical notes and inventory updated. Student lesson retained.

Reproduce:
```
python tools/capture_cube_net_cycle.py
python tools/publish_cube_net_cycle.py
python tools/export_book_captures.py --sequence primitives
```

The private capture project isolates museum control files and saves native frames.
FFmpeg encodes the measured frame intervals. Page contains no JavaScript.
The sibling ada_encyclopedia review route now serves MP4 with byte-range seeking,
using its existing audio range handler. No changes committed in this pass.
