# Artifact Theme Guide

**Version:** 1.0
**Last Updated:** 2026-01-29
**Status:** Proof of Concept (20 artifacts tagged)

## Overview

The Artifact Theme System organizes AdaResearch's 318+ artifacts by **purpose and function** rather than just by technical implementation. This improves developer workflow by making it easy to find artifacts for specific use cases.

## Philosophy

**Current Organization:** Artifacts are organized in registry files by algorithm family (`randomness.json`, `wavefunctions.json`, `cellular_automata.json`, etc.). This is good for technical understanding but makes it hard to answer questions like:

- "What audio/music artifacts do we have?"
- "Which artifacts are good for beginners?"
- "Show me all QFEP visualization tools"

**Theme Organization:** Adds metadata fields to artifacts that describe their **purpose**, **themes**, and **complexity**. Artifacts can belong to multiple themes (e.g., a Kraftwerk sequencer is both `audio` and `philosophy`).

**Key Principle:** Theme metadata is **purely additive** — it doesn't change lookup_names, file paths, or how artifacts load. It's **backward compatible** with all existing code.

## The 10 Themes

Based on codebase analysis, artifacts are organized into these thematic categories:

### 1. Primitives & Building Blocks
Basic shapes, grab objects, foundational elements for building experiences.

**Examples:** scalable cubes, pattern tiles, color systems, coordinate displays

### 2. Audio & Harmony
Music sequencers, synthesis, spectral analysis, sound generation.

**Examples:** step sequencers, spectral analyzers, synthesizers, melody generators

### 3. Physics & Dynamics
Soft bodies, rigid body simulations, oscillators, physical puzzles.

**Examples:** cloth simulation, trampolines, pendulums, springs, balance challenges

### 4. Procedural Generation
Noise systems, terrain generation, growth algorithms, procedural content.

**Examples:** Perlin noise, terrain generators, random walks, L-systems

### 5. Emergence & Complexity
Cellular automata, self-organization, evolutionary algorithms, edge of chaos.

**Examples:** Conway's Game of Life, reaction-diffusion, swarm behavior, genetic algorithms

### 6. QFEP Visualization & Control
Queer Free Energy Principle interactive tools — lambda, phi, entropy, free energy.

**Examples:** lambda slider, phi slider, entropy meters, bifurcation diagrams, formula displays

### 7. Waves & Oscillation
Sine/cosine visualizations, Fourier transforms, standing waves, harmonic motion.

**Examples:** waveform displays, Fourier series, interference patterns, Lissajous curves

### 8. Narrative & Philosophy
Foundations crisis artifacts, art-mathematics connections, conceptual pieces.

**Examples:** Gödel incompleteness, Russell's paradox, Escher loops, Magritte's pipe

### 9. Interactive Puzzles
Assembly challenges, construction puzzles, relief compositions.

**Examples:** furniture assembly, Mondrian compositions, Albers squares, Judd boxes

### 10. Navigation & Tools
UI elements, navigation aids, system utilities, catalogs.

**Examples:** world map, audio catalog, score displays, teleporters

## Tagging Artifacts

### Metadata Fields

Add these fields to any artifact entry in a registry JSON file:

```json
{
  "lookup_name": "artifact_name",
  "name": "Display Name",
  "scene": "res://path/to/artifact.tscn",

  // NEW THEME METADATA:
  "dev_themes": ["theme1", "theme2"],
  "dev_category": "specific_subcategory",
  "complexity": "beginner|intermediate|advanced|expert",
  "tags": ["tag1", "tag2", "tag3"]
}
```

### Field Descriptions

**`dev_themes`** (Array of strings)
1-3 theme keys that best describe the artifact's purpose. Most artifacts should have 1-2 themes; only use 3 if truly cross-cutting.

**Valid themes:** `primitives`, `audio`, `physics`, `procedural`, `emergence`, `qfep`, `waves`, `philosophy`, `puzzles`, `tools`

