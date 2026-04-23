<<<ADA_BUNDLE>>>
sequence: machinelearning
file: summary.md
maps: 9
skipped_passing: 0
created: 2026-04-23T19:17:11
only_failing: false
diff_mode: false
with_context: true
<<</ADA_BUNDLE>>>

<<<MAP: ML_Evolution>>>
# ML Evolution — Summary

ML_Evolution opens the Machine Learning sequence. It introduces optimisation the way biology discovered it — before calculus, without gradients, by variation and selection. The space is staged as a small arena where a population of candidate agents attempts a simple task, and the better ones reproduce.

A row of agents faces a short obstacle course. Each agent is a small body with a handful of weighted behaviours; the weights are its genome. The agents run the course in parallel; those that travel furthest are selected to produce offspring with small mutations. A generation counter at the wall ticks up, and the population improves without any single agent knowing what the landscape looks like.

Several controls expose the mechanics. A mutation-rate slider raises or lowers the variability of new offspring. A selection-pressure slider decides how harshly the weakest agents are culled. A reset button scrambles the population back to random weights, so the learner can run the experiment multiple times and watch the evolutionary trajectory vary.

Within the sequence, Evolution is the first answer to the question the rest of the sequence refines. It claims that optimisation can happen without a calculable gradient. ML_Gradient_Landscape will next replace random search with a directed step and ask what is gained by doing so.

<<<MAP: ML_Gradient_Landscape>>>
# ML Gradient Landscape — Summary

ML_Gradient_Landscape is the second map in the Machine Learning sequence. It replaces evolution's blind search with calculus. The central feature is a terrain — a surface whose height at each point is the loss of some hypothetical model at those parameter values — and the learner drops a marker onto it and lets gravity do the maths.

The terrain has hills and valleys. A global minimum sits at the lowest point; several local minima sit at higher basins. A marker at the surface computes the local slope at each step and moves in the opposite direction by an amount set by the learning-rate slider. The trajectory is drawn live, so each step is visible as a small descent.

Three controls change the experiment. The learning rate decides how bold each step is: too small, and the marker creeps; too large, and it overshoots the valley and oscillates. A momentum slider lets earlier steps influence later ones, which can escape shallow local minima. A reset button drops the marker at a new random starting point, so the same landscape can be explored from multiple initial conditions.

Within the sequence, Gradient_Landscape is where optimisation becomes cheap and directed. The landscape metaphor persists through every later map. ML_Classification will next use these mechanics on a concrete task.

<<<MAP: ML_Classification>>>
# ML Classification — Summary

ML_Classification is the third map in the Machine Learning sequence. It stages classification as geometric partitioning — the task of drawing a boundary through feature space that separates one class from another. The map runs three different algorithms on the same small dataset and lets the learner compare the boundaries they produce.

At the centre of the room, a scatter of labelled points sits in a two-dimensional feature space. Around it, three stations run k-means, a support vector machine, and a small neural network. K-means drops centroids and iterates; points migrate toward the nearest centroid until the assignment stops changing, and the resulting Voronoi partition is drawn across the floor. The SVM finds the widest linear margin between the two classes and draws a straight boundary. The neural network bends the boundary into a curve that follows the local density of the data.

Each station has a controls bench exposing the relevant hyperparameters. A shared button re-seeds the dataset with fresh random points, so the learner can watch each algorithm redraw its boundary from scratch.

Within the sequence, Classification makes the output of optimisation something you can see. The boundary is the artifact the model has learned. ML_Neural_Networks will next stack these decisions into layers.

<<<MAP: ML_Neural_Networks>>>
# ML Neural Networks — Summary

ML_Neural_Networks is the fourth map in the Machine Learning sequence. It arranges the neural network as a walkable architecture. The space is a long corridor divided into chambers; each chamber is a layer. Narrow passages between chambers force the data to compress, and the learner walks the compression with it.

Data enters at one end as undifferentiated input. The first chamber is a wide hall where each input dimension has its own display panel. The next passage is a narrow doorway; the number of panels on the other side is smaller, because the first layer has reduced the feature count by a weighted sum. The second chamber is narrower than the first, the third narrower still. At the end, a single bright panel reports the classification.

Each layer displays its weights as a matrix on a wall. A slider at the entrance exposes the learning rate, and a training button re-runs a small batch through the network, updating the weights and redrawing the matrices. A second display tracks the loss so the progress is visible.

Within the sequence, Neural_Networks is where depth earns its keep. A single layer can only draw a linear boundary; each additional layer bends that boundary further. ML_Perception will next zoom in on the single neuron that everything depends on.

<<<MAP: ML_Perception>>>
# ML Perception — Summary

ML_Perception is the fifth map in the Machine Learning sequence. It zooms in on the single neuron — the perceptron — after the previous map showed the whole network. A small room contains one large interactive neuron, with inputs, weights, a summation, a threshold, and a binary output made visible as a sequence of labelled stages.

