# Queer Collection 2 -- Expressive Material Shaders

A set of five GPU shaders that explore **material as expression** -- each shader encodes a poetic concept into fragment-level mathematics. The collection teaches advanced shader techniques (thin-film interference, subsurface scattering, diffraction gratings, anisotropic roughness, vertex displacement) while framing them through queer aesthetics.

## How It Works

Each shader is a standalone `.gdshader` file with a `.tres` material resource for direct use on any mesh. No GDScript controller is needed -- the shaders animate via `TIME` and view-angle uniforms.

### Oil Slick Latex
Deep black base with rainbow iridescence at glancing angles. Uses a spectral approximation function `spectrum(t)` to generate rainbow colors from the viewing angle. Noise-perturbed Fresnel rim drives thin-film interference, producing the oil-on-water rainbow sheen characteristic of latex surfaces.

### Memory Skin
Pale silicone base with time-varying "bruise" patterns. Two noise textures scroll at different speeds and are intersected (`n1 * n2`) to produce irregular organic shapes. Smoothstep thresholds create distinct bruise cores (purple) and edge halos (blue). Subsurface scattering via `SSS_STRENGTH` and reddish transmittance simulates light penetrating flesh.

### Crushed Pearl
White-pearl base with holographic sparkle. A diffraction grating effect combines viewing angle with high-frequency UV sine/cosine patterns ("dust particles") to shift the hue. A `glint` mask isolates sparkle points using a smoothstep threshold on the combined angle-dust signal, creating localized rainbow flashes.

### Sad Metal
Blue-chrome base with vertical "tear" streaks. Noise scrolls downward on vertically-stretched UVs to simulate flowing tears. Roughness is modulated by the tear mask -- wet tear regions are smooth (low roughness) while dry regions are blurry (high roughness). Anisotropic flow is set to vertical, creating directional reflections.

### Melted Candy
Hot pink glassy base with vertex displacement that simulates melting. A sine wave in the vertex shader pushes vertices downward and outward. The fragment shader adds backlight transmission, fake chromatic aberration via view-angle-dependent red/blue tinting, and high specular for a sticky-candy finish.

## Features

- Five expressive material shaders with distinct visual and conceptual identities
- Thin-film interference / iridescence (Oil Slick)
- Subsurface scattering simulation (Memory Skin)
- Diffraction grating hologram effect (Crushed Pearl)
- Anisotropic roughness with directional flow (Sad Metal)
- Vertex displacement melting animation (Melted Candy)
- All shaders self-animate via TIME -- no external controller required
- Pre-built `.tres` material resources for each shader

## Files

- `oil_slick_latex.gdshader` -- Thin-film interference on deep black
- `memory_skin.gdshader` -- Subsurface scattering with bruise patterns
- `crushed_pearl.gdshader` -- Holographic diffraction sparkle
- `sad_metal.gdshader` -- Anisotropic tear-streak chrome
- `melted_candy.gdshader` -- Vertex-displaced melting candy glass
- `mat_oil_slick.tres` -- Material resource for Oil Slick Latex
- `mat_memory_skin.tres` -- Material resource for Memory Skin
- `mat_crushed_pearl.tres` -- Material resource for Crushed Pearl
- `mat_sad_metal.tres` -- Material resource for Sad Metal
- `mat_melted_candy.tres` -- Material resource for Melted Candy
- `Collection_Gallery_A.tscn` -- Gallery scene displaying all five materials
