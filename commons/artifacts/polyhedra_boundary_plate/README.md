# An opening for the eye

Native reference illustration for Primitives_Polythedra. Reuses the Triangle plate’s casing and typography. The existing default grab_trihedron supplies the four positions and three faces; a coloured fourth face visualizes the boundary supplied by its convex collision hull.

The two studies share a fixed view rotation and uniform model enlargement/reduction. Their depth is compressed equally as a shallow relief so they remain legible from nearby museum angles. This is a schematic projection, not a metric measuring model. Meshes and labels remain native Godot nodes. The default scene hides the floor stand for wall mounting; its casing has collision, the depicted specimens have no interactive physics bodies.

Book and museum use this same scene. Run `python tools/capture_polyhedra_plate.py` to regenerate the clean image, spatial view, source hashes and controlled checks in `doc/book/iterations/2026-09-23-polyhedra-two-boundaries/figures/`. The runner verifies the held artifact’s source and copies the exact rendering dependencies into an isolated project.

Checks compare points/connectivity and probe surface-only versus convex collision with the same ray. They do not test an unconstrained VR hand, learner comprehension or headset legibility. Actual museum photos accompany the dated review.

Museum: source cell (1,5), rotation 90 degrees, scale 0.8, offset (-0.30,0.34,0). Casing centre 1.7 m above floor; about 3.4 m wide. All earlier works and pink corner fills remain.
