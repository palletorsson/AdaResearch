# Random Space — Artifacts
*Randomness: Freedom from Pattern · E_entropy · 5 artifacts*

> The sequence finale — randomness fills space itself. Gaussian distributions, fluttering butterflies, Pollock paintings converge in a contained arena. All the threads of the sequence woven into a final meditation on chaos.

The map, read through what it holds — its artifacts in the order you meet them:

## Noise Mixer
![Noise Mixer](/scene-catalog/noise_mixer.png)

Fractal Brownian Motion noise mixer — layers multiple sin-based noise octaves with controllable lacunarity and persistence. 128x128 floor texture with earth-tone color ramp. VR sliders adjust octaves (1–8), lacunarity (1.5–3.0), and persistence (0.3–0.7) to explore how complexity emerges from layered simple functions.

`noise_mixer`

## Worley Noise
![Worley Noise](/scene-catalog/worley_noise.png)

Voronoi/cellular noise texture on a floor quad. Scatters random seed points and computes F2-F1 (second-nearest minus nearest distance) for the classic cell boundary look. Complement to Perlin/Simplex noise.

`worley_noise`

## random_space
![random_space](/scene-catalog/random_space.png)

A crystal that contains mathematical chaos algorithms

`random_space`

## Dark Sphere
![Dark Sphere](/scene-catalog/dark_sphere.png)

USE a neutral sphere as a reference for scale, silhouette, and atmospheric change.

`dark_sphere`

## Shannon Entropy Meter
![Shannon Entropy Meter](/scene-catalog/shannon_entropy_meter.png)

Wall-mounted Shannon entropy gauge — generates a random sequence, computes symbol frequencies, and displays H = -Σ p(x) log₂ p(x). Bar gauge fills from 0 to max entropy (~3.32 bits for 10 symbols). Frequency histogram shows symbol distribution.

`shannon_entropy_meter`
