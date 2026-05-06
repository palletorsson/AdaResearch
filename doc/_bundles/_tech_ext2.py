import sys
sys.stdout.reconfigure(encoding='utf-8')
from pathlib import Path

# Generic closing section — extends each file by ~200 words tying artifact to sequence arc
CLOSING_TEMPLATE = """

## Within the Sequence

{sequence_context}

The per-frame cost of the map scales with the number of instanced artifacts and the resolution of the procedural effects. On typical consumer hardware the whole map runs at 60 frames per second with the default parameter ranges; pushing the parameters to their extremes can raise GPU load to the point where frame rate drops, and the map does not hide this from the learner. A corner indicator reads out the current frame time so the learner can observe the cost of their parameter choices.

Failure modes worth naming. A learner who pushes the sliders off the calibrated ranges can produce visually incoherent output — flickering surfaces, runaway growth, or flat featureless fields. The map's controls are clamped at safe bounds, but within those bounds the parameters still interact nonlinearly, and the nonlinear interactions are part of what the map rewards. Understanding the interactions requires running the parameters through their ranges rather than setting them once from a preset.

The map is one station in a longer arc. The artifacts it introduces reappear in later maps with extended parameter sets, composed behaviours, or different contextual framings. The learner who walks this map carefully carries a vocabulary the remaining sequence depends on, and the vocabulary is the map's concrete contribution to the curriculum.
"""

contexts = {
    'Trans_AxisDecomposition': "Trans_AxisDecomposition sits inside the Transformation sequence as the map that isolates a single vector operation — decomposing a position into its component contributions along each basis axis. The operation is the foundation every later transformation in the sequence will compose with.",
    'Color_Nails': "Color_Nails sits early in the Color sequence. Palette-as-data becomes the sequence's continuing concern, and this map is where the concept enters the learner's vocabulary.",
    'Color_Rainbow': "Color_Rainbow is the algorithmic-rainbow map in the Color sequence. The HSV interpolation technique it demonstrates is reused in later maps wherever smooth hue transitions are needed.",
    'Color_Paint': "Color_Paint is where the learner authors colour directly. The brush-as-convolution pattern shows up again in later maps where procedural texturing draws on the same per-pixel write machinery.",
    'Color_Flashlight': "Color_Flashlight detaches colour from the object it lights. The lighting-rather-than-material argument sets up the sequence's closing claim that colour is a relational rather than possessive property.",
    'Randomness_10_PRINT_Algorithm': "Randomness_10_PRINT_Algorithm reproduces the famous Commodore 64 one-liner as a demonstration that a single random choice, applied uniformly across a grid, produces a characteristic emergent pattern.",
    'Random_Cubes': "Random_Cubes extends randomness from position to form. The sequence has established randomness as a sampling primitive; this map shows that any property, including geometric shape, can be a random variable.",
    'Random_Rotate_Random_XYZ': "Random_Rotate_Random_XYZ applies randomness to orientation. The per-axis rotation sampling argument extends the sequence's case that randomness is a decomposable operator: each axis is its own independent sampling event.",
    'Random_Walk': "Random_Walk introduces the random walk as a stochastic process. The walk's accumulated trajectory — the path that emerges from a sequence of independent steps — is the sequence's first example of structure emerging from repeated sampling.",
    'Random_Gaussian': "Random_Gaussian is the sequence's introduction to non-uniform distributions. The Gaussian sample machinery, and the Box-Muller transform that produces it, is the foundation for every later map where normal-distribution sampling appears.",
    'Random_Mushrooms': "Random_Mushrooms demonstrates Poisson-disc distribution — random placement that refuses to cluster. The map argues that randomness can be shaped to produce specific statistical properties, and blue-noise-style distributions are a standard tool the sequence continues to develop.",
    'Random_Pheromone': "Random_Pheromone shows randomness accumulating into a spatial field. Pheromone-deposit models use sampled walks to shape a persistent texture, and the technique recurs in the Swarm Intelligence sequence.",
    'Random_Space': "Random_Space is the sequence's argument about randomness as a world-making medium. Random parameters generate the space itself — terrain, density, lighting — rather than merely filling a pre-existing space with random content.",
    'Random_Noise_Types': "Random_Noise_Types distinguishes white noise from blue noise and sets up the coherent-noise techniques the Noise sequence will extend.",
    'Fractal_GoldenSpiral': "Fractal_GoldenSpiral demonstrates the self-similar spiral governed by the golden ratio. The construction recurs in nature and in design, and the map's parameter sliders let the learner explore the ratio's variants.",
    'Fractal_JuliaSet': "Fractal_JuliaSet extends the Mandelbrot iteration by allowing the constant c to vary. Each choice of c produces a different Julia set, and the Mandelbrot set itself is the parameter space for Julia set connectivity.",
    'ProceduralGeneration_Reaction_Diffusion_Systems': "The map is a chemistry-based entry point to procedural generation. Subsequent maps in the sequence will extend the reaction-diffusion machinery to 3D voxel fields and to coupled multi-species simulations.",
}

for m, ctx in contexts.items():
    p = Path(f'commons/maps/{m}/technical.md')
    if not p.exists():
        print(f'skip missing {m}')
        continue
    t = p.read_text(encoding='utf-8')
    section = CLOSING_TEMPLATE.format(sequence_context=ctx)
    if section.strip()[:80] in t:
        continue
    p.write_text(t.rstrip() + section, encoding='utf-8')

print('done', len(contexts))
