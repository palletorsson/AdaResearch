# White Walls — where the wall colour is chosen, and what it is worth in pixels

> "most walls are white in a museum. The white cube."

This session was sent to fix a reported failure: *"a previous agent reported wiring
this and DID NOT — `gallery_white()` has ZERO callers and every wall still ships
`wall_plaster` at 0.72."*

**Half of that brief is wrong and the half that is right is right for a different
reason.** Both halves are established below with numbers rather than greps.

---

## 1. The file and line where a museum wall's material is chosen

```
commons/scenes/endless_museum.gd:1004
    var m_wall: Material = _sm("wall_white") if wc else _sm("wall")
```

with the two lines it depends on:

| line | what it does |
|---|---|
| `endless_museum.gd:459` | `_surf["wall"] = _mat_of("wall_plaster", [])` — the warm role |
| `endless_museum.gd:468` | `_surf["wall_white"] = _mat_of("gallery_white", [])` — the white role |
| `endless_museum.gd:1000` | `var wc: bool = _white_cube or bool(spec.get("white_cube", false))` — the gate |
| `endless_museum.gd:1004` | **the choice** |
| `endless_museum.gd:1010-1013` | the same choice mirrored into `_detail_mats["wall"]`, so door overpanels match the wall they sit in |

This is the only place. `m_wall` is consumed by every `_box()` that builds a wall
(1025, 1028, 1031, 1038, 1058) and by nothing else. `gallery_walk.gd` is a
different scene and does not use this library.

**I did not edit it.** My brief says that if the call site turns out to be in
`endless_museum.gd` I must report the edit instead of making it. The exact edit is
in §6. No source file was modified by this session.

### The "ZERO callers" claim was a grep artifact

`gallery_white()` **is** called, from `endless_museum.gd:468`, through
`_mat_of()` → `_mod_mats.callv(fn, args)` at line 524. The museum loads its render
modules by path and calls into them **reflectively**, so no literal string
`gallery_white(` exists at the call site and a grep for one returns nothing.

The engine says otherwise, in its own log, from the run captured below:

```
[white-cube] seg 0: hang licence 11 (min wall 6 m), 1 card per 44 faces, props/10m 0.1000, wall = gallery_white
[white-cube] seg 1: hang licence 11 (min wall 6 m), 1 card per 44 faces, props/10m 0.0962, wall = gallery_white
```

`em_materials.gd` is indeed unmodified — and it never needed modifying.
`gallery_white()` has been in the shipped library all along. The previous session
added the *caller*, not the material.

### What IS true: the gate is dead in the shipped data

`spec.get("white_cube", false)` defaults false, and **0 of 182 patterns in
`commons/data/template_patterns.json` declare `white_cube`** (checked
programmatically, not by eye). So absent `--em-white-cube` on the command line,
every wall in every shipped museum really is `wall_plaster` at 0.72. The colour
change exists, compiles, runs, and reaches nobody.

That is the actual gap, and it is a **data** gap sitting behind a **code** default.

---

## 2. Prediction, written before the capture

`scratchpad/white_walls_prediction.txt`, mtime **2026-08-13 04:40:16.565**, which
is 42 seconds before the first PNG existed (04:40:58.482).

| | predicted | measured | verdict |
|---|---|---|---|
| BEFORE wall-region mean luminance | 82.0 | **132.11** | wrong by 61% |
| **AFTER wall-region mean luminance** | **100.0** | **152.51** | **wrong by 53%** |
| ratio after/before | 1.22 | **1.1544** | wrong — and below the 1.20 floor I set myself |

I wrote: *"I expect measured ratio >= 1.22, and I will be wrong if it lands under
1.20."* It landed at 1.1544. **Wrong on the absolutes, wrong on the ratio, right
only on the direction.** §5 is what the miss bought.

---

## 3. The captures

Godot 4.6, `--xr-mode off --no-window`, wrapped in `tools/godot_watchdog.py`, one
instance at a time. BEFORE and AFTER differ by the single flag `--em-white-cube`.

```
commons/scenes/endless_museum.tscn -- --em-seed=46 [--em-white-cube] \
    --em-first=uffizi-spine-enfilade --em-shot=user://ww_{before,after}.png --em-segments=2
```

| PNG | mtime | bytes |
|---|---|---|
| `user://ww_before.png` | 2026-08-13 04:40:58.482 | 1 678 090 |
| `user://ww_after.png` | 2026-08-13 04:41:39.342 | 1 665 777 |
| `doc/reports/white_walls_before_uffizi.png` (copy) | 2026-08-13 04:52:35.678 | 1 678 090 |
| `doc/reports/white_walls_after_uffizi.png` (copy) | 2026-08-13 04:52:35.722 | 1 665 777 |

`user://` = `C:/Users/palle/AppData/Roaming/Godot/app_userdata/Ada Research Zero One/`.
The `doc/reports/` copies are local only — `.gitignore:372` ignores
`doc/reports/*.png` — so the `user://` paths are canonical. Both 1800×1200.

