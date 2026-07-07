# Force Preview

One shelf, the whole subject. Each station here returns as a full room later in the sequence.

Read a vector's length off the lantern.

```gdscript
func lantern_brightness(v: Vector3) -> float:
    return v.length()  # magnitude → light
```

Magnitude as brightness. The longer the vector, the brighter the lamp.

Add two arrows on the board.

```gdscript
func board_sum(a: Vector3, b: Vector3) -> Vector3:
    return a + b  # tip to tail
```

The adder board draws all three: a, b, and the sum that closes the triangle.

Ask the gauge how much two directions agree.

```gdscript
func agreement(a: Vector3, b: Vector3) -> float:
    return a.normalized().dot(b.normalized())  # 1 same, 0 perpendicular, -1 opposed
```

The dot product is a one-number answer to "how aligned?". The gauge needle is that number.

Stand in the weather field.

```gdscript
func wind_at(pos: Vector3) -> Vector3:
    return weather_field.sample(pos)
```

A field is a vector at every point. Walk and the answer changes under your feet.

Bounce a shot off the reflection hall.

```gdscript
func reflect(v: Vector3, n: Vector3) -> Vector3:
    return v - 2.0 * v.dot(n) * n
```

Reflection is subtraction of twice the projection. The hall makes the formula visible at wall scale.

> Try: fire the human catapult, then find which three stations on this shelf explain the flight — the sum, the magnitude, the field.

This room is a table of contents. Foundations names the arrows; Operations teaches dot and cross; Motion sets them moving; then forces, fields, springs, gravity, and the arena where it all collides.
