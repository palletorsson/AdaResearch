# Primitive Ontology

> Every primitive is a lens on the world. Not "how does it work" but
> "what does it reveal about the nature of things?"

This directory contains individual ontology files for each primitive in Ada Research.
Each file has YAML frontmatter for machine consumption and a full ontological discussion.

The master source is `doc/PRIMITIVE_ONTOLOGY.md`. These individual files add structured
metadata and enable per-primitive API access via the encyclopedia.

## Directory Structure

Files are organized by curriculum sequence:

```
doc/ontology/
  primitives/          — sequence: primitives (F_order phase)
    point.md
    line.md
    triangle.md
    grid.md
    coordinate-system.md
  transformation/      — sequence: transformation (F_order phase)
    vectors.md
  forces/              — sequence: forces (oscillation phase)
    forces.md
  arrays/              — sequence: array_tutorial (F_order phase)
    arrays.md
  wavefunctions/       — sequence: wavefunctions (oscillation phase)
    wave.md
  randomness/          — sequence: randomness (E_entropy phase)
    random-walk.md
    randomness.md
  procedural/          — sequence: proceduralgeneration (lambda_edge phase)
    procedural-generation.md
  screens/             — meta artifacts
    filter-screen.md
    science-screen.md
  index.json           — machine-readable index of all entries
  README.md            — this file
```

## Frontmatter Schema

Each `.md` file contains YAML frontmatter with:

| Field | Type | Description |
|-------|------|-------------|
| `title` | string | Display title with subtitle |
| `primitive` | string | Kebab-case identifier |
| `sequence` | string | Curriculum sequence name |
| `phase` | string | QFEP phase (F_order, oscillation, E_entropy, lambda_edge, meta) |
| `qfep_role` | string | Role within QFEP framework |
| `lens` | string | The ontological lens this primitive provides |
| `question` | string | The core question this primitive asks |
| `status` | string | Optional. `draft` if ontology is pending |
| `web_editor` | string | Path to the 2D web editor (or null) |
| `godot_infoboard` | string | Path to VR infoboard (or null) |
| `tags` | array | Searchable topic tags |

## Status

Entries marked `status: draft` have minimal ontological content and need discussion.
Currently draft: coordinate-system, randomness, procedural-generation, filter-screen, science-screen.

## API Access

The encyclopedia can serve these via `GET /api/ontology` using the `index.json` file
as a lookup table. Each entry's full markdown content is in the corresponding `.md` file.
