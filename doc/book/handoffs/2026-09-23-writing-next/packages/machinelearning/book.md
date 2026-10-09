# machinelearning: the chapters

## ML Evolution

*ML_Evolution*

# Survival without a finish line

If no judge ranks these bodies, does that mean nothing selects between them?


Choose a moving body and watch where it travels. Compare a body covering fresh territory with one remaining near places already visited. Stay long enough to notice a new body appear or an existing one disappear, then compare that event with the population’s continuing motion.

The simulation lets bodies gain energy by visiting new cells. Energy also drains with time. A body with enough energy can reproduce, dividing its available energy and giving its offspring slightly altered traits such as size, speed and colour. There is no final shape on a pedestal that every descendant is trying to become.

Look for continuity as well as difference around a reproduction event. A new body can resemble its parent while beginning a different route, and a visible difference need not immediately alter survival. What matters is how a trait enters the subsequent encounters with the grid and its energy rewards. Keep the description in that order: inherited variation, changed behaviour if you can observe it, then a consequence for continued movement or reproduction.

The changes nevertheless have consequences. A trait that alters movement can alter access to the rewarded cells, and that can affect the opportunity to reproduce. The environment supplies a preference even without a separate leaderboard. Removing an explicit fitness ranking has not removed the conditions under which some lineages continue and others stop.

Follow the child as a new trajectory rather than as an improved copy. Mutation introduces variation; it does not know which variation will help. Nor does a crowded population establish that each surviving body is closer to a universal ideal. It tells you that these bodies have continued under this particular energy economy.

The ecosystem in the previous room combined local behaviour with balancing interventions. Here the lesson is to look carefully at the apparently ordinary rule that pays for survival. Rewarding visits to new cells makes movement into unfamiliar territory consequential before anyone announces an objective called exploration.

Imagine changing that rule so that revisiting a dependable place also provides energy. Which traits might become useful? That is a proposed comparison, not a control offered by the present encounter. It would test how much of the population’s story belongs to its environment.


The gradient landscape next puts an objective in full view. Instead of inheriting a reward through survival, a moving point will be told exactly how its position is scored.

---

## ML Gradient Landscape

*ML_Gradient_Landscape*

# Three meanings of error

Can the same observations lead a learner downhill in different directions?


Find the moving point on each of the three landscapes. Each landscape scores a straight-line fit to the same set of observations. Keep OUTLIERS low for a first comparison, then raise it. The three points return to their starting places. RESET lets you watch the same beginning again. Look for a difference between the responses rather than asking which point arrives first.

The two horizontal coordinates represent the line’s slope and intercept. Height represents the error assigned to that candidate line. Moving across the surface therefore changes the proposed model, while moving down means improving the score under that particular definition of error.

Choose one candidate slope and intercept in your imagination and compare what the three surfaces would say about that same candidate. The candidate line is unchanged; only the rule assigning its height differs. This makes a useful distinction between moving within one landscape and comparing landscapes. An apparent hill on one surface is not a physical obstacle in the observations. It is a way the chosen error calculation rates a set of model parameters.

The squared-error surface punishes a large residual much more heavily than a small one. Huber loss is quadratic near zero and becomes linear for sufficiently large residuals. An unusual observation can therefore pull the two fitted lines differently. Raising OUTLIERS replaces more observations with fixed outlying values; it keeps the other observations and the outliers already introduced. Return the slider to an earlier setting and its sample returns too. We need something to hold still if we want to notice what a different judgement does.

The third surface has a deliberately wavy error rule: a sine term is added to a quadratic term. Its label uses the word “adversarial”, but this exhibit is not training a generative adversarial network. It offers a rougher landscape on which local downhill movement can encounter a different arrangement of rises and hollows.

At each step the points estimate a gradient from nearby samples of the surface and move against it. Their allowed slope and intercept are bounded. A final position can therefore reflect the starting point, the local terrain and the allowed region as well as the underlying observations.

