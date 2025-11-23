var text = '''[b]Randomness[/b]
[i]Understanding Pseudorandom Generation[/i]

Randomness is a fundamental concept in computing, used in everything from games to simulations.

True randomness is difficult to achieve in computers, so we use pseudorandom number generators (PRNGs). PRNGs create sequences of numbers that appear random but are actually determined by an initial value called a seed.

[code]
var rng = RandomNumberGenerator.new()
rng.randomize()  # Uses current time as seed

# Generate a random float between 0 and 1
var random_value = rng.randf()

# Generate a random integer between 1 and 10
var random_int = rng.randi_range(1, 10)
[/code]

[hr]

[b]Uniform Distribution[/b]

Uniform distribution gives each possible outcome an equal probability of occurring.

The standard random() function typically produces uniformly distributed values between 0 and 1. This distribution is perfect for simulating dice rolls, card shuffling, or any scenario where all outcomes should be equally likely.

Over time, with enough samples, a histogram of uniform random values should appear relatively flat.

[code]
func generate_uniform_values(count: int) -> Array:
    var values = []
    var rng = RandomNumberGenerator.new()
    rng.randomize()

    for i in range(count):
        values.append(rng.randf())  # Values between 0 and 1

    return values
[/code]

[hr]

[b]Gaussian Distribution[/b]

Gaussian (or normal) distribution creates a bell curve where values cluster around the mean.

Unlike uniform distribution, values near the middle are more likely than values at the extremes. This type of randomness is useful for modeling natural phenomena, like heights, weights, or measurement errors.

In creative coding, Gaussian randomness creates more natural-looking variation.

[code]
# Box-Muller transform for Gaussian distribution
func generate_gaussian(mean: float, std_dev: float) -> float:
    var rng = RandomNumberGenerator.new()
    rng.randomize()

    var u1 = rng.randf()
    var u2 = rng.randf()

    var z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * PI * u2)

    return mean + z0 * std_dev
[/code]

[hr]

[b]Random Walks[/b]

A random walk is a mathematical object that describes a path of random steps in some mathematical space.

In its simplest form, each step moves in a random direction from the current position. Random walks are used to model many processes in physics, economics, and biology. In creative coding, they create organic-looking paths.

[code]
class Walker:
    var position = Vector2.ZERO
    var rng = RandomNumberGenerator.new()

    func step():
        var direction = rng.randi_range(0, 3)
        match direction:
            0: position.x += 1  # Right
            1: position.x -= 1  # Left
            2: position.y += 1  # Down
            3: position.y -= 1  # Up
        return position
[/code]

[hr]

[b]Perlin Noise[/b]

Perlin Noise, developed by Ken Perlin, is a type of gradient noise that creates smooth, natural-looking randomness.

Unlike uniform or Gaussian randomness, Perlin noise values change smoothly over time or space. This property makes it ideal for generating terrain, clouds, textures, and natural motion.

[code]
var noise = FastNoiseLite.new()

func setup_noise():
    noise.seed = randi()
    noise.noise_type = FastNoiseLite.TYPE_PERLIN
    noise.frequency = 0.01

func get_noise_value(x: float, y: float) -> float:
    return noise.get_noise_2d(x, y)
[/code]
'''
