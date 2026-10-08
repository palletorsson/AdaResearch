# Queer Morphological Systems — Technical

The map is a 10×10 room with one primary `morphogenesis_bench`. Keep the seed, neighbourhood, update rule, and generation count visible beside the form. Store each generation so the learner can scrub history instead of comparing memory to a screenshot.

The first implementation can use a grid of scalar activations and a marching-cubes or instanced-cell view. A later pass may add continuous fields, but the causal chain should remain inspectable: parameter → local update → generation → morphology.
