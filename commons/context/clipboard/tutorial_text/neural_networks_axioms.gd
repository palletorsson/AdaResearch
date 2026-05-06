extends Node

var text = '''[center][font_size=28][b]Neural Networks[/b][/font_size][/center]
[center][i]Weighted Connections, Backpropagation, Learning[/i][/center]

**Neural networks learn through adjusting connection weights.**

**Structure:** Layers of neurons connected by weighted edges.

[hr]

[b]Architecture[/b]

**Input layer** → **Hidden layers** → **Output layer**

Each neuron: **activation = σ(Σ(wᵢxᵢ) + b)**

Where:
- **w** = weights
- **x** = inputs
- **b** = bias
- **σ** = activation function (sigmoid, ReLU, tanh)

[color=yellow][b]Code:[/b][/color]
[code]
class Neuron:
    var weights: Array[float]
    var bias: float

    func activate(inputs: Array[float]) -> float:
        var sum = bias
        for i in range(inputs.size()):
            sum += weights[i] * inputs[i]

        return sigmoid(sum)

    func sigmoid(x: float) -> float:
        return 1.0 / (1.0 + exp(-x))
[/code]

**Training:** Adjust weights via **backpropagation** (gradient descent on error).

[hr]

[b]Applications[/b]

- **Image recognition** (CNNs)
- **Natural language** (transformers, LLMs)
- **Game AI** (reinforcement learning)
- **Prediction** (time series, classification)

[hr]

[b]Queer Neural Nets[/b]

**Neural networks learn categories** - classify inputs into discrete outputs.

**Training reinforces existing categories** (labeled training data).

**This is normative learning:**
- **Categories pre-defined** (male/female labels in data)
- **Outliers penalized** (high error → adjust toward norm)
- **Optimization toward existing patterns** (reproduce training distribution)

**Queer resistance:**
- **Unlabeled learning** (unsupervised, discover own categories)
- **Embrace outliers** (high error = interesting deviation)
- **Adversarial examples** (inputs that break categories)

**Neural nets reproduce the biases in their training data.** Queer data is often missing.

[hr]

[color=cyan][b]Summary:[/b][/color]
Neural networks: layers of weighted connections, activation functions, backpropagation learning. Queer critique: learns pre-defined categories, penalizes outliers, reproduces training biases. Missing queer data, normative optimization. Resistance: unsupervised learning, adversarial examples, questioning categories.

'''
