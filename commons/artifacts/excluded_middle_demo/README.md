# Excluded Middle Demo

A visual demonstration of the Law of Excluded Middle (P v not-P), a foundational principle in classical logic, along with Brouwer's intuitionist rejection of it for non-constructive proofs.

## How It Works

Two glowing spheres represent the proposition P (green, true) and its negation not-P (red, false), connected by a large logical disjunction symbol. A text label explains the law and optionally shows Brouwer's objection that some propositions cannot be constructively decided. A VR slider lets the user toggle between the classical view ("either true or false") and the intuitionist rejection ("not always -- some P cannot be decided"), dynamically updating the explanation text.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `show_rejection` | bool | `true` |

## Features

- Two emissive spheres representing P and not-P with labeled identifiers
- Central disjunction symbol connecting the two states
- Toggleable explanation between classical logic and Brouwer's intuitionism
- VR horizontal slider to switch between viewpoints
- Grid system integration via `apply_grid_config()`

## Files

- `excluded_middle_demo.gd` — Main script
- `excluded_middle_demo.tscn` — Scene file
