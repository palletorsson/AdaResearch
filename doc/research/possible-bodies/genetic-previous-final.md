# What would you keep?

<!-- @GeneticProgramming -->

Which of these generated forms would you choose to keep, and why?

Compare two candidates in the genetic programming display. Choose a reason before looking for a score: perhaps an opening, a balance between parts, an awkward projection or a shape you cannot readily name. Then ask whether the scoring rule has any way to notice your reason.

Look for a candidate with overlapping parts and compare it with one whose parts are more clearly separated. Describe what you can establish from the visible silhouette and what remains hidden behind it. Then revisit your original reason for preferring a form. Was it a property of the complete volume, an opening visible from one angle, or an association prompted by its shape? The distinction helps locate where a score and a visitor's judgement consult different evidence, even before deciding whether either criterion should be changed.

The candidates are descriptions assembled from geometric primitives. The current fitness calculation rewards closeness to a target volume. It estimates a candidate's volume, compares that estimate with the target and gives a higher score to a smaller difference. A good score therefore has a specific meaning. It does not mean that a form is generally better, more useful or more interesting.

The estimate adds the volumes of individual primitives. Where two primitives overlap, their shared region is counted more than once. The score consequently describes the estimate the program actually uses, rather than an exact measurement of the visible union.

When an evolution step is run, the process retains selected candidates, chooses parents through small tournaments, combines descriptions and sometimes mutates them. Those operations make a new population available for another comparison. The current initial display can teach the representation and the criterion; demonstrating improvement over time also requires a visible sequence of generations.

The textile in the previous room made independent choices without evaluating their result as a maze. This search adds evaluation, but the purpose still comes from the criterion supplied to it.

<!-- @ -->

A useful extension would preserve one rejected candidate nominated by a visitor, alongside the numerical winner. Give the nomination a reason the score ignores. Then expose one generation step and inspect what selection retains or loses. The next room replaces a single score with many spatial targets, letting local growth respond to their distribution.
