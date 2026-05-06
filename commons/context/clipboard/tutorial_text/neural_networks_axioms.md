**Neural Networks**
Weighted Connections, Backpropagation, Learning

**Neural networks learn through adjusting connection weights.**

**Structure:** Layers of neurons connected by weighted edges.

---

## Architecture

**Input layer** → **Hidden layers** → **Output layer**

Each neuron: **activation = σ(Σ(wᵢxᵢ) + b)**

Where:
- **w** = weights
- **x** = inputs
- **b** = bias
- **σ** = activation function (sigmoid, ReLU, tanh)

**Code:**

```
class Neuron:
    var weights: Array
    var bias: float

    func activate(inputs: Array) -> float:
        var sum = bias
        for i in range(inputs.size()):
            sum += weights * inputs

        return sigmoid(sum)

    func sigmoid(x: float) -> float:
        return 1.0 / (1.0 + exp(-x))
```

**Training:** Adjust weights via **backpropagation** (gradient descent on error).

---

## Applications

- **Image recognition** (CNNs)
- **Natural language** (transformers, LLMs)
- **Game AI** (reinforcement learning)
- **Prediction** (time series, classification)

---

## Queer Neural Nets

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

---

**Summary:**
Neural networks: layers of weighted connections, activation functions, backpropagation learning. Queer critique: learns pre-defined categories, penalizes outliers, reproduces training biases. Missing queer data, normative optimization. Resistance: unsupervised learning, adversarial examples, questioning categories.