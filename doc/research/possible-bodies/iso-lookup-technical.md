# Classification and interpolation

The lesson binds the existing FifteenCasesController.gd. Its `margin` axis remaps low/high corner values without crossing threshold0.5; its `workings` axis selects expression, trace, operands or outcome. The controller does not replace MarchingCubesGenerator or its table. Direct keyboard controls on this instance are disabled so movement keys cannot silently change the lesson.

MARGIN pairs: (.30,.70),(.14,.54),(.44,.84),(.48,.88). Crossing fraction from high to low is (high-.5)/(high-low): .50,.10,.85,.95. `density < threshold` sets extractor bits, opposite to the display's original high-value config labels. The lesson reports both masks instead of calling the high mask the table index.

The original chunk contains 2x2x2 cells and 3x3x3 samples, not just one cell. Eight prescribed corners occupy one cell; surrounding samples use the current low value. Thus neighbouring cells can produce additional sheets. Fifteen selected illustrations do not establish an exhaustive canonical classification or resolve all ambiguous faces.

Source: res://algorithms/spacetopology/marchingcubes/scenes/FifteenCasesController.gd; extractor: res://algorithms/spacetopology/marchingcubes/core/MarchingCubesGenerator.gd; controls and scoped labels: res://commons/artifacts/timing_machines/iso_lookup_workshop.gd. Original artifact implementations are unchanged. Case spacing2.5m, displayed cage scale1.2, root height2.7m.

