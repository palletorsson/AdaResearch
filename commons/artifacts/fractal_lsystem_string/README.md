# Fractal L-System String

Visualizes L-system string expansion as stacked 3D text labels, showing how a simple rewriting rule transforms a short axiom into an exponentially growing string generation by generation.

## How It Works

Starting from an axiom string (default "F"), the artifact applies a production rule that replaces every matching symbol with its expansion at each generation. For example, the default rule replaces F with F[+F]F[-F]F, so the string grows rapidly with each step. Each generation is displayed as a billboard Label3D, color-graded from white (generation 0) to green (final generation). Long strings are truncated with a character count displayed. This reveals the self-similar structure encoded in the grammar before any geometric interpretation.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `display_size` | float | `0.6` |
| `axiom` | String | `"F"` |
| `rule_from` | String | `"F"` |
| `rule_to` | String | `"F[+F]F[-F]F"` |
| `num_generations` | int | `5` |
| `max_display_chars` | int | `60` |
| `line_spacing` | float | `0.12` |
| `string_font_size` | int | `20` |
| `title_font_size` | int | `28` |

## Features

- Configurable axiom, production rule, and number of generations
- Color gradient from early to late generations
- Automatic truncation with character count for long strings
- Grid config integration for dynamic rule/axiom changes
- Billboard labels readable from any angle

## Files

- `fractal_lsystem_string.gd` -- Main script
- `fractal_lsystem_string.tscn` -- Scene file
