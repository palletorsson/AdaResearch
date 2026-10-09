# A connection changed by an error

Where does a network store what it has learned?

<!-- @neural_network_visualization -->

Choose one connection between two layers and watch it through several training updates. Compare changes in its appearance with the error history. Try to distinguish the activity passing through a connection from a lasting change to the connection itself.

The moving activity belongs to a forward calculation: inputs contribute to later layers through weighted connections. The connection’s weight belongs to the model’s adjustable state. Changing that weight alters how a future input will influence the next layer, even after the current activity has passed.

Compare two views of progress: a single connection becoming visually different, and the aggregate error changing. They describe different scales of the update. One weight can move while the overall error changes little, because many other contributions still take part in the prediction. Conversely, a clearer improvement in the history does not identify one special wire as the location of the answer. The display asks you to relate a distributed calculation to its numerical summary.

This exhibit trains on a small, fixed set of four examples with four inputs and two desired outputs. It computes predictions, compares them with those targets, and uses the resulting error to adjust the weights. The backward calculation works out how changes to earlier weights contribute to changes in the final error. It does not send a little correct answer backwards through every wire.

The colour and strength of a connection help expose its sign and magnitude. A negative contribution is not a damaged connection, and a large weight is not a complete explanation of an output: the surrounding inputs, other connections and nonlinear transformations still matter. Follow the network as a calculation distributed across those relations.

K-means moved centres according to assigned examples. This learner changes many connected parameters according to the error on its training examples. In both cases, apparent improvement depends on a task and a measure selected beforehand.

The training display can establish that this small network is adjusting to its sample. It cannot establish that an unfamiliar case will be handled well. For a future experiment, hold out an example and compare its error with the training error. A widening difference would make the boundary between fitting and generalising visible.

<!-- @ -->

Perception next asks what enters such a model. Before a network can learn from an image, some distinctions must already be made available as input.
