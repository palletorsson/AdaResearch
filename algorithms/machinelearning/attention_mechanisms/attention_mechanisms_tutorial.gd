extends Node

var text = '''
[center][b]Self-Attention Mechanisms[/b][/center]
[center][i]Watch tokens attend to each other in real time[/i][/center]

[hr]
[b]What You Are Seeing[/b]
- A row of gold input tokens. One token (highlighted green) is the current query; the rest are keys.
- An attention matrix grid (MultiMesh spheres) lights up row-by-row showing computed scores.
- Focus indicator spheres above each token scale proportionally to their attention weight.
- Three rotating QKV cores (Query, Key, Value) pulse with the query token's score.
- A score meter tracks average attention across all tokens.

[hr]
[b]Key Controls[/b]
[color=yellow]Inspector[/color]
[code]
token_count      : number of tokens (rebuilds layout)
query_index      : select which token is the query
attention_falloff: controls score = 1/(1 + dist * falloff)
focus_gain       : scales focus indicator response
pulse_speed      : animation pulse frequency
rot_speed        : token rotation rate
matrix_cell_spacing: attention grid density
input_spacing    : gap between input tokens
[/code]

[hr]
[b]How It Works[/b]
- `_calculate_attention_scores()` computes distance-based softmax: for each key token, score = 1/(1 + distance × falloff), then all scores are normalized to sum to 1.
- The query token is included in its own key list — this is self-attention.
- `_animate_attention_matrix()` scales each MultiMesh sphere in the [row, col] grid and lerps its color from gray to purple based on the score.
- `_animate_focus()` scales indicator spheres above tokens: high-attention tokens get large purple halos, low-attention tokens shrink to near-invisible.
- Weight lines (MultiMesh cylinders) fade their alpha based on per-column attention scores.

[hr]
[b]Try This[/b]
1. Change `query_index` to watch the attention matrix row shift — see which tokens each query attends to most.
2. Increase `attention_falloff` to make attention sharper (nearby tokens dominate).
3. Lower it to 0.1 for nearly uniform attention — notice the focus spheres equalize.
4. Add more tokens to see how the matrix and weight lines scale.

[hr]
[i]VR Tip[/i]
Stand beside the attention matrix and look across the grid at eye level to read score patterns like a heatmap.
'''
