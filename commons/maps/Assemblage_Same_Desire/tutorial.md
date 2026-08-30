# Assemblage — The Same Desire

Two ends of one room: a loom at the near wall, Gödel's sentence at the far one. Before it, a grammar must already rewrite — an axiom, a production rule, a string that grows.

Thread each warp onto a shaft.

```gdscript
var _warp_shaft: PackedInt32Array   # [warp] -> shaft index, -1 = unthreaded

func set_threading(warp: int, shaft: int) -> void:
    _threading[warp * shafts + shaft] = 1
    _masks_dirty = true
```

Threading is the alphabet. Twenty-four warps over four shafts: each thread is given one symbol and keeps it for the whole cloth.

Tie the shafts to the treadles.

```gdscript
func _rebuild_masks() -> void:
    for t in treadles:
        var mask := 0
        for s in shafts:
            if _tieup[s * treadles + t]:
                mask |= (1 << s)
        _treadle_shaft_mask[t] = mask
```

The tie-up is the production rule: one treadle expands into a set of shafts. Four bits per treadle, and the whole grammar fits inside an integer.

Read the treadling as a string and derive the cloth.

```gdscript
for pick in picks:
    var active := 0
    for t in treadles:
        if _treadling[pick * treadles + t]:
            active |= _treadle_shaft_mask[t]
    for warp in warps:
        var shaft: int = _warp_shaft[warp]
        var up: bool = shaft >= 0 and bool(active & (1 << shaft))
        _drawdown[pick * warps + warp] = 1 if up else 0
```

One AND per crossing decides whether warp or weft lies on top. The drawdown is the derivation, printed. This is the oldest L-system in human hands.

Flip one coin per cell.

```gdscript
func _weave_row(y: float) -> Array:
    var threads: Array = []
    for c in range(cols):
        var slash := _rng.randf() < odds
        threads.append(_mark(cx, y, sx, slash, mat))
    return threads
```

10 PRINT, one flip per thread, forever. `odds` defaults to 0.5 because the fair coin is the argument — at 0 or 1 the maze collapses into a rib.

Give the coin its two marks.

```gdscript
bar.rotation.z = (PI * 0.25) if slash else (-PI * 0.25)
```

Two symbols and no memory. The bolt scrolls and never repeats, on one bit per thread.

Name the hands each rule came from.

```gdscript
const PLATES := [
    {"shader": "atlas_kente", "title": "KENTE",
     "makers": "Ashanti & Ewe strip-weavers · Ghana"},
    {"shader": "atlas_meander", "title": "MEANDER",
     "makers": "mosaic workshops · Pompeii"},
]
```

Each plate carries the rule as a shader, not a photograph of the cloth. The tag beneath is the whole difference between a return and an enclosure.

Cycle the plaque past its own edge.

```gdscript
var statements: Array[String] = [
    "This statement exists.",
    "This statement is unprovable within this system.",
    "G: ¬∃p: Proves(p, G)",
]

func advance_statement() -> void:
    current_index = (current_index + 1) % statements.size()
    _update_display()   # at index >= 4 it emits paradox_triggered
```

Nine statements, each more self-referential than the last. The ninth is a finite string of symbols meaning something no proof inside its own system can reach.

Build a beam that cannot come level.

```gdscript
var beam := add_box(Vector3(0.62, 0.03, 0.05), Vector3(0, 1.14, 0), STEEL)
beam.rotation_degrees = Vector3(0, 0, -13)
add_label("THIS SCALE'S OWN WEIGHT", Vector3(0, 1.46, 0), 0.0022, GOLD)
```

Thirteen degrees, hard-coded, with no physics behind it. The tilt is not a state the scale is in. It is the shape the scale was built as.

Stand the first maker in the middle of the room.

```gdscript
const PLATES := [
    {"shader": "mm_varma_backen", "title": "VARMA BACKEN", "makers": "Kristina Torsson · Vamlingbolaget · the Sudret meadow"},
    {"shader": "mm_bonan", "title": "BONAN", "makers": "Kristina Torsson · found in the pistachio bowl"},
    {"shader": "mm_mahjong_rand", "title": "MAH-JONG RAND", "makers": "K. Torsson · H. Henschen · V. Nygren · 1966"},
    {"shader": "mm_moders_drom", "title": "MODERS DROM", "makers": "Mothers Dream 2023 · Palle after Kristina Torsson"},
]
```

Six plates, each a living shader rather than a photograph of a cloth, each carrying its makers' names. Read left to right the row is a life: a meadow, a henyard, a pattern found by chance in a pistachio bowl, a collective in 1966, a teenage room in Vamlingbo, and a dream a machine was given.

Give the last plate a gene that runs between the drawing and the dream.

```gdscript
@export_range(0.0, 1.0) var g_dream: float = 0.0
material.set_shader_parameter("g_dream", g_dream)
```

At 0 the weave is as she drew it. At 1 it is what the machine breathes into it. Neither end is the work — the oscillation between them is, which is why the shader animates on TIME rather than settling.

The loom and the plaque stand at opposite ends of one floor, facing each other. Both take a finite grammar — four shafts, or the axioms of arithmetic — and compose inside it a statement the grammar cannot hold. One desire, two desks — and between them the origin gallery, so the grammar has somebody's name on it.
