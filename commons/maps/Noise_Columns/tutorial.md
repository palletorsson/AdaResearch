# Noise Columns — follow what receives the value

**Learning elements**

- Scalar drivers
- Receiving functions
- Local clocks

Begin with the three columns together. Follow an unnamed silhouette through more than one apparent return. FREEZE pauses this instrument's local clock. SPIN turns a held shape; MARBLE removes the shaft's veining. Let observation precede REVEAL.

The source contains three drivers:

```gdscript
func driver_phase(kind: String, t: float) -> float:
	match kind:
		"periodic":
			return sin(t * melt_speed) * 0.5 + 0.5          # the shipped driver
		"field":
			return clampf(_noise.get_noise_2d(t * 0.55, 0.0) * 0.5 + 0.5, 0.0, 1.0)
		_:
			return TRIO_BASE_PHASE
```

The output called phase is a normalized scalar, not necessarily an angular phase. Both moving drivers feed the same shaft recipe; the field samples along time rather than independently at every vertex. The recipe distributes that scalar using longitudinal progress v:

```gdscript
var melt_factor = pow(v, 0.5) * melt_strength * melt_phase
var height = v * column_height - melt_factor * 2.0
```

The shared 0.00–0.70 m range describes mapped drop at the shaft's top. Observe that the held reference is already ribbed and twisted. Geometry and its reference state were constructed before the new driver was added.

Keep the columns paused and observe the dark orb. Its own clock continues. Its sine enters brightness rather than shaft height:

```gdscript
var pulse_t := (sin(_time_elapsed * pulse_speed) + 1.0) * 0.5
```

Then approach the six-orb variant. The stand chose hush/swarm before construction. Six spheres turn with a parent; their gaps and alternating heights come from an array and a circle, not flocking. Compare the solitary body and the distributed body without requiring one to be an improvement over the other.

The red thread is the value and its recipient: sampled draws in the previous hall; a phase becoming shaft deformation here; another sine becoming light; configuration selecting body parts. Noise_One will give two recipients the same field, as relief and colour. Follow both what changes and what the receiving code keeps fixed.
