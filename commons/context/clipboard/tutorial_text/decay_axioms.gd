extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Decay[/b][/font_size][/center]
[center][i]Time-Based Procedural Randomness[/i][/center]

**Decay is entropy over time.** Order → disorder, structure → noise, signal → static.

**But decay is also generative** - it creates textures, atmospheres, organic patterns through progressive randomization.

[hr]

[b]Exponential Decay[/b]

**Exponential decay:** Quantity decreases by constant *proportion* per time step (not constant *amount*).

[color=yellow][b]Code: Basic Decay[/b][/color]
[code]
# Exponential decay formula: N(t) = N₀ * e^(-λt)
# λ = decay constant (rate)
# N₀ = initial quantity
# t = time

var initial_value = 100.0
var decay_rate = 0.1  # 10% per second

func get_decayed_value(time: float) -> float:
    return initial_value * exp(-decay_rate * time)

# At t=0: 100
# At t=5: 100 * e^(-0.5) ≈ 60.7
# At t=10: 100 * e^(-1.0) ≈ 36.8
# At t=20: 100 * e^(-2.0) ≈ 13.5
[/code]

**Half-life:** Time for quantity to reduce to 50%.
- t_half = ln(2) / λ ≈ 0.693 / λ
- For λ=0.1: t_half ≈ 6.93 seconds

