# ada — Fractal Project Navigator

A CLI tool for navigating the AdaResearch project structure.

## Philosophy

The project is fractal — self-similar at every level. This tool lets you zoom in/out and cross-cut.

```
project
  └── phase (F_order, oscillation, E_entropy, λ_edge, integration, synthesis)
       └── sequence (primitives, wavefunctions, randomness...)
            └── map (points, lines, harmonics...)
                 └── artifact / doc / interactable
```

## Usage

```bash
# Navigate
ada overview                  # project stats
ada spine                     # curriculum spine with branches
ada phase integration         # sequences in this QFEP phase
ada seq wavefunctions         # maps, docs, branches for sequence
ada map harmonics             # map details

# Search
ada find "lambda"             # fuzzy search everything
ada refs dark_sphere          # what maps use this artifact?
ada docs randomness           # all docs for sequence

# Launch
ada play randomness           # launch game → first map of sequence
ada play Random_Walk          # launch game → specific map
ada play wavefunctions -e     # open in Godot editor instead

# Maintenance
ada reindex                   # rebuild the index
```

## Output

- Human-readable by default (colors, tree structure)
- `--json` flag for machine-readable output (on some commands)

## Index

The tool builds/caches an index at `.ada_index.json` in the project root.

Index sources:
- `commons/maps/curriculum_spine.json` — QFEP spine + phases
- `commons/maps/sequences/*.json` — sequence definitions
- `commons/maps/map_progression.json` — additional sequences
- `commons/maps/*/map_data.json` — map metadata + artifacts
- `commons/artifacts/**/*.json` — artifact registry
- `commons/maps/*/*.md` — map documentation (blurb, summary, technical, critical)
- `doc/*.md` — project documentation

## Installation

```bash
# Just run directly
python tools/ada/ada.py overview

# Or add to PATH / create alias
alias ada="python /path/to/AdaResearch/tools/ada/ada.py"
```

## Environment Variables

- `GODOT_PATH` — Path to Godot executable (for `ada play`)

If not set, looks for Godot on Desktop (Windows).

## How `ada play` Works

1. Writes a launch intent to Godot's user data folder
2. Launches Godot with the project
3. MapProgressionManager reads the intent on startup
4. Game navigates to the requested map/sequence
5. Intent file is deleted (30-second timeout as safety)
