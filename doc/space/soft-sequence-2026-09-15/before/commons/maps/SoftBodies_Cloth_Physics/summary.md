# Cloth Physics — Summary

The fifth Soft Bodies map narrows focus to cloth — a two-dimensional spring-mass surface in three-dimensional space. A 16x16 grid of 256 mass points connected by three spring types (structural, shear, bend) hangs in a tall vertical chamber, where gravity's pull over long distances amplifies the visible differences between spring configurations.

Structural springs connect horizontal and vertical neighbors, resisting stretching. Shear springs connect diagonals, preventing angular collapse. Bend springs skip one vertex, resisting sharp folding. The ratio between these stiffnesses determines material character: silk (20:5:1 structural-to-shear-to-bend) folds deeply and conforms tightly; canvas (200:80:40) drapes in broad curves; rubber sheet (500:300:200) barely deflects. Same points, same masses — the topology of relations defines the material.

Pinning freezes selected vertices in world space, creating the tension differential that makes draping possible. Two corner pins produce a hanging U-shape. One full edge produces a curtain. No pins and the cloth falls as a unit. Verlet integration carries forward from the jelly cube, with global damping (0.999 velocity multiplier) providing air resistance. Constraint satisfaction requires six to eight iterations for 700+ springs — more than the cube's four — to prevent visible stretching at attachment points.

Wind applies per-vertex force varying with time and position, creating traveling ripple waves. Collision against obstacles uses per-vertex position correction with friction via old_position manipulation. Self-collision — O(n^2) pairwise distance checks — prevents the cloth from passing through itself during folding, giving the surface virtual thickness.

The existing critical analysis tests Barad's agential realism (springs as inherently relational — force undefined for a single point), Butler's performativity (Verlet stores history in position-difference), and the CFL condition as constitutive finitude (violate it and the simulation explodes). Through Ahmed, the pin configuration is an imposed orientation — the cloth did not choose where to attach. Through Merleau-Ponty, the cloth is flesh that perceives through its whole surface simultaneously, each point knowing its neighbors and no point deciding the shape alone.

**Artifacts:** softstopscene (cloth draping and collision), cloth_straps (fabric strips), flagdancer (wind-driven cloth).
**Sequence position:** 5 of 9 in Soft Bodies (integration phase). Follows SoftBodies_Obsticals_Part2, leads to SoftBodies_Playground_of_Joy.
