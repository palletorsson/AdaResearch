extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]White Noise[/b][/font_size][/center]
[center][i]Pure Randomness, Maximum Entropy[/i][/center]

**White noise is chaos.** No pattern. No structure. Every value independent, unpredictable.

**The baseline of randomness** - all other noise types are filtered white noise.

[hr]

[b]What Is White Noise?[/b]

**Properties:**
- **All frequencies equally present** (flat power spectrum)
- **Each sample independent** (no correlation)
- **Maximum entropy** (unpredictable)
- **No pattern** (looks like TV static)

**Sound:** Hiss, static, "shhhhh"
**Visual:** Random pixel colors, salt-and-pepper noise

[hr]

[b]Generating White Noise[/b]

**Simplest noise - just random values:**

[color=yellow][b]Code: 1D White Noise[/b][/color]
[code]
# Audio white noise (sound)
func generate_white_noise_audio(sample_count: int) -> PackedFloat32Array:
    var samples = PackedFloat32Array()
    samples.resize(sample_count)

    for i in range(sample_count):
        samples[i] = randf_range(-1.0, 1.0)

    return samples

# Result: Pure static, all frequencies, maximum harshness
# Play through AudioStreamGenerator for "shhhhh" sound
[/code]

[color=yellow][b]Code: 2D White Noise (Visual)[/b][/color]
[code]
# Image white noise (visual static)
func generate_white_noise_image(width: int, height: int) -> Image:
    var image = Image.create(width, height, false, Image.FORMAT_RGB8)

    for y in range(height):
        for x in range(width):
            var gray = randf()
            image.set_pixel(x, y, Color(gray, gray, gray))

    return image

# Result: TV static, random grayscale pixels
[/code]

[hr]

[b]Frequency Spectrum (Why "White"?)[/b]

**Color names describe frequency distribution:**

[color=yellow][b]Noise Colors:[/b][/color]
[code]
# White noise: All frequencies equal (flat spectrum)
# Power(f) = constant
# Like: white light (all colors equally present)

# Pink noise (1/f): Low frequencies stronger
# Power(f) ∝ 1/f
# Like: natural sounds (waterfalls, rain)

# Brown/Red noise: Very low frequencies dominant
# Power(f) ∝ 1/f²
# Like: Brownian motion, rumble

# Blue noise: High frequencies stronger (opposite of pink)
# Power(f) ∝ f
# Like: Poisson disk sampling, evenly spaced

# Violet noise: Very high frequencies dominant
# Power(f) ∝ f²
# Like: differentiated white noise
[/code]

**White noise = equal energy at all pitches** (in audio) or spatial frequencies (in images).

[hr]

[b]White Noise as Building Block[/b]

**Filter white noise to create other types:**

[color=yellow][b]Code: Pink Noise from White Noise[/b][/color]
[code]
# Low-pass filter white noise → pink noise
func white_to_pink(white_samples: PackedFloat32Array) -> PackedFloat32Array:
    var pink = PackedFloat32Array()
    pink.resize(white_samples.size())

    var b0 = 0.0
    var b1 = 0.0
    var b2 = 0.0

    for i in range(white_samples.size()):
        var white_val = white_samples[i]

        # Simple pink noise filter (Paul Kellett)
        b0 = 0.99886 * b0 + white_val * 0.0555179
        b1 = 0.99332 * b1 + white_val * 0.0750759
        b2 = 0.96900 * b2 + white_val * 0.1538520

        pink[i] = b0 + b1 + b2 + white_val * 0.3104856

    return pink

# Result: Natural-sounding noise (waterfalls, wind)
[/code]

**All noise starts as white, then filtered to desired spectrum.**

[hr]

[b]Applications of White Noise[/b]

[color=yellow][b]1. Audio Synthesis[/b][/color]
[code]
# Wind, rain, ocean sounds
func wind_sound() -> AudioStream:
    var white_noise = generate_white_noise_audio(44100)  # 1 second

    # Low-pass filter for softer wind
    var filtered = apply_low_pass_filter(white_noise, 2000)  # Cut above 2kHz

    return audio_stream_from_samples(filtered)

