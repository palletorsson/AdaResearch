# The White Cube

> "consider the museum as modular and built. The museum tiles modules need to be
> lighter, and there need to be white straight long walls with room for artifacts,
> only like one or two props (museum props), most walls are white in a museum.
> The white cube."

Two sessions. The first measured the corpus, wrote a prediction, built the gate,
and died on a session limit mid-sentence — "four buildings go to ZERO showings
under the 6 m floor, let me add the guard". This session verified that claim
(it was true), built the guard, and proved the whole thing in the running engine.

Everything below is measured. Nothing is inherited on trust.

---

## 1. MEASURED FIRST — the 30 real museums, before any change

`tools/em_white_cube_measure.py` is a Python mirror of the three GDScript modules
that decide what stands on a wall (`em_budget.gd` rate, `em_detail.gd` hang,
`em_props.gd` cap). Its transcription of `em_budget.TEMPLATES` was diffed against
the source: **25/25 rows, 0 drift**. Its output was then checked against the live
engine four separate times (§5) and agreed exactly every time.

**5071 m of wall run across 30 museum-tagged templates, cut into 2104 walls.**

| metric | BEFORE |
|---|---|
| props per linear wall metre | **0.0594** (one every 16.8 m) |
| props per ROOM (segment) | **10.0** |
| all wall features per metre | **0.349** (one mark every 2.9 m) |
| hung showings per room | 34.0 |
| wall cards per room | 14.9 |
| longest bare run, mean / max | **9.0 m / 27.0 m** |
| % of wall band area bare | **91.4%** |
| % of wall LENGTH bare | 69.9% |

### The finding that redirected the whole change

The wall is **not too full**. 91.4% of its readable band area was already bare
before anything was touched. The fault is a different one:

```
stretch-length histogram, all 2104 walls in the corpus
   1 m       1241 walls    1241 m   24.5% of all wall run   <-- 59% of all WALLS
   2 m        233 walls     466 m    9.2%
   3-5 m      499 walls    1965 m   38.7%
   6-9 m       78 walls     528 m   10.4%
  >=10 m       53 walls     871 m   17.2%
```

Mean unbroken wall: **2.7 m**. Length-weighted: 6.4 m. Fifty-nine percent of every
wall in the museum corpus is exactly one metre long.

So the corpus-average wall is 2.7 m and carries one mark. There is no
uninterrupted white plane anywhere in the building set — not because the walls are
crowded, but because they are **short and busy**, which is a different fault with a
different cure. The change treats the busy half, because that half is knobs. The
short half is the template tiles themselves and is reported here rather than
worked around.

---

## 2. THE PROPOSAL — four existing knobs, no new system

Every number turns something that was already there and already wired. `em_budget`
computed `wall_features_max` and `fill_walls` and passed them into `dress_segment`
already; `em_props` had read `props_per_10m` since it was written and **nothing had
ever supplied it**; `em_materials.gallery_white()` had been in the library with
**zero callers** while every wall in every proof frame was drawn in warm plaster.

| knob | file / function | before | after | why |
|---|---|---|---|---|
| hang licence | `em_budget.gd` `for_segment()` — `hang_rate` replaces the row's `wf` in the `wf_max` arithmetic only | per-template 0.3–5.0 /10 m | **0.55 /10 m** | one showing per ~18 m of run. `wall_features_per_10m` is returned unchanged, so `em_props`' silent/statutory bands still read each building's own text and a Teshima still gets nothing |
| props per room | `em_budget.gd` `for_segment()` emits `props_per_10m`; consumed at `em_props.gd:449` | derived `wf_rate * 0.40` | **2.0 per ROOM** | the brief said "one or two props". `wf` is a rate per 10 m, so a 200 m building is crowded no matter how low the rate goes — a count per room is the only way to state it |
| wall floor | `em_detail.gd` `_stretch_candidates()` `min_stretch` | 2 m (`HANG_PITCH_FACES`) | **6 m** | the floor already existed ("a one-metre stub is a pier return, not a wall"); this raises it so showings collect on long planes and the 1 m stubs go blank |
| wall cards | `em_detail.gd` `_add_labels()` `every` | 11 faces | **44 faces** | had no knob at all; now a parameter with the shipped value as default |
| wall colour | `endless_museum.gd` `_build_surfaces()` / `_build_segment()` — role `wall_white` | `wall_plaster` 0.72 albedo | **`gallery_white` 0.885** | a 0.165 albedo gap on the surface that is 60–70% of every frame. No amount of hanging or unhanging things on it closes that |

