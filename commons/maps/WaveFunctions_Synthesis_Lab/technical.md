# Decompose and reconstruct signals at workstations where every instrument vibrates at a frequency that belongs to it

The walking path proved that the body can trace a wave. Steps landed on computed positions, sine and cosine became architecture, and the learner moved through trigonometry as a physical act. But walking one function at a time leaves a question unanswered: what happens when waves stack?

A single sine wave is a tone. Two sines at different frequencies produce a chord. A thousand sines at the right amplitudes and phases produce a human voice, a violin bow, a heartbeat. The Synthesis Laboratory is where this stacking becomes material.

Fourier's theorem states that any periodic signal decomposes into a sum of sine waves at integer multiples of a fundamental frequency. The formula is compact:

```
f(t) = Sigma An * sin(n * omega * t + phi_n)
```

Each term contributes one harmonic. The fundamental (n=1) sets the pitch. The overtones (n=2, 3, 4...) shape the timbre. This room contains the apparatus to build signals from components, observe the patterns that emerge when frequencies agree, and discover that biological systems run on oscillation too.

## Additive Synthesis: Stacking Harmonics

The `additive_wave_demo` is the laboratory's central instrument. Five sliders control the amplitudes of harmonics 1 through 5. The combined waveform draws in real time above the control panel, and below it each harmonic renders as a separate colored line.

```gdscript
func _calculate_wave_value(phase: float) -> float:
    var value = 0.0
    for h in range(harmonic_amplitudes.size()):
        value += harmonic_amplitudes[h] * sin(phase * (h + 1))
    return value
```

The loop body is the Fourier series made operational. `harmonic_amplitudes[h]` is An. The multiplier `(h + 1)` produces integer multiples of the fundamental phase. No phase offset appears here because the sliders control only amplitude, keeping the demonstration focused on one variable at a time. The output is a single float — the vertical displacement of the combined wave at that instant.

Each harmonic renders in its own color below the combined waveform: green for the fundamental, blue for the second, pink for the third, yellow for the fourth, purple for the fifth. The color separation makes the contribution of each harmonic trackable even when the combined wave grows complex. Turn off all harmonics except the third and fifth, and the component waves remain visible underneath. The learner sees the ingredients and the result in the same frame.

Raise the first slider alone and a pure sine wave appears. Add the third harmonic at one-third the amplitude of the fundamental and the waveform begins to square off. The preset detection recognizes this:

```gdscript
# Square wave: odd harmonics with 1/n amplitude
if a[0] > 0.9 and a[1] < 0.1 and abs(a[2] - a[0]/3.0) < 0.1 and a[3] < 0.1:
    return "= Square Wave (odd harmonics)"
```

A square wave contains only odd harmonics (1, 3, 5, 7...) with amplitudes that decay as 1/n. The demo approximates this with five sliders. Five harmonics is enough to see the flat tops forming. It takes infinitely many to produce a true square wave — the partial sum always overshoots at the discontinuities, a phenomenon called Gibbs ringing. The demo does not name this effect, but the learner sees it: the waveform almost squares off, but the corners ripple.

A sawtooth wave uses all harmonics at 1/n amplitude. A triangle wave uses only odd harmonics at 1/n-squared. The preset system detects all three by comparing slider positions against known signatures. The distinction between waveforms is entirely in the harmonic recipe — which overtones are present and how loud they are. Timbre, in music, is this recipe. A trumpet and a flute on the same note differ because their harmonic amplitudes differ. The additive demo makes this audible concept visual.

The formula label updates dynamically as sliders move:

```gdscript
if h == 0:
    active_terms.append("%.1f*sin(wt)" % harmonic_amplitudes[h])
else:
    active_terms.append("%.1f*sin(%dwt)" % [harmonic_amplitudes[h], h + 1])
```

Every slider position maps to a term in the Fourier series. The label reads `f(t) = 1.0*sin(wt) + 0.3*sin(3wt) + 0.2*sin(5wt)` and the learner sees both the equation and its shape simultaneously. The symbol and the signal occupy the same space.

## Chladni Patterns: Where Vibration Cancels to Zero

Sand reveals what mathematics describes. The `chladni_plate` vibrates at a frequency determined by two mode numbers (n, m), and 400 particles migrate toward the nodal lines — curves on the plate surface where the vibration amplitude equals zero.

```gdscript
func _chladni_amplitude(x: float, y: float) -> float:
    var n = mode_n * PI
    var m = mode_m * PI
    return cos(n * x) * cos(m * y) - cos(m * x) * cos(n * y)
```

