# Illustration handoff

The illustration work is proceeding separately. This wall provides the receiving frame; no new illustration or prose interpretation was commissioned here.

Installed scene: `res://commons/artifacts/research_info_wall/research_info_wall.tscn`.

Map: `Random_Entropies`, independent artifact at (9,13), rotation 0. The default temporary image is the earlier native overhead capture `res://doc/book/iterations/2026-10-16-entropy-visible-states/aerial.png`. It predates this research-wall addition.

The image opening is 1.62 × 0.90 m inside a frame. Aspect ratio is preserved with margins; no crop or distortion is applied. A landscape detail or a composed overview can therefore be read larger than the current tall room capture.

To replace it, set the scene's `illustration_path` and `illustration_caption`, supply grid configuration with those keys, or call:

```gdscript
work_wall.set_illustration("res://path/to/illustration.png", "A concise description of the view")
```

This only updates the image and caption. It does not rebuild the wall, alter the observations or reset saved ink. Keep the stable `storage_key` `Random_Entropies-work-wall` on the installed wall. Add the image through the normal target export workflow when packaging for a headset; this pass checks the local Godot runtime, not a new APK.
