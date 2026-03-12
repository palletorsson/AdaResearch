# Progression Driver

An interactive VR control panel for advancing, resetting, and managing progression across the game's EcosystemManager, HazardManager, and CatalystCapabilityManager. Used as a debug and testing tool during development.

## How It Works

The panel reads sequence and hazard data from the `soft_stages.json` file at startup, building a sorted list of all sequences and collecting unique hazard types. A VR slider selects a target sequence, and push buttons trigger `force_advance_to` or `reset_progression` calls on each of the three progression managers. A grid of befriend buttons lets testers instantly befriend individual hazard types. A status label at the bottom reports the result of each action.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `panel_width` | float | `0.9` |
| `panel_height` | float | `0.65` |

## Features

- Slider-based sequence selection ordered by curriculum stage
- Advance, Reset, and Unlock All buttons acting on all three progression managers
- Dynamic befriend button grid generated from hazard types in `soft_stages.json`
- Status label providing feedback on the last action taken
- Grid system integration via `apply_grid_config` for start sequence and auto-advance
- Proper signal cleanup on exit

## Files

- `progression_driver.gd` -- Main script
- `progression_driver.tscn` -- Scene file