The classic Chladni equation. Two cosine products subtracted produce a 2D standing wave pattern. Where this function returns zero, the plate does not move. Sand collects there because the gradient pushes particles away from vibrating regions and toward stillness:

```gdscript
var amplitude = _chladni_amplitude(nx, nz)
var grad = _chladni_gradient(nx, nz)
var force = -grad * abs(amplitude) * particle_speed
```

The force is proportional to both the gradient direction and the local amplitude. Particles far from nodal lines experience strong force toward them. Particles already on a nodal line feel nothing — they have arrived. Random jitter proportional to local amplitude keeps particles in motion near antinodes while allowing them to settle at nodes:

```gdscript
var jitter = Vector3(
    randf_range(-1, 1), 0, randf_range(-1, 1)
) * 0.02 * abs(_chladni_amplitude(nx, nz))
```

The pattern self-organizes from chaos. Random initial positions converge into geometric lines within seconds.

The plate auto-cycles through mode pairs: (2,3), (3,4), (4,5), (2,5), and others. Each pair produces a distinct geometry. Low mode numbers create simple patterns — a few broad nodal lines. High mode numbers create dense, finely patterned lattices. The complexity scales with frequency, not with any new physics. The same equation, the same particles, the same gradient descent — only the numbers change. Pattern emerges from parameter.

Every question about resonance lives on this plate. Why does a wine glass shatter at a specific pitch? Because that pitch excites the glass's natural mode, and the amplitude at the antinodes exceeds what the material can absorb. Antinodes vibrate maximally. Nodes stand still. The boundary between them concentrates the energy.

## Lissajous Curves: Frequency Ratios as Geometry

Two perpendicular oscillations combined in time produce a parametric curve. The `lissajous_curves` artifact extends this to three dimensions:

```gdscript
func _calculate_point(t: float) -> Vector3:
    return Vector3(
        amplitude_x * sin(freq_ratio_x * t + phase_shift),
        amplitude_y * sin(freq_ratio_y * t),
        amplitude_z * sin(freq_ratio_z * t)
    )
```

Each axis oscillates at its own frequency. When the frequency ratios are integers — 3:2, 5:4, 2:1 — the curve closes on itself and forms a stable knot. When the ratios are irrational, the curve never closes and eventually fills a volume. The distinction between rational and irrational frequency ratios becomes visible as the difference between pattern and chaos.

The phase shift parameter `delta` rotates the figure continuously. A Lissajous curve with ratio 1:1 and phase shift PI/2 is a circle. The same ratio with phase shift 0 is a straight diagonal line. Phase determines whether two equal frequencies reinforce along one axis or distribute into circular motion. The artifact animates this transition — a line unfurls into a circle as phase increases from zero.

Lissajous figures encode a deep fact: the geometry of any combined oscillation depends only on the frequency ratio and the phase relationship. Amplitude scales the figure. Phase rotates it. But the shape — the topology of the knot — comes from the ratio alone. Ratio 2:1 always produces a figure eight. Ratio 3:2 always produces a trefoil. The integers determine the form.

## The Spring and the Oscillator Equation

The `spring_demo` implements Hooke's law with damping:

```gdscript
var spring_force = -spring_k * position_y
var damping_force = -damping_c * velocity_y
var total_force = spring_force + damping_force
var acceleration = total_force / mass
```

F = -kx is the simplest oscillator. The restoring force opposes displacement and scales linearly with it. The solution is a sine wave whose frequency depends on the spring constant and mass: omega = sqrt(k/m). Integration uses Euler's method:

```gdscript
velocity_y += acceleration * delta
position_y += velocity_y * delta
```

Two lines of code. Acceleration changes velocity, velocity changes position. Each frame advances the simulation by one timestep. The result is visually indistinguishable from the analytic solution for reasonable step sizes — and when the step size grows too large, the simulation blows up.

The demo exposes all three parameters through sliders. Increase stiffness and the oscillation speeds up — a stiffer spring produces a higher natural frequency. Increase mass and it slows down — heavier objects resist acceleration. Increase damping and the amplitude decays — energy bleeds into the environment.

The natural frequency emerges from these two parameters alone:

```gdscript
func get_natural_frequency() -> float:
    return sqrt(spring_k / mass) / TAU if mass > 0 else 0
```

Every object that can oscillate has a natural frequency. A bridge, a building, a vocal cord, a crystal. The spring demo reduces this principle to its minimal form: one mass, one spring, one equation. The sine wave that results is the same sine wave the additive demo stacks. The connection is not metaphorical. It is literal. The spring traces the fundamental harmonic of every oscillating system.

