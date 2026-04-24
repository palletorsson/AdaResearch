# Chamber Transformation

The miura_crawler folds rather than dies. The catalyst induces a state change.

Build the transformation catalyst.

```gdscript
class_name TransformationCatalyst extends Node3D

func fire(direction: Vector3) -> void:
    var projectile := FOLD_PROJECTILE_SCENE.instantiate()
    projectile.global_position = global_position
    projectile.linear_velocity = direction * 8.0
    projectile.operator = "fold"
    get_tree().root.add_child(projectile)
```

Projectiles carry a folding operator. On impact, the operator runs against whatever they hit.

Build the miura crawler.

```gdscript
class_name MiuraCrawler extends CharacterBody3D

@export var fold_decay_rate: float = 0.1
@export var hit_fold_increment: float = 0.3

var fold_amount: float = 0.0  # 0 = unfolded, 1 = fully folded

func _process(delta: float) -> void:
    fold_amount = max(0.0, fold_amount - fold_decay_rate * delta)
    update_mesh(fold_amount)
```

The fold decays toward zero over time. Each hit resets it partway up.

Respond to a fold hit.

```gdscript
func on_fold_operator() -> void:
    fold_amount = min(1.0, fold_amount + hit_fold_increment)
```

Each hit bumps the fold amount by 0.3. Three well-timed hits fold the creature completely.

Deform the mesh based on fold amount.

```gdscript
func update_mesh(amount: float) -> void:
    var compression: float = 1.0 - amount * 0.8
    scale = Vector3(1, compression, 1)
```

Vertical compression scales with the fold amount. Zero fold is full height; full fold is 20% height.

Detect befriending.

```gdscript
var sustained_fold_time: float = 0.0

func _process(delta: float) -> void:
    super(delta)
    if fold_amount > 0.8:
        sustained_fold_time += delta
    else:
        sustained_fold_time = 0.0
    if sustained_fold_time > 3.0:
        befriend()
```

Three seconds of sustained folding triggers befriending. Short hits don't count; you have to keep the fold.

Record befriending.

```gdscript
func befriend() -> void:
    var save = get_tree().get_first_node_in_group("save_manager")
    save.add_befriended_creature("miura_crawler")
```

The creature joins the learner's roster of companions. It appears in later chambers as a witness.

Log events to the science screen.

```gdscript
func log_fold_event(amount: float) -> void:
    var screen = get_tree().get_first_node_in_group("science_screen")
    screen.log_scatter(Vector2(Time.get_ticks_msec() / 1000.0, amount))
```

Each hit becomes a scatter-plot point. The screen accumulates the history as a small dataset.

You can now build the transformation catalyst, project folding operators, deform the miura_crawler's mesh according to fold amount, and trigger befriending through sustained folding. The sequence hands you back to the Lab with the transformation catalyst in your kit and the miura_crawler as a companion.

Check identity.

```gdscript
func is_identity(t: Transform3D) -> bool:
    return t.is_equal_approx(Transform3D.IDENTITY)
```

Identity preserves the input. Useful as a test for whether a chain of transforms cancels out.

Invert a transform.

```gdscript
func invert(t: Transform3D) -> Transform3D:
    return t.affine_inverse()
```

Undo the transform. Composing t with t.affine_inverse() produces identity.
