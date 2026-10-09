# No Color Is Alone

The crowd room. Everything the sequence taught gathers here to make one claim: a color's value is decided by its neighbors. Code can state that claim precisely.

The physics of the claim — simultaneous contrast, simulated:

```gdscript
func perceived(target: Color, surround: Color, k: float = 0.18) -> Color:
    # the eye subtracts a fraction of the surround from what it reports
    var shift := Color(
        target.r - k * (surround.r - 0.5),
        target.g - k * (surround.g - 0.5),
        target.b - k * (surround.b - 0.5))
    return shift.clamp()
```

Render one gray patch on a warm field and the same gray on a cool field, then compute `perceived` for both: the *identical* RGB triple returns two different reports. Albers' Homage to the Square is this function run on canvas for forty years.

Build the demonstration — one swatch, two contexts:

```gdscript
func albers_pair(swatch: Color, ctx_a: Color, ctx_b: Color) -> void:
    make_panel(Vector3(-2, 1.5, 0), ctx_a, swatch)   # nested squares
    make_panel(Vector3( 2, 1.5, 0), ctx_b, swatch)

func make_panel(pos: Vector3, outer: Color, inner: Color) -> void:
    add_quad(pos, Vector2(1.6, 1.6), outer)
    add_quad(pos + Vector3(0, 0, 0.01), Vector2(0.8, 0.8), inner)
```

Stand back and the two inner squares refuse to match. Walk close and read their labels: same hex. The room never lies numerically — it lies perceptually, which is the lesson.

Harmony rules are geometry on the hue wheel:

```gdscript
func complementary(c: Color) -> Color:
    return Color.from_hsv(fmod(c.h + 0.5, 1.0), c.s, c.v)
func triadic(c: Color) -> Array[Color]:
    return [Color.from_hsv(fmod(c.h + 1.0/3, 1.0), c.s, c.v),
            Color.from_hsv(fmod(c.h + 2.0/3, 1.0), c.s, c.v)]
```

Opposite point, equilateral triangle — the artists' systems in the room (Mondrian's primaries, Kandinsky's triad, Rothko's close-valued fields) are positions taken on this wheel, each with an ideology attached.

Try: pick any furniture piece in the crowd, sample its dominant color, and compute what every *other* piece does to it with `perceived`. The room is not a gallery of colors. It is a system of mutual interference — which is what the sequence meant by relational all along.
