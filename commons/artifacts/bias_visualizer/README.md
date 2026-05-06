# Bias Visualizer

Visualizes bias in word embeddings using a 3D word cloud, demonstrating how machine learning models absorb and encode societal stereotypes from their training data. Words are positioned in a simulated embedding space where proximity to gendered anchor words reveals learned associations.

## How It Works

Words like "doctor", "nurse", "engineer", and "secretary" are placed in 3D space according to simulated embedding coordinates. Their proximity to gendered anchors ("man"/"woman") reveals stereotypical associations absorbed from training corpora. Three analogy modes expose different bias patterns: gender-profession bias (who gets associated with which jobs), gender-trait bias (gendered personality attributions), and algorithmic redlining (proxy-based discrimination). Connection lines between word pairs and gender anchors make the bias structure visible. VR push buttons switch between analogy modes.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `display_size` | float | `1.0` |
| `word_scale` | float | `0.05` |
| `male_color` | Color | `Color(0.3, 0.5, 1.0)` |
| `female_color` | Color | `Color(1.0, 0.4, 0.6)` |
| `neutral_color` | Color | `Color(0.5, 0.9, 0.4)` |
| `profession_color` | Color | `Color(1.0, 0.8, 0.2)` |
| `analogy_type` | int | `0` (Gender-Profession) |

## Features

- Three analogy modes: Gender-Profession, Gender-Trait, Algorithmic Redlining
- MultiMesh word cloud with color-coded categories (gender, profession, trait)
- Connection lines showing gender-word associations via ImmediateMesh
- VR push buttons for analogy selection and rotation toggle
- References critical theory scholars (Safiya Noble, Ruha Benjamin)
- Keyboard shortcuts for desktop mode (1-3 for analogies, Space for rotation)
- Gender axis indicators with male/female symbols

## Files

- `bias_visualizer.gd` -- Main script
- `bias_visualizer.tscn` -- Scene file