Artifacts, plinths and guests are deliberately untouched. They are the visual event.

---

## 3. THE GATE — off unless asked, twice over

`endless_museum.gd` is a dealer and gained no placement logic. Two independent
opt-ins, both default false:

- `--em-white-cube` — forces every segment of this run into the mode
- `"white_cube": true` on a pattern in `template_patterns.json` — one building, every run

Absent both, `em_budget.for_segment()` does not compute the four gate keys at all,
so `hang_min_stretch` and `label_every` fall to `2` and `11` — the shipped values —
and `hang_rate` is the building's own `wf`. The guard cannot fire (it requires
`min_stretch > HANG_PITCH_FACES`).

**Verified live, against the committed code.** The gate-off run in §5 logs
`170 dressed faces, licence 50, 50 showings hung (min wall 2 m)` — identical to the
"BEFORE" block of `white_cube_prediction.txt` (170 m run, licence 50, 50 showings),
which was written from a runtime log of the *unmodified* code. The mtimes prove the
ordering and are not open to interpretation:

```
21:55:57  doc/reports/white_cube_prediction.txt   <- BEFORE figures recorded here
21:57:38  commons/scenes/em/em_budget.gd          <- first edit lands after
21:59:45  commons/scenes/endless_museum.gd
04:19:09  commons/scenes/em/em_detail.gd          <- the guard, this session
```

So an unchanged museum on the changed code produces the same three numbers the
unchanged code produced.

One un-gated side effect, disclosed: `_surf` gains a `wall_white` entry
unconditionally, so the line `[endless_museum] surfaces: N roles` prints one
higher. `_surf` is read in exactly two places — a null-erase loop and that print —
so nothing rendered changes.

---

## 4. THE FOUR-ZERO RISK — verified, not inherited, and guarded

The dying session's claim was **TRUE**, and exactly four buildings:

| template | showings BEFORE | under a flat 6 m floor | its longest wall | % of run ≥6 m |
|---|---|---|---|---|
| soane-cabinet-vista | 60 | **0** | 5 m | 0.0% |
| sainsbury-false-perspective-enfilade | 52 | **0** | 5 m | 0.0% |
| pompidou-plateau-libre | 27 | **0** | 4 m | 0.0% |
| mengoni-glazed-thoroughfare | 8 | **0** | 5 m | 0.0% |

All four share one property and only one: **their longest plane is shorter than the
floor**, so every candidate is rejected and the licence has nowhere to spend
itself. The Soane — the cabinet museum, the busiest wall in the set — would have
hung nothing at all. (The other eight zeros in the after-table are buildings whose
own budget row says `fill_walls: false`. They hung nothing before either. Not a
regression.)

**The guard** (`em_detail.gd` `_add_wall_showings()`, plus helpers
`_wall_stretches()`, `_candidates_at_floor()`, `_longest_stretch()`): the floor is
a *preference*, not a law. If it silences a building completely, fall back to that
building's **own longest wall** — not to the shipped 2 m floor, which would put the
pictures straight back onto the pier returns this change exists to clear. A museum
whose longest plane is 5 m hangs on its 5 m planes and nowhere else.

It fires on exactly those four templates and on nothing else, and after it the
corpus has **8 museums hanging nothing — the same 8 as before**.

---

## 5. PROOF — the running engine, same seed, same camera

Godot 4.6, `--xr-mode off --no-window`, wrapped in `tools/godot_watchdog.py`, one
instance at a time. BEFORE and AFTER differ by the single flag `--em-white-cube`.

```
commons/scenes/endless_museum.tscn -- [--em-white-cube] --em-first=<key> \
    --em-shot=user://<name>.png --em-segments=<n>
```

### The captures

| PNG | mtime | bytes |
|---|---|---|
| `user://wc_before_uffizi.png` → `doc/reports/white_cube_before_uffizi.png` | 2026-08-13 04:23:03.810 +0200 | 1 682 520 |
| `user://wc_after_uffizi.png` → `doc/reports/white_cube_after_uffizi.png` | 2026-08-13 04:23:33.759 +0200 | 1 666 204 |
| `user://wc_before_soane.png` → `doc/reports/white_cube_before_soane.png` | 2026-08-13 04:25:46.643 +0200 | 1 744 494 |
| `user://wc_after_soane.png` → `doc/reports/white_cube_after_soane.png` | 2026-08-13 04:26:16.799 +0200 | 1 708 508 |

