# PG Genetic Evolution — Summary

PG_Genetic_Evolution opens the Procedural Generation sequence. It stages creature evolution as the sequence's first generative strategy: no designer, no explicit rules, only a population under selection pressure and the bodies that result.

A sunken arena takes up the centre of the room. Inside it, a small population of creatures is born with random body plans — random limb counts, random joint positions, random weighted behaviours. Most cannot move. A few flop forward. A few thrash sideways. A fitness function scores each creature on how far it travels from the spawn point within a short time window, and the top performers are selected to breed.

Breeding is visible on a side panel: two parents contribute genes, a small mutation is applied, and a new body plan is assembled. The next generation drops into the arena. Over many generations, the population improves, and the kinds of locomotion that win the fitness test settle into clear categories — rolling, hopping, shuffling — each reached by a different lineage.

Within the sequence, Genetic_Evolution argues that structure can arise from selection alone. L-Systems in the previous sequence required explicit grammar; this one requires only variation and culling. PG_Space_Colonization will next replace selection with spatial hunger.
