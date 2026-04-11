extends Node

var text = '''
[center][b]Transformer Architecture[/b][/center]
[center][i]Encoder-decoder attention in 3D space[/i][/center]

[hr]
[b]What You Are Seeing[/b]
Two versions run here: Transformers.gd (showcase) and Transformers_VR.gd (interactive).
- Encoder tokens (green) and decoder tokens (orange/blue) float in two vertical stacks separated by a gap.
- ImmediateMesh attention beams connect decoder queries to encoder keys, colored by head index.
- Sine/cosine positional encoding waves animate below the sequences.
- A QKV triplet — Query (red), Key (green), Value (blue) — pulses above, with the formula Attention(Q,K,V) = softmax(QK^T/√d)V displayed.

[hr]
[b]Key Controls[/b]
[color=yellow]Inspector (VR version)[/color]
[code]
sequence_length    : tokens per sequence (4–16)
num_attention_heads: parallel head count
training_speed     : how fast loss decays
show_attention_beams: toggle beam visibility
show_positional_encoding: toggle wave display
enable_token_grabbing: pick up tokens in VR
enable_head_switching: head selector buttons
[/code]

[color=yellow]Inspector (Showcase version)[/color]
[code]
attention_heads : head count (2–8)
training_rate   : controls loss/accuracy curve
auto_train      : enable/disable auto-progress
pulse_intensity : visual pulse strength
[/code]

[hr]
[b]How It Works[/b]
- `_initialize_attention()` builds a [head][query][key] weight matrix, normalized via softmax.
- `_update_attention_weights()` drifts weights with small random deltas each frame, re-normalizing per query row.
- `_animate_attention_beams()` redraws ImmediateMesh lines from decoder to encoder tokens; beam emission scales with the attention weight.
- Positional encoding uses freq = 1/10000^(2·pos/seq_len) — the same formula from "Attention Is All You Need."
- `switch_attention_head(head)` toggles beam visibility between heads so you can compare learned patterns.

[hr]
[b]Try This[/b]
1. Switch between attention heads (H0–H3 buttons) to see different learned patterns.
2. Grab an encoder token and drag it — watch beam geometry update in real time.
3. Turn off positional encoding to see what attention looks like without position info.
4. Reset training and watch loss decay from 1.0 toward 0.05 as weights sharpen.

[hr]
[i]VR Tip[/i]
Walk between the encoder and decoder stacks to stand inside the attention beams — the weight colors surround you.
'''