`user://` = `C:/Users/palle/AppData/Roaming/Godot/app_userdata/Ada Research Zero One/`.
The `doc/reports/` copies are local only — `.gitignore:373` ignores
`doc/reports/**/*.png`, so the `user://` paths are the canonical ones.
Both pairs 1800×1200. Frame delta: uffizi mean luminance 51.2 → 57.1 (+5.9),
29.51% of pixels moved more than 8/255; soane 56.8 → 63.4 (+6.6), 23.95% moved.
In the uffizi pair the far wall at the end of the enfilade carries two framed
showings and a card BEFORE, and is one uninterrupted white plane AFTER.

### The engine's own log

```
BEFORE  --em-first=uffizi-spine-enfilade --em-segments=2
[em_detail] walls: 170 dressed faces, licence 50, 50 showings hung (min wall 2 m)
[em_detail] walls: 205 dressed faces, licence 52, 52 showings hung (min wall 2 m)
  seg 0 = uffizi-spine-enfilade      placed 16/16 + 3 plinths + 16 props
  seg 1 = sainsbury-false-persp...   placed 14/14 + 6 plinths + 14 props
  dressing: 9 plinths (4.5/seg), 30 props (15.0/seg), 2 guests

AFTER   --em-white-cube  (same key, same seed, same camera)
[em_detail] walls: 170 dressed faces, licence 11, 11 showings hung (min wall 6 m)
[white-cube] seg 0: hang licence 11 (min wall 6 m), 1 card per 44 faces, props/10m 0.1000, wall = gallery_white
[em_detail] no wall reaches 6 m; falling back to this building's longest wall (5 m)
[em_detail] walls: 205 dressed faces, licence 11, 11 showings hung (min wall 6 m)
  seg 0 = uffizi-spine-enfilade      placed 16/16 + 3 plinths + 2 props
  seg 1 = sainsbury-false-persp...   placed 14/14 + 6 plinths + 2 props
  dressing: 9 plinths (4.5/seg), 4 props (2.0/seg), 2 guests
```

Segment 1 of that very capture is **sainsbury-false-perspective-enfilade — one of
the four at-risk buildings.** The line `no wall reaches 6 m` is printed only from
inside `if per_run.is_empty()`, so the engine is itself reporting that zero
candidates existed at the 6 m floor. Without the guard this frame hangs nothing;
with it, 11. The risk is not argued away, it is caught in the act and handled.

Artifacts, plinths and guests are byte-identical across the pair (16/16, 14/14,
3 and 6 plinths, 2 guests). Only the wall furniture moved.

The Soane, the extreme case:

```
BEFORE  [em_detail] walls: 201 dressed faces, licence 80, 60 showings hung (min wall 2 m)   + 16 props
AFTER   [em_detail] no wall reaches 6 m; falling back to this building's longest wall (5 m)
        [em_detail] walls: 201 dressed faces, licence 13,  2 showings hung (min wall 6 m)   +  2 props
```

---

## 6. MEASURED AFTER — the 30 museums, with the gate and the guard

| metric | BEFORE | AFTER | |
|---|---|---|---|
| **props per linear wall metre** | 0.0594 | **0.0116** | 5.1× fewer |
| props per ROOM | 10.0 | **2.0** | the brief's number, exactly |
| all wall features per metre | 0.349 | **0.072** | 4.8× fewer |
| hung showings per room | 34.0 | 6.8 | |
| wall cards per room | 14.9 | 3.4 | |
| **longest bare run, mean** | 9.0 m | **13.0 m** | +44% |
| longest bare run, max | 27.0 m | **30.2 m** | |
| **% of wall band area bare** | 91.4% | **98.3%** | |
| % of wall LENGTH bare | 69.9% | **94.0%** | |
| museums hanging nothing | 8 | **8** | guard holds — no new zeros |

---

## 7. Prediction vs measurement — where they disagreed

### The first session's prediction: agreed on all six, and that is worth nothing

`doc/reports/white_cube_prediction.txt` (uffizi, segment 0) predicted 11 showings,
3 cards, 2 props, 0.094 features/m, 25.2 m longest bare run, 90.3% bare length. The
measurement returned 11, 3, 2, 0.094, 25.2, 90.3 — six for six.

**That agreement proves nothing, and the reason matters.** The prediction was
produced by running the same Python mirror in `--after` mode. It was not a
prediction; it was the tool quoting itself. A prediction that agrees with the
instrument that generated it has tested nothing.

