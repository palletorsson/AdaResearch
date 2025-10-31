extends Node

# Tutorial card rendered in-world via BBCode
var text = '''
[center][b]Gradient Descent[/b][/center]
[center][i]Follow the slope to the minimum[/i][/center]

[hr]
[b]What Happens[/b]
- Heightfield = cost surface generated from noise.
- Walker samples the slope at its XZ position.
- Each step moves downhill and updates the path.

[hr]
[b]Controls[/b]
[color=yellow]Methods[/color]
[code]
reset_descent()
reset_descent(false)
[/code]
[color=yellow]Exports[/color]
`learning_rate`, `step_interval`, `gradient_sample_distance`, `stop_gradient_magnitude`, `show_gradient`.

[hr]
[b]Experiments[/b]
1. Increase `learning_rate` to see overshoot and oscillation.
2. Randomise the seed and compare basins.
3. Toggle gradient lines to focus on the trace.

[hr]
[i]Tip[/i]
The walker stops when |gradient| < threshold or the step budget runs out.
'''
