# Why rejected: point — 2026-05-06T12-54

## What didn't work
proposal is sound (curriculum-honest entrance animation, on-essence, deterministic) but the chamber's capture pipeline can't yet sample animation timepoints — captures only the rest state, which is identical before/after for transient effects. Needs a --at-time=<fraction> flag in capture_multi_angle.gd to demonstrate this kind of improvement visually. Preserving the @identity block + animation code as the patch for future re-application after the chamber upgrade lands.

## What to try instead
<optional>

## Tags
needs-other-system