What *did* test it was the engine. The mirror's four claims, checked against live
Godot runs: uffizi BEFORE 170 faces / licence 50 / 50 showings — **exact**; uffizi
AFTER 170 / 11 / 11 — **exact**; soane BEFORE 201 / 60 showings — **exact**; soane
AFTER 201 / licence 13 / 2 showings — **exact**. The mirror is sound. The
prediction was circular. Those are two separate facts and only the first is good news.

### My own guard prediction: wrong in three of four, and that is the useful line

Written to `doc/reports/white_cube_guard_prediction.txt` *before* the guard existed
(mtime 04:18:44, guard first ran 04:21). I predicted the licence would bind:

| template | predicted | measured | |
|---|---|---|---|
| sainsbury-false-perspective-enfilade | 11 | **11** | right, and by luck |
| soane-cabinet-vista | 11 | **2** | wrong by 5.5× |
| pompidou-plateau-libre | 3 | **8** | wrong by 2.7× |
| mengoni-glazed-thoroughfare | 2 | **4** | wrong by 2× |

Two independent errors, one arithmetic and one conceptual.

**The arithmetic one.** I computed `licence = round(wall_run × 0.1 × 0.55)` using
the `wall` column of my own table — the count of *dressed faces*. `em_budget` does
not use that number. `em_budget.gd:365` sets `wall_run = _perimeter_of(tile)`, the
tile's wall perimeter, which is a different quantity: soane's licence is 13, not
11; pompidou's is 8, not 3; mengoni's is 5, not 2. **Two numbers in this system are
both called "wall run" and they are not equal.** Anyone reading a rate off the
measurement table and expecting the engine to honour it will be wrong, and nothing
in either file says so. That is worth more than the guard.

**The conceptual one, and it is the larger.** I assumed the *licence* decides how
much hangs. Once the floor is raised it usually does not — the **candidate supply**
does. The Soane is licensed 13 showings and hangs 2, because after the 5 m floor
the entire building offers exactly two candidate positions. Mengoni is licensed 5
and hangs 4.

The consequence is a design fact nobody had: **below a certain floor, turning the
rate knob stops doing anything.** Dropping `WHITE_CUBE_HANG_PER_10M` from 0.55 to
0.1 would not remove a single picture from the Soane, because geometry is already
the binding constraint, not rate. The rate knob governs the long-walled museums;
the short-walled ones are governed by their tiles. Which returns to §1's finding
from the other direction — the corpus's real fault is 59% of its walls being 1 m
long, and no budget knob reaches that.

---

## 8. What is still open

- **The tiles themselves.** The gate makes the walls white, quiet and long-*read*;
  it cannot make them long. 24.5% of all wall run in the corpus is 1 m fragments,
  and the only cure is editing `template_patterns.json` tiles. Untouched here by
  choice — the brief said "modular and built", and the modules are data.
- **"Lighter" was read as albedo, not as geometry.** `gallery_white` at 0.885 vs
  plaster at 0.72 answers the colour reading. If the brief meant lighter meshes
  the change is elsewhere and unstarted.
- **No shipped pattern opts in.** `--em-white-cube` is a run flag; the per-template
  `"white_cube": true` is honoured but set on none of the 30. Turning it on for
  real museums is a data decision, not a code one.
- **The Soane at 2 showings** is arguably correct — its own argument is a cabinet,
  and a white cube done to a Soane should look like a contradiction. But it is a
  large behavioural change to a specific building and deserves a human eye.

---

## Files

| path | role |
|---|---|
| `commons/scenes/em/em_budget.gd` | the gate's four constants; `for_segment()` emits the keys only when asked |
| `commons/scenes/em/em_detail.gd` | `min_stretch` / `label_every` parameters; the stubby-building guard and its three helpers |
| `commons/scenes/endless_museum.gd` | `--em-white-cube` parse, per-template opt-in, `wall_white` surface role, per-segment resolve |
| `tools/em_white_cube_measure.py` | the 30-museum mirror; `--after` runs the gate, `--json=` machine-readable |
| `doc/reports/white_cube_prediction.txt` | session 1's prediction (circular — see §7) |
| `doc/reports/white_cube_guard_prediction.txt` | session 2's guard prediction (wrong 3 of 4 — see §7) |
| `doc/reports/white_cube_{before,after}_{uffizi,soane}.png` | the four proof frames |

Compile-checked: `em_detail.gd`, `em_budget.gd`, `endless_museum.gd` — 3 checked,
0 failed. Not committed.