The spring coil itself visualizes tension. Color shifts from neutral to red as displacement increases:

```gdscript
var tension = abs(position_y) / initial_displacement
var color = Color(0.5 + tension * 0.5, 0.5, 0.5 - tension * 0.3)
```

Maximum displacement produces maximum redness. At equilibrium, the coil fades to gray. The color encodes the potential energy stored in the spring — red means loaded, gray means relaxed.

The demo also reveals damping regimes. When damping is subcritical (c < 2*sqrt(k*m)), the mass oscillates with exponentially decaying amplitude. At critical damping, it returns to rest as fast as possible without overshooting. Beyond critical, it sluggishly creeps back. These three behaviors — underdamped, critically damped, overdamped — appear everywhere: car suspensions, door closers, the settling of a needle on a scale.

## Phase Propagation: Waves Traveling Through Glass

The `samplevialrack` demonstrates wave propagation as phase offset across discrete elements. Six vials pulse with emission intensity driven by a sine wave, each offset by a fraction of TAU:

```gdscript
# Linear - wave travels left to right
for i in range(num_vials):
    phase_offsets.append(float(i) * TAU / float(num_vials))
```

Each vial receives the same sine wave, shifted by one-sixth of a full cycle from its neighbor. The result: a pulse of light that appears to travel from left to right across the rack. No physical object moves. Each vial oscillates in place. The traveling wave is an illusion created by coordinated phase offsets — the same mechanism that produces the wave in a stadium crowd.

```gdscript
var wave = sin(time * wave_frequency * TAU + phase)
var normalized = (wave + 1.0) / 2.0  # 0 to 1
var glow = lerp(glow_min, glow_max, normalized)
```

The normalization from [-1, 1] to [0, 1] maps the sine wave onto the glow range. This is the same shift-and-scale the dark sphere uses for its emission pulse. Whenever a sine must drive a parameter that only accepts positive values, this mapping bridges the gap.

The rack supports three phase modes: linear, radial, and random. Linear produces a traveling wave. Radial produces a wave that expands outward from the center vial. Random produces no coherent pattern — the same frequency, the same amplitude, but without phase alignment there is no wave. Phase coherence is the difference between signal and noise.

## Biological Oscillation: DNA, Worms, and Resonance

The laboratory extends oscillation beyond physics. The `dna_specimen` rotates a double helix in a glass jar — two sinusoidal strands displaced by half a period, wound around a shared axis:

```gdscript
# Rotate helix slowly
if helix:
    helix.rotation.y += delta * rotation_speed

# Pulse the fluid glow
if fluid and fluid.material_override:
    var pulse = 0.2 + sin(pulse_phase) * 0.1
    fluid.material_override.emission_energy_multiplier = pulse
```

The DNA helix is a wave frozen in molecular geometry. Two strands of nucleotides trace sine curves around the helical axis, offset by 180 degrees — the same relationship as sine and cosine on the unit circle. Rotation makes this visible. The specimen turns at 0.2 radians per second, slow enough to track the interleaving of the strands. The fluid pulses softly, a secondary oscillation suggesting metabolic activity inside the jar.

The `petri_dish_worms` carry oscillation into locomotion. Each worm crawls forward while its body undulates laterally:

```gdscript
var wave_offset = sin(_time * worm.frequency + worm.phase + t * 8.0)
    * oscillation_amplitude * (1.0 - t * 0.5)
segment_pos += perpendicular * wave_offset
```

The sine wave drives lateral displacement perpendicular to the direction of travel. The `t * 8.0` term creates a spatial wave along the body — multiple oscillation cycles visible from head to tail. The `(1.0 - t * 0.5)` decay factor reduces amplitude toward the tail, matching the biomechanics of nematode locomotion. C. elegans moves by generating a traveling wave along its body. The wave pushes against the substrate, and the reaction force propels the worm forward. Locomotion as wave propagation.

Each worm has its own phase, its own frequency, its own speed — all drawn from random ranges at spawn time. The petri dish contains a population of independent oscillators. No two are synchronized, yet all use the same equation. Individual variation within structural uniformity: a hallmark of biological systems.

## Standing Waves and Resonance

The `biomagneticresonator` visualizes standing waves through concentric field rings:

```gdscript
for h in range(1, harmonic_count + 1):
    var harmonic_amplitude = 1.0 / float(h)
    wave += harmonic_amplitude * sin(
        time * resonance_frequency * float(h) * TAU + ring_phase * float(h)
    )
```