**Properties:**
- Never reaches zero (asymptotic)
- Same proportional decrease per time step
- Memoryless (future decay doesn't depend on past)

[hr]

[b]Decay as Noise Generation[/b]

**Procedural decay:** Add randomness that decreases over time.

[color=yellow][b]Code: Decaying Noise[/b][/color]
[code]
# Apply decaying random offset to position
var noise_amplitude = 10.0
var decay_rate = 0.2

func add_decaying_noise(position: Vector3, time: float) -> Vector3:
    var decay_factor = exp(-decay_rate * time)
    var noise = Vector3(
        randf_range(-1, 1),
        randf_range(-1, 1),
        randf_range(-1, 1)
    )
    return position + noise * noise_amplitude * decay_factor

# Early (t=0): Large random offsets (±10 units)
# Later (t=10): Small random offsets (±1.4 units)
# Eventually: Almost no noise (settled to position)
[/code]

**Use cases:**
- **Particle systems** (fireworks lose velocity, drift settles)
- **Camera shake** (explosion shake decays to stillness)
- **Audio effects** (reverb tail fades)
- **Spring physics** (oscillation dampens to rest)

[hr]

[b]Radioactive Decay (Discrete Random Events)[/b]

**Radioactive decay:** Each atom has probability λ of decaying per time step.

[color=yellow][b]Code: Probabilistic Decay[/b][/color]
[code]
# Simulate N radioactive atoms
var atoms = []
for i in range(1000):
    atoms.append(true)  # true = not yet decayed

var decay_probability = 0.1  # 10% chance per second

func update_decay(delta: float):
    for i in range(atoms.size()):
        if atoms[i]:  # If not yet decayed
            if randf() < decay_probability * delta:
                atoms[i] = false  # Decay!
                emit_decay_particle(i)

# Result: exponential decay curve
# But each atom decays at RANDOM time
# Aggregate behavior is predictable, individual behavior is random
[/code]

**Key insight:** **Macroscopic determinism emerges from microscopic randomness.**

Many atoms → predictable half-life.
Single atom → completely unpredictable decay time.

[hr]

[b]Perlin Noise Decay[/b]

**Combine decay with Perlin noise** for organic, time-evolving textures:

[color=yellow][b]Code: Decaying Perlin Noise[/b][/color]
[code]
# Generate terrain height with decaying noise influence
var noise = FastNoiseLite.new()
noise.noise_type = FastNoiseLite.TYPE_PERLIN

func get_height(x: float, z: float, time: float) -> float:
    var base_height = 10.0

    # Decay factor decreases over time
    var decay_factor = exp(-0.1 * time)

    # Perlin noise modulates height, but influence decays
    var noise_value = noise.get_noise_2d(x, z)
    var noise_contribution = noise_value * 5.0 * decay_factor

    return base_height + noise_contribution

# Early (t=0): Rough, noisy terrain (±5 units variation)
# Later (t=20): Smooth, flat terrain (±0.7 units variation)
# Result: Terrain "settles" over time, like erosion
[/code]

**Metaphor:** Erosion smooths mountains, decay removes high-frequency detail.

[hr]

[b]Color Decay (Fade to Gray)[/b]

**Desaturation as decay:** Colors fade toward gray (loss of chroma).

[color=yellow][b]Code: Saturation Decay[/b][/color]
[code]
# Decay color saturation over time
var initial_color = Color(1.0, 0.2, 0.8)  # Bright magenta
var decay_rate = 0.15

func get_decayed_color(time: float) -> Color:
    var decay_factor = exp(-decay_rate * time)

    # Interpolate toward gray (0.5, 0.5, 0.5)
    var gray = Color(0.5, 0.5, 0.5)
    return initial_color.lerp(gray, 1.0 - decay_factor)

# t=0: Bright magenta
# t=5: Faded magenta
# t=10: Almost gray
# t=20: Gray (desaturated)
[/code]

**Applications:**
- **Memory fading** (old photographs lose color)
- **Death animations** (life drains to gray)
- **Temporal distance** (past is monochrome)

[hr]

[b]Audio Decay (Reverb and Echo)[/b]

**Sound decay:** Exponential amplitude reduction over time.

[color=yellow][b]Code: Simple Echo Decay[/b][/color]
[code]
# Generate decaying echo
var original_sound = load_audio_sample()
var echo_delays = [0.2, 0.4, 0.6, 0.8]  # Seconds
var decay_rate = 0.5  # 50% amplitude reduction per echo

func generate_echo(sound: AudioStream) -> AudioStream:
    var output = sound.duplicate()

    for i in range(echo_delays.size()):
        var delay_time = echo_delays[i]
        var amplitude = pow(1.0 - decay_rate, i + 1)

        # Add delayed, attenuated copy of sound
        output.mix_delayed(sound, delay_time, amplitude)

    return output

# Result: Original sound + softer echoes
# Each echo quieter than previous (exponential decay)
[/code]

**Reverb:** Infinite echoes with exponential decay → atmospheric tail.

[hr]

[b]Spring Damping (Oscillation Decay)[/b]

**Damped harmonic motion:** Oscillation that loses energy over time.

[color=yellow][b]Code: Damped Spring[/b][/color]
[code]
# Spring physics with damping
var position = Vector3.ZERO
var velocity = Vector3.ZERO
var spring_constant = 5.0  # Restoring force strength
var damping = 0.3  # Velocity decay per second

func update_spring(target: Vector3, delta: float):
    # Spring force (Hooke's law)
    var displacement = target - position
    var spring_force = displacement * spring_constant

    # Damping force (proportional to velocity)
    var damping_force = -velocity * damping

    # Update velocity and position
    var acceleration = spring_force + damping_force
    velocity += acceleration * delta
    position += velocity * delta

# Result: Overshoots target, oscillates, settles (decaying oscillation)
# High damping: slow, no overshoot (overdamped)
# Low damping: bouncy, long oscillation (underdamped)
# Critical damping: fastest settle without overshoot
[/code]

**Use cases:**
- **UI animations** (smooth settling)
- **Camera follow** (lag with smooth catch-up)
- **IK chains** (joints settle to target)

[hr]

[b]Decay as Procedural Aging[/b]

**Time-based material randomization:** Objects age through accumulated noise.

[color=yellow][b]Code: Rust and Weathering[/b][/color]
[code]
# Shader: Add rust texture over time
uniform float time;
uniform sampler2D rust_noise;
uniform sampler2D base_texture;

void fragment() {
    vec2 uv = UV;

    # Base color
    vec4 base = texture(base_texture, uv);

    # Rust noise (increases with time)
    float rust_amount = time * 0.1;  # 10% per time unit
    float noise = texture(rust_noise, uv).r;

    # Apply rust where noise exceeds threshold
    if (noise < rust_amount) {
        # Rust color (brown-orange)
        vec3 rust_color = vec3(0.7, 0.3, 0.1);
        COLOR.rgb = mix(base.rgb, rust_color, smoothstep(rust_amount - 0.1, rust_amount, noise));
    } else {
        COLOR.rgb = base.rgb;
    }
}

# Result: Metal gradually rusts from high-noise areas first
# Organic, non-uniform aging pattern
[/code]

**Decay as texture:** Randomness increases over time, creating detail.

[hr]

[b]Inverse Decay (Growth from Noise)[/b]

**Inverted decay:** Start with randomness, converge to order over time.

[color=yellow][b]Code: Noise Annealing[/b][/color]
[code]
# Start with random positions, settle to grid
var particles = []
for i in range(100):
    particles.append(Vector3(randf_range(-50, 50), 0, randf_range(-50, 50)))

var grid_size = 10.0
var convergence_rate = 0.2

func update_annealing(delta: float):
    for i in range(particles.size()):
        var particle = particles[i]

        # Find nearest grid point
        var grid_x = round(particle.x / grid_size) * grid_size
        var grid_z = round(particle.z / grid_size) * grid_size
        var target = Vector3(grid_x, 0, grid_z)

        # Move toward grid point (inverse decay)
        particle = particle.lerp(target, convergence_rate * delta)
        particles[i] = particle

# t=0: Random scatter
# t=5: Particles moving toward grid
# t=20: Perfectly aligned to grid
# Inverse of decay: order emerges from randomness
[/code]

**Simulated annealing:** Optimization algorithm that uses "temperature" (noise) that decays over time.
- High temp: large random jumps (exploration)
- Low temp: small local adjustments (exploitation)

[hr]

[b]Decay Curves (Beyond Exponential)[/b]

**Different decay curves for different effects:**

[color=yellow][b]1. Linear Decay[/b][/color]
[code]
func linear_decay(time: float, duration: float) -> float:
    return max(0, 1.0 - time / duration)
# Constant rate, reaches zero at t=duration
[/code]

[color=yellow][b]2. Quadratic Decay (Ease Out)[/b][/color]
[code]
func quadratic_decay(time: float, duration: float) -> float:
    var t = min(time / duration, 1.0)
    return (1.0 - t) * (1.0 - t)
# Fast initial decay, slows near end (smooth stop)
[/code]

[color=yellow][b]3. Logarithmic Decay[/b][/color]
[code]
func logarithmic_decay(time: float) -> float:
    return 1.0 / (1.0 + log(1.0 + time))
# Slow decay that never quite reaches zero
[/code]

**Choice of curve affects feel:**
- Exponential: natural (physics-based)
- Linear: uniform, mechanical
- Quadratic: smooth, animation-friendly
- Logarithmic: persistent, lingering

[hr]

[b]Decay and Memory[/b]

**Temporal blur:** Recent events weighted more than distant past.

[color=yellow][b]Code: Exponential Moving Average[/b][/color]
[code]
# Weighted average that "forgets" old values exponentially
var moving_average = 0.0
var decay_rate = 0.1  # How fast to forget

func update_average(new_value: float, delta: float):
    var alpha = 1.0 - exp(-decay_rate * delta)
    moving_average = lerp(moving_average, new_value, alpha)

# Recent values have high weight
# Old values fade exponentially
# Smooth signal, but responsive to change
[/code]

**Applications:**
- **Camera smoothing** (follow player, decay old positions)
- **Velocity estimation** (smooth jittery input)
- **Audio metering** (VU meters with decay)

[hr]

[b]What Decay Reveals[/b]

Decay shows us:

1. **Entropy increases over time** - Order naturally dissolves to disorder
2. **Exponential is universal** - Physics, biology, finance all use e^(-λt)
3. **Microscopic random, macroscopic predictable** - Single atom random, population deterministic
4. **Decay is generative** - Creates textures, atmospheres, organic variation
5. **Damping stabilizes** - Springs settle, oscillations die out
6. **Aging is accumulated noise** - Rust, weathering, memory fading
7. **Inverse decay is optimization** - Annealing, convergence to order

**Decay is time-based randomization** - progressive addition of entropy, gradual loss of structure, inevitable slide toward equilibrium.

**But:** Decay is also **aesthetic** - the texture of time passing, the beauty of impermanence, the generative power of gradual dissolution.

[hr]

[color=cyan][b]Summary:[/b][/color]
Decay is exponential decrease over time (N(t) = N₀ * e^(-λt)). Applied to noise, creates time-evolving textures. Radioactive decay: individual atoms random, aggregate predictable. Combine with Perlin noise for organic erosion effects. Color saturation decays to gray. Audio decay creates reverb tails. Spring damping: oscillation with energy loss. Procedural aging through accumulated noise. Inverse decay: convergence from randomness to order (annealing). Exponential moving average: weighted memory with decay.

[hr]

[color=orange][b]Next:[/b] Blue Noise - Structured Randomness[/color]
If decay is disorder over time, blue noise is order within randomness - random distribution that avoids clustering, maximally even spread. Randomness that refuses to clump.

'''
