# Keep a reading; change its arrangement

The previous hall let you question a formula. This workbench evaluates one small implementation of it. Its four rails supply F, E, lambda and phi, each between zero and one. None is a sensor measuring the surrounding room.

Move one rail. Watch its point on the four-axis diagram and the number below. Press KEEP: the pale outline and retained total stay while the coloured shape follows your next movements. The instrument holds one arrangement at a time. Pressing KEEP again replaces it.

The implemented calculation is:

```gdscript
return _F - _lambda * _E + _phi * rate_delta_e
```

Here `rate_delta_e` is fixed at 0.30. Its historical name does not make it a measured rate. F and E are supplied numbers too; this workbench neither estimates a probability distribution nor evaluates free energy from a model.

Try F = 0.4, E = 0.2, lambda = 0.5 and phi = 0.5. The result is 0.45. Keep it. Change F to 0.6 and E to 0.6. The total returns to 0.45, but the two outlines differ. Two increases have compensated in this calculation. The saved arrangement makes their difference available to inspection.

Then set lambda to zero. Moving E still changes the diagram, but no longer changes this total. Restore a nonzero lambda and repeat. A control’s consequence depends on the expression receiving it.

The name and colour are selected separately: the script compares your four values with seven authored reference tuples, using the sum of absolute differences. The closest example supplies the label. Equal totals need not receive the same name. These are project references, not physical phases detected by the instrument.

The nearby formula and separate lambda/phi rails remain secondary comparisons. They are not wired to the workbench’s four controls. The separate phi rail runs from -1 to +1; this console’s phi runs from 0 to 1. Read the particular instrument’s domain.

The current hall preserves the earlier term spheres and other works. Proposals for remembered scenes, a responsive room and a measured receiver remain in [design-proposals.md](design-proposals.md), clearly marked as development work. Next, the F hall can ask what a prediction would actually be compared against.
