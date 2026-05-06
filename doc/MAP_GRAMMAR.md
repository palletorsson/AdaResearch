# Map Grammar
> Auto-generated from 797 maps + the formal grammar in `commons/artifacts/grammar_operations.json`. Run `python tools/extract_map_grammar.py` to refresh.

## The two grammars

Ada Research carries **two grammars at once**:

1. **Formal grammar** — declared in `commons/artifacts/grammar_operations.json` and enforced at runtime by `GrammarOperationsManager`. Each sequence unlocks operations that produce form types. The biome can only manifest forms whose form_type is unlocked at the player's current sequence.

2. **Latent grammar** — the patterns the 791 existing maps actually use. Mined from the structure layer: 3×3 height n-grams, symmetries, height histograms, corridor widths.

This document brings them into one view so generation strategies (auto-research) can respect both.

## Formal grammar — sequence ladder

Each row is a sequence. Operations unlock cumulatively; outputs become available form_types from that point on.

| order | sequence | operations | outputs |
|---:|---|---|---|
| 1 | `primitives` | `materialize`, `extrude`, `close`, `revolve`, `sweep`, `mirror` | `atom`, `polygon`, `same`, `segment`, `solid`, `surface|solid` |
| 2 | `transformation` | `translate`, `rotate`, `scale`, `compose`, `invert` | `same`, `transform` |
| 3 | `color` | `paint`, `emit`, `mix`, `palette_sample`, `contrast` | `color`, `perceived_color`, `same` |
| 4 | `forces` | `push`, `fall`, `friction`, `attract`, `spring` | `bound_orbit`, `damped_trajectory`, `oscillation`, `trajectory` |
| 5 | `arrays` | `repeat`, `grid`, `tile`, `index` | `any`, `lattice`, `pattern` |
| 6 | `wavefunctions` | `oscillate`, `interfere`, `resonate`, `propagate`, `fourier_compose` | `wave`, `wave_field` |
| 7 | `randomness` | `sample`, `jitter`, `scatter`, `walk` | `any*`, `same`, `trajectory`, `value` |
| 8 | `noise` | `perturb`, `warp`, `terrain`, `octaves` | `field`, `same`, `terrain` |
| 9 | `cellularautomata` | `step`, `rule`, `seed`, `evolve` | `automaton`, `automaton_history`, `cell_state` |
| 10 | `fractals` | `recurse`, `subdivide`, `delete`, `iterate_complex`, `measure_dimension` | `dimension`, `fractal` |
| 11 | `lsystems` | `rewrite`, `turtle_interpret`, `branch`, `parametric_rewrite` | `growth`, `string` |
| 12 | `proceduralgeneration` | `generate`, `percolate`, `colonize`, `wfc` | `generated`, `growth`, `pattern` |
| 13 | `softbodies` | `deform`, `spring_mass`, `cloth`, `reaction_diffusion` | `pattern`, `softbody` |
| 14 | `swarmintelligence` | `flock`, `stigmergy`, `physarum`, `optimize_swarm` | `best_params`, `network`, `swarm`, `swarm trail` |
| 15 | `machinelearning` | `classify`, `optimize_gradient`, `evolve`, `remember`, `generate_learned` | `adaptive`, `generated`, `label`, `memory`, `parameters` |
| 16 | `foundationscrisis` | `non_euclidean`, `paradox`, `self_reference`, `impossible` | `paradoxical`, `space` |
| 17 | `qfeplaboratory` | `tune_lambda`, `tune_phi`, `dissolve`, `re_become` | `parameters`, `tunable` |
| 19 | `graphtheory` | `connect`, `traverse`, `layout`, `flow` | `flow`, `graph`, `path` |

## Form types declared

