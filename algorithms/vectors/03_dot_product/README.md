# Dot Product & Projections

Experiment with the dot product as an angle-sensitive measure by sculpting two vector arrows inside VR. A decomposition overlay shows how vector **a** splits into components parallel and perpendicular to vector **b**, while billboard analytics connect geometry to equations.

## Highlights
- **Interactive Pair** – Both vectors accept grab-and-drag interactions via the shared line primitive.
- **Projection Vector** – Bright green arrow displays `proj_b(a)` and scales with `cos θ`.
- **Rejection Vector** – A magenta arrow anchored at the projection tip illustrates the orthogonal leftover.
- **Angle Indicator** – Floating label tracks the instantaneous angle between the vectors.

## Interaction Cheatsheet
- **Grab Either Vector** – Adjust direction and magnitude to explore positive, zero, and negative dots.
- **Watch the Projection** – When vectors align, the projection matches **a**; when they are orthogonal, it collapses to zero.
- **Monitor Analytics** – Dot product, `|a||b|cosθ`, and decomposition values refresh continuously.

## Learning Goals
1. Connect the numeric dot product to geometric projection length.
2. Visualise orthogonal decomposition using rejection vectors.
3. Interpret the sign of the dot product through angle intuition.

## Scene Path
```
res://algorithms/vectors/03_dot_product/VectorDotProduct.tscn
```