# Result: Whooshing wind sound
[/code]

[color=yellow][b]2. Texture Synthesis[/b][/color]
[code]
# Random grain, film noise
func add_film_grain(image: Image, strength: float):
    for y in range(image.get_height()):
        for x in range(image.get_width()):
            var color = image.get_pixel(x, y)

            # Add white noise to each channel
            var noise = randf_range(-strength, strength)
            color.r = clamp(color.r + noise, 0, 1)
            color.g = clamp(color.g + noise, 0, 1)
            color.b = clamp(color.b + noise, 0, 1)

            image.set_pixel(x, y, color)

# Result: Film grain, analog texture
[/code]

[color=yellow][b]3. Dithering[/b][/color]
[code]
# Break up color banding
func dither_image(image: Image, palette_size: int):
    for y in range(image.get_height()):
        for x in range(image.get_width()):
            var color = image.get_pixel(x, y)

            # Add white noise before quantization
            var noise = randf_range(-0.02, 0.02)
            color.r += noise
            color.g += noise
            color.b += noise

            # Quantize to palette
            color.r = round(color.r * palette_size) / palette_size
            color.g = round(color.g * palette_size) / palette_size
            color.b = round(color.b * palette_size) / palette_size

            image.set_pixel(x, y, color)

# Result: No banding, smooth gradients despite low colors
[/code]

[color=yellow][b]4. Random Displacement[/b][/color]
[code]
# Scatter particles, jitter positions
func jitter_particles(particles: Array):
    for particle in particles:
        var jitter = Vector3(
            randf_range(-1, 1),
            randf_range(-1, 1),
            randf_range(-1, 1)
        )
        particle.position += jitter * 0.1

# Result: Breaks perfect grid alignment
[/code]

[hr]

[b]White Noise Shader[/b]

**GPU-generated white noise:**

[color=yellow][b]Shader: Screen-Space White Noise[/b][/color]
[code]
shader_type canvas_item;

uniform float time;

// Hash function for pseudo-random
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
    // Different noise each frame (use time)
    float noise = hash(UV * 100.0 + vec2(time * 10.0, 0.0));

    COLOR = vec4(vec3(noise), 1.0);
}

# Result: Animated white noise (TV static)
# Every pixel random, updates each frame
[/code]

[hr]

[b]Gaussian White Noise[/b]

**Usually uniform distribution, but can use Gaussian:**

[color=yellow][b]Code: Gaussian White Noise[/b][/color]
[code]
# White noise with Gaussian distribution (instead of uniform)
func gaussian_white_noise(sample_count: int) -> PackedFloat32Array:
    var samples = PackedFloat32Array()
    samples.resize(sample_count)

    for i in range(sample_count):
        samples[i] = gaussian_random(0, 1)  # Mean 0, std dev 1

    return samples

# Result: Still white (all frequencies), but amplitude distribution Gaussian
# More samples near 0, fewer extreme values
# Common in signal processing (AWGN - Additive White Gaussian Noise)
[/code]

[hr]

[b]Colored Noise Comparison[/b]

**Visual comparison of noise types:**

[color=yellow][b]Code: Noise Spectrum Visualization[/b][/color]
[code]
# Generate different noise colors for comparison
func compare_noise_colors():
    var white = generate_white_noise_audio(44100)
    var pink = white_to_pink(white)
    var brown = white_to_brown(white)
    var blue = white_to_blue(white)

    # Play/visualize each
    # White: Harsh, bright hiss
    # Pink: Softer, balanced (natural)
    # Brown: Deep rumble, low frequency
    # Blue: Bright, crispy (high frequency)

# Frequency spectrum (power vs frequency):
# White: Flat line
# Pink: Downward slope (1/f)
# Brown: Steeper downward slope (1/f²)
# Blue: Upward slope (f)
[/code]

[hr]

[b]White Noise in Nature[/b]

**Rare - nature prefers pink/brown:**

