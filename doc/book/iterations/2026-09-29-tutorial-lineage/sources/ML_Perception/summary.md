# ML Perception — Summary

ML_Perception is the fifth map in the Machine Learning sequence. It zooms in on the single neuron — the perceptron — after the previous map showed the whole network. A small room contains one large interactive neuron, with inputs, weights, a summation, a threshold, and a binary output made visible as a sequence of labelled stages.

Three input channels arrive at the neuron as coloured arrows. Each arrow has a weight slider attached to it; the learner can turn the weights up or down and watch the arrows fatten or thin accordingly. The summation stage draws the total of the weighted inputs as a bar against a threshold line. When the bar crosses the threshold, the neuron fires; when it does not, the neuron is silent.

A second station extends the perceptron into vision. A small grid of pixels sits at the top of the room; a convolution window slides across it, multiplying and summing against a small filter matrix. The resulting activation map is drawn below the pixel grid. A filter library lets the learner swap in edge-detection, blur, and sharpening filters and see the effect on the activation map.

Within the sequence, Perception makes the atomic mechanism transparent. After this map, every reference to "a neuron" in the rest of the sequence has a concrete referent. ML_Sequence_Memory will next add the connection back to itself that turns a neuron into a memory.
