# ML Synthesis — Technical

The map stages three islands, each running a different ML paradigm: reinforcement learning on the first, a small generative language pipeline on the second, a classifier on the third. A central beacon tracks the overall loss across all three systems at once.

Reinforcement learning learns a policy from reward signals rather than from labelled examples. The walker creature on the first island has a policy that maps states to actions; an environment provides reward signals for successful steps. Q-learning is the canonical algorithm.

```gdscript
class_name QLearner extends Node

var q_table: Dictionary = {}  # (state, action) -> value
@export var alpha: float = 0.1  # learning rate
@export var gamma: float = 0.99  # discount factor
@export var epsilon: float = 0.1  # exploration rate

func choose_action(state) -> int:
    if randf() < epsilon:
        return randi() % n_actions
    var best: int = 0
    var best_q: float = -INF
    for a in range(n_actions):
        var q = q_table.get([state, a], 0.0)
        if q > best_q:
            best_q = q; best = a
    return best

func update(s, a, reward, s_next) -> void:
    var max_q_next: float = -INF
    for a_next in range(n_actions):
        max_q_next = max(max_q_next, q_table.get([s_next, a_next], 0.0))
    var old_q: float = q_table.get([s, a], 0.0)
    q_table[[s, a]] = old_q + alpha * (reward + gamma * max_q_next - old_q)
```

## Policy Gradient

Q-learning works for small state spaces but scales badly. Policy gradient methods parameterise the policy directly and optimise expected reward by gradient ascent.

```gdscript
func reinforce_update(trajectory: Array, lr: float = 0.01) -> void:
    var returns: Array = compute_returns(trajectory)
    for i in range(trajectory.size()):
        var state = trajectory[i].state
        var action = trajectory[i].action
        var G: float = returns[i]
        var grad = log_policy_gradient(state, action)
        update_policy_parameters(grad, lr * G)
```

The REINFORCE algorithm has high variance. Actor-critic methods reduce variance by using a learned value function as a baseline.

## Generative Station

The second island runs a small character-level language model — a two-layer LSTM trained on a short corpus. Given a seed prompt, it samples continuations character by character.

## Classifier Station

The third island runs the classifier from ML_Classification redeployed as a live demo. Incoming data points are classified in real time, and the learner can paint new training examples onto the space and retrain.

## Complexity

Each island's runtime cost is dominated by its own forward pass. Running three simultaneously requires careful frame budgeting. The map runs each at a reduced update frequency (every third frame) so all three fit within a single frame's time budget.

Within the sequence, Synthesis unifies the arc. Evolution, gradient descent, classification, neural composition, perception, memory, and generation all converge into the single practice of searching a loss surface the model cannot fully see.

## Multi-Armed Bandits

Bandit problems are a simpler setting than full RL. The agent chooses among K actions, each with an unknown reward distribution; the goal is to maximise cumulative reward. Epsilon-greedy explores randomly with probability epsilon and exploits the current best with probability 1-epsilon. Upper Confidence Bound (UCB) chooses the action whose upper confidence interval on reward is highest.

```gdscript
func ucb_choose(mean_rewards: Array, counts: Array, t: int) -> int:
    var best: int = 0
    var best_score: float = -INF
    for i in range(mean_rewards.size()):
        if counts[i] == 0:
            return i
        var bonus: float = sqrt(2.0 * log(t) / counts[i])
        var score: float = mean_rewards[i] + bonus
        if score > best_score:
            best_score = score; best = i
    return best
```

Bandits generalise to contextual bandits (the reward depends on a context vector) and then to full RL (actions change the state). The progression is conceptually clean and the map's third island shows it.

## Transfer Learning

Transfer learning reuses features learned on one task for another. A vision model pretrained on ImageNet can be fine-tuned on a small specialised dataset and vastly outperform a model trained from scratch. The reuse is conceptually simple: freeze the early layers, replace the output head, train the output head (and optionally unfreeze some upper layers).

```gdscript
func transfer_model(base_model, new_task_head) -> FeedforwardNet:
    var model := FeedforwardNet.new()
    for layer in base_model.layers.slice(0, -1):
        model.layers.append(layer)
        model.layers[-1].trainable = false
    model.layers.append(new_task_head)
    return model
```

Transfer learning is one reason large pretrained models have become dominant. The cost of pretraining is borne once; downstream tasks benefit without repeating the cost.

## Deployment

Training is only one part of the lifecycle. Deployment raises concerns the training process does not: latency, memory, robustness to distribution shift, ability to retrain on new data. Production systems are often smaller than their training-time models (via distillation, quantisation, or pruning) because deployment cost matters more than training cost.