**Same camera, and the engine says so rather than me:** both runs log
`shot composed at 13.5,15.5 — 8 of 32 dealt objects in view, nearest 3.2 m`. The
standpoint is auto-composed from what was dealt, so this was a real risk (the
AFTER run strips 26 props) and it had to be checked, not assumed.

**Same everything except wall furniture:** artifacts 16/16 and 14/14, plinths 3
and 6, guests 2 — identical across the pair. Props 30 → 4, showings 52 → 11.

---

## 4. Mean wall-region luminance

Rec.709 luminance on the sRGB-encoded bytes, 0-255. Regions are declared by
geometry in `scratchpad/regions.py` and drawn onto a contact sheet so the choice
can be audited rather than trusted.

| region | before | after | delta | ratio |
|---|---|---|---|---|
| **wall (far gallery wall, as photographed)** | **130.72** | **152.42** | **+21.70** | **1.1660** |
| **wall (sub-rect bare in BOTH frames)** | **132.11** | **152.51** | **+20.40** | **1.1544** |

The two rows are the useful pair. The first includes the framed showing and card
that the gate removes; the second is a sub-rectangle of the same wall that carries
no furniture in *either* frame. They differ by 0.012 of ratio, so on this wall
**the colour is doing essentially all of the work and the emptying almost none.**
That decomposition matters, because `--em-white-cube` is one gate driving five
knobs and the brief only asked about one of them.

Whole frame for scale: 52.562 → 58.092, ratio 1.1052.

---

## 5. Did anything other than walls change colour? Checked, not assumed

Brightness alone cannot answer this — a surface next to a whiter wall gets
brighter without changing material. **The R/B channel ratio can**, because it is a
fingerprint of the albedo and is untouched by how much light arrives:

- `wall_plaster` R/B = 0.720/0.675 = 1.0667
- `gallery_white` R/B = 0.885/0.872 = 1.0149
- so a plaster→white swap **must** move R/B by a factor of **0.9515**
- a surface that merely caught more light moves it by **1.0000**

| region | luminance ratio | R/B shift | reading |
|---|---|---|---|
| **wall, far plane** | 1.1660 | **0.9576** | **material changed** |
| **wall, far bare** | 1.1544 | **0.9590** | **material changed** |
| ceiling soffit (lintel) | 1.0035 | 0.9997 | untouched |
| floor, foreground deck | 1.0063 | 0.9976 | untouched |
| artifact (dealt red box) | 1.0225 | 1.0250 | untouched |
| floor, gallery deck | 1.0407 | 1.0063 | brighter, same material |
| trim (travertine pilaster) | 1.0849 | 0.9869 | brighter, same material |
| plinth deck | 1.1057 | 0.9817 | brighter, same material |

**The wall's fingerprint lands at 0.958 — within 0.8% of the 0.9515 the albedo
swap predicts. Every non-wall surface stays within 2.5% of 1.0000, and none comes
near 0.9515.** So: exactly one material changed, and it is the wall. Trim, floor,
ceiling and joints kept their own paint.

Three non-wall surfaces did get **brighter** — the pilaster by 8.5%, the plinth
deck by 10.6%, the far floor by 4.1% — with their hue intact. That is indirect
bounce off a wall that is now the building's main reflector, plus, for the plinth,
26 fewer props casting shadows. It is a lighting consequence of the change, not a
second material change, and it is the reason `gallery_white`'s own docstring calls
it "the building's main bounce source".

---

## 6. The exact edit (reported, not made)

The machinery works. Two things are wrong with it as it stands:

1. Nothing turns it on.
2. Colour and emptying are welded to one flag, so a building cannot take the white
   paint without also taking the 6 m wall floor, the hang licence and the
   2-props-per-room cap.

The brief asked for museum walls to be white **and** for an opt-out. That is the
second problem, so the edit splits the gate.

**`endless_museum.gd:583`** — carry a tri-state so "unset" still means "follow the
white-cube gate":

```gdscript
                    "white_cube": bool(p.get("white_cube", false)),
                    # PAINT IS NOT HANGING POLICY. Tri-state: absent means "follow
                    # the white-cube gate", present means this building has an
                    # opinion about its own walls.
                    "gallery_white": (bool(p["gallery_white"]) if p.has("gallery_white") else null),
```

**`endless_museum.gd:1000-1013`** — replace `wc` with the colour gate in the three
places that choose a *surface*, leaving the two that choose *policy* alone:

```gdscript
	var wc: bool = _white_cube or bool(spec.get("white_cube", false))
	# "most walls are white in a museum" is a claim about paint, not about how much
	# hangs on it. Defaults to wc, so every existing caller and every existing
	# capture is unchanged; a pattern sets it true to whiten alone, false to keep
	# warm plaster while still emptying.
	var gw = spec.get("gallery_white", null)
	var white_wall: bool = wc if gw == null else bool(gw)
	var wall_col := Color(0.86, 0.855, 0.845) if white_wall else Color(0.32, 0.32, 0.36)
	var m_wall: Material = _sm("wall_white") if white_wall else _sm("wall")
	if m_wall == null:
		m_wall = _sm("wall")
	if white_wall and _surf.has("wall_white"):
		_detail_mats["wall"] = _surf["wall_white"]
	elif _surf.has("wall"):
		_detail_mats["wall"] = _surf["wall"]
```

