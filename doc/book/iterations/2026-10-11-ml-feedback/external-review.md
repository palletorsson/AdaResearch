# Machine Learning — Critical assessment of the eight-hall sequence

Ada Research · 11 October 2026 · Complete tutorials, reflections and review evidence

My judgment: Machine Learning is one of the most important sequences in Ada Research, because it turns the museum's investigation of algorithms toward the question of learning itself.

It is also one of the most demanding sequences you've shown me, not primarily because of the mathematical complexity, but because the difference between a convincing demonstration and a system that genuinely learns becomes central to the work.

The sequence succeeds especially well at distinguishing what a model receives, what it changes, what it retains, what it produces, and how its results are judged.

I see a particularly strong progression in the second half, where the visitor moves from observing machine learning to providing examples, recording gestures, training models, generating variations and evaluating responses.

## 1. The eight-hall progression

| Hall                   | Core operation                                                 | Reflective question                                                |
| ---------------------- | -------------------------------------------------------------- | ------------------------------------------------------------------ |
| 01. Evolution          | Selection through inherited traits and environmental resources | What selects when there is no explicit ranking?                    |
| 02. Gradient Landscape | Adjust parameters according to a loss gradient                 | What does our score make consequential?                            |
| 03. Classification     | Alternate point assignment and centre updates                  | When does a computed group acquire a name?                         |
| 04. Neural Networks    | Train a small network and inspect its connections              | What was already supplied before learning began?                   |
| 05. Perception         | Teach three hand-pose labels from six coordinates              | What can a measurement recognize about a gesture?                  |
| 06. Sequence Memory    | Learn and compare complete timed movements                     | What does a recorded phrase retain or exclude?                     |
| 07. Generative         | Sample variations from learned movement records                | What distinguishes a recording from a newly generated possibility? |
| 08. Synthesis          | Compare intended performances with model predictions           | Who decides whether an answer is appropriate?                      |

The progression develops two different kinds of learning.

Halls 1–4 establish mathematical mechanisms. Students encounter environmental selection, loss functions, clustering and parameter optimization. The black sphere successively becomes a control, a parameter selector, a cluster centre and a model-input query.

Halls 5–8 establish an experimental relationship between a person and a learned model. Students teach, test, record, generate and evaluate. Their own performances become the training data.

That second movement is particularly important. The visitor is no longer simply investigating a mathematical model constructed by someone else. The visitor is helping determine what the model can recognize and produce.

## 2. The strongest achievement: the visitor becomes the source of the training data

I think the transition from Neural Networks to Perception is particularly successful.

In Neural Networks, students fit a complete 2 → 3 → 1 network with thirteen parameters. They can change an input without changing the weights, then initiate training and watch those weights change.

In Perception, the exercise becomes bodily.

The model receives six coordinates representing the positions of two hands relative to the head. The visitor chooses three poses, records examples, trains an 83-parameter classifier and tests new performances.

The crucial artistic decision is that the labels are not already established.

The participant supplies the distinction the model learns.

The program does not discover an intrinsic meaning in a gesture. It constructs a relationship between a representation, examples, named categories and a training procedure.

And its subsequent responses—FLOAT, SPIN and STRETCH—are authored separately.

The learner acquires an association. It does not acquire the significance of the gesture or invent the response.

That is an important distinction to make experienceable, particularly in a museum concerned with AI.

The reflection's insistence that recognising six coordinates is not equivalent to judging a dance performance is exactly right.

## 3. Sequence Memory → Generative → Synthesis is the strongest sustained passage

These three halls should be considered one extended investigation.

The two data paths

Sequence Memory

Recorded movements from both hands, with timing preserved

ONE recordings

Generative

Fits variation across whole paired takes and samples a new trajectory

A/B recordings

Synthesis

Tests fresh intended phrases against trained A/B prototypes

This is not simply a narrative connection. The software actually saves and reloads the teaching records between lessons.

That is a substantial improvement over sequences where conceptual continuity is established through similar objects but the computational states remain separate.

### Sequence Memory

