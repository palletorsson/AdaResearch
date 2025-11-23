var text = '''[b]Procedural Generation[/b]
[i]Algorithmic Content Creation[/i]

Procedural generation is the algorithmic creation of content with limited or indirect user input.

It enables creation of complex, varied, and potentially infinite worlds and objects from simple rules.

[i]Key Advantages:[/i]
- Reduced memory usage
- Greater variety
- Replayability
- Rapid prototyping

[hr]

[b]Noise-Based Terrain[/b]

Noise functions are the foundation of procedural terrain generation.

Perlin noise and Simplex noise create smooth, continuous random values that resemble natural patterns. By combining noise at different scales (octaves), we can create realistic terrain features.

[code]
func generate_terrain(width: int, height: int, seed: int) -> Array:
    var noise = FastNoiseLite.new()
    noise.seed = seed
    noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
    noise.fractal_type = FastNoiseLite.FRACTAL_FBM
    noise.fractal_octaves = 4
    noise.frequency = 0.01

    var terrain = []
    for y in range(height):
        var row = []
        for x in range(width):
            var elevation = noise.get_noise_2d(x, y)
            elevation = (elevation + 1) * 5  # Scale to 0-10
            row.append(elevation)
        terrain.append(row)
    return terrain
[/code]

[hr]

[b]L-Systems[/b]

L-systems (Lindenmayer systems) are parallel rewriting systems that can model growth processes.

They consist of an alphabet of symbols, a set of production rules, and an initial axiom. By repeatedly applying rules to the axiom, complex structures emerge from simple instructions.

L-systems are particularly effective for generating plants, trees, and fractals.

[code]
func generate_lsystem(axiom: String, rules: Dictionary, iterations: int) -> String:
    var result = axiom

    for i in range(iterations):
        var next_result = ""

        for c in result:
            if rules.has(c):
                next_result += rules[c]
            else:
                next_result += c

        result = next_result

    return result

# Example: Axiom: "F", Rules: {"F": "F[+F]F[-F]F"}
# F = Draw forward, + = Turn right, - = Turn left
# [ = Save position, ] = Restore position
[/code]

[hr]

[b]Dungeon Generation[/b]

Procedural dungeon generation creates game levels or mazes algorithmically.

[i]Common Approaches:[/i]
- Grid-based methods
- BSP (Binary Space Partitioning) trees
- Agent-based systems
- Cellular automata

The process typically involves room placement, corridor creation, and connectivity checks.

[code]
class BSPNode:
    var x: int
    var y: int
    var width: int
    var height: int
    var left_child: BSPNode
    var right_child: BSPNode

    func split(min_size: int) -> bool:
        var split_horizontal = randf() > 0.5

        if width > height && width / height >= 1.25:
            split_horizontal = false
        elif height > width && height / width >= 1.25:
            split_horizontal = true

        var max_split = height - min_size if split_horizontal else width - min_size

        if max_split < min_size:
            return false

        var split = min_size + randi() % (max_split - min_size + 1)

        if split_horizontal:
            left_child = BSPNode.new(x, y, width, split)
            right_child = BSPNode.new(x, y + split, width, height - split)
        else:
            left_child = BSPNode.new(x, y, split, height)
            right_child = BSPNode.new(x + split, y, width - split, height)

        return true
[/code]

[hr]

[b]Advanced Techniques[/b]

Beyond the basics, procedural generation encompasses:

- [i]Wave Function Collapse:[/i] Generates patterns based on constraints and local rules
- [i]Grammar-based generation:[/i] Creates content using formal grammars
- [i]Voronoi diagrams:[/i] Partitions space for natural-looking regions
- [i]Generative adversarial networks:[/i] Uses machine learning for realistic content

Used in games (Minecraft, No Man's Sky), film (landscapes, crowds), architecture, and music.
'''
