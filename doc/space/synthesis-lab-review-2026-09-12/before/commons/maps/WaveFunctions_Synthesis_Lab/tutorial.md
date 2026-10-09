# Synthesis Lab

Fourier said any periodic signal is a sum of sines. Build the bench where five amounts of five sines make a shape, and take it apart again. Every excerpt below is from `commons/artifacts/additive_wave_demo/additive_wave_demo.gd`.

Keep five amounts.

```gdscript
var harmonic_amplitudes: Array[float] = [1.0, 0.0, 0.0, 0.0, 0.0]
```

Five coefficients, one per harmonic. Harmonic h + 1 runs at h + 1 times the fundamental; nothing in this file changes the fundamental itself.

Sum them at one phase.

```gdscript
func _calculate_wave_value(phase: float) -> float:
	var value = 0.0
	for h in range(harmonic_amplitudes.size()):
		value += harmonic_amplitudes[h] * sin(phase * (h + 1))
	return value
```

The loop body is the Fourier series made operational. The output is one number: the sum's height at that phase.

Draw the sum from 256 samples, four cycles across two metres, scrolling with a clock.

```gdscript
	for i in range(WAVE_POINTS):
		var t = float(i) / (WAVE_POINTS - 1)
		var x = (t - 0.5) * WAVE_LENGTH
		var phase = t * TAU * 4.0 + _time * TAU
```

`WAVE_POINTS` is 256 and `WAVE_LENGTH` 2.0. The same `t` and `phase` draw each harmonic's own row, one sine each, so the rows and the sum are always at the same places.

Hang the rows under the sum, one per harmonic.

```gdscript
	return Vector3(x, y * 0.2 - 0.35 - h * 0.15, 0.1)
```

The ladder: row h sits 0.15 m below the row above, drawn at two thirds of the sum's scale. This is the ingredient list; `components:overlay` draws the rows on the sum's own axis instead.

Wire each slider to its amount.

```gdscript
func _on_harmonic_changed(_value, harmonic_index: int) -> void:
	if harmonic_index < harmonic_sliders.size() and harmonic_sliders[harmonic_index]:
		harmonic_amplitudes[harmonic_index] = harmonic_sliders[harmonic_index].get_normalized_value()
		_dirty = true
		waveform_changed.emit(harmonic_amplitudes)
```

A slider changes exactly one number, read back from the handle's position. The meshes redraw every frame; the labels and the readout only when something changed.

Name the recipes.

```gdscript
		"sawtooth":
			# Sawtooth: all harmonics, amplitude 1/n
			_set_amplitudes([1.0, 0.5, 0.333, 0.25, 0.2])
```

`set_preset` writes a table of amounts onto the five sliders. The room is placed with this one; `_detect_preset` gives the label its name back when the amounts are near a table, and "Custom Waveform" when they are not.

Stage it for a body (the `stand` axis, opt-in by token).

```gdscript
func restore_baseline() -> void:
	_set_amplitudes(_baseline)
	waveform_changed.emit(harmonic_amplitudes)
```

Under `#stand:bench` the display is lifted onto a backboard, the sliders stand as a console on a bench, and three buttons use the same paths the sliders use: BASELINE writes the arrival table back, H1 ALONE keeps the first amount and zeroes the rest, HOLD stops `_time` so a place on the board can be read. A readout prints each row's value at a marker and the sum of the drawn rows beside the drawn total, from the same loop.

Let five fail to make a corner.

The sawtooth's ideal, Σ sin(nφ)/n = (π − φ)/2, drops in no distance at all. Five terms climb from trough to crest over about nine centimetres of a fifty-centimetre cycle and ripple about once per row on the flank. No slider straightens that; more terms would, and this bench has five.

You have synthesized the sequence: sines as shape, as source, as sound, as a sum built on purpose. The museum's route goes on to Random_Definition, where a result that looks as involved as this one is asked whether it can be brought back at all.
