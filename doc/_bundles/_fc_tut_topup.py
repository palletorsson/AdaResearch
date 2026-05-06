import sys
sys.stdout.reconfigure(encoding='utf-8')
from pathlib import Path

splits = {
    'NonEuclidean_Spaces': [
        ('Two lines start parallel. At k=-1 they diverge. At k=0 they stay parallel. At k=+1 they converge and meet.',
         'Two lines start parallel. At k=-1 they diverge.\n\nAt k=0 they stay parallel. At k=+1 they converge and meet.'),
    ],
    'Chamber_Foundations': [
        ('Identical translucency. Identical colour. Identical animation timings. The classifier has nothing to tell them apart with.',
         'Identical translucency. Identical colour. Identical animation timings.\n\nThe classifier has nothing to tell them apart with.'),
    ],
}

for name, pairs in splits.items():
    f = Path('commons/maps/' + name + '/tutorial.md')
    t = f.read_text(encoding='utf-8')
    for old, new in pairs:
        t = t.replace(old, new)
    f.write_text(t, encoding='utf-8')

adds = {
    'Russell_Paradox': """

Count the members of each box on a readout.

```gdscript
func readout_counts(panel: Label3D) -> void:
    panel.text = "even: %d\nboxes: %d\nrussell: %d" % [
        even_box.members.size(),
        boxes_box.members.size(),
        russell.members.size(),
    ]
```

The counts let the learner compare sizes at a glance. Russell's count shifts whenever a non-self-containing set is added elsewhere in the room.

Disable inference when Russell is opened.

```gdscript
func disable_inference() -> void:
    classical_engine.enabled = false
    inference_lamp.light_energy = 0.0
```

Classical inference halts. The lamp darkens. The room makes the failure of the system visible.

Offer a restart.

```gdscript
func _on_reset_pressed() -> void:
    russell.members.clear()
    alarm_light.visible = false
    classical_engine.enabled = true
```

Reset clears the paradox and re-enables inference. The learner can rebuild from scratch. The sequence continues.
""",
    'Brouwer_Intuitionism': """

Count constructed propositions on a tally.

```gdscript
func update_tally(label: Label3D) -> void:
    var built := 0
    for p in propositions:
        if p.constructed: built += 1
    label.text = "%d / %d constructed" % [built, propositions.size()]
```

The tally rises only when propositions are actually built. Claims without construction do not count. The tally is a running honesty check.
""",
    'Crisis_Synthesis': """

Animate the summit light on full completion.

```gdscript
func animate_summit() -> void:
    var t := Time.get_ticks_msec() / 1000.0
    summit_light.light_energy = 3.0 + sin(t * 0.8) * 0.8
    summit_light.light_color = Color(1.0, 0.9, 0.7)
```

A gentle pulse once the four wings are visited. The pulse is slow enough to read as breath.
""",
}

for name, a in adds.items():
    p = Path('commons/maps/' + name + '/tutorial.md')
    p.write_text(p.read_text(encoding='utf-8').rstrip() + a, encoding='utf-8')

print('done')
