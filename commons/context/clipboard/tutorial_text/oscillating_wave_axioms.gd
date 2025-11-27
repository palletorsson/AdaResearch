extends Node

var text = '''[center][font_size=28][b]Oscillating Wave[/b][/font_size][/center]
[center][i]Sine Creates Curves - Motion Becomes Form Becomes Sound[/i][/center]

**The oscillating wave demonstrates the fundamental truth: sine creates curves.**

**Core concept:** A sphere oscillates vertically. It traces a sine curve in 3D space. The curve position controls sound.

**Motion → Form → Sound**
- Sine function → Visible wave → Musical tone
- Mathematics → Geometry → Audio
- One domain translates into another

[hr]

[b]The Fundamental Concept[/b]

**Simple harmonic motion:**

[color=yellow][b]Vertical Position (y):[/b][/color]
[code]
y(t) = A × sin(ω × t)

Where:
- A = amplitude (maximum displacement)
- ω = angular frequency (radians per second)
- t = time

Example: A = 1.5, ω = 2π (1 Hz oscillation)
y(0) = 1.5 × sin(0) = 0 (center)
y(0.25) = 1.5 × sin(π/2) = 1.5 (top)
y(0.5) = 1.5 × sin(π) = 0 (center)
y(0.75) = 1.5 × sin(3π/2) = -1.5 (bottom)
y(1.0) = 1.5 × sin(2π) = 0 (center, one complete cycle)
[/code]

**As the sphere moves forward at constant speed, it traces a sine curve in space:**
- Time becomes space
- Oscillation becomes wave
- Function becomes form

**This is how sine creates curves.**

[hr]

[b]Interactive Demo[/b]

**Try it yourself:**
[color=cyan]res://algorithms/wavefunctions/oscillating_wave/OscillatingWave.tscn[/color]

**What you'll see:**
- Magenta sphere oscillating up and down
- Glowing trail of points forming a sine wave
- Blue reference curve (mathematical ideal)
- Info label showing frequency, amplitude, phase

**What you'll hear:**
- Pitch changes as sphere moves horizontally (left to right)
- Volume pulses with vertical position (up = loud, down = quiet)
- Timbre shifts with wave phase

**Controls:**
- Oscillation Frequency slider: How fast it bobs up/down (0.1-5 Hz)
- Oscillation Amplitude slider: How far it moves vertically (0.5-3.0)
- Horizontal Speed slider: How fast it moves forward (0.1-3.0)
- Show Reference button: Toggle blue reference sine curve

**Experiment:**
1. Watch the sphere oscillate and trace the sine wave
2. Compare the magenta trail to the blue reference curve
3. Adjust oscillation frequency - faster = more waves per unit distance
4. Adjust amplitude - larger = taller waves
5. Listen to how sound changes with position

[hr]

[b]Mathematics: Sine Function[/b]

**The sine function is the foundation of all waves:**

[color=yellow][b]Definition:[/b][/color]
[code]
sin(θ) = opposite / hypotenuse (in right triangle)

Or, from unit circle:
sin(θ) = y-coordinate of point on circle at angle θ

As θ increases from 0 to 2π (one full rotation):
sin(0) = 0
sin(π/2) = 1 (maximum)
sin(π) = 0
sin(3π/2) = -1 (minimum)
sin(2π) = 0 (back to start)
[/code]

**Properties:**
- Periodic: sin(θ + 2π) = sin(θ)
- Bounded: -1 ≤ sin(θ) ≤ 1
- Smooth: Infinitely differentiable
- Symmetric: sin(-θ) = -sin(θ)

**This is the simplest repeating pattern in mathematics.**

[hr]

[b]Position → Sound Mapping[/b]

**In our demo:**

[color=yellow][b]Horizontal Position (x) → Frequency:[/b][/color]
[code]
x = -5 to +5 meters
Frequency = lerp(110 Hz, 880 Hz, (x + 5) / 10)

Left side (x = -5):   110 Hz (A2, low)
Center (x = 0):       495 Hz (B4, mid)
Right side (x = +5):  880 Hz (A5, high)

Why: As sphere moves forward, pitch rises
Result: Ascending scale
[/code]

[color=yellow][b]Vertical Position (y) → Amplitude:[/b][/color]
[code]
y = -1.5 to +1.5 meters (default amplitude)
Volume = lerp(-12 dB, 0 dB, (y / amp + 1) / 2)

Bottom (y = -1.5): -12 dB (quiet)
Center (y = 0):    -6 dB (medium)
Top (y = +1.5):    0 dB (loud)

Why: Height represents energy
Result: Pulsing volume synchronized with oscillation
[/code]

[color=yellow][b]Wave Phase (t) → Timbre:[/b][/color]
[code]
phase = fmod(oscillation_frequency × time, 1.0)

Phase 0:    Even harmonics strong
Phase 0.25: Odd harmonics strong
Phase 0.5:  Even harmonics strong again
Phase 0.75: Odd harmonics strong again

Why: Continuous spectral evolution
Result: Timbre breathes with the wave
[/code]

**The result:** A musical tone that evolves in pitch, volume, and color as the wave unfolds.

[hr]

[b]How Sine Creates Curves[/b]

**Step-by-step transformation:**

**1. Circular Motion:**
[code]
# Point on unit circle
x = cos(θ)
y = sin(θ)

As θ increases: point rotates around circle
[/code]

**2. Project to Line:**
[code]
# Take only y-coordinate
y = sin(θ)

As θ increases: y oscillates up and down
This is simple harmonic motion
[/code]

**3. Add Forward Motion:**
[code]
# Move horizontally while oscillating vertically
x = t × speed (linear motion)
y = sin(ω × t) (oscillation)

As t increases: traces sine wave in space
[/code]

**4. Result:**
- Circular motion → Oscillation → Wave form
- Rotation → Vibration → Propagation
- **Sine creates curves**

[hr]

[b]Code: Generate Oscillating Motion[/b]

[color=yellow][b]Update Position:[/b][/color]
[code]
var time: float = 0.0
var oscillation_frequency: float = 1.0  # Hz
var oscillation_amplitude: float = 1.5  # Meters
var horizontal_speed: float = 1.0       # Meters per second
var horizontal_position: float = 0.0

func _process(delta: float):
    time += delta

    # Vertical: sine oscillation
    var y = oscillation_amplitude * sin(oscillation_frequency * TAU * time)

    # Horizontal: constant forward motion
    horizontal_position += horizontal_speed * delta
    var x = horizontal_position

    # Update sphere
    sphere.position = Vector3(x, y, 0)

    # Leave trail point
    trail[trail_index].position = sphere.position
    trail_index = (trail_index + 1) % TRAIL_LENGTH
[/code]

[color=yellow][b]Generate Audio:[/b][/color]
[code]
func update_sound():
    # Map x position to frequency
    var x_normalized = (sphere.position.x + 5.0) / 10.0
    base_frequency = lerp(110.0, 880.0, x_normalized)

    # Map y position to volume
    var y_normalized = (sphere.position.y / oscillation_amplitude + 1.0) / 2.0
    volume_db = lerp(-12.0, 0.0, y_normalized)

    # Map phase to timbre
    var phase = fmod(oscillation_frequency * time, 1.0)
    for i in range(NUM_HARMONICS):
        var modulation = 0.5 + 0.5 * sin(phase * TAU * (i + 1))
        harmonic_amplitudes[i] = (1.0 / (i + 1)) * modulation
[/code]

[hr]

[b]Why Sine Is Fundamental[/b]

**Sine appears everywhere in nature:**

**1. Pendulum:**
[code]
# Angle of pendulum bob
θ(t) = θ_max × sin(√(g/L) × t)

Small oscillations follow sine function exactly
[/code]

**2. Spring:**
[code]
# Position of mass on spring
x(t) = A × sin(√(k/m) × t)

Where k = spring constant, m = mass
Hooke's Law → sine oscillation
[/code]

**3. Sound Wave:**
[code]
# Air pressure variation
P(x, t) = P_0 × sin(kx - ωt)

Where k = wave number, ω = angular frequency
This IS the sine curve propagating through space
[/code]

**4. Light Wave:**
[code]
# Electric field
E(x, t) = E_0 × sin(kx - ωt + φ)

Electromagnetic radiation = sine wave
[/code]

**5. Circular Motion:**
[code]
# Projection of rotation
y(t) = r × sin(ωt)

Any rotation, viewed from the side, looks like sine oscillation
[/code]

**Sine is the natural result of:**
- Restoring forces (springs, pendulums)
- Circular motion (wheels, orbits)
- Energy conservation (no friction)
- Linear differential equations (physics)

**This is why it appears everywhere - it's the shape of simple, repeating motion.**

[hr]

[b]Fourier Insight[/b]

**Any repeating curve can be built from sines:**

[color=yellow][b]Fourier Series:[/b][/color]
[code]
f(t) = A_0 + A_1×sin(ωt) + A_2×sin(2ωt) + A_3×sin(3ωt) + ...

Any periodic function = sum of sine waves at different frequencies
[/code]

**But the single sine is the building block:**
- Pure sine = simplest wave
- Complex curves = sums of sines
- **All curves reduce to sines (Fourier decomposition)**
- **All sines combine to curves (Fourier synthesis)**

**Our demo shows the fundamental building block** - one pure sine creating one pure curve.

[hr]

[b]Applications[/b]

**Educational:**
- Visualize simple harmonic motion
- See sine function as geometric curve
- Understand oscillation → wave relationship
- Learn phase, frequency, amplitude concepts

**Musical:**
- Generative melody (horizontal position)
- Expressive dynamics (vertical position)
- Rhythmic pulsing (oscillation frequency)
- Ambient soundscapes

**Game Audio:**
- Procedural wave sound effects (ocean, energy fields)
- Position-based musical feedback
- Rhythmic ambient loops
- Visualization of audio waveforms

**Scientific:**
- Sonification of oscillatory data
- Pendulum motion demonstration
- Wave propagation visualization
- Teaching tool for physics/math

[hr]

[b]Variations[/b]

**Multiple Oscillators:**
[code]
# Two spheres with different frequencies
Sphere A: f = 1.0 Hz → slow, long waves
Sphere B: f = 2.0 Hz → fast, short waves

Result: Two intertwined sine curves
Demonstrates frequency relationship
[/code]

**Lissajous Figures:**
[code]
# Oscillate in both x and y
x(t) = A × sin(f_x × t)
y(t) = B × sin(f_y × t + φ)

Result: Complex 2D patterns (circles, figure-8s, flowers)
Depends on frequency ratio and phase
[/code]

**Damped Oscillation:**
[code]
# Amplitude decreases over time
y(t) = A × e^(-γt) × sin(ωt)

Where γ = damping coefficient
Result: Dying away (like plucked string)
[/code]

**Frequency Sweep:**
[code]
# Frequency changes over time
ω(t) = ω_0 + αt

Result: Compressed waves (chirp)
Used in sonar, radar, synthesizers
[/code]

[hr]

[b]Connection to Other Wave Concepts[/b]

**Relates to:**

[color=cyan][b]Harmonic Series:[/b][/color]
- Multiple oscillators at integer frequency ratios
- Fundamental + overtones = complex timbre
- See: `harmonic_series_axioms.gd`

[color=cyan][b]Beat Frequencies:[/b][/color]
- Two oscillators with close frequencies
- Interference creates amplitude modulation
- See: `beat_frequencies_axioms.gd`

[color=cyan][b]Fourier Synthesis:[/b][/color]
- This demo shows ONE sine component
- Multiple sines combine to create complex curves
- See: `fourier_synthesis_axioms.gd`

[color=cyan][b]Spherical Harmonics:[/b][/color]
- 3D oscillation (orbital motion)
- Position → sound mapping
- See: `spherical_harmonics_axioms.gd`

[color=cyan][b]Wavefunction Form:[/b][/color]
- How waves become geometry
- Parametric curves from oscillation
- See: `wavefunction_form_axioms.gd`

[hr]

[b]Philosophy: One Domain Translates Into Another[/b]

**"Sine translates to curves."**

**This demo embodies the unity of:**

**Mathematics:**
- y = A × sin(ωt) [equation]
- Precise, abstract, universal

**Geometry:**
- Visible sine curve [form]
- Spatial, tangible, beautiful

**Physics:**
- Oscillating motion [dynamics]
- Temporal, causal, natural

**Sound:**
- Musical tone [sensation]
- Audible, emotional, aesthetic

**All four are the same thing, experienced differently.**

**This is the power of mathematics:**
- One equation (sine)
- Multiple manifestations (curve, motion, sound, light)
- **Unity beneath diversity**

**"We have a comprehensive sequence where we can see how sine creates form."**

Here, we complete the vision:
- **Sine** (abstract math) → **Oscillation** (physical motion) → **Curve** (geometric form) → **Sound** (aesthetic experience)

[hr]

[b]Historical Note: Sine Tables[/b]

**Ancient astronomers needed sine values:**

**Hipparchus (c. 150 BCE):**
- Created first trigonometric tables
- Used for astronomy (planetary positions)
- No concept of "wave" yet

**Indian mathematicians (Aryabhata, c. 500 CE):**
- Refined sine tables
- Called it "jya" (bowstring)
- Still astronomical, not wave-related

**Fourier (1822):**
- "Théorie analytique de la chaleur"
- **Showed sine is fundamental to all periodic phenomena**
- Heat diffusion, waves, oscillations - all reducible to sines

**Today:**
- Sine is THE building block of signal processing
- Every digital audio system uses sine-based synthesis
- **Our demo continues the 2,000-year tradition of exploring sine**

[hr]

[b]Exercises[/b]

**Using the interactive demo:**

1. **Predict the Wave:**
   - Set oscillation frequency to 2.0 Hz
   - Set horizontal speed to 1.0
   - Count how many complete waves appear in the trail
   - Should see ~2 complete cycles

2. **Match the Reference:**
   - Enable the blue reference curve
   - Adjust oscillation frequency until magenta trail matches blue
   - This demonstrates parameter → form relationship

3. **Hear the Motion:**
   - Close your eyes
   - Listen to volume pulsing
   - Hear the rhythm of oscillation
   - Open eyes - see it matches the up/down motion

4. **Create Patterns:**
   - High frequency (5 Hz), slow horizontal (0.5) → many tight waves
   - Low frequency (0.5 Hz), fast horizontal (2.0) → gentle rolling hills
   - Large amplitude (3.0) → dramatic peaks and valleys

5. **Timbre Evolution:**
   - Listen for 30 seconds
   - Notice timbre "breathing" with the wave
   - Harmonic content cycles with oscillation phase

[hr]

[color=cyan][b]Summary:[/b][/color]
Oscillating wave = sphere that oscillates vertically while moving horizontally. Traces visible sine curve in 3D space. Motion (oscillation) → Form (sine curve) → Sound (musical tone). Horizontal position → frequency. Vertical position → amplitude. Wave phase → timbre. Demonstrates: sine creates curves, one domain translates to another, mathematics becomes geometry becomes sound. Simple harmonic motion: y = A×sin(ωt). Fundamental to: pendulums, springs, sound waves, light waves, circular motion. Building block for all periodic phenomena (Fourier). Applications: education, generative music, game audio, scientific sonification. This is how sine becomes form becomes beauty.

[hr]

[color=orange][b]Try It Now:[/b][/color]
Open [color=cyan]res://algorithms/wavefunctions/oscillating_wave/OscillatingWave.tscn[/color]

Watch the sphere oscillate up and down.
See the sine curve emerge in space.
Hear the pitch rise as it moves forward.
Hear the volume pulse with vertical motion.

**This is sine creating curves before your eyes.**
**This is mathematics becoming geometry becoming sound.**

**Motion → Form → Sound → Beauty**

'''
