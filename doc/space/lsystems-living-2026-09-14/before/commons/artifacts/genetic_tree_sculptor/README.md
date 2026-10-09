# Genetic Tree Sculptor

Interactive DNA-to-tree workbench where eight sliders control genetic parameters that shape a procedurally generated tree, teaching how encoded genetic information maps to phenotypic expression through a morphology system.

## How It Works

The artifact creates a CritterDNA object with tree-kingdom genes and maps eight slider values to genetic parameters: branching depth, fork count, branch angle, taper ratio, leaf density, gravitational tropism, axial twist, and phyllotactic arrangement. When any slider changes, a debounced rebuild regenerates the tree via the TreeMorphology system. A Randomize button generates a fresh random DNA, and a Plant button stores the designed DNA globally so that the branching catalyst artifact can read and instantiate copies elsewhere in the world.

## Features

- Eight VR sliders controlling tree genetics in real time
- Debounced tree regeneration (0.3s cooldown) to prevent rebuilding during scrubbing
- Randomize button for instant new tree DNA
- Plant/Export button stores DNA globally for cross-artifact use
- Pedestal with live 3D tree preview
- Grid config integration via DNA seed

## Files

- `genetic_tree_sculptor.gd` -- Main script
- `genetic_tree_sculptor.tscn` -- Scene file
