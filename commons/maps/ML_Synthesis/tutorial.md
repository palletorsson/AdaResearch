# ML Synthesis

Reinforcement learning, generation, classification. Three islands.

Build a Q-table.

```gdscript
class_name QLearner

var q_table: Dictionary = {}  # state -> array of Q values per action

func get_q(state, action: int) -> float:
    return q_table.get(state, Array([0, 0, 0, 0]))[action]

func set_q(state, action: int, value: float) -> void:
    if not state in q_table:
        q_table[state] = [0.0, 0.0, 0.0, 0.0]
    q_table[state][action] = value
```

One row per state, one column per action. Values track expected future reward.

Epsilon-greedy action selection.

```gdscript
@export var epsilon: float = 0.1

func choose_action(state) -> int:
    if randf() < epsilon:
        return randi() % 4
    var q_values: Array = q_table.get(state, [0, 0, 0, 0])
    var best: int = 0
    for i in range(1, 4):
        if q_values[i] > q_values[best]:
            best = i
    return best
```

With probability epsilon explore; otherwise exploit the best known action.

Q-learning update.

```gdscript
@export var alpha: float = 0.1  # learning rate
@export var gamma: float = 0.99  # discount factor

func update(state, action: int, reward: float, next_state) -> void:
    var max_next_q: float = -INF
    for a in 4:
        max_next_q = max(max_next_q, get_q(next_state, a))
    var old_q: float = get_q(state, action)
    var new_q: float = old_q + alpha * (reward + gamma * max_next_q - old_q)
    set_q(state, action, new_q)
```

Temporal-difference update. Blends current reward with discounted future expectations.

Run an episode.

```gdscript
func run_episode(env) -> float:
    var state = env.reset()
    var total_reward: float = 0.0
    while not env.is_done():
        var action := choose_action(state)
        var result: Dictionary = env.step(action)
        update(state, action, result.reward, result.next_state)
        state = result.next_state
        total_reward += result.reward
    return total_reward
```

One episode from start to terminal state. The total reward measures how well the policy performed.

Policy gradient (REINFORCE).

```gdscript
func reinforce_update(trajectory: Array, learning_rate: float = 0.01) -> void:
    var returns: Array = compute_returns(trajectory, gamma)
    for i in trajectory.size():
        var state = trajectory[i].state
        var action: int = trajectory[i].action
        var G: float = returns[i]
        var grad: Array = policy_gradient(state, action)
        update_policy(grad, learning_rate * G)
```

Gradient ascent on expected return. Unlike Q-learning, learns a stochastic policy directly.

Sample from a trained language model.

```gdscript
func sample_from_lm(prompt: String, max_tokens: int, temperature: float = 0.7) -> String:
    var output: String = prompt
    for _i in max_tokens:
        var logits: Array = lm_forward(tokenize(output))
        var scaled: Array = []
        for l in logits: scaled.append(l / temperature)
        var probs: Array = softmax(scaled)
        var token_idx: int = sample_categorical(probs)
        output += detokenize([token_idx])
    return output
```

Autoregressive generation. Temperature controls randomness; higher is more diverse.

Retrain a classifier on new data.

```gdscript
func online_retrain(classifier, new_examples: Array) -> void:
    for _epoch in 5:
        for example in new_examples:
            classifier.backward(example.features, example.label)
```

Fine-tune on incoming data. Useful for classifiers that must adapt to distribution shift.

You can now build a Q-learner with epsilon-greedy and temporal-difference updates, run policy gradient, sample from a language model with temperature, and retrain a classifier online. Chamber_ML closes with an adversarial optimiser.
