# What survives your criterion?

An evolutionary algorithm does not discover the best body in the abstract. It repeats a decision: generate candidates, score them, keep some, alter others, and call the next population an improvement.

<!-- @evolutionary_algorithms -->

Start with the displayed population. Compare two forms that differ in one visible feature. Which one receives the higher fitness score? Change the criterion and let the population run again. If the survivors change, the algorithm has not found a universal beauty; it has made your chosen measure consequential.

The loop is simple: selection preserves candidates with higher scores, mutation introduces variation, and reproduction carries selected traits forward. A seed makes one run repeatable. A changed seed changes the path without changing the rule. The result is therefore neither pure chance nor a plan written in advance.

The speculative turn is political as well as technical. A fitness function decides what counts as success, and every decision leaves other forms with less time, less visibility, or no descendants. Watch the discarded candidates. Their disappearance is part of the output.

Try a criterion that rewards compactness, then one that rewards difference. The same population can become tidy or strange depending on what the loop is asked to preserve. The algorithm supplies variation; the evaluator supplies a direction.

This first room keeps the workbench small so the operation stays legible. Later halls can let several agents negotiate a criterion, alter one another’s rules, or refuse selection altogether. For now, ask the question that will follow the whole speculative sequence: what bodies become possible when a measure becomes a law?