**`dev_category`** (String)
More specific subcategory. This is freeform but should follow these patterns:
- `qfep_controller`, `qfep_visualization`
- `procedural_audio`, `procedural_terrain`, `procedural_sculpture`
- `foundations_crisis`, `art_mathematics`
- `random_walk_algorithm`, `procedural_maze`

**`complexity`** (String)
Educational/usage complexity level:
- `beginner` - Simple, single-concept artifacts for introduction
- `intermediate` - Multi-parameter artifacts requiring some understanding
- `advanced` - Complex systems with multiple interacting components
- `expert` - Highly sophisticated artifacts requiring deep theoretical understanding

**`tags`** (Array of strings)
Freeform descriptive tags for search and discovery. Use 3-6 tags that describe:
- What it is (e.g., `sequencer`, `terrain`, `sculpture`)
- How it works (e.g., `random_walk`, `noise`, `self_organizing`)
- Special properties (e.g., `interactive`, `realtime`, `vr`, `3d`)

### Tagging Examples

**QFEP Controller:**
```json
"lambda_slider": {
  "name": "Lambda Slider",
  "lookup_name": "lambda_slider",
  "description": "QFEP λ parameter controller...",
  "scene": "res://commons/interfaces/qfep/lambda_slider.tscn",
  "interaction": "grab_slide",
  "sequence": "qfeplaboratory",
  "artifact_type": "qfep_controller",
  "qfep_term": "λ",
  "capacity": "TUNE entropy drive",

  "dev_themes": ["qfep", "tools"],
  "dev_category": "qfep_controller",
  "complexity": "intermediate",
  "tags": ["interactive", "slider", "parameter_control", "entropy"]
}
```

**Audio Sequencer:**
```json
"step_sequencer_trap": {
  "name": "Trap Sequencer",
  "lookup_name": "step_sequencer_trap",
  "description": "Trap beat sequencer with 16 steps.",
  "scene": "res://commons/audio/sequencer/step_sequencer.tscn",
  "config": {
    "num_tracks": 4,
    "num_steps": 16,
    "bpm": 85,
    "sound_preset": "trap_beats"
  },

  "dev_themes": ["audio"],
  "dev_category": "procedural_audio",
  "complexity": "beginner",
  "tags": ["music", "sequencer", "trap", "beats", "interactive"]
}
```

**Philosophy Artifact:**
```json
"magritte_pipe": {
  "scene": "res://commons/interfaces/foundations/magritte_pipe.tscn",
  "class_name": "MagrittePipe",
  "description": "'Ceci n'est pas une pipe' - The gap between representation and reality",
  "gamwell_reference": "Chapter 9: Magritte's 'The Treachery of Images' (1929)",

  "dev_themes": ["philosophy"],
  "dev_category": "art_mathematics",
  "complexity": "intermediate",
  "tags": ["magritte", "representation", "meta", "art", "interactive"]
}
```

**Procedural Generation:**
```json
"pixel_cloud": {
  "name": "pixel_cloud",
  "lookup_name": "pixel_cloud",
  "description": "Builds an upward-biased self-avoiding random walk...",
  "scene": "res://algorithms/randomness/pixelcloud/pixel_cloud.tscn",

  "dev_themes": ["procedural", "emergence"],
  "dev_category": "procedural_sculpture",
  "complexity": "intermediate",
  "tags": ["random_walk", "self_avoiding", "sculpture", "voxel", "3d"]
}
```

## Using the Query Utility

### Basic Queries

```gdscript
# Find all audio artifacts
var audio_artifacts = ArtifactThemeQuery.get_by_theme("audio")
print("Audio artifacts: ", audio_artifacts)
# Output: ["step_sequencer_trap", "step_sequencer_house", "step_sequencer_kraftwerk", ...]

# Find all QFEP artifacts
var qfep_artifacts = ArtifactThemeQuery.get_by_theme("qfep")

# Find all beginner-friendly artifacts
var beginner_artifacts = ArtifactThemeQuery.get_by_complexity("beginner")

# Find all procedural generation artifacts
var procedural_artifacts = ArtifactThemeQuery.get_by_theme("procedural")
```

