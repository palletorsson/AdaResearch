# Perceptron Playground

An interactive single-neuron classifier where users adjust weights (w1, w2) and bias via VR sliders to find a linear decision boundary that separates two classes of data points. Teaches the foundational concept of neural networks: how a perceptron computes y = step(w1*x1 + w2*x2 + bias) to classify inputs.

## How It Works

A scatter plot of 60 random 2D data points is generated with a ground-truth separation along x + y = 0.1 (with noise). The perceptron classifies each point by computing the weighted sum w1*x + w2*y + bias and applying a step function: positive activations are class 1, negative are class 0. The decision boundary -- the line where w1*x + w2*y + bias = 0 -- is drawn on the plot and updates in real-time as sliders change. A neuron diagram shows the network structure with color-coded weight lines (blue for positive, red for negative), and an accuracy counter tracks how many points are correctly classified.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `w1_slider_path` | NodePath | "ControlPanel/W1Slider" |
| `w2_slider_path` | NodePath | "ControlPanel/W2Slider" |
| `bias_slider_path` | NodePath | "ControlPanel/BiasSlider" |
| `plot_size` | float | 0.5 |
| `plot_resolution` | int | 128 |
| `num_points` | int | 60 |

## Features

- Interactive weight and bias adjustment via VR sliders (w1, w2: -3 to 3; bias: -2 to 2)
- Real-time decision boundary line drawn on the scatter plot
- Soft shading near the boundary for visual gradient
- Misclassified points highlighted with white corner markers
- Neuron diagram with color-coded weight lines and output arrow
- Live accuracy counter showing correct classifications
- Formula label updating with current weight values

## Files

- `perceptron_playground.gd` — Main script
- `perceptron_playground.tscn` — Scene file
