# ML Gradient Landscape — Artifacts
*Machine Learning: Algorithms That Learn · integration · 3 artifacts*

> Every neural network learns by falling. Gradient descent drops a point onto a surface and lets gravity do the math — follow the steepest slope, step by step, toward the lowest valley. The learning rate decides how bold each step is. Too large, you overshoot. Too small, you never arrive. Momentum keeps you rolling through flat spots where the gradient whispers.

The map, read through what it holds — its artifacts in the order you meet them:

## Gradient Descent
![Gradient Descent](/scene-catalog/gradient_descent_visualization.png)

Gradient descent optimization on a loss landscape — watch the optimizer slide downhill following the steepest direction. The engine behind all neural network training, with learning rate and momentum visible.

`gradient_descent_visualization`

## PCA Visualization
![PCA Visualization](/scene-catalog/pca_visualization.png)

Principal Component Analysis — high-dimensional data projected onto principal axes. Shows variance capture and dimensionality reduction in 3D.

`pca_visualization`

## Loss Function Comparator
![Loss Function Comparator](/scene-catalog/loss_function_comparator.png)

Same dataset, three different loss functions applied simultaneously. MSE (smooth bowl), Huber (outlier-robust), and adversarial (deceptive valleys). Gradient descent balls roll on each surface, arriving at different answers. The landscape is not given — it is authored.

`loss_function_comparator`
