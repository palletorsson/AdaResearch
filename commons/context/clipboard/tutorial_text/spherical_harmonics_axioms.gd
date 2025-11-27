extends Node

var text = '''[center][font_size=28][b]Spherical Harmonics[/b][/font_size][/center]
[center][i]Music of the Spheres - Hearing the Geometry[/i][/center]

**Spherical harmonics = the ancient dream of hearing celestial geometry made real.**

**Core concept:** A sphere's position in space (latitude, longitude) directly determines sound (frequency, timbre).

**This is Pythagoras's vision made literal:** The geometry of spheres creates music.

[hr]

[b]The Ancient Dream[/b]

**Pythagoras (c. 570-495 BCE) believed:**
- Celestial spheres (planets, stars) make music as they move
- Each sphere produces a tone based on its orbit
- We can't hear it because we've heard it since birth
- But the music is there - the "harmony of the spheres"

**For 2,500 years, this remained metaphorical.**

**Today, we make it literal:**
- Sphere position → sound parameters
- Geometry → music
- Mathematics → beauty you can hear

[hr]

[b]Spherical Coordinates[/b]

**Any point on or around a sphere can be described with three values:**

[color=yellow][b]Theta (θ) - Latitude Angle:[/b][/color]
[code]
Range: 0 to π (0° to 180°)
θ = 0:   North pole (top)
θ = π/2: Equator (middle)
θ = π:   South pole (bottom)

Measures: Vertical position around sphere
[/code]

[color=yellow][b]Phi (φ) - Longitude Angle:[/b][/color]
[code]
Range: 0 to 2π (0° to 360°)
φ = 0:   Front (starting point)
φ = π/2: Right side
φ = π:   Back
φ = 3π/2: Left side
φ = 2π:  Back to front (full rotation)

Measures: Horizontal rotation around sphere
[/code]

[color=yellow][b]Radius (r) - Distance:[/b][/color]
[code]
Range: 0 to ∞
r = 0:   Center of sphere
r = 1:   Surface of unit sphere
r > 1:   Outside sphere

Measures: How far from center
[/code]

**Convert to Cartesian coordinates (x, y, z):**
[code]
x = r × sin(θ) × cos(φ)
y = r × cos(θ)
z = r × sin(θ) × sin(φ)

Example: θ=π/2, φ=0, r=2
x = 2 × sin(π/2) × cos(0) = 2 × 1 × 1 = 2
y = 2 × cos(π/2) = 2 × 0 = 0
z = 2 × sin(π/2) × sin(0) = 2 × 1 × 0 = 0
→ Point at (2, 0, 0) - right side of sphere
[/code]

[hr]

[b]Position → Sound Mapping[/b]

**In our interactive demo:**

[color=yellow][b]Theta (Latitude) → Frequency (Pitch):[/b][/color]
[code]
θ = 0 (top):      110 Hz (A2, low)
θ = π/2 (middle): 495 Hz (B4, middle)
θ = π (bottom):   880 Hz (A5, high)

Formula: frequency = lerp(110, 880, θ/π)

Why: Smooth pitch change as sphere moves up/down
Result: Ascending/descending scales
[/code]

[color=yellow][b]Phi (Longitude) → Timbre (Harmonic Content):[/b][/color]
[code]
φ = 0 to π/2:        Pure sine → Triangle wave
φ = π/2 to π:        Triangle → Square wave
φ = π to 3π/2:       Square → Sawtooth wave
φ = 3π/2 to 2π:      Sawtooth → Organ-like

Why: Timbre changes as sphere rotates around
Result: Constantly evolving tone color
[/code]

[color=yellow][b]Radius → Amplitude (Volume):[/b][/color]
[code]
r = small:  Quiet (sphere close to center)
r = large:  Loud (sphere far from center)

(In our demo, radius is fixed at 2.0 for simplicity)
[/code]

**The result:** As the small sphere orbits, you hear a melody with constantly changing timbre - geometry becomes music.

[hr]

[b]Interactive Demo[/b]

**Try it yourself:**
[color=cyan]res://algorithms/wavefunctions/spherical_harmonics/SphericalHarmonics.tscn[/color]

**What you'll see:**
- Large translucent sphere (reference)
- Small glowing sphere (orbiter, sound source)
- Orange trail showing orbital path
- Position label (θ, φ, frequency)
- Title: "Music of the Spheres"

**What you'll hear:**
- Pitch rises and falls (theta motion)
- Timbre morphs (phi rotation)
- Continuous, evolving musical tone

**Controls:**
- Orbit Speed θ slider: Vertical motion speed
- Orbit Speed φ slider: Rotation speed
- Auto Orbit button: Toggle automatic motion

**Experiment:**
1. Watch the sphere orbit automatically
2. Listen to how pitch changes with vertical position
3. Notice timbre evolution as it rotates
4. Adjust orbit speeds for different patterns
5. Fast theta, slow phi → rapid pitch changes, slow timbre morphing
6. Slow theta, fast phi → sustained pitches, rapid timbre cycling

[hr]

[b]The Code: Position to Sound[/b]

[color=yellow][b]Spherical to Cartesian Conversion:[/b][/color]
[code]
var theta: float = 0.0  # Latitude (0 to PI)
var phi: float = 0.0    # Longitude (0 to TAU)
var radius: float = 2.0 # Distance from center

func update_sphere_position():
    # Convert spherical → Cartesian
    var x = radius * sin(theta) * cos(phi)
    var y = radius * cos(theta)
    var z = radius * sin(theta) * sin(phi)

    small_sphere.position = Vector3(x, y, z)
[/code]

[color=yellow][b]Theta → Frequency:[/b][/color]
[code]
func update_sound_from_position():
    # Normalize theta from [0, PI] to [0, 1]
    var theta_normalized = theta / PI

    # Map to frequency range (A2 to A5)
    base_frequency = lerp(110.0, 880.0, theta_normalized)

    # Examples:
    # theta = 0    → theta_normalized = 0   → freq = 110 Hz
    # theta = PI/2 → theta_normalized = 0.5 → freq = 495 Hz
    # theta = PI   → theta_normalized = 1   → freq = 880 Hz
[/code]

[color=yellow][b]Phi → Harmonic Content (Timbre):[/b][/color]
[code]
func update_sound_from_position():
    var phi_normalized = phi / TAU  # [0, 1]

    # Cycle through different harmonic recipes
    for i in range(NUM_HARMONICS):
        var harmonic_num = i + 1

        if phi_normalized < 0.25:
            # Pure sine → Triangle wave
            var mix = phi_normalized / 0.25
            if harmonic_num % 2 == 1:  # Odd harmonics
                harmonic_amplitudes[i] = lerp(
                    1.0 if i == 0 else 0.0,  # Pure sine
                    1.0 / (harmonic_num * harmonic_num),  # Triangle
                    mix
                )
        elif phi_normalized < 0.5:
            # Triangle → Square wave
            # (similar pattern for other ranges)
[/code]

[color=yellow][b]Audio Synthesis:[/b][/color]
[code]
func generate_audio_samples():
    for _frame in range(frames_to_fill):
        var sample: float = 0.0

        # Add each harmonic
        for i in range(NUM_HARMONICS):
            var harmonic_freq = base_frequency * (i + 1)
            sample += sin(audio_phases[i]) * harmonic_amplitudes[i]

            # Update phase
            audio_phases[i] += harmonic_freq * TAU / SAMPLE_RATE

        # Normalize and push to audio buffer
        sample = sample / sqrt(active_harmonics) * 0.5
        playback.push_frame(Vector2(sample, sample))
[/code]

[hr]

[b]Why This Is Beautiful[/b]

**Mathematics → Geometry → Sound:**

1. **Spherical coordinates** (mathematical abstraction)
2. **Orbital motion** (geometric form)
3. **Frequency & timbre** (audible beauty)

**Each domain informs the other:**
- See the orbit → predict the sound
- Hear the pitch → know the height
- Hear the timbre → know the rotation angle

**This is synesthesia by design** - geometry becomes sound, sound reveals geometry.

[hr]

[b]Historical Context: Music of the Spheres[/b]

**Pythagoras (c. 570-495 BCE):**
- Discovered musical ratios (octave = 2:1, fifth = 3:2)
- Believed planets emit tones based on orbital speeds
- "Harmony of the spheres" - celestial music

**Plato (c. 428-348 BCE):**
- Each planet's orbit has a "siren" singing a single tone
- Eight tones create a cosmic scale
- Described in "Republic" (Myth of Er)

**Kepler (1571-1630):**
- "Harmonices Mundi" (Harmony of the World)
- Calculated actual "musical intervals" from planetary orbits
- Still metaphorical, but mathematically rigorous

**Today:**
- We sonify actual planetary data
- We create interactive geometry-to-sound systems
- **We make the ancient dream tangible and playable**

[hr]

[b]Spherical Harmonics (Mathematical)[/b]

**In mathematics/physics, "spherical harmonics" means something specific:**

[color=yellow][b]Mathematical Definition:[/b][/color]
[code]
Y_l^m(θ, φ) = orthogonal functions on sphere surface

Where:
- l = degree (number of nodal lines)
- m = order (azimuthal pattern)

Used in:
- Quantum mechanics (atomic orbitals)
- Computer graphics (lighting, reflections)
- Audio (spatial audio encoding - Ambisonics)
- Geophysics (Earth's magnetic field)
[/code]

**Our demo is a simplification:**
- We map position → sound directly
- No complex orthogonal basis functions
- Focuses on intuitive geometry → sound translation

**But the spirit is the same:** Understanding the sphere's geometry through its "harmonics" (sounds).

[hr]

[b]Applications[/b]

**Educational:**
- Visualize spherical coordinates
- Understand geometry-sound relationships
- Experience Pythagorean philosophy
- Learn timbre morphing concepts

**Musical:**
- Generative music (ever-changing melodies)
- Expressive controller (3D position input)
- Ambient soundscapes
- Meditation drones

**Game Audio:**
- Position-based procedural music
- Planet ambience sounds (literal music of spheres!)
- Orbit visualization sonification
- Abstract interactive installations

**Scientific:**
- Sonification of orbital mechanics
- Molecular motion → sound
- Particle trajectories → music
- Data exploration through audio

[hr]

[b]Variations and Extensions[/b]

**Multiple Spheres:**
[code]
# 3 orbiting spheres at different radii
Sphere A: r=1, fast orbit → high tones
Sphere B: r=2, medium orbit → mid tones
Sphere C: r=3, slow orbit → bass tones

Result: Three-voice polyphonic harmony
[/code]

**Elliptical Orbits:**
[code]
# Radius varies over time (ellipse)
r(t) = a × (1 - e²) / (1 + e × cos(ωt))

Where:
- a = semi-major axis
- e = eccentricity
- ω = angular velocity

Result: Volume swells and fades (closer = louder)
[/code]

**Lissajous Orbits:**
[code]
# Two frequencies for theta and phi
theta(t) = A × sin(f1 × t)
phi(t) = B × sin(f2 × t)

Result: Complex 3D patterns (figure-8s, rosettes)
Different patterns = different melodies
[/code]

**User-Drawn Paths:**
[code]
# VR controller traces path in space
# Sphere follows traced curve
# Sound changes with curve position

Result: Draw your own musical geometry
[/code]

[hr]

[b]Connection to Other Wave Concepts[/b]

**Relates to:**

[color=cyan][b]Harmonic Series:[/b][/color]
- Our phi mapping cycles through harmonic recipes
- Different positions = different timbres
- See: `harmonic_series_axioms.gd`

[color=cyan][b]Additive Synthesis:[/b][/color]
- We build sound from 8 harmonics
- Amplitude of each varies with phi
- See: `additive_synthesis_axioms.gd`

[color=cyan][b]Fourier Synthesis:[/b][/color]
- Timbre morphing = interpolating Fourier series
- Position determines spectral content
- See: `fourier_synthesis_axioms.gd`

[color=cyan][b]Wavefunction Form:[/b][/color]
- Orbital motion creates 3D curves
- Geometry and waves unified
- See: `wavefunction_form_axioms.gd`

[hr]

[b]Exercises[/b]

**Using the interactive demo:**

1. **Predict the Pitch:**
   - Close your eyes
   - Listen to current pitch
   - Open eyes and check sphere height
   - High pitch = top, low pitch = bottom

2. **Timbre Recognition:**
   - Listen for 10 seconds
   - Try to identify: pure, triangle, square, or sawtooth?
   - Check phi angle (front/right/back/left)

3. **Create Patterns:**
   - Set theta speed to 1.0
   - Set phi speed to 0.1 (10× slower)
   - Hear: fast pitch changes, slow timbre evolution
   - Now reverse: theta = 0.1, phi = 1.0
   - Hear: sustained pitches, rapid timbre cycling

4. **Find Consonance:**
   - Set theta speed to 0.5
   - Set phi speed to 1.0
   - Listen for "nice sounding" moments
   - These occur when orbit aligns with musical intervals

5. **Manual Control (if joystick added):**
   - Disable auto-orbit
   - Move sphere manually
   - Try to "play" a melody
   - Experience direct geometry → sound mapping

[hr]

[b]Philosophy: Desire, Beauty, Form[/b]

**"Driven by the desire to see the math, to hear the sirens of spheres."**

**This demo embodies:**

**Desire:**
- Pythagoras's longing to hear celestial harmony
- Our drive to understand through multiple senses
- The wish to make abstract math tangible

**Beauty:**
- Mathematical elegance (spherical coordinates)
- Visual beauty (glowing orbital trails)
- Audible beauty (musical tones)
- Unified beauty (all three together)

**Form:**
- Sine/cosine create circular motion
- Circular motion creates orbital paths
- Orbital paths create melodies
- **Mathematics becomes geometry becomes music becomes experience**

**"One domain translates into another. Sine translates to curves."**

Here, we complete the circle:
- **Sine** (math) → **Sphere position** (geometry) → **Sound** (physics) → **Music** (beauty)

[hr]

[color=cyan][b]Summary:[/b][/color]
Spherical harmonics = music of the spheres made real. Position on sphere (θ, φ, r) determines sound (frequency, timbre, amplitude). Theta (latitude) → pitch. Phi (longitude) → harmonic content. Small sphere orbits large sphere, creating constantly evolving musical tone. Pythagoras dreamed of celestial harmony - we make it interactive. Spherical coordinates convert to Cartesian for 3D positioning. Audio synthesis uses 8 harmonics with position-dependent amplitudes. Demonstrates: geometry → sound translation, cross-domain mapping, synesthetic experience. Applications: education, generative music, game audio, scientific sonification. This is how mathematics becomes beauty you can see and hear.

[hr]

[color=orange][b]Try It Now:[/b][/color]
Open [color=cyan]res://algorithms/wavefunctions/spherical_harmonics/SphericalHarmonics.tscn[/color]

Watch the small sphere orbit the large sphere.
Listen as pitch rises and falls with height.
Hear timbre morph as it rotates around.
Adjust orbit speeds to create different patterns.

**You are hearing the geometry of spheres.**
**This is Pythagoras's dream - 2,500 years later - made real, interactive, beautiful.**

**Welcome to the music of the spheres.**

'''
