**Poisson Disk Sampling**
Blue Noise, Organic Spacing, Minimum Distance

**Poisson Disk Sampling generates points that are evenly spaced but not regular.**

**Not a grid** (too uniform, artificial)
**Not random** (too clumpy, uneven)
**Blue noise** (organic, natural, evenly distributed)

**The constraint:** No two points closer than **minimum distance** (r).

**The result:** Points fill space efficiently while maintaining separation - like seeds dispersed by wind, trees in a forest, cells in tissue.

**This is organic distribution** - structured but not rigid, spaced but not gridded.

---

## The Minimum Distance Constraint

**Poisson Disk Sampling enforces one rule:**

**dist(p_i, p_j) ≥ r** for all point pairs (p_i, p_j)

**Where:**
- **r** = minimum distance (radius)
- **dist()** = Euclidean distance (usually)

**What This Means:**

**No two points can be closer than r.**

If you try to place a point within r of an existing point, **it is rejected**.

**Code: Checking Validity**

```
var min_distance: float = 1.0
var sample_points: Array[Vector3] = []

func is_valid_point(new_point: Vector3) -> bool:
    # Check if new_point is at least min_distance from all existing points
    for existing_point in sample_points:
        var dist = new_point.distance_to(existing_point)
        if dist < min_distance:
            return false  # Too close - reject
    return true  # Valid - accept
```

**This prevents clumping** - points maintain personal space.

---

## Why Blue Noise?

**Noise** in signal processing refers to frequency distribution of samples.

**White noise:** Completely random (clumpy, uneven)
**Blue noise:** High-frequency content (evenly spaced, no low-frequency clumps)

**Poisson Disk Sampling produces blue noise** - points are randomly distributed but with minimum separation.

**Applications:**
- **Stippling** (dots for shading - blue noise looks more natural than grid)
- **Texture anti-aliasing** (sample distribution reduces artifacts)
- **Plant placement** (trees, grass - looks organic, not planted in rows)
- **Particle systems** (initial distribution for smoke, debris, stars)

**Blue noise feels natural** because **nature uses similar strategies** (seed dispersal, territorial spacing).

---

## Naive Dart Throwing: Slow but Simple

**Simplest algorithm:** Throw darts randomly, reject if too close to existing points.

**Code: Dart Throwing**

```
func dart_throwing(bounds: Vector3, min_dist: float, max_attempts: int) -> Array[Vector3]:
    var points: Array[Vector3] = []
    var attempts = 0

    while attempts < max_attempts:
        # Random position
        var candidate = Vector3(
            randf_range(-bounds.x / 2, bounds.x / 2),
            randf_range(-bounds.y / 2, bounds.y / 2),
            randf_range(-bounds.z / 2, bounds.z / 2)
        )

        # Check if valid (not too close to any existing point)
        var valid = true
        for p in points:
            if candidate.distance_to(p) < min_dist:
                valid = false
                break

        if valid:
            points.append(candidate)
            attempts = 0  # Reset attempts counter
        else:
            attempts += 1

    return points
```

**Problem:** **Very slow** for dense distributions.

**Checking every existing point** for every candidate is O(n) per attempt.

With thousands of points, this becomes **O(n²) or worse**.

**We need spatial acceleration.**

---

Bridson