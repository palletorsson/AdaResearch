# PG Space Colonization — Summary

PG_Space_Colonization is the second map in the Procedural Generation sequence. It grows a tree without using a grammar. Instead, the space is seeded with scattered attractor points, a small seed is dropped at the base of the room, and branches reach outward toward whichever attractor is nearest.

The algorithm is visible as it runs. Each branch tip samples the attractors within a given radius and extends a short segment in the averaged direction of those attractors. When a segment gets close enough to an attractor, the attractor is consumed and removed from the field. New tips sprout from the growing branch and repeat the process, so the tree's shape is determined by where the attractors happened to be.

Three controls change the outcome. A density slider changes how many attractors are scattered. A kill-radius slider decides how close a branch must get before an attractor is consumed. A new-seed button re-scatters the attractors and re-runs the algorithm, so the learner can watch several different trees grow from the same rule under different spatial conditions.

Within the sequence, Space_Colonization extends the claim of the previous map: structure can come from the geometry of the environment rather than from an author. PG_Percolation_Network will next turn to connectivity.
