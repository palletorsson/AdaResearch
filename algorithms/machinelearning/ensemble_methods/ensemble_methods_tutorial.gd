extends Node

var text = '''
[center][b]Ensemble Methods[/b][/center]
[center][i]Multiple models vote on a single prediction[/i][/center]

[hr]
[b]What You Are Seeing[/b]
- Four model types shown as color-coded particle clusters:
  [color=red]Decision Tree[/color] · [color=green]Random Forest[/color] · [color=cyan]SVM[/color] · [color=yellow]Neural Network[/color]
- Five ensemble method cores orbit the central hub: Bagging, Boosting, Voting, Stacking, Blending.
- Box-shaped vote particles form a ring around the voting system, pulsing with confidence.
- Cyan prediction particles converge into a final consensus output.
- Gold flow particles trace the pipeline from base models → ensemble hub → final prediction.
- Accuracy and diversity meters track ensemble quality.

[hr]
[b]Key Controls[/b]
[color=yellow]Inspector[/color]
[code]
simulation_speed   : training progression rate (0.01–0.5)
particle_count     : base model cluster density (8–60, rebuilds on change)
color_decision_tree: red channel for DT particles
color_random_forest: green channel for RF particles
color_svm          : blue channel for SVM particles
color_neural_net   : gold channel for NN particles
[/code]

[hr]
[b]How It Works[/b]
- `create_model_particles()` assigns each particle to model type `i % 4`, positioning them in 5-particle clusters at angular offsets.
- `animate_base_models()` applies type-dependent oscillation speeds (`0.8 + model_type * 0.5`) so each model family moves differently — diversity made visible.
- `animate_voting_system()` scales vote boxes with `sin(time + i * 0.5)` gated by ensemble progress — votes "arrive" as training advances.
- The ensemble hub (EnsembleCore/EnsembleHub) pulses at progress-proportional intensity.
- `_rebuild_all_particles()` safely frees and recreates all arrays when `particle_count` changes at runtime.
- Accuracy reaches ~95% while diversity reaches ~80%, reflecting the ensemble tradeoff.

[hr]
[b]Try This[/b]
1. Change model colors to visually identify which base learner contributes most.
2. Increase `particle_count` to 60 to see a dense, noisy ensemble with many weak learners.
3. Watch the voting ring — boxes that pulse brightest are the most confident votes.
4. Compare accuracy vs. diversity meters: high diversity with high accuracy is the sweet spot.

[hr]
[i]VR Tip[/i]
Stand inside the voting ring to see vote boxes surrounding you — the ensemble literally voting around you.
'''
