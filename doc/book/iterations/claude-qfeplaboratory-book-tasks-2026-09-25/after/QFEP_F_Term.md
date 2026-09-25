# Predictable according to what model?

When a pattern looks orderly, what exactly can you predict?

<!-- @shannon_workbench -->

Move p towards one end of the workbench’s rail and inspect the bit grid. Then bring it towards the middle. Before reading H, predict which setting would make guessing the next bit easier. Compare p near 0.1 with p near 0.9 as a second pair.

Near either end, one bit value predominates. Near the middle, the two values are more balanced. The entropy readout rises towards the middle and falls towards both ends. Reversing which bit is common can preserve the amount of uncertainty even though the grid’s dominant colour changes.

Look at individual cells after forming your expectation from p. The setting describes a probability, not an instruction that every small neighbourhood must display exactly that proportion. A patch can look unusually mixed or unusually uniform within the same sample. Distinguishing the chosen source from its finite realisation helps you avoid treating one striking patch as a refutation of the parameter. It also keeps the model’s prediction separate from the particular observation you are trying to explain.

The workbench calculates binary Shannon entropy from the chosen probability: H(p) = −p log₂ p − (1−p) log₂(1−p). The grid is one finite sample of the specified source. H describes uncertainty under that source model; it is not a guarantee about the exact shortest encoding of this particular displayed grid.

The F of the formula asks a related but different question about a model’s fit and prediction. Predictability under an assumed distribution, a realised prediction error and variational free energy are not interchangeable quantities. The entropy readout computes the first of those. It gives us a precise starting observation without pretending its H readout is already a measurement of F.

Press EXPECT 0. Each amber underline marks a bit that refuses that guess. Compare p near 0.1 with p near 0.9 again. The entropy returns to almost the same height, but the mistakes spread. The source is no more uncertain; this predictor is less suited to it.

Leave p near 0.9 and press EXPECT 1. Keep your eye on the bits, not only the number. Their colours stay; the amber marks change sides. You have improved this predictor’s performance without making the world easier.

The screen distinguishes expected errors under the chosen probability from mistakes counted in this particular grid. They need not agree exactly. The smaller experiment is enough to ask something consequential: when we call a world difficult, whose expectation is meeting it?

Here you can change the expectation with one button. Elsewhere a system might insist that the world change instead. Keep that difference with you.

The entropy room next counts alternatives explicitly, asking which possibilities the model has allowed into its world.
