# NonEuclidean Spaces — Artifacts
*Foundations Crisis: The Limits of Formalization · synthesis · 5 artifacts*

> Euclid's fifth postulate held for two millennia. Then Bolyai, Lobachevsky, and Riemann asked: what if parallel lines don't behave? Two answers emerged — one where parallels diverge without limit, one where they always meet.

The map, read through what it holds — its artifacts in the order you meet them:

## Hyperbolic Surface
![Hyperbolic Surface](/scene-catalog/hyperbolic_surface.png)

Saddle-shaped surface demonstrating negative Gaussian curvature (K < 0) — where parallel lines diverge and triangle angles sum to less than 180 degrees.

`hyperbolic_surface`

## Elliptic Surface
![Elliptic Surface](/scene-catalog/elliptic_surface.png)

Dome/sphere-like surface demonstrating positive Gaussian curvature (K > 0) — where parallel lines converge and triangle angles sum to more than 180 degrees.

`elliptic_surface`

## Curvature Slider
![Curvature Slider](/scene-catalog/curvature_slider.png)

VR slider controlling Gaussian curvature from negative (hyperbolic) through zero (flat/Euclidean) to positive (elliptic). Emits curvature_changed signal for linked surfaces.

`curvature_slider`

## Poincare Disk
![Poincare Disk](/scene-catalog/poincare_disk.png)

Poincaré disk model of hyperbolic geometry - where parallel lines diverge and triangles have angle sum < 180°

`poincare_disk`

## Riemann Sphere
![Riemann Sphere](/scene-catalog/riemann_sphere.png)

The Riemann sphere — compactified complex plane with stereographic projection lines, north pole at infinity, equator, and projection plane visible.

`riemann_sphere`
