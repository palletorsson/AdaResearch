# Lab Progression Consistency Report

**Date:** 2026-02-09  
**Analyzed:** 34 post_* lab files

---

## Executive Summary

| Metric | Count | Status |
|--------|-------|--------|
| Total post_* files | 34 | |
| Have `progression_delta` | 8 | 🔴 24% |
| Layer dimensions match | 9 | 🔴 26% |
| On spine (curriculum_spine.json) | 18 | |
| Off spine (branch sequences) | 16 | |

**Critical:** Most files have broken layer dimensions and no progression tracking.

---

## Spine Files (curriculum_spine.json order)

These are the 18 main progression files:

| # | File | Delta | Base | Dimensions | Status |
|---|------|-------|------|------------|--------|
| 1 | primitives | ✅ Yes | map_data | 8×8×8 | ✅ OK |
| 2 | transformation | ✅ Yes | post_primitives | 8×8×8 | ✅ OK |
| 3 | wavefunctions | ✅ Yes | post_transformation | 14×14×14 | ✅ OK |
| 4 | forces | ✅ Yes | post_wavefunctions | 14×14×14 | ✅ OK |
| 5 | random | ✅ Yes | post_forces | 14×14×14 | ✅ OK |
| 6 | noise | ✅ Yes | post_random | 20×19×14 | ❌ MISMATCH |
| 7 | cellularautomata | ❌ No | - | 20×19×14 | ❌ MISMATCH |
| 8 | fractals | ❌ No | - | 20×19×14 | ❌ MISMATCH |
| 9 | lsystems | ❌ No | - | 30×15×15 | ❌ MISMATCH |
| 10 | proceduralgeneration | ❌ No | - | 18×20×15 | ❌ MISMATCH |
| 11 | morphogenesis | ❌ No | - | 7×7×7 | ✅ OK |
| 12 | swarmintelligence | ❌ No | - | 32×16×16 | ❌ MISMATCH |
| 13 | softbodies | ❌ No | - | 27×23×14 | ❌ MISMATCH |
| 14 | machinelearning | ❌ No | - | 22×20×15 | ❌ MISMATCH |
| 15 | foundationscrisis | ❌ No | - | 7×7×7 | ✅ OK |
| 16 | qfeplaboratory | ❌ No | - | 7×7×7 | ✅ OK |
| 17 | speculativecomputation | ❌ No | - | 49×24×24 | ❌ MISMATCH |
| 18 | criticalalgorithms | ❌ No | - | 47×23×23 | ❌ MISMATCH |

**Spine status:** 5/18 files are correct (primitives→random). Everything from noise onward needs fixing.

---

## Branch Files (off-spine sequences)

| File | Delta | Dimensions | Status |
|------|-------|------------|--------|
| advancedlaboratory | ❌ | 53×26×26 | ❌ MISMATCH |
| array | ❌ | 14×13×12 | ❌ MISMATCH |
| artmathematics | ❌ | 7×7×7 | ✅ OK |
| color | ✅ Yes | 14×14×12 | ❌ MISMATCH |
| computationalgeometry | ❌ | 43×21×21 | ❌ MISMATCH |
| datastructures | ❌ | 20×10×10 | ❌ MISMATCH |
| geometric | ❌ | 14×7×7 | ❌ MISMATCH |
| graphtheory | ❌ | 20×20×15 | ❌ MISMATCH |
| meshes | ❌ | 12×9×8 | ❌ MISMATCH |
| patterngeneration | ❌ | 0×0×0 | ❌ EMPTY |
| physicssimulation | ❌ | 17×18×15 | ❌ MISMATCH |
| proceduralaudio | ❌ | 22×11×11 | ❌ MISMATCH |
| recursiveemergence | ❌ | 22×20×15 | ❌ MISMATCH |
| resourcemanagement | ❌ | 50×25×25 | ❌ MISMATCH |
| searchpathfinding | ❌ | 38×19×19 | ❌ MISMATCH |
| vectors | ❌ | 16×9×9 | ❌ MISMATCH |

---

## Common Issues

### 1. Layer Dimension Mismatches
Most files have `structure` with more rows than `utilities` and `interactables`.
This will cause grid system crashes or missing content.

**Example (cellularautomata):**
```
structure:     20 rows
utilities:     19 rows  ← missing 1 row
interactables: 14 rows  ← missing 6 rows
```

### 2. Missing progression_delta
Only 8/34 files track their inheritance chain.
Without delta, we can't:
- Validate cumulative changes
- Auto-generate files from previous state
- Audit what changed between states

### 3. No Cumulative Inheritance
Files after `random` don't follow the established pattern.
They appear to be independent copies rather than incremental builds.

### 4. Inconsistent Lab Sizes
The lab jumps between very different sizes:
- Compact: 7-8 rows (primitives, foundationscrisis, qfep)
- Medium: 14-20 rows (wavefunctions→noise)
- Large: 30-53 rows (speculativecomputation, advancedlaboratory)

---

## Recommended Fix Order

### Priority 1: Complete spine chain (noise → criticalalgorithms)
Fix the 12 remaining spine files to have:
- Matching layer dimensions
- Proper progression_delta
- Cumulative inheritance from previous

### Priority 2: Fix branch files
Branch files should inherit from their unlock point on the spine.

### Priority 3: Validate content
Ensure artifacts mentioned in progression_delta actually exist in interactables.

---

## Files Fixed So Far

| File | Commit | Status |
|------|--------|--------|
| post_primitives | 57d2ce7c | ✅ |
| post_transformation | 57d2ce7c | ✅ |
| post_wavefunctions | 57d2ce7c + a2be0f3b | ✅ |
| post_forces | 57d2ce7c | ✅ |
| post_random | 57d2ce7c + a2be0f3b | ✅ |
| post_noise | 57d2ce7c + a2be0f3b | ⚠️ Dimensions still mismatched |

---

## Next Steps

1. Fix `post_noise` layer dimensions (add 6 empty rows to interactables)
2. Create `post_cellularautomata` with proper delta from noise
3. Continue down spine to `post_criticalalgorithms`
4. Then address branch files based on unlock points