Each ring receives a superposition of harmonics. The fundamental and its overtones combine, with amplitudes decaying as 1/n — the same harmonic series the additive wave demo builds manually. The ring phases multiply with harmonic number, producing standing wave nodes at specific heights. Some rings pulse brightly while their neighbors dim. The bright rings are antinodes. The dim rings are nodes. The pattern is stable in space while oscillating in time: a standing wave.

Resonance occurs when the driving frequency matches a natural frequency of the system. The resonator's `trigger_resonance_burst` method momentarily doubles the field strength:

```gdscript
func trigger_resonance_burst() -> void:
    var original_strength = field_strength
    field_strength = 2.0
    await get_tree().create_timer(0.5).timeout
    field_strength = original_strength
```

A half-second of doubled energy, then relaxation back to baseline. This is what happens when external energy matches internal periodicity. Amplitude spikes. In physical systems, this amplification is what breaks bridges, shatters glass, and tunes radio receivers.

The `seismograph` writes oscillation into permanent record. Its pen arm traces the output of a sine wave mixed with noise:

```gdscript
func _get_current_trace_value() -> float:
    var base_wave = sin(_time * trace_frequency * TAU)
    var noise = (randf() - 0.5) * noise_intensity
    var spike = 0.0
    if randf() < SPIKE_CHANCE:
        spike = (randf() - 0.5) * 2.0
    return (base_wave + noise + spike) * trace_amplitude
```

The trace is a sum: signal plus noise plus rare spikes. This is the Fourier thesis in reverse. The additive demo builds complexity from simple components. The seismograph records complexity and implicitly challenges the viewer to decompose it. The underlying sine wave is visible in the trace, but the noise obscures it. Signal extraction — recovering the fundamental from a noisy measurement — is the practical application of Fourier analysis. Every medical EKG, every seismic survey, every audio equalizer performs this operation.

## The Unit Circle Returns

The `UnitCircleTrig` artifact sits inside the laboratory, connecting the final map back to the sequence's origin. A point travels the unit circle. Its y-coordinate projects rightward as a sine trail. Its x-coordinate projects downward as a cosine trail:

```gdscript
var x = cos(angle) * radius
var y = sin(angle) * radius
driver_ball.position = Vector3(x, y, 0)

sine_ball.position = Vector3(radius + projection_offset, y, 0)
cosine_ball.position = Vector3(x, -radius - projection_offset, 0)
```

The unit circle generates every wave in this room. The additive demo sums sines. The Chladni plate multiplies cosines. The Lissajous curves combine sines across axes. The spring oscillates at a frequency determined by sqrt(k/m). The DNA helix winds two sinusoidal strands.

The worms undulate laterally by sin(). The vials pulse by sin(). The seismograph traces sin(). The unit circle is the source function. Rotation becomes oscillation. Oscillation becomes signal. Signal decomposes back into rotation.

Fourier's theorem closes the loop. Any periodic function — no matter how complex, how jagged, how biological — equals a sum of circular motions at integer frequencies. The sequence began with a point on a circle. It ends with the proof that the circle was always sufficient.

## Possible Artifacts

**fourier_decomposer** — The inverse of the additive wave demo. The learner draws or selects a complex waveform (square, sawtooth, arbitrary), and the artifact computes and displays its Fourier coefficients as a bar graph of harmonic amplitudes. Each bar links to a visible sine wave component, and toggling bars on and off shows how the reconstruction improves or degrades. Connects the synthesis direction (building up) to the analysis direction (breaking down), completing the conceptual round trip.

**resonance_bridge** — A suspension bridge model with adjustable driving frequency. The learner sweeps frequency with a slider. At most frequencies the bridge barely moves. At the natural frequency, amplitude grows dramatically — the mesh deforms visibly, cables oscillate, and a displacement graph spikes. A damping slider shows how friction suppresses the resonance peak. Demonstrates why resonance matters in engineering and connects the spring demo's natural frequency to a structural-scale consequence.

**circadian_oscillator** — Three coupled sine waves representing core clock genes (per, cry, bmal1) with phase offsets modeling the transcription-translation feedback loop. The waves drive a day-night color gradient in the background. Disrupting one oscillator's phase (simulating jet lag) causes transient desynchronization visible as interference patterns before the system re-entrains. Extends the biological oscillation thesis from molecular geometry (DNA) and locomotion (worms) into temporal biology.
