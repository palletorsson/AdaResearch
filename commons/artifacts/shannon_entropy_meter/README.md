# Shannon Entropy Meter

A wall-mounted gauge that generates a random symbol sequence, computes its Shannon entropy, and displays the result alongside a frequency histogram. Teaches information theory fundamentals: how unpredictability in a message is quantified as bits.

## How It Works

The meter generates a random sequence of configurable length drawn from a set of symbols. It counts the frequency of each symbol, then computes Shannon entropy using the formula H = -sum(p(x) * log2(p(x))) over all symbols with non-zero probability. The result is displayed as a fill bar scaled against the theoretical maximum entropy (log2 of the number of symbols), with colored frequency bars showing each symbol's count. A sample of the generated sequence is displayed at the bottom of the panel.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `panel_size` | Vector2 | (0.7, 0.5) |
| `num_symbols` | int | 10 |
| `sequence_length` | int | 200 |
| `bar_color_low` | Color | (0.2, 0.3, 0.9) |
| `bar_color_high` | Color | (0.9, 0.2, 0.3) |

## Features

- Computes and visualizes Shannon entropy with the canonical formula
- Entropy fill bar with color gradient from low (blue) to high (red)
- Per-symbol frequency histogram with hue-mapped colors
- Tick marks at integer entropy values plus the theoretical maximum
- Sequence sample display for inspecting the raw data

## Files

- `shannon_entropy_meter.gd` -- Main script
- `shannon_entropy_meter.tscn` -- Scene file
