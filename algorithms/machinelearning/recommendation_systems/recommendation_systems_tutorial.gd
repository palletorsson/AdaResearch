extends Node

var text = '''
[center][b]Recommendation Systems[/b][/center]
[center][i]Collaborative, content-based, and hybrid filtering[/i][/center]

[hr]
[b]What You Are Seeing[/b]
- Blue user profile particles cluster on one side; green item catalog particles on the other.
- Three rotating engine cores represent the filtering methods:
  [color=red]Collaborative[/color] — finds similar users.
  [color=cyan]Content-Based[/color] — matches item features.
  [color=yellow]Hybrid[/color] — combines both signals.
- A user-item matrix core rotates in the middle, representing the sparse ratings table.
- Gold flow particles travel through the pipeline from users → engine → items.
- Precision and recall meters track recommendation quality.

[hr]
[b]Key Controls[/b]
[color=yellow]Inspector[/color]
[code]
recommendation_progress : 0–1 manual progress override
precision_score         : manual precision (0–1)
recall_score            : manual recall (0–1)
particle_count          : user/item cluster density
animation_speed         : global animation multiplier
auto_progress           : enable auto-advance mode
[/code]

[hr]
[b]How It Works[/b]
- `animate_recommendation_engine()` drives all three method cores independently. Each has its own activation wave (sin/cos at different frequencies) scaled by overall progress.
- The hybrid core uses gold emission (1.0, 0.85, 0.2), visually signaling that it blends the red and blue signals.
- `_on_progress_changed()` fires a gold→green emission tween on the engine core whenever progress updates — a visual "processing" flash.
- `reset_recommendation()` zeros all state and pulses the engine core to 1.5× scale as confirmation.
- The stats label updates each frame: "Progress: X% | Precision: Y% | Recall: Z%".

[hr]
[b]Try This[/b]
1. Disable `auto_progress` and manually drag `recommendation_progress` to watch the pipeline respond.
2. Set precision high but recall low — notice the color difference on the two meters.
3. Change `particle_count` to simulate a sparse vs. dense user base.
4. Call `reset_recommendation()` and watch the engine pulse.

[hr]
[i]VR Tip[/i]
Walk from the user cluster through the engine to the item cluster to follow the data flow path physically.
'''
