# Chamber ML — Technical

The chamber hosts a gradient_hunter creature that learns the learner's movement patterns in real time. The hunter samples the learner's position each frame and updates a predictor of the next position.

```gdscript
class_name GradientHunter extends CharacterBody3D

var samples: Array = []  # ring buffer of (position, velocity) pairs
var predictor: LinearPredictor

func _physics_process(dt: float) -> void:
    var target_pos: Vector3 = get_tree().get_first_node_in_group("player").global_position
    var target_vel: Vector3 = target_pos - last_target_pos
    samples.append([target_pos, target_vel])
    if samples.size() > 64:
        samples.pop_front()
    predictor.update(samples)
    var predicted: Vector3 = predictor.predict(target_pos, target_vel)
    move_toward(predicted, dt)
    last_target_pos = target_pos
```

## Linear Predictor

The hunter uses a linear predictor: the next position is approximated as current position plus current velocity scaled by a learned coefficient. Ordinary least squares fits the coefficient to the recent samples.

```gdscript
class_name LinearPredictor

var coefficient: float = 1.0

func update(samples: Array) -> void:
    var num := 0.0
    var den := 0.0
    for i in range(samples.size() - 1):
        var delta = samples[i + 1][0] - samples[i][0]
        var vel = samples[i][1]
        num += delta.dot(vel)
        den += vel.dot(vel)
    if den > 0.0001:
        coefficient = num / den

func predict(pos: Vector3, vel: Vector3) -> Vector3:
    return pos + vel * coefficient
```

## Loss Tracking

A science screen plots the hunter's loss — the squared distance between predicted and actual position — over time. The loss drops as the predictor improves. A secondary plot shows the predicted position as a ghost ahead of the learner so the hunter's current model is visible.

## Counter-Strategy

The only defence is unpredictability. Smooth, rhythmic movement gives the predictor clean gradient to fit; noisy, unpredictable movement withholds the gradient. The hunter's loss rises when the learner moves erratically and falls when they settle into a pattern.

```gdscript
# On the learner side, measuring own predictability
func motion_predictability() -> float:
    var recent_velocities: Array = get_recent_velocities()
    var mean = recent_velocities.reduce(func(a, b): return a + b) / recent_velocities.size()
    var variance := 0.0
    for v in recent_velocities:
        variance += (v - mean).length_squared()
    return 1.0 / (1.0 + variance)  # higher = more predictable
```

## Complexity

Each frame requires an O(N) pass over the N-sample buffer for the least-squares fit. With N=64, this is 64 multiply-adds per frame — trivial. Richer predictors (Kalman filters, neural nets) would cost more but are overkill for the chamber's pedagogical aims.

Within the sequence, Chamber_ML closes Machine Learning by converting optimisation from a solitary practice into a mutual encounter. The hunter is the optimiser; the learner is the training distribution.

## Kalman Filter Alternative

A Kalman filter is the principled approach to online prediction. It maintains a belief state as a Gaussian distribution over positions and velocities, updates the belief from each observation, and produces a maximum-a-posteriori prediction of the next state.

```gdscript
class_name KalmanFilter

var mean: Vector3
var covariance: Array  # 3x3 matrix
var process_noise: float = 0.1
var observation_noise: float = 0.2

func predict(dt: float) -> Vector3:
    # Propagate mean forward
    mean = mean + velocity * dt
    # Inflate covariance by process noise
    for i in range(3):
        covariance[i][i] += process_noise * dt
    return mean

func update(observation: Vector3) -> void:
    var innovation: Vector3 = observation - mean
    var kalman_gain = covariance_inverse_plus_noise()
    mean = mean + kalman_gain * innovation
    covariance = reduce_covariance_by_observation()
```

The Kalman filter is optimal for linear-Gaussian systems. The hunter in the map uses a simpler linear predictor because the chamber's pedagogical aim is to make the learning curve legible, not to produce the fastest tracker.

## Online Learning

The chamber stages a contrasting example to batch learning. Batch learning trains once on a fixed dataset and deploys. Online learning updates continuously as new data arrives. The hunter is a continuous online learner, and its learning curve is visible frame by frame.

Online learning has theoretical guarantees: under mild conditions, the regret (difference between online loss and best-possible batch loss) grows sublinearly in the number of samples. The hunter's loss trajectory shown on the science screen is roughly this regret over time.

## Adversarial Noise

A learner can deliberately inject noise into their trajectory to degrade the hunter's prediction accuracy. The noise does not need to be uniformly random — adversarial noise specifically targets the hunter's current model and produces maximum prediction error for minimum actual deviation.

```gdscript
func adversarial_noise(current_model_state, budget: float) -> Vector3:
    # Direction that maximally surprises the current predictor
    var gradient = predict_gradient(current_model_state)
    return -gradient.normalized() * budget
```

Adversarial noise is a practical defence for the learner but requires knowing the predictor's current state — information the science screen partially provides.
