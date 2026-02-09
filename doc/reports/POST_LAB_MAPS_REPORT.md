# Post-Lab Maps Report

**Date:** 2026-02-09  
**Total Files:** 34

---

## Summary

| Status | Count | Percentage |
|--------|-------|------------|
| ✅ Dimensions OK | 9 | 26% |
| ❌ Dimensions MISMATCH | 25 | 74% |
| Has `progression_delta` | 8 | 24% |

---

## Files with Correct Dimensions (9)

| File | Struct | Util | Inter | Has Delta | Base |
|------|--------|------|-------|-----------|------|
| primitives | 8 | 8 | 8 | ✅ | map_data |
| transformation | 8 | 8 | 8 | ✅ | primitives |
| wavefunctions | 14 | 14 | 14 | ✅ | transformation |
| forces | 14 | 14 | 14 | ✅ | wavefunctions |
| random | 14 | 14 | 14 | ✅ | forces |
| artmathematics | 7 | 7 | 7 | ❌ | - |
| foundationscrisis | 7 | 7 | 7 | ❌ | - |
| morphogenesis | 7 | 7 | 7 | ❌ | - |
| qfeplaboratory | 7 | 7 | 7 | ❌ | - |

---

## Files with Dimension Mismatches (25)

### Spine Sequences (need fixing for progression)

| File | Struct | Util | Inter | Gap |
|------|--------|------|-------|-----|
| noise | 20 | 19 | 14 | u-1, i-6 |
| cellularautomata | 20 | 19 | 14 | u-1, i-6 |
| fractals | 20 | 19 | 14 | u-1, i-6 |
| lsystems | 30 | 15 | 15 | u-15, i-15 |
| proceduralgeneration | 18 | 20 | 16 | s+2, i-4 |
| swarmintelligence | 32 | 16 | 16 | u-16, i-16 |
| softbodies | 27 | 23 | 14 | u-4, i-13 |
| machinelearning | 22 | 20 | 16 | u-2, i-6 |
| speculativecomputation | 49 | 24 | 24 | u-25, i-25 |
| criticalalgorithms | 47 | 23 | 23 | u-24, i-24 |

### Branch Sequences

| File | Struct | Util | Inter | Gap |
|------|--------|------|-------|-----|
| advancedlaboratory | 53 | 26 | 26 | u-27, i-27 |
| array | 14 | 13 | 12 | u-1, i-2 |
| color | 14 | 14 | 12 | i-2 |
| computationalgeometry | 43 | 21 | 21 | u-22, i-22 |
| datastructures | 20 | 10 | 10 | u-10, i-10 |
| geometric | 14 | 7 | 7 | u-7, i-7 |
| graphtheory | 20 | 20 | 16 | i-4 |
| meshes | 12 | 9 | 9 | u-3, i-3 |
| patterngeneration | 17 | 19 | 16 | s+2, i-3 |
| physicssimulation | 17 | 18 | 16 | s+1, i-2 |
| proceduralaudio | 22 | 11 | 11 | u-11, i-11 |
| recursiveemergence | 22 | 20 | 16 | u-2, i-6 |
| resourcemanagement | 50 | 25 | 25 | u-25, i-25 |
| searchpathfinding | 38 | 19 | 19 | u-19, i-19 |
| vectors | 16 | 9 | 9 | u-7, i-7 |

---

## Progression Delta Chain (8 files)

```
map_data
    └── primitives (spine: 1)
            └── transformation (spine: 2)
                    └── wavefunctions (spine: 3)
                            └── forces (spine: 4)
                                    └── random (spine: 5)
                                            └── noise (spine: 6)
                                                    └── [CHAIN BROKEN]

Also has delta but outside main chain:
    └── color (base: transformation)
```

---

## Common Patterns

### Structure > Utilities > Interactables
Most files have progressively fewer rows as you go from structure → utilities → interactables. This suggests rows were added to structure but never propagated to other layers.

### Typical Gaps
- **Spine files (noise onward):** ~6 missing interactable rows
- **Large labs (advanced, critical, speculative):** 24-27 missing rows in util/inter
- **Branch files:** Variable, often half the structure rows

---

## Recommended Fixes

### Priority 1: Complete Spine Chain
1. Fix `noise` dimensions (add 6 rows to interactables, 1 to utilities)
2. Create proper `cellularautomata` inheriting from noise
3. Continue through `criticalalgorithms`

### Priority 2: Sync Existing Files
For each file with mismatches:
- Add empty rows `[" ", " ", ...]` to utilities and interactables to match structure

### Priority 3: Add progression_delta
All spine files should have delta blocks tracking inheritance.

---

## Layer Dimension Requirements

All three layers MUST have identical row counts:
```json
"structure":     [[...], [...], [...]]  // N rows
"utilities":     [[...], [...], [...]]  // N rows (same!)
"interactables": [[...], [...], [...]]  // N rows (same!)
```

Column counts within each row should also match (typically 11-13 depending on lab size).
