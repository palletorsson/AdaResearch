# Noise One

One field, read twice. Every line below is from `algorithms/randomness/noisetorus/noisetorus.gd` and `commons/resourses/shaders/noiseTorus.gdshader`, the artifact and shader the map places as `noisetorus`.

Sample the field once, in the vertex stage.

```glsl
    vec2 noise_input = vec2(object_pos.x * noise_scale, object_pos.z * noise_scale);
    float wrapped_time = mod(TIME, 3600.0);
    float time_offset = wrapped_time * noise_speed;
    noise_input += vec2(time_offset, time_offset);

    float noise_value = noise(noise_input);
    vec3 displacement = NORMAL * noise_value * height_multiplier * show_relief;
```

And again, in the fragment stage, from the same expression.

```glsl
    vec2 noise_input = vec2(object_pos.x * noise_scale, object_pos.z * noise_scale) + vec2(time_offset, time_offset);
    float noise_value = noise(noise_input);
    ALBEDO = mix(plain_albedo, rainbow_color * noise_value, show_colour);
```

Two stages, one coordinate, one value. That is why the two rings on the bench can be called readings of the same field rather than two fields that happen to resemble each other.

Notice what the second one cannot do. `noise()` returns minus one to plus one; `ALBEDO` cannot be negative. Where the value is below zero the multiplication drives the colour to black and the pipeline clamps it there, so the colour reading keeps the positive half of the field and throws the rest away. The displacement above keeps both halves, pushing inward for one of them.

Read the field on the processor too, for the plate.

```gdscript
func _hash2(p: Vector2) -> float:
	var q: Vector2 = (p * 0.3183099 + Vector2(0.71, 0.113))
	q = Vector2(q.x - floor(q.x), q.y - floor(q.y)) * 50.0
	var v: float = q.x * q.y * (q.x + q.y)
	return -1.0 + 2.0 * (v - floor(v))
```

The same hash the shader uses, ported line for line, so the plate can say what the field IS at a coordinate rather than what it looks like. The graphics card computes this in 32-bit arithmetic and this runs in 64-bit, so the last digits of a very chaotic hash differ; what the plate claims is a definition, not a screenshot.

Spend the value two ways.

```gdscript
func relief_of(value: float) -> float:
	return value * float(PAIR_AMPS[_amp_i])


func colour_of(value: float) -> float:
	return maxf(value, 0.0)
```

One line each, and the difference between them is the room.

Stop every clock, not just the visible one.

```gdscript
		mat.set_shader_parameter("noise_speed", 0.0 if _pair_frozen else noise_speed)
		mat.set_shader_parameter("hue_shift_speed", 0.0 if _pair_frozen else hue_shift_speed)
```

The shader has two: one slides the coordinate the field is sampled at, the other rotates the hue. Zeroing the second alone would leave a ring whose colours had stopped while its sample kept moving — a still picture of a moving thing. Every `TIME` in that file reaches an output through one of these two, which is what makes this a freeze.

Tell a reading from the field.

```gdscript
func cycle_amplitude() -> void:
	_amp_i = (_amp_i + 1) % PAIR_AMPS.size()
	_last_touched = "AMPLITUDE (a reading: the field did not move)"
```

```gdscript
func cycle_frequency() -> void:
	_freq_i = (_freq_i + 1) % PAIR_FREQS.size()
	_last_touched = "FREQUENCY (the field itself: another value is here now)"
```

Amplitude scales what the surface does with a value; frequency changes which value is at the coordinate. The plate prints whichever was touched last, in those words, because the two buttons look alike and are not alike at all.

Stage it in a map.

```
noisetorus:180#stand:pair
```

`stand:pair` builds the bench, the two rings, the markers, the plate and FREEZE, SAMPLE, AMPLITUDE and FREQUENCY. The `180` turns the bench toward the hall's door. Without the token the artifact is the single ring it always was, spending the field as relief and colour at once, with the `readout` axis (relief, plate, none) that an earlier pass gave it.
