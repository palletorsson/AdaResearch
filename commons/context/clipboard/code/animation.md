# Tween-Based Animation

- Create a Tween node to animate properties over time.
- Chain tweens for smooth movement and easing.
- Optionally repeat or reverse for looping sequences.

```gdscript
# Slide a node upward over half a second
var tween := create_tween()
tween.tween_property($YourNode, "position", Vector3(0, 2, 0), 0.5)
tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
```