Three input channels arrive at the neuron as coloured arrows. Each arrow has a weight slider attached to it; the learner can turn the weights up or down and watch the arrows fatten or thin accordingly. The summation stage draws the total of the weighted inputs as a bar against a threshold line. When the bar crosses the threshold, the neuron fires; when it does not, the neuron is silent.

A second station extends the perceptron into vision. A small grid of pixels sits at the top of the room; a convolution window slides across it, multiplying and summing against a small filter matrix. The resulting activation map is drawn below the pixel grid. A filter library lets the learner swap in edge-detection, blur, and sharpening filters and see the effect on the activation map.

Within the sequence, Perception makes the atomic mechanism transparent. After this map, every reference to "a neuron" in the rest of the sequence has a concrete referent. ML_Sequence_Memory will next add the connection back to itself that turns a neuron into a memory.

<<<MAP: ML_Sequence_Memory>>>
# ML Sequence Memory — Summary

ML_Sequence_Memory is the sixth map in the Machine Learning sequence. It introduces recurrence — the practice of feeding a network's hidden state back into its own input at the next step — and makes memory a property of a shared connection rather than a separate module.

A recurrent network sits at the centre of the space. Its hidden state is drawn as a coloured bar above the neuron body, and the feedback connection loops visibly from the output back to the input. Short text sequences scroll into the network one token at a time; the hidden state changes with each input and carries traces of previous tokens forward. A readout panel at the output shows the network's prediction for the next token in the sequence.

A second station demonstrates the vanishing-gradient problem. The same network is run on longer sequences, and a diagnostic panel traces how much influence each input token still has on the final output. The trace decays as inputs recede into the past; by ten steps back, the influence is nearly zero. A toggle swaps in an LSTM cell, whose gated memory decays much more slowly.

Within the sequence, this map adds the temporal dimension that feedforward networks lack. ML_Generative will next build generation on top of it.

<<<MAP: ML_Generative>>>
# ML Generative — Summary

ML_Generative is the seventh map in the Machine Learning sequence. It treats a generative model as a network that has learned the structure of a data distribution well enough to sample new instances from it. The space is built around a generative adversarial pair: a generator and a discriminator, trained against each other.

The generator sits at one station. It takes random noise vectors as input and produces image-like outputs on a large display. The discriminator sits opposite. It takes an input — either a generated fake or a real example — and judges its origin. A shared training loop alternates between them; the generator updates to fool the discriminator, and the discriminator updates to catch the generator.

Controls at the shared bench show the progression. Early in training, the fakes are noise. Over many iterations the fakes sharpen, gain shape, and start to look like members of the real distribution. A slider lets the learner move forward and backward through training checkpoints; a second slider samples different noise vectors at the current checkpoint so the variety within the learned distribution becomes visible.

Within the sequence, Generative is the creative turn. The model does not memorise examples; it learns the manifold that produced them and samples from it. ML_Synthesis will next gather every thread the sequence has developed.

<<<MAP: ML_Synthesis>>>
# ML Synthesis — Summary

ML_Synthesis is the eighth and final map in the Machine Learning sequence. Three floating islands sit above a void, each staging one of the sequence's open problems, and the space invites the learner to see them as three views of the same question: how do you find structure in data when the landscape is larger than you can see?

The first island runs reinforcement learning. A creature with random joints learns to walk by trial and failure. It thrashes, falls, and occasionally takes a step; a reward signal reinforces steps and the creature's policy slowly improves. The second island runs a small generative pipeline that produces short text continuations from a seed prompt. The third island holds a classifier that sorts incoming data points into a learned decision surface.

The connecting bridges carry labelled panels that name the shared operations: loss functions, optimisation steps, parameter update rules. A central beacon tracks the overall loss across all three systems at once, so the learner can see the three optimisations running in parallel and registering progress on the same axis.

Within the sequence, Synthesis unifies the arc. Evolution, gradient descent, classification, neural composition, perception, memory, and generation all converge into the single practice of navigating a loss landscape the model cannot fully see.

<<<MAP: Chamber_ML>>>
# Chamber ML — Summary

Chamber_ML is the catalyst chamber for the Machine Learning sequence. Unlike earlier chambers, its creature is itself an optimiser: the gradient_hunter studies the learner's movements and refines its policy in real time.

The chamber is small and bare. A single hunter creature paces the floor. Every time the learner moves, the hunter samples the move as a training example and updates its prediction of where the learner will go next. The science screen on the wall plots the hunter's loss over time; early in the encounter, its predictions are random and the loss is high. As the encounter continues, the loss drops.

The learner's counter-practice is to move unpredictably. Regular movement gives the hunter gradient to follow; noise withholds gradient. The screen labels this dynamic explicitly as adversarial learning — the learner is the training set, and the hunter improves only to the extent that the training set is legible.

Within the sequence, Chamber_ML reframes catalyst practice as mutual learning. The creature is the optimiser; the learner is the distribution. The chamber hands the learner back to the Lab after the sequence's last demonstration of what it means to learn from another body's behaviour.