**White noise examples:**
- **Radio static** (interstellar background radiation)
- **Thermal noise** (electron agitation in circuits)
- **Shot noise** (quantum effects in detectors)

**Nature is mostly NOT white:**
- **Waterfalls:** Pink noise (1/f)
- **Rustling leaves:** Pink noise
- **Human speech:** Pink-ish
- **Earthquakes:** Brown noise (1/f²)

**White noise is artificial** - maximum disorder, rarely occurs naturally.

[hr]

[b]Perceptual Masking[/b]

**White noise masks other sounds:**

[color=yellow][b]Code: Sound Masking[/b][/color]
[code]
# Add white noise to hide unwanted frequencies
func mask_background_noise(audio: PackedFloat32Array, mask_strength: float):
    var white_noise = generate_white_noise_audio(audio.size())

    for i in range(audio.size()):
        audio[i] += white_noise[i] * mask_strength

    return audio

# Use case: Sleep machines, privacy (mask conversations)
# White noise covers all frequencies → masks speech
[/code]

[hr]

[b]Information Theory: Maximum Entropy[/b]

**White noise = maximum unpredictability:**

[color=yellow][b]Entropy Concept:[/b][/color]
[code]
# Entropy = measure of unpredictability

# Constant signal (all zeros):
# Entropy = 0 (perfectly predictable)

# Periodic signal (sine wave):
# Entropy = low (can predict next sample from pattern)

# White noise:
# Entropy = MAXIMUM (cannot predict next sample)

# Information theory:
# White noise carries no information (paradoxically)
# Because every value is noise, nothing is signal
[/code]

**White noise is paradox:** Maximum randomness = no information (can't extract meaning from chaos).

[hr]

[b]Testing Randomness[/b]

**Check if generator produces white noise:**

[color=yellow][b]Code: Autocorrelation Test[/b][/color]
[code]
# True white noise has zero autocorrelation (no pattern)
func autocorrelation(samples: PackedFloat32Array, lag: int) -> float:
    var mean = 0.0
    for sample in samples:
        mean += sample
    mean /= samples.size()

    var numerator = 0.0
    var denominator = 0.0

    for i in range(samples.size() - lag):
        numerator += (samples[i] - mean) * (samples[i + lag] - mean)

    for i in range(samples.size()):
        denominator += (samples[i] - mean) * (samples[i] - mean)

    return numerator / denominator

# For white noise:
# autocorrelation(samples, 0) ≈ 1.0 (sample correlates with itself)
# autocorrelation(samples, k) ≈ 0.0 for all k > 0 (no correlation)

# If autocorrelation(lag > 0) != 0, not white noise (has pattern)
[/code]

[hr]

[b]What White Noise Reveals[/b]

White noise shows us:

1. **Maximum entropy** - Complete unpredictability
2. **No correlation** - Each sample independent
3. **Flat spectrum** - All frequencies equally present
4. **Baseline for filtering** - Start white, filter to get other types
5. **Rare in nature** - Nature prefers pink/brown (structured)
6. **Perceptual harshness** - Bright, fatiguing to listen to
7. **Information paradox** - Maximum randomness = no information

**White noise is anarchist** - refuses pattern, rejects structure, pure chaos.

**It is the sound/vision of entropy maximized** - heat death of signal.

[hr]

[color=cyan][b]Summary:[/b][/color]
White noise is pure randomness with flat frequency spectrum (all frequencies equal). Maximum entropy, zero autocorrelation. Generated via random samples (uniform or Gaussian distribution). Building block for other noise types (filter white → pink/brown/blue). Applications: audio synthesis (wind, rain), texture grain, dithering, jitter. GPU shader for real-time static. Rare in nature (artificial). Perceptual masking (covers other sounds). Information theory: maximum unpredictability = no extractable information.

[hr]

[color=orange][b]Next:[/b] Shader Noise - GPU Randomness[/color]
CPU white noise is sequential. GPU noise is parallel - thousands of random values per frame, hash functions instead of PRNGs, procedural generation in fragment shaders.

'''
