# Improvement: point — gravity of reduction
artifact: commons/primitives/point/point.gd
date:     2026-05-06T12:54
sequence: primitives (seq 1)
maps:     P_Point, Gallery_Primitives_3
identity: "a 0-dimensional position primitive — a point in Euclidean space, the smallest geometry teaches abstraction"

## What to change

Two changes in one proposal:

**1. Add an `@identity` block** (the artifact existed but wasn't named in the
project's narrative grammar — a chamber proposal should always include this if
missing, since it makes future iterations reasonable):

```
essence:           a 0-dimensional position primitive
desire:            to be the player's first encounter with "everything reduces
                   to a position"
critical_parameter: global_position
truth:             a point is not a small object — it is a position made
                   visible. The seven fragments that converge on entry teach
                   abstraction physically: many things become one place.
```

**2. Add a gravity-of-reduction entrance animation** in `_ready()`:
- Spawn `FRAGMENT_COUNT = 7` small glowing yellow spheres on a 1m sphere
  around the point center
- Positions: golden-angle Fibonacci distribution (deterministic, no random)
- Animate them collapsing to the center over `ANIMATION_DURATION = 1.5s`
  with cubic ease-in
- Scale → 0 in parallel with position → 0
- `queue_free()` once the animation completes

## Why

@identity essence: *"a 0-dimensional position primitive — a point in Euclidean
space, the smallest geometry teaches abstraction."*

The animation IS the lesson. The player approaches the artifact and witnesses
*many things becoming one place*. That motion — gravity of reduction — performs
abstraction physically. By the time the entrance completes, the artifact has
shown the player what it IS: not a sphere, not a small object, but a position
made visible.

The seven-count is canonical (the smallest "many" that reads as a group rather
than as individuals). It pre-figures the line / triangle / cube primitives
that follow — each itself a structured collection of points.

## Curriculum honesty

✓ **Uses:** position, scale, translation, easing math (cubic), constants
   (golden ratio φ, TAU). Sequence 1 unlocks all of these.

✓ **Does NOT use:** `randf()` (forbidden before seq 7), Perlin/Simplex noise
   (forbidden before seq 8), particles, shaders beyond StandardMaterial3D
   emission, physics. Fragment positions are deterministic —
   `theta = i·2π/φ`, `phi = acos(1 - 2(i+0.5)/N)`.

## Captures

```
before/{front,left,right,top}.png   the original artifact at rest
after/{front,left,right,top}.png    the modified artifact at rest
                                    (camera locked to same focus + distance)
```

**Both captures use identical camera framing** — focus `(0,0,0)`, distance
`0.05m` (read from before's `capture_report.json` and passed back to the after
capture as `--fixed-focus` and `--fixed-distance` flags). This means the
before/after comparison is finally valid; any visual difference between them
is a real difference in the artifact, not a difference in how it was framed.

## What the captures show (honest finding)

Before and after are **visually identical**. The capture script waits 4 seconds
before snapping; the entrance animation completes in 1.5s; by capture time, the
seven fragments have converged to scale 0 and been freed. What the snapshot
captures is the artifact's *rest state*, which is the same in both branches —
because the proposal is non-destructive (the entrance is transient, by design).

**This is the chamber working correctly.** The visual comparison truthfully
shows: the proposed change has zero residual effect on the artifact's
appearance once the player has been there for a few seconds. That's exactly
what was designed.

But it also means the chamber **cannot visually verify transient improvements
yet** — entrance animations, hover effects, on-grab effects all live in time
windows the capture script currently can't sample. Logged as the next chamber
upgrade below.

## Open issue surfaced (chamber roadmap)

`capture_multi_angle.gd` should grow a `--at-time=<fraction>` flag. When set,
the script should:
1. Spawn the artifact
2. Drive `_process()` deterministically for `fraction × ANIMATION_DURATION`
   game-seconds (or some other configurable duration)
3. Pause the engine
4. Capture all angles

That gives the chamber **timepoint-aware visual diffs**: capture the entrance
animation at `t=0.0` (before any motion), `t=0.3` (mid-collapse, fragments
visible), `t=1.0` (settled). Three frames per state turns "before/after" into
a small filmstrip — much more useful for animation work.

This is the same shape the biome lab's per-zone walk solved for spatial diffs.
The chamber needs the temporal equivalent.

## Apply with

```bash
# verbatim — note: original main file may have a UTF-8 BOM that the patch
# doesn't preserve; if `git apply` errors with "patch does not apply", strip
# the BOM with: sed -i 's/^\xEF\xBB\xBF//' commons/primitives/point/point.gd
git apply data/chamber/draft/point/2026-05-06T12-54/changes.patch

# OR via prompt re-run (skips the patch entirely; works even if BOM mismatched)
/ada-artifact-improver point --proposal=<this-proposal-path>
```

## Decision

**Recommended status: rejected** — but for a useful reason.

The proposal itself is sound (the entrance animation is curriculum-honest,
deterministic, on-essence, and would work well in VR). What's not sound *yet*
is the chamber's ability to visually verify it. Rejecting this iteration with
the reason "needs `--at-time` capture flag in capture_multi_angle.gd" lets us
preserve the @identity block + animation code for re-application later, and
flags the architectural work that needs to happen first.

Tag: `needs-other-system` (chamber capture pipeline doesn't yet sample
animation timepoints).
