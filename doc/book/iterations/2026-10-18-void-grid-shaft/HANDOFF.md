# Grid on Trace — 2026-10-18

User decision: entire Grid encounter on Trace floor 04, not a separate floor.
Original grid_lines.tscn is nested in record/GridReplay. Lattice world (-10,-25,0); controls (-6.9,-22.8,1.8). Uses actual shared TraceData; no sample records seeded in production.

21 native assertions pass including synthetic XR pickup/release, retained source, derived copy, paging, open shaft, part movement/copy, streaming and retry. Mobile captures in this folder. No physical headset test.

Exported to ada_encyclopedia/public/void-models. Lab editor floor=4 exposes GridReplay. rooms.json equals the before-task snapshot; floor 05 unassigned. Original museum map and book texts unchanged.

Run: python tools/test_void_grid.py --capture; python tools/export_void_editor.py; python tools/validate_void_rooms.py.

Also fixed soundscape.gd zero-argument button hooks: only unbind signal arguments when count > 0. Other soundscape work is concurrent; preserve it.
