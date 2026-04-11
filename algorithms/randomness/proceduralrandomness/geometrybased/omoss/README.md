# Omoss -- Liquid Fabric Composition

A procedural 3D composition inspired by the digital art style of Albert Omoss, blending glossy liquid surfaces with fabric-like textures. This artifact teaches the concept that **randomness combined with material variety produces organic, tactile compositions** -- demonstrating how surface properties (roughness, clearcoat, refraction, normal maps) interact with random geometry to create visual richness.

## How It Works

1. **Environment setup** -- A soft pink background with SSAO (depth), SSR (reflections), and glow. Three lights (key, rim, fill) provide cinematic illumination.

2. **Material creation** -- Eight materials are generated procedurally:
   - **Glossy purple/red** -- Low roughness with clearcoat for a wet, liquid look.
   - **Glossy clear** -- Transparent with refraction for drip elements.
   - **Fabric pink/yellow/purple** -- High roughness with noise-based normal maps to simulate woven texture.
   - **Granular orange** -- Cellular noise normal map for a bumpy, organic surface.
   - **Bubble material** -- Transparent, refractive, low-roughness spheres.

3. **Composition assembly**:
   - A base purple fluid mass is built from a sphere surrounded by randomly placed deformation spheres.
   - Three fabric layers are generated using ImmediateMesh with procedural triangle geometry, noise-displaced vertices, and computed normals.
   - A red glossy blob and a granular orange sphere (with 40 surface bumps) are stacked on top.
   - 15 drip elements (droplets, elongated capsules, flat puddles) are scattered around.
   - 8 bubble extensions -- chains of shrinking spheres radiating outward with noisy direction changes -- extend from the top.

4. The composition rotates slowly each frame.

## Parameters

No exported parameters. Internal constants control composition size and element counts.

## Features

- ImmediateMesh fabric generation with per-vertex noise displacement and computed normals
- Clearcoat materials for wet/liquid appearance
- Cellular noise normal maps for granular surface texture
- Transparent refractive materials for glass and drip effects
- Multi-sphere deformation for organic fluid shapes
- Procedural bubble extensions with direction noise

## Files

| File | Description |
|------|-------------|
| `omoss.gd` | Liquid fabric composition generator |
| `omoss.tscn` | Scene file for the composition |
