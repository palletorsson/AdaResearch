# ML Neural Networks — Summary

ML_Neural_Networks is the fourth map in the Machine Learning sequence. It arranges the neural network as a walkable architecture. The space is a long corridor divided into chambers; each chamber is a layer. Narrow passages between chambers force the data to compress, and the learner walks the compression with it.

Data enters at one end as undifferentiated input. The first chamber is a wide hall where each input dimension has its own display panel. The next passage is a narrow doorway; the number of panels on the other side is smaller, because the first layer has reduced the feature count by a weighted sum. The second chamber is narrower than the first, the third narrower still. At the end, a single bright panel reports the classification.

Each layer displays its weights as a matrix on a wall. A slider at the entrance exposes the learning rate, and a training button re-runs a small batch through the network, updating the weights and redrawing the matrices. A second display tracks the loss so the progress is visible.

Within the sequence, Neural_Networks is where depth earns its keep. A single layer can only draw a linear boundary; each additional layer bends that boundary further. ML_Perception will next zoom in on the single neuron that everything depends on.
