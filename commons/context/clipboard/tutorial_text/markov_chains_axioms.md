**Markov Chains**
Probabilistic State Transitions, Memoryless Process

**Markov chain: system transitions between states probabilistically.**

**Key property: Memoryless** - next state depends only on current state, not history.

---

## Definition

**States:** S₁, S₂, S₃, ...
**Transition probabilities:** P(Sⱼ | Sᵢ) - probability of moving from state i to state j

**Example: Weather**
States: {Sunny, Rainy}
Transitions:
- P(Sunny | Sunny) = 0.8
- P(Rainy | Sunny) = 0.2
- P(Sunny | Rainy) = 0.4
- P(Rainy | Rainy) = 0.6

**Code:**

var states = [