Return to an outlying observation in your imagination. Is it a measurement mistake, a rare event or a person whose case the majority fit neglects? The loss function cannot answer that question. Reducing its influence may be sensible in one situation and erase important evidence in another.


The classification room will exchange a fitted line for groups. The same question remains: which differences does the chosen measure treat as important?

---

## ML Classification

*ML_Classification*

# A boundary that moves with its centre

Why can a point change groups even though the point itself has not moved?


Begin with BLOBS. Press STEP to give the points their first colours, then pick one near the boundary between two groups. Keep its position in view while watching the centres nearby. Predict which centre will claim it at the next step. PAUSE / RUN lets the updates continue; RESET returns this sample and its centres to their beginning.

The points are repeatedly assigned to their nearest centre. Each centre then moves to the mean position of the points assigned to it. Moving a centre changes where the next boundary will fall, so a stationary point can acquire a different group membership. Assignment and centre movement take turns reshaping one another.

Follow a centre during an update and identify the points that are pulling its mean towards one side. A single centre summarises the assigned positions without preserving their whole arrangement. Two differently shaped groups could share a mean, so the centre is already a compression of the data. When the next assignment uses that centre, it acts on the summary. This is one reason to keep watching the points rather than allowing the moving centres to become your only evidence.

This is k-means clustering. The number of centres is chosen in advance; the procedure searches for an arrangement of those centres using distance. The default display starts with four centres, while the generated sample contains three broad blobs and some noise. It is a useful reason to look closely instead of assuming the chosen number reveals the data’s natural categories.

The room sits in a classification sequence, but this encounter does not learn named classes from labelled examples. It groups observations by geometry. Calling a cluster a diagnosis, a personality or a social identity would add an interpretation that the distance calculation did not supply.

Watch a point on the edge of a blob after most colours appear settled. A hard colour boundary reports one assignment and conceals how nearly the alternatives competed. The displayed total distance is also a particular readout; do not confuse it with a complete explanation of why every individual assignment is appropriate.

Press DATASET to replace the blobs with RINGS. Four centres remain. Before stepping, follow a ring with your eye; then watch where its colour breaks. The grouping follows distance to a centre, which need not follow the form you were tracing.

Press DATASET again for BLOCK, a sample with no planted clusters. The procedure still gives it four groups. Does the confidence of the colour change when there was no group for it to discover? Return to BLOBS and the earlier sample returns. We have changed what the procedure encounters while keeping its demand for four centres. The boundary belongs to that meeting.


The neural-network room introduces learned connections between layers. It will still need an account of what its training examples and error measure ask it to preserve.

---

## ML Neural Networks

*ML_Neural_Networks*

# A connection changed by an error

Where does a network store what it has learned?


Choose one connection between two layers and watch it through several training updates. Compare changes in its appearance with the error history. Try to distinguish the activity passing through a connection from a lasting change to the connection itself.

The moving activity belongs to a forward calculation: inputs contribute to later layers through weighted connections. The connection’s weight belongs to the model’s adjustable state. Changing that weight alters how a future input will influence the next layer, even after the current activity has passed.

Compare two views of progress: a single connection becoming visually different, and the aggregate error changing. They describe different scales of the update. One weight can move while the overall error changes little, because many other contributions still take part in the prediction. Conversely, a clearer improvement in the history does not identify one special wire as the location of the answer. The display asks you to relate a distributed calculation to its numerical summary.

This exhibit trains on a small, fixed set of four examples with four inputs and two desired outputs. It computes predictions, compares them with those targets, and uses the resulting error to adjust the weights. The backward calculation works out how changes to earlier weights contribute to changes in the final error. It does not send a little correct answer backwards through every wire.

The colour and strength of a connection help expose its sign and magnitude. A negative contribution is not a damaged connection, and a large weight is not a complete explanation of an output: the surrounding inputs, other connections and nonlinear transformations still matter. Follow the network as a calculation distributed across those relations.

