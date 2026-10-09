# Another one — 2026-10-04

Implemented in the existing Point_Animatedcube net at grid (4,10).
Six faces fold into a cube, shrink to 45 percent, and are copied into a rigid body.
The cube stays on the floor; after 2.2 seconds the working net grows and reopens.
Each cycle leaves another cube. Collection bounded to 24 bodies, oldest retired.
Native checks: 29 passed, two complete cycles. Physical headset untested.
Separate physics fixture: 26 drops settled, 24 bodies retained at the limit.
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