### Advanced Queries

```gdscript
# Find beginner-friendly primitives
var tutorial_objects = ArtifactThemeQuery.get_by_themes_and_complexity(
    ["primitives"],
    "beginner"
)

# Find artifacts that are BOTH qfep AND philosophy
var qfep_philosophy = ArtifactThemeQuery.get_by_themes_intersection(
    ["qfep", "philosophy"]
)

# Find artifacts that are qfep OR philosophy (union)
var either_theme = ArtifactThemeQuery.get_by_themes_union(
    ["qfep", "philosophy"]
)

# Find all QFEP visualization tools (specific category)
var qfep_vis = ArtifactThemeQuery.get_by_category("qfep_visualization")
print("QFEP visualizations: ", qfep_vis)
# Output: ["qfep_formula_3d", "bifurcation_walkway", "edge_of_chaos_orb"]

# Get all available themes
var all_themes = ArtifactThemeQuery.get_all_themes()
print("Available themes: ", all_themes)
```

### Utility Methods

```gdscript
# Get system statistics
var stats = ArtifactThemeQuery.get_stats()
print("Total tagged artifacts: %d" % stats["total_tagged_artifacts"])
print("Number of themes: %d" % stats["theme_count"])

# Print full summary to console
ArtifactThemeQuery.print_summary()
# Output:
# === Artifact Theme System Summary ===
# Total tagged artifacts: 20
# Themes (7):
#   - qfep: 9 artifacts
#   - audio: 5 artifacts
#   - philosophy: 6 artifacts
#   ...

# Clear cache (if index file updated at runtime)
ArtifactThemeQuery.clear_cache()
```

## Workflow

### For Developers Adding New Artifacts

1. **Create artifact scene and script** as usual
2. **Add entry to appropriate registry** (e.g., `qfep.json`, `arrays.json`)
3. **Add theme metadata fields:**
   - Choose 1-2 themes from the 10 available
   - Pick a category (or create new one following naming patterns)
   - Assign complexity level
   - Add 3-6 descriptive tags
4. **Update theme index:**
   - Add artifact `lookup_name` to appropriate theme arrays in `artifact_theme_index.json`
   - Add to complexity level array
   - Add to category array
   - Add to registry array
5. **Test:** Use `ArtifactThemeQuery` to verify artifact appears in correct theme

### For Developers Finding Artifacts

**Old way:**
- "I need audio artifacts" → Open `arrays.json`, search manually, maybe check `wavefunctions.json` too, hope you find them all

**New way:**
```gdscript
var audio_artifacts = ArtifactThemeQuery.get_by_theme("audio")
```

## Theme Index Maintenance

The `artifact_theme_index.json` file is currently **manually maintained**. When you tag artifacts:

1. Add metadata fields to artifact entry in registry JSON
2. Add artifact `lookup_name` to theme index arrays

**Future Enhancement:** Auto-generation script that builds `artifact_theme_index.json` by scanning all registry files for theme metadata.

## Current Status

- **Phase:** Proof of Concept
- **Tagged artifacts:** 20 / 318+
- **Registries with tagged artifacts:** 4 (qfep.json, arrays.json, foundations.json, randomness.json)
- **Next:** Complete high-value themes (Audio, QFEP, Primitives) — ~140 artifacts

## Reference Files

- **Theme taxonomy:** `commons/artifacts/artifact_themes.json`
- **Theme index:** `commons/artifacts/artifact_theme_index.json`
- **Query utility:** `commons/artifacts/ArtifactThemeQuery.gd`
- **Artifact registries:** `commons/artifacts/registry/*.json`

## Questions?

For questions about the theme system or help tagging artifacts, see:
- This guide
- `artifact_themes.json` for theme definitions and examples
- Existing tagged artifacts in proof-of-concept registries for patterns
