# ML Gradient Landscape — Summary

ML_Gradient_Landscape is the second map in the Machine Learning sequence. It replaces evolution's blind search with calculus. The central feature is a terrain — a surface whose height at each point is the loss of some hypothetical model at those parameter values — and the learner drops a marker onto it and lets gravity do the maths.

The terrain has hills and valleys. A global minimum sits at the lowest point; several local minima sit at higher basins. A marker at the surface computes the local slope at each step and moves in the opposite direction by an amount set by the learning-rate slider. The trajectory is drawn live, so each step is visible as a small descent.

Three controls change the experiment. The learning rate decides how bold each step is: too small, and the marker creeps; too large, and it overshoots the valley and oscillates. A momentum slider lets earlier steps influence later ones, which can escape shallow local minima. A reset button drops the marker at a new random starting point, so the same landscape can be explored from multiple initial conditions.

Within the sequence, Gradient_Landscape is where optimisation becomes cheap and directed. The landscape metaphor persists through every later map. ML_Classification will next use these mechanics on a concrete task.
