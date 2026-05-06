# Chamber ML — Summary

Chamber_ML is the catalyst chamber for the Machine Learning sequence. Unlike earlier chambers, its creature is itself an optimiser: the gradient_hunter studies the learner's movements and refines its policy in real time.

The chamber is small and bare. A single hunter creature paces the floor. Every time the learner moves, the hunter samples the move as a training example and updates its prediction of where the learner will go next. The science screen on the wall plots the hunter's loss over time; early in the encounter, its predictions are random and the loss is high. As the encounter continues, the loss drops.

The learner's counter-practice is to move unpredictably. Regular movement gives the hunter gradient to follow; noise withholds gradient. The screen labels this dynamic explicitly as adversarial learning — the learner is the training set, and the hunter improves only to the extent that the training set is legible.

Within the sequence, Chamber_ML reframes catalyst practice as mutual learning. The creature is the optimiser; the learner is the distribution. The chamber hands the learner back to the Lab after the sequence's last demonstration of what it means to learn from another body's behaviour.
