# Predictable according to what model?

When a pattern looks orderly, what exactly can you predict?

<!-- @shannon_workbench -->

Move p towards one end of the workbench’s rail and inspect the bit grid. Then bring it towards the middle. Before reading H, predict which setting would make guessing the next bit easier. Compare p near 0.1 with p near 0.9 as a second pair.

Near either end, one bit value predominates. Near the middle, the two values are more balanced. The entropy readout rises towards the middle and falls towards both ends. Reversing which bit is common can preserve the amount of uncertainty even though the grid’s dominant colour changes.

Look at individual cells after forming your expectation from p. The setting describes a probability, not an instruction that every small neighbourhood must display exactly that proportion. A patch can look unusually mixed or unusually uniform within the same sample. Distinguishing the chosen source from its finite realisation helps you avoid treating one striking patch as a refutation of the parameter. It also keeps the model’s prediction separate from the particular observation you are trying to explain.

The workbench calculates binary Shannon entropy from the chosen probability: H(p) = −p log₂ p − (1−p) log₂(1−p). The grid is one finite sample of the specified source. H describes uncertainty under that source model; it is not a guarantee about the exact shortest encoding of this particular displayed grid.

The room’s F term asks a related but different question about a model’s fit and prediction. Predictability under an assumed distribution, a realised prediction error and variational free energy are not interchangeable quantities. This display computes the first of those. It gives us a precise starting observation without pretending its H readout is already a measurement of F.

Imagine a predictor that always expects zero. It would usually succeed near one end of the rail and usually fail near the other, although the entropy can be the same at those two settings. The example separates uncertainty in a source from mismatch between a source and a particular predictor.

The next useful addition would display that predictor’s expectations and errors beside the grid. It could then change its expectations while the source stays fixed. A learner would see whether improvement came from an easier world or from a better model of it.

<!-- @ -->

The entropy room next counts alternatives explicitly, asking which possibilities the model has allowed into its world.
