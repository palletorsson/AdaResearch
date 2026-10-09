# A source and an expectation

The Introduction showed different arrangements returning the same total. Here two sources can have the same entropy while one predictor fares very differently against them.

The Shannon workbench keeps a seeded array of random draws. Its p rail sets the probability of a one by thresholding each stored draw:

```gdscript
var bit: bool = _draws[i] < _p
```

Moving the rail changes this threshold. It does not replace the stored draws. The normal sample has 256 cells; smaller and larger evidence presets remain available in the artifact configuration.

The source readout computes binary Shannon entropy from p. It does not run a compressor on the grid. The previous claim that this particular grid was incompressible has been removed. A chosen probability and one finite realisation are different things to inspect.

In this hall, `prediction_study:on` adds EXPECT 0 and EXPECT 1. Each button chooses one constant prediction for every cell. Amber underlines identify the cells that disagree. Expected error is p for EXPECT 0 and 1−p for EXPECT 1. Observed error counts mismatches in the displayed sample. At p = 0.1 and p = 0.9 the source entropy is the same, but EXPECT 0 has different expected error.

```gdscript
if int(_draws[i] < _p) != _prediction:
    errors += 1
```

Leave p at 0.9 and change the prediction. The stored draws, threshold, bit colours and source entropy stay fixed. Only the mismatch marks and predictor readout change. This is a deliberately small comparison: improvement can come from changing an expectation without changing the observed world. It does not establish that this mistake count is variational free energy.

The none preset reports no observed sample, even though the source formula and expected error are still defined. Changing sample size or seed updates the observed count and marks together. Other placements keep their single-control interface unless prediction study is explicitly enabled.

The snap puzzles and crystal remain secondary comparisons. The old snap_cube_puzzle and snap_tetra_puzzle aliases were disabled in the museum registry; this map now uses the active octahedron and tetrahedron names for the same scene files. The independent lambda rail is movable. The legacy dark sphere retains its decorative role.

Next, the E hall asks which alternatives enter a model’s distribution. Before counting uncertainty, we must decide what is counted as an outcome.