- **`atom`** — The minimal unit — a position with no extent *(emerges in `primitives`)*
- **`segment`** — A bounded 1D stroke between two atoms *(emerges in `primitives`)*
- **`polygon`** — A closed 2D region bounded by segments *(emerges in `primitives`)*
- **`surface`** — A 2D manifold, possibly curved *(emerges in `primitives`)*
- **`solid`** — A 3D bounded region *(emerges in `primitives`)*
- **`lattice`** — A regular arrangement of forms in a grid *(emerges in `arrays`)*
- **`pattern`** — A tile-able arrangement with symmetry *(emerges in `arrays`)*
- **`wave`** — An oscillating form — position + time *(emerges in `wavefunctions`)*
- **`field`** — A function from space to value *(emerges in `noise`)*
- **`terrain`** — A displaced surface driven by a field *(emerges in `noise`)*
- **`automaton`** — A form that evolves under local rules *(emerges in `cellularautomata`)*
- **`fractal`** — A form self-similar at every scale *(emerges in `fractals`)*
- **`growth`** — A form produced by rewriting rules *(emerges in `lsystems`)*
- **`generated`** — A form produced by a procedural system *(emerges in `proceduralgeneration`)*
- **`softbody`** — A deformable form with constraints *(emerges in `softbodies`)*
- **`swarm`** — Many forms acting as one *(emerges in `swarmintelligence`)*
- **`adaptive`** — A form that learns/changes from experience *(emerges in `machinelearning`)*
- **`paradoxical`** — A form whose existence is self-contradictory *(emerges in `foundationscrisis`)*
- **`tunable`** — A form whose parameters the player can tune live *(emerges in `qfeplaboratory`)*

## Latent grammar — what the corpus actually does

### Height histogram across all 797 maps

| height | meaning | cells | % |
|---:|---|---:|---:|
| 0 | void | 15,398 | 10.9% |
| 1 | floor | 105,255 | 74.5% |
| 2 | wall (h2) | 14,313 | 10.1% |
| 3 | wall (h3) | 2,118 | 1.5% |
| 4 | wall (h4) | 1,480 | 1.0% |
| 5 | pillar (h5) | 1,602 | 1.1% |
| 6 | ? | 252 | 0.2% |
| 7 | ? | 141 | 0.1% |
| 8 | ? | 239 | 0.2% |
| 9 | ? | 516 | 0.4% |
| 10 | ? | 4 | 0.0% |

### Symmetry — average score (1.0 = exact symmetry)

| axis | mean | reading |
|---|---:|---|
| horizontal flip | 0.897 | mirror left↔right |
| vertical flip | 0.854 | mirror top↔bottom |
| rotate 180 | 0.849 | 180° rotational |

Most maps are *not* perfectly symmetric — values around 0.5–0.7 indicate partial regularity, not full mirror symmetry.

### Form-type tags assigned (heuristic)

| form_type | maps tagged |
|---|---:|
| `pattern` | 676 |
| `lattice` | 668 |
| `solid` | 431 |
| `terrain` | 103 |

### Top 3×3 height patterns

Most-frequent 3×3 windows of structure heights across the corpus. These ARE the recurring motifs — pieces of the latent grammar a strategy could replay.

```
# count=64919
   
   
   

# count=1611
·  
·  
·  

# count=1567
  ·
  ·
  ·

# count=1470
···
   
   

# count=1247
···
···
···

# count=1104
   
   
···

# count=538
   
   
  .

# count=426
   
 . 
   

# count=400
   
   
 . 

# count=361
   
   
...

# count=356
   
   
.  

# count=350
 ..
 ..
 ..

```

Glyphs: `.` void, ` ` floor, `·` wall(h2), `▫` wall(h3), `█` wall(h4), `▓` pillar(h5)

## Where this leads

- A `corpus_grammar` strategy can sample from the top 3×3 patterns + paste them with overlap → maps that *look like* the existing corpus by construction.
- A `gated_grammar` strategy can refuse to use a form_type whose required sequence isn't unlocked yet — keeps generated maps **honest** to the curriculum (the same gating `BiomeRingComponent` applies to foliage).
- The form_type counts above tell you which form_types the corpus is *short on* — places the generative strategies should cover.
