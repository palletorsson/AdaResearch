# Markov Blanket Visualization

## Overview
This implementation visualizes the concept of Markov blankets from the Free Energy Principle, a fundamental theory in neuroscience and cognitive science. The simulation demonstrates how biological systems maintain their organization through the exchange of information across boundaries.

## Algorithm Description
A Markov blanket is a statistical boundary that separates a system's internal states from external states. In this visualization, it represents the membrane of a cell or organism that regulates information flow between inner and outer environments.

### Key Concepts
- **Inner States**: The organism's internal environment
- **Outer States**: The external environment
- **Markov Blanket**: The boundary (membrane) that mediates exchange
- **Information Hotspots**: Areas of high information exchange
- **Entropy**: Measure of uncertainty/disorder in each region

### Simulation Components
1. **3D Sphere Membrane**: Represents the Markov blanket boundary
2. **Inner/Outer Regions**: Different environments with varying entropy
3. **Information Hotspots**: Dynamic points showing active information exchange
4. **Pulsing Dynamics**: Rhythmic changes representing system dynamics
5. **Noise-Based Deformation**: Organic movement using Perlin noise

## Algorithm Flow
1. **Initialize**: Create 3D sphere with inner/outer regions
2. **Generate Hotspots**: Create information exchange points
3. **Update Entropy**: Modify inner/outer entropy based on exchanges
4. **Animate Membrane**: Deform boundary using noise functions
5. **Visualize Information**: Show hotspots with lifetime dynamics

## Files Structure
- `puls_markov.gd`: Main simulation with 3D visualization and physics
- `puls_markov.tscn`: Scene setup with camera and environment

## Parameters
- **Sphere Properties**: Base radius (1.0), resolution (32)
- **Information**: Max hotspots (8), lifetime (5.0 seconds)
- **Noise**: Scale (0.3), frequency (0.05)
- **Animation**: Pulse speed (1.0), max amplitude (0.3)

## Theoretical Foundation
Based on:
- **Free Energy Principle**: Karl Friston's theory of biological self-organization
- **Markov Blankets**: Statistical boundaries in probabilistic systems
- **Information Theory**: Entropy and information exchange
- **Predictive Processing**: How organisms minimize surprise

## Applications
- Computational neuroscience modeling
- Understanding cellular organization
- Cognitive science research
- Artificial life simulations
- Philosophy of mind studies

## Visual Features
- Real-time 3D membrane visualization
- Color-coded entropy regions
- Dynamic information hotspot animation
- Organic pulsing and deformation
- Interactive camera controls

## Usage
Run the simulation to observe how information flows across biological boundaries. Watch the dynamic interplay between inner and outer entropy, and how information hotspots emerge and fade over time.