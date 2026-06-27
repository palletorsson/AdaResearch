# Curated Wall — Fractal_MandelbrotSet (sequence: fractals)

> *"z = z² + c. Five characters containing infinite complexity… the boundary is infinitely complex, never resolved, computationally irreducible. The edge of chaos made visible."* — the map's own blurb. lambda_edge phase; the master fractal.

## The argument

Curation is an argument made with placement. The map's lesson is the cruelest joke in
mathematics: **the simplest possible iteration produces the most complex known object, and its
boundary is as rich as the whole plane it lives in** (Hausdorff dimension 2, per Shishikura). The
wall makes that a walkable escalation. As you read left→right the *scale of the staging climbs in
lockstep with the depth of the idea* — from a thing in your hand, to a rule burning on a panel, to
a world you walk up to, to an infinite descent. The math never gets more complicated; the
encounter does. That gap **is** the lesson.

## Reading order (+X axis, left → right)

1. **small — `living_paper_mandelbrot`** on a `station_micropod` (sub-1 m post, `base_meters` 0.6).
   Set BACK (z 2.0). Its measured AABB is 0.2 m — genuinely a held thing, so it gets the high,
   narrow micro-pedestal, never a 1 m block. Plate: "Living Paper — Mandelbrot Set". *The whole
   atlas, small enough to hold.* The wall panel above it carries the opening truth-beat: **THE
   MASTER FRACTAL / z → z² + c / FIVE CHARACTERS.**
2. **medium — `mandelbrot_bench`** on a slim `station_plinth` 2×2 (top 0.9), mid-depth (z 1.4).
   Its soul: *"z → z² + c, asked of every point… the burning fringe is where it almost escapes."*
   This is where the rule becomes legible as a question put to every point.
3. **large / FOCAL — `mandelbrot_set`** on a low broad `station_stage` 4×4 (step 0.18), pushed
   FORWARD to the foreground (z 0.4) as the one clear focal point. This artifact is **world-scale**
   (measured 16.9 × 5.5 × 9.6 m, 170 measured cells) — it cannot perch on a podium, so per the
   brief's ">9 → stage capped ~4×4" rule it stands on a low deck that *grounds and names* it while
   the mesh towers and overhangs. That overhang is deliberate: a 4×4 m claim under a world is
   "infinite within finite" rendered as furniture. The stage carries its plate via `name_plate`
   (NOT caption_text): "Mandelbrot Set". Two `station_pillar` (height 3) at the back corners
   (z 2.6) turn the focal zone into a built alcove rather than an object in a void.
4. **applied — `mandelbrot_dive`** on a `station_plinth` 2×2 at stand-height (top 0.9), z 1.2.
   It is literally a 1×1 m zoom table (measured 1.2 × 1.33 m); the plinth meets it at the height
   you'd lean over to dive. Plate: "Mandelbrot Dive". Its soul: *"at 10¹⁵ you see copies of
   yourself."* The wall panel behind closes the arc: **THE EDGE NEVER RESOLVES / INFINITE BOUNDARY
   / ZOOM FOREVER.**

## Focal point

`mandelbrot_set` — the world-scale 3D landscape — set forward (z 0.4) and centered (x 8), framed
by the two corner pillars and backed by the floated `dark_sphere`. Everything else is read at
greater depth (z 1.2–2.6), so from the front iso it reads as a clean left→right ladder, and on
free-cam orbit the focal set sits proud in the foreground with the small/medium tiers tucked into
back bays. The applied dive sits forward-right of the set, the natural next step after the wall.

## Why each prop

- **`station_micropod`** (small) — the home for genuinely sub-1 m precious things; a 0.2 m paper on
  a full 1 m plinth would lie about its size. High + narrow = "this is precious."
- **`station_plinth` 2×2** (medium, applied) — footprint-4 artifacts; slim podium at the height the
  artifact wants to be met (0.9 for the bench panel and the dive table).
- **`station_stage` 4×4** (large) — the only honest base for a world-scale walk-in: low + broad =
  "this is a world," and `name_plate` keeps the big artifact captioned without demoting it to a
  low-broad plinth-for-the-label.
- **`station_pillar` ×2** — turn the centerpiece into architecture (an alcove corner), so the focal
  zone reads as a built bay, not a lone object.
- **`station_panel` ×2** (wall) — the only text in the room. They carry the map's actual
  truth-beats (the opening "five characters", the closing "infinite boundary"), framing the ladder
  like a gallery's wall texts. All other floating artifact labels are hidden by the editor; these
  plates + the base captions are the labels.
- **`dark_sphere`** — placed as the **void/sky backdrop only** (floated high and back, z 2.4 /
  y 3.2, **no base**), per its identity as a neutral anchor / atmospheric reference. It is NOT a
  display artifact and is deliberately not staged on a plinth (the baseline's mistake — it sat on a
  podium at x 0).

## What this beats (baseline `spine_walls.json`)

- Baseline lined **everything on one flat z = 0.8** — no composition. This stagger spans z 0.4–2.6
  and y 0–3.2.
- Baseline **put `dark_sphere` on a `station_plinth`** (x 0). Fixed: floated as backdrop, base-free.
- Baseline bases had **no plates** (bare stage, bare plinths). Every base here carries its display
  name (caption_text / name_plate), and the two wall panels carry the truth-beats.
- Baseline had **no medium tier** (counts.medium = 0) and a bare pillar standing in for it. This
  completes the ladder by pulling in two same-concept kin from `doc/fractal_concept_map.json`
  ("Mandelbrot set"): `living_paper_mandelbrot` (small) and `mandelbrot_bench` (medium) — the
  honest small→medium→large→applied climb for the master fractal.
- Baseline scattered pieces across x 0 → 26 with empty pillars; this composes inside ~14 m as a
  legible, walkable bay.

## Prop gaps flagged

- **No "Mandelbrot–Julia bridge" artifact exists** (the map's own documented gap in `intent.md`):
  an artifact showing the Mandelbrot set with a movable cursor that renders the corresponding Julia
  set in real time beside it. That would make the atlas metaphor — *each point c indexes a Julia
  set; M is the catalog of which are connected* — tangible. If built, it would be the ideal
  **applied** centerpiece companion here (or a second applied bay between the set and the dive).
  Until then `mandelbrot_dive` carries applied alone.
- **`living_paper_mandelbrot` is registered to `testmaps` only**, not `fractals`. It is pulled in as
  curation kin (valid scene, on disk) to fill the small tier; consider promoting it into the
  `fractals` map_sequences if this staging proves out.
- **No dedicated sub-1 m display light** in the station kit reaches the back-set micropod; the
  small tier reads on ambient. A `station_task_light` aimed at z 2.0 would lift the precious paper —
  worth trying next.

## What to try next

- Capture the map (`--mode=map --target=Fractal_MandelbrotSet`) and orbit: confirm the world-scale
  `mandelbrot_set` overhang frames cleanly inside the pillars and the dive plinth doesn't collide
  with the set's measured bulk (its origin centers a ~17 m span; nudge the applied bay further +X if
  the mesh intrudes).
- If the overhang reads as collision rather than "infinite within finite," widen the focal alcove
  (pillars to x 5 / 11) before shrinking the set.
