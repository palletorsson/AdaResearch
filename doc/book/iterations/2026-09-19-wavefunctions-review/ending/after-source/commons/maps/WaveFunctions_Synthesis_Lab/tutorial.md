# Five amounts and one shared phase

AirMusic gave each struck bar its own beginning. Synthesis Lab gives five components one phase and asks what their amounts can make together. The primary is `additive_wave_demo`, a visual instrument. It does not render these curves to an audio stream. All code excerpts below come from `commons/artifacts/additive_wave_demo/additive_wave_demo.gd`.

## Take the assembled shape apart

Press HOLD to stop the display's drift. Lower H2 through H5 and compare the remaining row with the pale sum. H1 ALONE performs that removal together; BASELINE restores the five arrival coefficients. These buttons preserve the current held phase. H1 ALONE keeps H1's current amount, restoring it to one only if it was below 0.01.

The state begins as five coefficients. The map then selects the sawtooth preset:

```gdscript
var harmonic_amplitudes: Array[float] = [1.0, 0.0, 0.0, 0.0, 0.0]
```

```gdscript
_set_amplitudes([1.0, 0.5, 0.333, 0.25, 0.2])
```

At a chosen phase, each coefficient scales one sine. The harmonic index selects how many returns it makes in a cycle:

```gdscript
func _calculate_wave_value(phase: float) -> float:
    var value = 0.0
    for h in range(harmonic_amplitudes.size()):
        value += harmonic_amplitudes[h] * sin(phase * (h + 1))
    return value
```

Raise H2 again. At the amber mark, predict whether it adds or subtracts from the total before reading the plate. A coefficient is nonnegative, but its sine can be above or below zero. Addition can therefore lower the sum.

## One position, several rates

The drawing evaluates 256 samples across two metres and four cycles:

```gdscript
var t = float(i) / (WAVE_POINTS - 1)
var x = (t - 0.5) * WAVE_LENGTH
var phase = t * TAU * 4.0 + _time * TAU
```

The combined wave is drawn at 0.30 m per signal unit. The ladder uses 0.20 m per unit and separates the rows vertically:

```gdscript
return Vector3(x, y * 0.2 - 0.35 - h * 0.15, 0.1)
```

Adding literal screen heights would also add the offsets. Read the values at the shared mark instead. The `overlay` source configuration uses the sum's scale and axis; there is no visitor mode selector on this placed bench.

The clock moves only when the display is not held:

```gdscript
if not held:
    _time = fmod(_time + delta * base_frequency, 1000.0)
```

Multiplying the whole phase by `h + 1` keeps the components related as the picture scrolls. There are no separate phase controls, signed coefficients, constant offset or harmonics above five. This finite family is useful without containing every periodic shape. The older source preset ID `triangle` keeps its positive odd 1/n² coefficients; the label now names that mix. A triangle series with this sine orientation would require alternating signs, which these sliders cannot supply.

In this hall, read the amounts and compare the rows before naming the recipe. `name_after_compare:true` leaves the preset name at `ARRIVAL RECIPE` until H1 ALONE or BASELINE is used; HOLD does not reveal it. After a manual edit it instead says `COMPARE THE SUM`. Those invitations do not change the coefficients or their drawing.

## The slider and the name are different operations

Moving a real slider updates its own coefficient from the handle position:

```gdscript
harmonic_amplitudes[harmonic_index] = harmonic_sliders[harmonic_index].get_normalized_value()
```

The geometry uses that value. The recipe label compares all five amounts relative to H1:

```gdscript
for h in range(NUM_HARMONICS):
    if absf(harmonic_amplitudes[h] / first - float(recipe[h])) > RECIPE_TOLERANCE:
        return false
```

`RECIPE_TOLERANCE` is 0.025. At H1 = 1, moving H5 from the sawtooth's 0.20 to 0.22 retains the name; 0.24 leaves it. Scaling every coefficient together preserves the ratios. An all-zero state gets its own label, and any single nonzero harmonic is a sine. A new name does not change the accumulation loop.

## A contribution can leave the picture first

Component ribbons disappear below amplitude 0.01. The formula label rounds to one decimal place and omits small terms; the housed readout rounds to two decimals. The sum continues using the stored coefficients. Its marker readout compares the sum of visible rows with the full sum, reporting inequality when their difference exceeds 0.005. Display precision and signal state are distinct.

With the arrival coefficients, the finite sum rounds the ideal sawtooth's jump and ripples along its descent. The current capture spans about 0.086 m from trough to the following crest in a 0.5 m cycle. That is a measurement of this sampled, five-term construction. It does not measure all possible settings or give the sum a universal amplitude ceiling.

Hold a phase, alter the five amounts, then restore BASELINE. The shape returns at that phase. Release HOLD and the phase continues; BASELINE restores coefficients without rewinding time. The next hall, Random_Definition, asks which other state must be retained for a result to return.
