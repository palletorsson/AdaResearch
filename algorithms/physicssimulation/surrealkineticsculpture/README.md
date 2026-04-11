# Surreal Kinetic Sculpture

A kinetic art installation that combines the dark, biomechanical aesthetics of Yves Tanguy with the vibrant, organic forms of Niki de Saint Phalle. Three black piston-rotor mechanisms drive colorful organic sculptures in continuous motion, inspired by Jacolby Satterwhite's approach to merging references.

## Concept Taught

**Coupled mechanical-organic systems** -- how rigid, deterministic mechanical motion (pistons, rotors) can drive fluid, organic visual responses. The sculpture demonstrates phase-offset oscillation, hierarchical scene composition, and the relationship between a driving mechanism and a driven response.

## How It Works

1. **SurrealKineticSculpture** (`SurrealKineticSculpture.gd`) is the main controller. It builds a dark cylindrical base platform, instantiates three `TanguyPistonRotor` mechanisms in a triangular formation, and attaches a `NikiOrganicForm` to each piston tip.

2. **TanguyPistonRotor** (`TanguyPistonRotor.gd`) creates a piston-rotor mechanism from CSG primitives. A base cylinder with octagonal cross-section supports a rotating disc with three biomechanical arms. A piston rod extends vertically, driven by sinusoidal motion linked to the rotor angle. The piston tip serves as an attachment point for the organic forms.

3. **NikiOrganicForm** (`NikiOrganicForm.gd`) generates colorful organic structures from CSG spheres and cylinders. It creates a central body with randomly positioned protrusions, flowing ribbon-like appendages, and decorative mosaic spots. The form responds to the mechanism's motion data by scaling and rotating subtly.

4. **SurrealMaterialSystem** (`SurrealMaterialSystem.gd`) manages two material families: dark metallic Tanguy materials (black metal, dark iron with clearcoat) and bright Niki color schemes (pink/magenta, blue/cyan, yellow/orange with emission).

5. Dynamic colored accent lights (pink, blue, yellow) are attached to each Niki form, creating moving light pools that shift with the kinetic motion.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `sculpture_scale` | float | 1.0 | Overall scale of the entire sculpture |
| `piston_speed_multiplier` | float | 1.0 | Global speed multiplier for all mechanisms |
| `color_intensity` | float | 1.2 | Brightness of Niki color schemes |
| `mechanical_precision` | float | 0.95 | Precision of mechanical motion |
| `organic_distortion` | float | 0.8 | Amount of organic surface variation |
| `rotation_speeds` | Array[float] | [0.5, 0.7, 0.3] | Per-mechanism rotation speeds |
| `piston_amplitudes` | Array[float] | [2.0, 1.5, 2.5] | Per-mechanism piston travel range |
| `phase_offsets` | Array[float] | [0.0, 120.0, 240.0] | Phase offsets in degrees per mechanism |

## Features

- Three independent piston-rotor mechanisms with configurable phase offsets
- Procedurally generated organic forms with random protrusions and flowing appendages
- Dual material system: dark mechanical metals vs. bright emissive colors
- Dynamic accent lighting that follows organic forms
- Sinusoidal piston extension with subtle rotational wobble
- Decorative mosaic spots on organic surfaces
- Directional shadow-casting key light

## Files

| File | Description |
|------|-------------|
| `SurrealKineticSculpture.gd` | Main controller -- builds base, mechanisms, organic forms, and lighting |
| `TanguyPistonRotor.gd` | Dark biomechanical piston-rotor mechanism with CSG geometry |
| `NikiOrganicForm.gd` | Colorful organic form generator with protrusions and appendages |
| `SurrealMaterialSystem.gd` | Material palette for Tanguy metals and Niki color schemes |