K-means moved centres according to assigned examples. This learner changes many connected parameters according to the error on its training examples. In both cases, apparent improvement depends on a task and a measure selected beforehand.

The training display can establish that this small network is adjusting to its sample. It cannot establish that an unfamiliar case will be handled well. For a future experiment, hold out an example and compare its error with the training error. A widening difference would make the boundary between fitting and generalising visible.


Perception next asks what enters such a model. Before a network can learn from an image, some distinctions must already be made available as input.

---

## ML Perception

*ML_Perception*

# An edge is not yet an object

At which point does a difference between pixels become a claim about what is there?


Find an edge of the cross or disk in the input image. Compare that location with the neighbouring edge image. Follow the small moving window and look at what happens when it crosses a boundary rather than a uniform patch.

The edge image emphasises abrupt changes in intensity. The exhibit applies horizontal and vertical Sobel filters to a small pixel grid, combines their responses into a gradient magnitude, and displays that result. A bright response says that nearby pixel values change sharply; it does not by itself say “circle” or “cross”.

Compare the interior of the disk with its boundary. Both belong to what you recognise as the same object, yet the filter treats them differently because its question is about local change. Then compare a short fragment of the disk’s edge with a fragment of the cross. The image-wide identity that seems obvious to you is not present as a complete object inside either tiny neighbourhood. The window makes that difference of scale inspectable.

The moving window helps you connect a local neighbourhood with a local calculation. The whole boundary is assembled from many such responses. At the outer border, this implementation leaves the result at zero, which is another reminder that an image-processing rule includes a decision about what happens where neighbours are missing.

Now read the object names and confidence percentages. In this exhibit those names and percentages are supplied in advance. They are not predictions learned from the computed edges. The room currently places a real filtering operation beside an illustrated classification claim; the link between the two remains to be built.

That separation gives us a precise question for developing the encounter. What evidence would a recogniser need before it could justify the name, and how would its confidence be checked? A future interaction could alter the input while exposing which stages actually change, allowing an unsupported label to become visible as a broken dependency.

For now, use your own observation: identify one edge fragment that could belong to more than one object. Local contrast can be real while its interpretation remains ambiguous. Adding a confident word does not remove that ambiguity.


The sequence-memory room adds another source of evidence: what happened before the current input arrived.

---

## ML Sequence Memory

*ML_Sequence_Memory*

# What should survive the next input?

How can a learner use the past without keeping every past event equally active?


Walk around the gate diagram and trace the route from incoming information towards the cell-state stream and the outgoing path. Choose one gate and predict what withholding information there would change. Keep that prediction separate from the movement of the decorative particles.

The diagram distinguishes three kinds of decision: what previous state to retain, what new material to admit and what part of the current state to expose as output. These are useful distinctions even when the same stream appears continuous from a distance. A memory has to preserve something while permitting something else to change.

Trace the cell-state route separately from the output route. Imagine retaining a detail for later without displaying it now; then imagine producing an immediate response without keeping every detail of the current input. These are different jobs. The spatial separation helps you ask which job a gate is meant to regulate. It also prevents the stream’s continuity from becoming a vague claim that all information simply passes unchanged from the beginning to the end.

In a working long short-term memory network, learned gates scale numerical contributions to the cell state and output. A gate can take an intermediate value; it is not necessarily a literal door that is either fully open or fully shut. Repeated updates let earlier information influence later predictions through an evolving internal state.

The present arrangement is a spatial diagram of that arrangement. Its particles follow an animation, and it does not yet carry an input sequence through a computed recurrent memory. The gate bodies therefore support tracing the proposed relationships, but their appearance cannot demonstrate that a particular earlier input has been remembered or forgotten.

Take the sentence “the key beside the cabinets is missing”. Which earlier distinction matters when choosing “is” rather than “are”? This thought experiment asks memory to retain the relevant subject across intervening words. It does not imply that a gate comes with an explicit grammatical label or that every trained network solves the problem reliably.

