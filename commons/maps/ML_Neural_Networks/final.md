# A connection changed by an error

Where does a network store what it has learned?

<!-- @neural_network_visualization -->

Choose one connection between two layers and watch it through several training updates. The original diagram starts training when the hall is built; it stops after one thousand batches. Its desktop keyboard offers restart and training controls, but this exhibit has no nearby spatial restart button. Compare a change in the connection's appearance with the error history. Try to distinguish the activity passing through it from a lasting change to the connection itself.

The activity belongs to a forward calculation: inputs contribute to later layers through weighted connections. The weight belongs to the model's adjustable state. Changing that weight alters how a future input influences the next layer, even after the current activity has passed.

Compare a single connection becoming visually different with the aggregate error changing. They describe different scales. One weight can move while the overall error changes little, because other contributions still take part in the prediction. A clearer improvement in the history does not identify one special wire as the location of the answer. We have to relate the distributed calculation to its numerical summary.

The exhibit's own readout now begins: ANSWER ALREADY IN THE INPUT. There is a problem with its examples. It receives four inputs and predicts two outputs; its last two input values already contain those desired outputs, in reverse order. It can adjust real weights and reduce error while being given information that makes the supposed problem much easier. A convincing display of training does not establish what had to be learned. We have to inspect what entered. The display keeps the correspondence visible: input three is target two; input four is target one. Even the flat version therefore cannot serve as a demonstration that a network without a hidden layer fails at XOR. Its extra inputs have changed that problem.

The backward calculation estimates how each parameter affects the chosen error. It does not send a little correct answer backwards through every wire. The input, the outgoing weights and the activation function all affect the derivative. A learning rate then scales the parameter update. Too large a step can increase the error; a smaller one may take longer. The rate is a choice about this numerical procedure, not a measure of how much the network understands.

The colour and strength of a connection expose its sign and magnitude. A negative contribution is not a damaged connection, and a large weight is not a complete explanation of an output. Its effect depends on the input, the other connections and the nonlinear transformations around it.

<!-- @ -->

At the tutorial study the familiar black sphere moves across a square. Four small dots retain labels we supplied. The diagram beside them receives only two coordinates. Move the sphere: the numbers at its nodes change. One weight remains printed above the table. Keep looking at it. Nothing you do in this forward calculation changes that number.

Now leave the sphere still and press STEP. The weight changes; the same input may receive a different answer. A record has changed which can affect later encounters. Moving the point explores a fitted relation. Training revises the relation. The distinction can be felt before it becomes a claim about intelligence.

The two labels occupy opposite diagonals. A single straight boundary in these coordinates cannot separate them; the hidden layer gives the calculation another possibility. That possibility still has to be fitted. FLIP reverses the supplied answers and returns the weights to their starting values. Train again. The same positions support another convention, because their coordinates never contained the names 0 and 1 in the first place.

K-means moved centres according to assigned observations. This learner changes connected parameters against supplied answers. The change is consequential, but improvement still needs a task and a measure. The network's fitting is real; the significance of its labels remains a question for those using them.

CHECK measures four positions withheld from gradient updates. We used these cases while choosing a repeatable starting condition, so they belong to development, too. A good result there is evidence about those four cases. It cannot fill the space between and beyond them with assurance. Bring the sphere to the centre, where we supplied no example, and watch the score. The system can answer there. Its willingness to answer is not an account of what supports that answer.

Perception next asks what enters such a model when the examples come from us. Your hand positions become six coordinates, your examples supply three labels, and the sphere gives an accepted answer a visible consequence. Before fitting begins, we have already chosen which distinctions the model can receive. Those choices can be revised; the tutorial should leave us able to find them.
