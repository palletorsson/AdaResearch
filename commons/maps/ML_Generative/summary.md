# ML Generative — Summary

ML_Generative is the seventh map in the Machine Learning sequence. It treats a generative model as a network that has learned the structure of a data distribution well enough to sample new instances from it. The space is built around a generative adversarial pair: a generator and a discriminator, trained against each other.

The generator sits at one station. It takes random noise vectors as input and produces image-like outputs on a large display. The discriminator sits opposite. It takes an input — either a generated fake or a real example — and judges its origin. A shared training loop alternates between them; the generator updates to fool the discriminator, and the discriminator updates to catch the generator.

Controls at the shared bench show the progression. Early in training, the fakes are noise. Over many iterations the fakes sharpen, gain shape, and start to look like members of the real distribution. A slider lets the learner move forward and backward through training checkpoints; a second slider samples different noise vectors at the current checkpoint so the variety within the learned distribution becomes visible.

Within the sequence, Generative is the creative turn. The model does not memorise examples; it learns the manifold that produced them and samples from it. ML_Synthesis will next gather every thread the sequence has developed.
