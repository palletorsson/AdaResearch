# Turing Pattern Reaction-Diffusion

## Overview
This implementation demonstrates Alan Turing's reaction-diffusion model for pattern formation, which explains how complex patterns emerge in nature through the interaction of two chemical substances with different diffusion rates. This algorithm produces patterns similar to those found in animal coats, seashells, and bacterial colonies.

## Algorithm Description
The Turing reaction-diffusion system simulates two chemicals (typically called activator and inhibitor) that react with each other and diffuse through space at different rates. The activator promotes its own production and that of the inhibitor, while the inhibitor suppresses the activator. This creates a feedback loop that generates stable spatial patterns.

### Mathematical Foundation
The system is governed by partial differential equations:
- ∂u/∂t = D_u∇²u + f(u,v) 
- ∂v/∂t = D_v∇²v + g(u,v)

Where u and v are concentrations, D_u and D_v are diffusion coefficients, and f,g are reaction functions.

### Key Parameters
- **Diffusion Rates**: Different rates for activator (D_a=1.0) and inhibitor (D_b=0.5)
- **Feed Rate**: Rate at which activator is supplied (f=0.055)
- **Kill Rate**: Rate at which inhibitor is removed (k=0.062)
- **Reaction Rate**: Speed of chemical reactions (1.0)

## Pattern Types
The algorithm can generate various patterns including:
- Coral patterns (f=0.055, k=0.062)
- Mitosis patterns (f=0.0367, k=0.0649)
- Maze-like structures
- Spotted patterns
- Striped patterns

## Files Structure
- `turing_pattern.gd`: Main algorithm implementation with UI controls
- `turing_pattern.tscn`: 2D visualization scene
- `turing_pattern_reaction_diffusion.tscn`: Basic scene
- `2d_in_3d_turing_pattern_reaction_diffusion.tscn`: 3D visualization

## Applications
- Biological pattern formation modeling
- Texture generation for computer graphics
- Understanding morphogenesis in development
- Art and procedural content generation
- Study of self-organization in nature

## Usage
Run the scene to see real-time pattern formation. Adjust parameters using the UI sliders to explore different pattern types and observe how small parameter changes can dramatically alter the resulting patterns.