The important insight is that two gestures can occupy the same positions but have a different order.

A four-second recording is resampled into 41 timed positions, and the system compares both hands separately against a learned prototype.

This is a productive distinction between a state and a history.

There is a valuable limitation: the system compares corresponding times without time-warping. A pause or delay can change the result even when the overall gesture remains recognizable to a human.

The experiment therefore makes a model's particular conception of time visible.

### Generative

The generator computes a mean trajectory and retains the residual differences from the recorded performances. It uses Gaussian coefficients to combine those residuals into new movements.

Importantly, one coefficient applies across an entire recorded residual, rather than independently randomizing every coordinate at every instant. This helps preserve relationships across the two hands and through time.

But there is a mathematical limitation worth making especially visible.

With three teaching performances, the generated variation is confined to at most two independent residual directions in the much larger trajectory space. With twelve performances, that rises to at most eleven. It is a low-rank empirical model, not an open-ended generator of arbitrary choreography.

That limitation is not a defect. It gives the student a concrete way to understand how a generative system's possible outputs depend upon its examples and model structure.

### Synthesis

This is perhaps the most original pedagogical choice in the sequence.

The visitor declares an intention before performing, and the model predicts from the recorded movement without receiving that declaration.

The journal keeps the intention, prediction, exact take and model version.

A mismatch is preserved as something to investigate, rather than automatically becoming either human error or model failure.

I particularly like the separate UNKNOWN and AMBIGUOUS categories. They distinguish a movement that neither prototype accepts from one that both accept too similarly.

The system is not only learning how to respond. The visitor is learning how to evaluate the relationship between a response and an intention without assuming they are equivalent.

## 4. The reflections form a coherent critique of machine learning

Several recurring distinctions give the eight texts intellectual continuity.

| Common assumption                           | What the sequence demonstrates                                           |
| ------------------------------------------- | ------------------------------------------------------------------------ |
| Evolution improves organisms                | Survival depends on inherited variation and the environment's conditions |
| Lower error means better knowledge          | The loss function decides which errors matter                            |
| Clusters are natural categories             | K and the distance measure are supplied                                  |
| Network training demonstrates understanding | Outputs depend on representation, labels and training                    |
| Gesture recognition understands expression  | The learner sees a limited set of coordinates                            |
| Memory preserves an event                   | It preserves a selected representation of the event                      |
| Generation produces independent novelty     | Its variation is constrained by examples and model structure             |
| Prediction should match intention           | Agreement and disagreement require interpretation                        |

These are not simply skeptical claims about AI. They become practical questions that students can investigate by changing the data, objective, model or conditions of testing.

I also appreciate that the reflection texts generally resist turning individual numerical outcomes into claims about people.

That discipline is especially important in Perception and Synthesis, where an apparently successful classifier could easily be assigned more authority than its evidence warrants.

## 5. My most important criticisms

### A. The Neural Networks museum exhibit has a serious credibility problem

The original large network receives desired output information in two of its input channels.

The new tutorial explicitly identifies this target leakage, and the reconstructed network removes it.

That is an excellent act of critical inspection. But the original exhibit can still give visitors a convincing demonstration of successful training without revealing how much of the answer was supplied.

I would make that discrepancy unmistakable in the physical installation, not only in the accompanying text.

It could even become a productive comparison: a network that appears to learn, and another that must learn without being given the answer.

The methodological failure becomes an artifact worth investigating.

### B. Evolution has a consequential timing issue

The original novelty-based population renews resources according to rendered frames rather than elapsed simulation time.

The reflection documents one run where the population disappears after approximately 35.8 simulated seconds at 60 frames per second.

A different frame rate can change the rate of renewal relative to the population's movement.

In a desktop and VR museum, this matters considerably. It means that performance characteristics can become unacknowledged environmental conditions governing survival.

I would either move the resource-renewal rule to simulation time or explicitly expose frame-dependent renewal as an experimental parameter. Otherwise, comparisons across runs and machines may be confounded.