The next useful addition would make an input sequence and cell-state values visible, then compare two sequences differing at one earlier step. That would turn your prediction about a gate into an observable test.


Generative learning next changes the task again: a model produces candidates, while another source of feedback judges them.

---

## ML Generative

*ML_Generative*

# Learning from an opponent’s response

What changes when a learner’s critic is also learning?


Move between the generator and discriminator regions and follow the indicated exchange. First identify where a candidate is supposed to originate. Then trace where a judgement would return. Before watching the scores, say which part would need to change if the critic became better at distinguishing generated examples.

The two roles depend on one another. A generator attempts to produce candidates that a discriminator will accept as resembling the reference data. The discriminator attempts to distinguish the sources of the examples it receives. Improving one role can change the problem faced by the other, so the learning environment is partly made by another learner.

Read the exchange once from the generator’s side and once from the discriminator’s side. The same candidate can be useful to one participant as an attempted success and to the other as a training example to distinguish. The two roles therefore do not share a single meaning of improvement. Keeping their questions separate will matter when the room gains actual examples: a number moving in a favourable direction for one role may signal a changing difficulty for the other.

That relationship differs from descending a fixed surface. In the loss-landscape room, the scoring rule stayed in place while a point moved. Here the intended training process changes the evaluator as well as the evaluated model. A low score needs interpretation in relation to both participants and the examples they have seen.

This room currently illustrates those roles through animated zones, particles and progress displays. Its displayed losses are prescribed curves over time; no generator and discriminator are actually trained by the exhibit. The motion can help you remember the proposed exchange, but it cannot provide evidence that the generated candidates have improved.

Use that boundary to specify the experiment the room still needs: show a changing candidate, the discriminator’s response and the reference example involved in an actual update. Repeating one convincing candidate would then become distinguishable from producing a varied set. A beautiful average or a falling score alone would not settle the difference.

Ask also what the reference set treats as recognisable. Producing more of what an evaluator already accepts can leave unusual forms outside its reward, even when those forms matter to someone encountering the result.


The synthesis room looks directly at that outside: how does a model decide that an observation is an anomaly?

---

## ML Synthesis

*ML_Synthesis*

# The point outside the rule

When a point is flagged as unusual, what exactly has been discovered?


Find one raised, enlarged point and compare its position with a nearby unflagged point. Read the active detection mode. Before interpreting the raised point as an error, ask which numerical comparison could have put it above the threshold.

In the default view, the exhibit measures displacement from the sample’s mean along each coordinate, scaled by the spread on that coordinate. It adds the two absolute standardised displacements and compares the result with a threshold. Points meeting the threshold are lifted and enlarged, making a numerical decision into a spatial distinction.

Compare a point displaced mainly along one coordinate with a point displaced along both. The default score adds coordinate contributions, so the shape of its decision boundary comes from that addition as well as from the sample’s spread. Do not rely only on the impression of being far from the centre. The exhibit gives you a chance to connect the position of a raised point with the particular arithmetic that made its distance count.

The score depends on the sample used to compute the mean and spread. Here the generated outer points are included in those statistics along with the central cloud. The population helping define normality therefore includes the very observations that may later be called abnormal.

This is a specific coordinate-based rule. It is not a complete judgement about an observation’s origin or importance. A point might be an error, a rare valid case, an emerging pattern or a case the representation describes poorly. The raised position tells you what the score did; it does not choose among those explanations.

The machine-learning sequence has repeatedly separated the operation from the interpretation: a cluster from a named class, an edge from an object, and a training curve from demonstrated generalisation. The same care applies here. A detector’s name cannot supply evidence that its flags are useful.

Choose one flagged point you would investigate rather than discard. State what additional observation would help you decide. For a future version, exposing the threshold and allowing the reference population to change would make the cost of a decision visible: which rare cases become ordinary, and which ordinary cases become suspect?


Graph theory will give us another representation of relations. Instead of asking how far points lie from a centre, we will ask which points are connected and what those connections permit.

---
