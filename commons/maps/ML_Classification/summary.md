# ML Classification — Summary

ML_Classification is the third map in the Machine Learning sequence. It stages classification as geometric partitioning — the task of drawing a boundary through feature space that separates one class from another. The map runs three different algorithms on the same small dataset and lets the learner compare the boundaries they produce.

At the centre of the room, a scatter of labelled points sits in a two-dimensional feature space. Around it, three stations run k-means, a support vector machine, and a small neural network. K-means drops centroids and iterates; points migrate toward the nearest centroid until the assignment stops changing, and the resulting Voronoi partition is drawn across the floor. The SVM finds the widest linear margin between the two classes and draws a straight boundary. The neural network bends the boundary into a curve that follows the local density of the data.

Each station has a controls bench exposing the relevant hyperparameters. A shared button re-seeds the dataset with fresh random points, so the learner can watch each algorithm redraw its boundary from scratch.

Within the sequence, Classification makes the output of optimisation something you can see. The boundary is the artifact the model has learned. ML_Neural_Networks will next stack these decisions into layers.
