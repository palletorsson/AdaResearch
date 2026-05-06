# Entropy Jar

A VR-interactive glass jar filled with colored particles -- red in the bottom half, blue in the top. Grab the jar and shake it to mix the particles. Shannon entropy is measured in real time and displayed alongside the jar. The particles never unmix on their own, making the second law of thermodynamics a physical, embodied experience.

## Concept Taught

**Entropy, irreversibility, and the second law of thermodynamics.** This artifact teaches what entropy actually feels like. In the initial state, the jar is ordered: red below, blue above. The entropy is low because the system's configuration is highly structured. Shake the jar, and the particles intermingle. The entropy rises. Keep shaking, and it approaches maximum entropy -- a uniform mixture with no discernible pattern. Now set the jar down. The particles will never spontaneously sort themselves back into red-bottom, blue-top. The second law of thermodynamics says entropy in a closed system tends to increase or stay the same, never decrease. Students feel this irreversibility in their hands: mixing is easy, unmixing is impossible. The QFEP connection is deep -- irreversibility as the arrow of time, the asymmetry between past and future, the physical basis for why some transformations cannot be undone.

## How It Works

1. A pedestal with a flat top surface is built. The jar is an XRTools pickable RigidBody3D with a transparent glass cylinder, opaque bottom, and a lid.
2. Particles are spawned as small RigidBody3D spheres inside the jar: `particle_count` red particles in the bottom half, `particle_count` blue particles in the top half. Each particle has slight color variation for visual richness.
3. When the jar is picked up, shake detection begins. Each physics frame, the acceleration is measured (velocity change over delta time). If acceleration exceeds `shake_threshold` and the cooldown has expired, a shake event fires.
4. Each shake applies small random impulses to all particles, pushing them in random directions. This physical agitation causes mixing.
5. Entropy is measured by dividing the jar into 6 vertical bins and counting how many red and blue particles occupy each bin. Per-bin Shannon entropy is computed: `H = -pa*log2(pa) - pb*log2(pb)`, where `pa` and `pb` are the proportions of each color in that bin. The weighted sum gives the system's total entropy.
6. The entropy display shifts color from cool blue (ordered) to warm red (mixed) based on the current entropy value.
7. The stats label reports shake count, entropy in bits, and qualitative state ("Partially ordered", "Mixing...", "MAXIMUM ENTROPY -- Cannot unmix!").
8. A RESET button returns the jar to the pedestal and re-separates all particles into their original red-bottom, blue-top arrangement.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `jar_radius` | float | 0.08 | Radius of the glass jar |
| `jar_height` | float | 0.20 | Height of the jar |
| `jar_wall_thickness` | float | 0.004 | Glass wall thickness |
| `jar_mass` | float | 0.3 | Mass of the jar body |
| `glass_color` | Color | (0.85, 0.92, 0.95, 0.25) | Transparent glass color |
| `particle_count` | int | 40 | Number of particles per color group |
| `particle_radius` | float | 0.008 | Radius of each particle |
| `color_a` | Color | red (0.9, 0.15, 0.1) | Color of the first particle group |
| `color_b` | Color | blue (0.1, 0.3, 0.9) | Color of the second particle group |
| `particle_mass` | float | 0.005 | Mass of each particle |
| `pedestal_height` | float | 0.9 | Height of the pedestal |
| `pedestal_color` | Color | dark brown | Pedestal color |
| `shake_threshold` | float | 1.5 | Acceleration magnitude to register a shake |

## Features

- XRTools pickable jar with freeze-on-grab, release-to-set-down physics
- 80 physics-simulated particles (40 red, 40 blue) inside the jar
- Per-particle color variation for visual richness and emission glow
- Acceleration-based shake detection with cooldown to prevent over-counting
- Real-time Shannon entropy measurement across 6 vertical bins
- Entropy display color shifts from blue (ordered) to red (mixed)
- Qualitative state messages: ordered, mixing, maximum entropy
- RESET button fully re-separates particles and returns jar to pedestal
- Transparent glass cylinder with double-sided rendering
- Lid, bottom disc, and highlight ring for complete jar appearance
- Pedestal with high-friction top surface to prevent sliding

## Files

| File | Purpose |
|------|---------|
| `entropy_jar.gd` | Complete entropy jar -- jar construction, particle physics, shake detection, Shannon entropy measurement, VR controls |
