# Map prompt: tweaked_demo

*A tweaked version of Trans_Translation. Changes from auto-generated:*
- *archetype changed from `bridge` → `promenade` (full floor instead of void edges)*
- *width 7 → 11 (wider room)*
- *depth 24 → 28 (longer walk)*
- *spawn moved to south-center, teleporter to north-center (instead of both at bottom)*
- *artifact list rewritten to use the promenade form*

**Archetype**: `promenade`
**Dimensions**: 11 wide × 28 deep × 5 tall
**Aspect ratio**: 2.55
**Spawn**: row 26, col 5
**Teleporter**: row 1, col 5

## Notes (human)

Trying to take what Trans_Translation does (translation primitives along a walk)
but with proper promenade-style pacing — paced beats with breathing room between.

---

```yaml
archetype: promenade
width: 11
depth: 28
spawn: [26, 5]
teleporter: [1, 5]
artifacts:
  - name: science_screen
    t: 0.1
    lane: spine
  - name: z_translation_cube
    t: 0.25
    lane: spine
  - name: pick_up_cube
    t: 0.35
    lane: left
  - name: pick_up_cube
    t: 0.35
    lane: right
  - name: y_translation_cube
    t: 0.5
    lane: spine
  - name: dark_sphere
    t: 0.6
    lane: left
  - name: dark_sphere
    t: 0.6
    lane: right
  - name: x_translation_cube
    t: 0.75
    lane: spine
  - name: player_trace
    t: 0.9
    lane: spine
```
