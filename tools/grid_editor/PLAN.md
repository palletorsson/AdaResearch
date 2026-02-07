# Grid Editor Element Plan

## Overview

Three element sets for different VR contexts:
1. **Audio Rack** — Wall-mounted modular synth (XY plane)
2. **Glass Rack** — Laboratory chemistry apparatus (YZ plane) 
3. **Big Pipes** — Industrial pipe system (XZ plane)

---

## 1. Audio Rack ✓ COMPLETE

**Grid:** 8cm per unit | **Plane:** XY (wall-mounted)

### Sizing System (4-unit alignment)
```
Width options: 1, 2, 4 units
Height options: 1, 2, 3 units

Monitor     = 4×3 (32×24cm) — base reference
Knob        = 1×1 (8×8cm)   — 4 fit under monitor
V-Slider    = 1×3 (8×24cm)  — 4 fit under monitor
H-Slider    = 4×1 (32×8cm)  — same width as monitor
Small disp  = 2×2 (16×16cm) — half monitor width
Wide disp   = 4×2 (32×16cm) — full width, shorter
```

### Elements

| Element | Size | Scene |
|---------|------|-------|
| Knob (osc, noise) | 1×1 | VRAudioControlDial.tscn |
| V-Slider (VCA) | 1×3 | VRAudioControlSliderVertical.tscn |
| H-Slider | 4×1 | VRAudioControlSlider.tscn |
| Filters (LP/HP/BP) | 2×2 | VRSpectrumDisplaySmall.tscn |
| ADSR | 2×2 | VRWaveformDisplaySmall.tscn |
| LFO | 2×2 | VRSimpleWaveformSmall.tscn |
| Delay | 4×2 | VRWaveformDisplayWide.tscn |
| Reverb | 4×2 | VRSpectrumDisplayWide.tscn |
| Mixer | 4×3 | VRAudioMonitor.tscn |
| Output | 4×3 | VRLissajousDisplay.tscn |
| Monitor | 4×3 | VRAudioMonitor.tscn |

### New VR Scenes Created
- VRSpectrumDisplaySmall.tscn (16×16cm)
- VRSpectrumDisplayWide.tscn (32×16cm)
- VRWaveformDisplaySmall.tscn (16×16cm)
- VRWaveformDisplayWide.tscn (32×16cm)
- VRSimpleWaveformSmall.tscn (16×16cm)
- VRAudioControlSliderVertical.tscn (8×24cm)

---

## 2. Glass Rack ✓ COMPLETE

**Grid:** 10cm per unit | **Plane:** YZ (side view) | **Procedural meshes**

### Elements — All Have Mesh Generators

| Category | Element | Size | segment_type |
|----------|---------|------|--------------|
| Vessels | Flask | 2×3 | flask |
| | Beaker | 2×2 | beaker |
| Tubes | Vertical 2 | 1×2 | straight |
| | Vertical 3 | 1×3 | straight |
| | Horizontal | 2×1 | straight (rot) |
| Bends | Corner | 2×2 | corner |
| | S-Bend | 2×2 | sbend |
| | U-Bend | 2×2 | ubend |
| Junctions | T-Junction | 2×2 | junction |
| | Y-Splitter | 2×2 | ypipe |
| | Cross | 2×2 | cross |
| Condensers | Spiral | 1×4 | spiral |
| | Jacketed | 1×3 | condenser |
| Terminals | Cap | 1×1 | cap |
| | Drip | 1×1 | drip |

### Future Additions (optional)
- [ ] Funnel (2×2?)
- [ ] Stopcock/valve (1×1)
- [ ] Separating funnel
- [ ] More tube lengths

---

## 3. Big Pipes ✓ COMPLETE

**Grid:** 2m per unit | **Plane:** XZ (top-down) | **Scene-based**

### Elements

| Category | Element | Size | Scene |
|----------|---------|------|-------|
| Basic | Straight | 1×1 | pipe_straight.tscn |
| Turns | Corner Left | 1×1 | pipe_corner.tscn (rot 90) |
| | Corner Right | 1×1 | pipe_corner.tscn (rot 0) |
| | S-Bend | 2×1 | pipe_s_bend.tscn |
| Junctions | T-Junction | 1×1 | pipe_t_junction.tscn ✓ NEW |
| | Cross | 1×1 | pipe_cross.tscn ✓ NEW |
| Vertical | Bend Up | 1×1 | pipe_vertical_up.tscn ✓ NEW |
| | Bend Down | 1×1 | pipe_vertical_down.tscn ✓ NEW |
| Terminals | End Cap | 1×1 | pipe_end_cap.tscn ✓ NEW |

### New Pipe Scenes Created
- pipe_t_junction.tscn
- pipe_cross.tscn
- pipe_vertical_up.tscn
- pipe_vertical_down.tscn
- pipe_end_cap.tscn

---

## Summary

| Set | Grid | Plane | Elements | Status |
|-----|------|-------|----------|--------|
| Audio Rack | 8cm | XY | 16 | ✓ Complete |
| Glass Rack | 10cm | YZ | 15 | ✓ Complete |
| Big Pipes | 2m | XZ | 9 | ✓ Complete |

All three element sets now have:
- Proper sizing aligned to their grid system
- Working VR scenes (no broken references)
- Complete element coverage for basic use cases
