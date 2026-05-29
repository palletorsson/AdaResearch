Concept: The partial derivative — extending slope from a curve to a surface. A 2D function z = f(x,y) has a rate of change in x and a separate rate in y; together they describe the tilt of the ground at any point.
Sequence role: Third map of Change, foundation cluster. The hinge between the single-variable derivative (maps 1-2) and the vector field (maps 6-7). Introduces the idea that slope on a surface requires a direction, which becomes the gradient and then the flow field.
Technical angle: Evaluating ∂f/∂x and ∂f/∂y by sampling the surface in each axis, rendering them as two slope arrows at the queried point, and stepping the query point across the terrain. The gradient (∂f/∂x, ∂f/∂y) is the vector these two arrows compose.
Critical angle: Change acquires dimension. On a curve, "which way" was never a question — there was only along it. On a surface, change is no longer a number but a direction-and-magnitude. This is the first encounter with a function of space rather than time, the move the sequence completes in Flow_Field.
Key artifacts: partial_derivative_terrain renders the surface and its directional slope arrows; science_screen mirrors the two partial values in 2D.

Gap: partial_derivative_terrain is a scaffolded name — the surface-with-slope-arrows scene is not yet built. Size budget is moderate, larger than the compact intro maps.