### C. The sequence risks presenting too many distinct activities as equivalent forms of learning

Evolution, gradient descent, k-means, supervised networks, timed prototypes and Gaussian trajectory sampling are very different computational procedures.

Your writing recognizes this.

But the title Machine Learning could lead students to expect a continuous learner that becomes increasingly capable.

The sphere is carried between halls, but the first four models do not share learned state. Even Perception begins a new network rather than inheriting the trained weights from Neural Networks.

The data continuity in the last three halls is real, but the early continuity is mainly conceptual.

I would make that structural difference part of the teaching:

A familiar interface does not imply a shared internal model.

### D. Sequence Memory concentrates too much material

This is the most demanding lesson pedagogically.

In a single hall, students encounter timed capture, interpolation, resampling, validation of entire trajectories, prototype fitting, per-hand distance measures, tolerance calculation, A/B classification and ambiguous outcomes.

All these operations are relevant, but their combined complexity is substantial.

The review's recommendation to treat it as two visits is sound: first learn and replay ONE phrase, then return to distinguish A and B.

I would not split the hall structurally. I would split the learner's immediate task.

### E. The sequence still needs actual evaluation of recognition quality

The numerical tests verify calculations, but they do not establish how reliably the recognizers work with different people, tracking conditions or movement styles.

The user's choice of gestures may be affected by height, arm reach, mobility, controller tracking and differences between rehearsed and spontaneous performance.

These variations are not peripheral. They are precisely the differences that become important when a model developed in a controlled study is used by another body.

I'd want a small empirical study in which unfamiliar participants teach their own gestures and explain which results surprise them.

## 6. Technical evidence

# 370

Passing Godot assertions

# 18

Cross-hall file checks

# 128

Museum checks reported

The tests cover all eight reconstructed lessons. The cross-hall tests are especially valuable: they verify saved-data compatibility, preservation of source recordings and separation of the Generative and Synthesis teaching branches.

The report also documents an actual integration defect caught during the Gradient review: the unheld sphere could return to a previous height after a paused update. That was corrected and retested.

The evidence is meaningful, but the reconstruction was author-informed, used synthetic performances and was not a blind student assessment or physical headset walkthrough.

## 7. What Machine Learning adds to Ada Research

Compared with the other sequences, I would describe the development this way:

Cellular Automata investigates how rules change states.

Swarm investigates how information and interaction become distributed.

Procedural Generation investigates how rules construct and select forms.

Machine Learning investigates how a system's parameters and stored representations can change in response to examples, measurements or environmental consequences.

But the most important development is not simply that the algorithms become more sophisticated.

It's that the visitor becomes part of the system's epistemology.

The person provides examples. The program constructs a representation. A fitted model produces an answer. The person evaluates the answer and may revise the examples.

Unlike some earlier sequences, this isn't just a metaphor for research. The software actually implements that cycle.

## Final judgment

I would preserve all eight halls and their order.

The second half is particularly successful, and Synthesis is a strong artistic conclusion because it refuses to equate a model's result with a person's intention.

I would prioritize making the original network's leakage visible in the installation, addressing Evolution's frame-dependent resource renewal, and testing the hand-learning encounters with people who did not construct the system.

I would also resist adding more machine-learning algorithms merely to increase coverage. There is already enough material here to investigate selection, fitting, representation, generation and evaluation with considerable depth.

One larger issue deserves attention, however.

Ada Research is itself being constructed through extensive AI assistance. This sequence provides carefully inspectable examples of small learning systems, but it does not explain the language models participating in the project's production. The review acknowledges that limitation, and I think it is significant.

That difference could provide a compelling transition into Foundations Crisis: from systems whose calculations, data and parameters the student can inspect completely, toward systems whose scale and opacity make the conditions of knowledge much harder to establish.

The strongest proposition I take from Machine Learning is therefore:

Learning is not simply the ability of a system to change its answers. It is a relationship between what is represented, what is retained, what is optimized, what can be tested, and who has the authority to decide what the answer means.

That is a substantial contribution to the larger artistic research project.