Then the data decision, in `template_patterns.json`: `"gallery_white": true` on the
buildings whose argument IS the white cube, and left absent everywhere else.

### Which buildings should keep warm plaster, and why

The white cube is a specific 20th-century invention, not a synonym for "museum".
Painting these white would be painting over the thing the template exists to
teach:

| keep warm plaster | why |
|---|---|
| `uffizi-spine-enfilade`, `uffizi-spine-ordered` | 1581 Vasari corridor. A frescoed Renaissance gallery in flat emulsion is an anachronism. |
| `soane-cabinet-vista` | Soane's house-museum: Pompeian red, dense cabinet hang. The white cube is its literal opposite. |
| `grande-galerie-axial` | 17th-c. Louvre salon hang on coloured walls. |
| `altes-rotunda-hub` | Schinkel 1830 — stone and scagliola, not paint. |
| `mezquita-hypostyle` | 8th-c. Córdoba: striped voussoirs. There is no painted wall to whiten. |
| `castelvecchio-*` | Scarpa's whole argument is against neutral ground. |
| `chichu-buried-cells`, `teshima-droplet` | Ando / Nishizawa: fair-faced concrete IS the material claim. |
| `pompidou-plateau-libre`, `libeskind-void-axis` | exposed structure and raw voids. |
| `capuchin-crypt-corridor`, `caracalla-thermal-axis` | not galleries at all. |

The white-cube lineage — `neue-nationalgalerie-free-plan`, `dia-beacon-field`,
`kanazawa-room-matrix`, `kanazawa-matrix-vista`, `louisiana-pavilion-chain`,
`guggenheim-serpentine`, `sainsbury-false-perspective-enfilade` — is where
`"gallery_white": true` belongs. That is a curatorial call and is Palle's, not
mine; 26 non-challenger museum patterns are in the corridor rotation.

---

## 7. Why the prediction missed, and the explanation I tried and could not confirm

Direction right, magnitude wrong. In linear light:

```
albedo ratio                     0.4735 -> 0.7584   = 1.6017
measured, post-tonemap linear    0.2311 -> 0.3163   = 1.3685
measured, sRGB-encoded             132.11 -> 152.51 = 1.1544   (I predicted 1.237)
```

I assumed rendered radiance ∝ albedo with nothing added. It is not. If
`rendered = k·albedo + c`, the measured 1.3685 solves to **c ≈ 0.30k** — an
albedo-independent term worth about 30% of a unit-albedo surface's direct return.

**I tested the obvious candidate and it failed.** If that term were atmospheric
in-scattering over the ~12 m to the far wall, then the same material swap on a
foreground wall ~3 m away should compress *less*. It compresses *more*: the near
wall measures ratio 1.1133 against the far wall's 1.1544. That probe is also
contaminated — it sits in shadow at luminance 37/255, crossed by volumetric light
shafts, and its R/B moves +6% (the wrong way for a plaster→white swap), which
means removed props are in it. So depth is not the compressor, the near-wall probe
is not clean enough to convict anything else, and **the explanation is open.**
Tonemap shoulder and ambient are the remaining candidates. I would rather leave
that unresolved than write a tidy wrong reason for it.

The absolute miss (82 vs 132) is a separate and less interesting failure: I
guessed an exposure and a band placement before ever looking at a frame.

One thing the miss did buy: I only reached for the R/B fingerprint in §5 because
the luminance ratio came back too low to argue from on its own. Luminance alone
could not have distinguished the wall's material swap from the pilaster's +8.5%
bounce. The fingerprint can, and it is the measurement that actually answers the
brief's last question.

---

## 8. Compile check

```
2 checked, 0 failed
```

`res://commons/scenes/endless_museum.gd`, `res://commons/scenes/em/em_materials.gd`,
via `commons/testing/check_compile.gd`. Neither was modified by this session — the
check confirms the uncommitted working tree parses, and both files additionally
ran to completion twice under the captures above, which is the stronger test.

Nothing committed.

## Files

| path | role |
|---|---|
| `commons/scenes/endless_museum.gd` | lines 459 / 468 / 1000 / **1004** / 1010-1013 — where the wall material is chosen |
| `commons/scenes/em/em_materials.gd` | `gallery_white()` at 216, `_make_gallery_white()` at 612 — unmodified, and already correct |
| `commons/data/template_patterns.json` | 0 of 182 patterns opt in; 26 non-challenger museums available |
| `doc/reports/white_walls_{before,after}_uffizi.png` | the proof pair (gitignored, local) |
