# Edit Distance (Levenshtein)

Visualization of the minimum edit operations needed to transform one string into another — a computational metaphor for identity transformation.

## QFEP Connection

Edit distance measures **the cost of becoming**. Every transformation requires work: insertions, deletions, substitutions. The algorithm finds the *minimum* path (F, optimization) through the space of possible changes (E, combinatorial explosion). In queer terms: the distance between deadname and chosen name is computable.

## How It Works

```
"deadname" → "chosen_name"

Operations:
1. Delete 'd'      → "eadname"
2. Substitute 'e'  → "chadname"  
3. Insert 'o'      → "choadname"
4. ... (continues)

Total: 8 operations
```

### Dynamic Programming Table

```
      ""  c  h  o  s  e  n  _  n  a  m  e
""  [ 0  1  2  3  4  5  6  7  8  9 10 11]
d   [ 1  1  2  3  4  5  6  7  8  9 10 11]
e   [ 2  2  2  3  4  4  5  6  7  8  9 10]
a   [ 3  3  3  3  4  5  5  6  7  7  8  9]
...
```

Each cell = minimum operations to transform prefix into prefix.

## Conceptual Framing

The code explicitly connects to identity:
- **Source**: `"deadname"` (past/old identity)
- **Target**: `"chosen_name"` (future/new identity)
- **Operations**: The work of transition
- **Path**: The journey of becoming

## Parameters

### Identity Transformation
| Export | Default | Description |
|--------|---------|-------------|
| `source_string` | "deadname" | Starting identity |
| `target_string` | "chosen_name" | Desired identity |
| `operation_costs` | (1,1,1) | Insert, Delete, Substitute costs |

### Visualization
| Export | Default | Description |
|--------|---------|-------------|
| `animation_speed` | 1.2 | Seconds per operation |
| `show_dynamic_programming_table` | true | Display DP matrix |
| `highlight_optimal_path` | true | Show backtracked path |
| `auto_animate` | true | Animate automatically |

### Colors
| Export | Meaning |
|--------|---------|
| `source_color` | Red — past/old |
| `target_color` | Green — future/new |
| `operation_color` | Yellow — transformation |
| `path_color` | Magenta — the journey |

## Operations

| Operation | Cost | Description |
|-----------|------|-------------|
| **Insert** | 1 | Add a character |
| **Delete** | 1 | Remove a character |
| **Substitute** | 1 | Replace one character with another |

## Files

| File | Purpose |
|------|---------|
| `levenshtein_distance_visualization.tscn` | Scene |
| `levenshtein_distance_visualization.gd` | Algorithm and visualization |

## Usage

```gdscript
var edit = preload("res://algorithms/stringalgorithms/editdistance/levenshtein_distance_visualization.tscn").instantiate()
edit.source_string = "kitten"
edit.target_string = "sitting"
add_child(edit)
```

## Algorithm Complexity

| Metric | Value |
|--------|-------|
| Time | O(m × n) |
| Space | O(m × n) (can reduce to O(min(m,n))) |

Where m, n are string lengths.

## VR Experience

Watch the DP table fill in cell by cell, understanding how each decision builds on previous subproblems. Then watch the optimal path animate backward through the table, showing the sequence of operations. Finally, see the source string transform into the target, character by character.

## Applications

- **Spell checking**: Suggesting corrections
- **DNA sequencing**: Measuring genetic distance
- **Diff tools**: Showing file changes
- **Plagiarism detection**: Measuring text similarity
- **Identity**: Computing the distance between selves

## See Also

- `stringalgorithms/patternmatching/` — Finding substrings
- `datastructures/` — Underlying data representations
