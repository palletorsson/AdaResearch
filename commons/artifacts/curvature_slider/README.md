# Curvature Slider

An interactive slider that controls a curvature parameter ranging from negative (hyperbolic) through zero (flat/Euclidean) to positive (elliptic), teaching the concept of Gaussian curvature and how it classifies geometric surfaces.

## How It Works

The slider maps a normalized 0-1 range to a curvature value K between -1 and +1. As the user moves the slider, the label dynamically updates to show the numeric curvature value and its geometric classification: hyperbolic (K < 0), flat/Euclidean (K = 0), or elliptic (K > 0). The artifact emits a `curvature_changed` signal so other artifacts can react to the curvature value in real time.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `curvature` | float | `0.0` |

## Features

- VR-compatible horizontal slider mapped from -1 to +1
- Live label showing curvature value and geometry type classification
- Emits `curvature_changed` signal for inter-artifact communication
- Grid system integration via `apply_grid_config()`

## Files

- `curvature_slider.gd` — Main script
- `curvature_slider.tscn` — Scene file
