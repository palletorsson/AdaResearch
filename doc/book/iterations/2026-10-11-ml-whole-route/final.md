# Machine Learning — complete reflective sequence

Eight halls of the existing Endless Museum. Review snapshot, 11 October 2026.

<!-- Canonical chapter: commons/maps/ML_Evolution/final.md -->

# Survival without a finish line

If no judge ranks these bodies, does that mean nothing selects between them?

<!-- @non_teleological_evolution -->

Choose a moving body and watch where it travels. Compare a body covering fresh territory with one remaining near places already visited. Stay long enough to notice a new body appear or an existing one disappear, then compare that event with the population’s continuing motion. The plate under the title counts births and deaths; watch Born and Died tick while you look for the body that changed them.

A sign under the title now says: no fitness ranking; energy selects. The simulation lets bodies gain energy by visiting new cells. Energy also drains with time. A body with enough energy can reproduce, dividing its available energy and giving its offspring slightly altered traits such as size, speed and colour. There is no final shape on a pedestal that every descendant is trying to become.

Beside these bodies stands a population that does have a judge. In the current creature code, a generation lasts twenty seconds. Forward displacement, overall distance and a height bonus contribute to its score. Two leading genomes are retained; the rest are bred from the top five, with blended parameters and possible mutation. Watch what each population carries onward. A score makes a preference explicit; an energy economy makes a preference consequential without sorting everyone into rank.

Look for continuity as well as difference around a reproduction event. A new body can resemble its parent while beginning a different route, and a visible difference need not immediately alter survival. What matters is how a trait enters the subsequent encounters with the grid and its energy rewards. Keep the description in that order: inherited variation, changed behaviour if you can observe it, then a consequence for continued movement or reproduction.

The changes nevertheless have consequences. A trait that alters movement can alter access to the rewarded cells, and that can affect the opportunity to reproduce. The environment supplies a preference even without a separate leaderboard. Removing an explicit fitness ranking has not removed the conditions under which some lineages continue and others stop.

Follow the child as a new trajectory rather than as an improved copy. Mutation introduces variation; it does not know which variation will help. Nor does a crowded population establish that each surviving body is closer to a universal ideal. It tells you that these bodies have continued under this particular energy economy.

Earlier ecosystem encounters combined local behaviour with balancing interventions. Graph Theory, immediately before this sequence, asked what relations permit. Here the lesson is to look carefully at the apparently ordinary rule that pays for survival. Rewarding visits to new cells makes movement into unfamiliar territory consequential before anyone announces an objective called exploration.

The fresh ground is finite: four hundred cells. In a recorded run on 25 September, drawn at sixty frames per simulated second, the population reached its ceiling of a hundred and twenty within three seconds and disappeared by 35.8 seconds.[^novelty] Those times belong to that older version and run. It cleared one random cell every 120 drawn frames; rendering helped set the conditions of survival. The revised exhibit advances movement and renewal on a fixed simulation clock and names the renewal interval beside the population. One random cell becomes available every two simulated seconds. The earlier trace remains below as evidence of the version we changed, not a prediction for today's room. A clock that once passed unnoticed has become a choice we can inspect.

![Bodies alive and fresh cells visited, over the first fifty seconds of the hall](images/fresh-ground-runs-out.png)

*Archived run, 25 September, before the simulation-clock correction on 11 October. The curve has not been regenerated or relabelled as evidence for the revised exhibit.*

The tutorial table lets us make a smaller comparison. Begin with the same twelve bodies and seed. In one condition each cell pays once. In the other, food returns after four simulated seconds. A place can become sustaining again, even for a body that stayed there. Watch what changes before calling one family better. Part of what persists belongs to the body, and part belongs to the conditions we have made available to it.

The original exhibit also offers uniform, culled, runaway and split arrangements. These are composed states; their motion is stopped. A field of identical bodies can make a warning vivid, but its appearance does not demonstrate that a single objective inevitably removes difference. To make that causal claim we would need to name the process and watch it produce the result. The tutorial asks us to keep an image of an argument distinct from its test.

The flowers in this hall have a judge too, and the judge is a sentence: symmetry, long petals, a hue near purple, an angle near thirty degrees, each worth so many points. They evolve toward a taste someone wrote down. In Karl Sims's *Galápagos* (1997), visitors selected animated forms by standing on sensors in front of their displays. The selected forms survived and produced varied offspring. A written taste and a visitor's choice give selection different histories. Neither speaks for everyone. Ask what each arrangement makes easy to preserve. [Karl Sims, Galápagos](https://www.karlsims.com/galapagos/)

<!-- @ -->

The gradient landscape next puts an objective in full view. A moving point will follow an explicitly scored landscape. Keep asking what the score makes consequential, and who can change that question.

[^novelty]: Measured with `commons/testing/probe_novelty_finite.gd`, the artifact's own frame loop at a fixed sixty frames a second: thirty bodies at the start, a hundred and twenty at 2.4 seconds, the visited fraction at one by ten seconds, seventy-six bodies at twenty, eight at thirty, none at 35.8. The version measured then cleared one random cell every 120 drawn frames, too slowly to sustain a survivor in this recorded run. That frame-dependent rule has since been replaced; the probe and curve document the earlier experiment. A visitor arriving after extinction in this configuration meets an empty plane; that absence belongs to the process too.


---

<!-- Canonical chapter: commons/maps/ML_Gradient_Landscape/final.md -->

# Three meanings of error

Evolution made persistence depend on the conditions around a body. Here we write a score explicitly. Can the same observations lead a learner downhill in different directions?

<!-- @loss_function_comparator -->

Find the moving point on each of the three landscapes. Each landscape scores a straight-line fit to the same set of observations. Keep OUTLIERS low for a first comparison, then raise it. The three points return to their starting places. The unlabelled button beside the slider is the reset; press it to watch the same beginning again. Look for a difference between the responses rather than asking which point arrives first.

The two horizontal coordinates represent the line’s slope and intercept. Height represents the error assigned to that candidate line. Moving across the surface therefore changes the proposed model, while moving down means improving the score under that particular definition of error. The three sheets are separately rescaled to fit their displays. A centimetre of height is not the same quantity of loss on each sheet. Their moving markers use an approximate height mapping too; an apparent hover is a feature of the display, not a force acting on the model.

Choose one candidate slope and intercept in your imagination and compare what the three surfaces would say about that same candidate. The candidate line is unchanged; only the rule assigning its height differs. This makes a useful distinction between moving within one landscape and comparing landscapes. An apparent hill on one surface is not a physical obstacle in the observations. It is a way the chosen error calculation rates a set of model parameters.

The squared-error surface penalizes a large residual much more heavily than a small one. Huber loss is quadratic near zero and becomes linear for sufficiently large residuals. An unusual observation can therefore pull the two fitted lines differently. Raising OUTLIERS replaces more observations with fixed outlying values; it keeps the other observations and the outliers already introduced. Return the slider to an earlier setting and its sample returns too. We need something to hold still if we want to notice what a different judgement does.

The third surface has a deliberately wavy error rule: a sine term is added to a quadratic term. Its label uses the word “adversarial”, but this exhibit is not training a generative adversarial network. It offers a rougher landscape on which local downhill movement can encounter a different arrangement of rises and hollows.

The tutorial table lets you hold the question in your hand. Its familiar point selects one slope and intercept; beside it, a line moves among five visible observations. Change the loss while keeping that line still. The observations have not moved and the prediction has not changed, but the account of its error has. Height is calculated from one fixed scale here.

At each step the points estimate a gradient from nearby samples of the surface and move against it. Their allowed slope and intercept are bounded. A final position can therefore reflect the starting point, the local terrain and the allowed region as well as the underlying observations. On the tutorial table, lengthen the step. A direction that initially points downhill can carry the candidate past the improvement. Choosing a score and choosing how to follow it are separate decisions.

Return to an outlying observation in your imagination. Is it a measurement mistake, a rare event or a person whose case the majority fit neglects? The loss function cannot answer that question. Reducing its influence may be sensible in one situation and erase important evidence in another.

<!-- @ -->

The classification room will exchange a fitted line for groups. The same question remains: which differences does the chosen measure treat as important?


---

<!-- Canonical chapter: commons/maps/ML_Classification/final.md -->

# A boundary that moves with its centre

Why can a point change groups even though the point itself has not moved?

In Gradient Landscape we chose a line and a measure of its error. Here the parameters are centres, and an observation's distance to them helps decide which group will claim it.

<!-- @enhanced_kmeans -->

Begin with BLOBS. Press STEP to give the points their first colours, then choose one to watch near the boundary between two groups. Keep its position in view while watching the centres nearby. Predict which centre will claim it at the next step. PAUSE / RUN lets the updates continue; RESET returns this sample and its centres to their beginning.

The points are repeatedly assigned to their nearest centre. Each centre then moves to the mean position of the points assigned to it. Moving a centre changes where the next boundary will fall, so a stationary point can acquire a different group membership. Assignment and centre movement take turns reshaping one another.

Follow a centre during an update and identify the points that are pulling its mean towards one side. A single centre summarises the assigned positions without preserving their whole arrangement. Two differently shaped groups could share a mean, so the centre is already a compression of the data. When the next assignment uses that centre, it acts on the summary. This is one reason to keep watching the points rather than allowing the moving centres to become your only evidence.

This is k-means clustering. The number of centres is chosen in advance; the procedure searches for an arrangement of those centres using distance. The default display starts with four centres, while the generated sample contains three broad blobs and some noise. It is a useful reason to look closely instead of assuming the chosen number reveals the data’s natural categories.

The room is called Classification, but this encounter does not learn named classes from labelled examples. It groups observations by geometry. Calling a cluster a diagnosis, a personality or a social identity would add an interpretation that the distance calculation did not supply.

Two other works in this hall use labelled examples. The SVM seeks a separating boundary with a margin and highlights observations that influence it through its fitted coefficients. This is a numerical training procedure; the gold points do not certify a perfect separator. The forest trains trees on resampled data and combines their votes. Both received class labels; the moving centres did not. Their different procedures give us a reason to ask where the answers entered, before admiring the clarity of the boundary.

Watch a point on the edge of a blob after most colours appear settled. A hard colour boundary reports one assignment and conceals how nearly the alternatives competed. The exhibit's total distance adds ordinary distances before the centres move. The tutorial table instead shows the sum of squared distances for the assignments currently displayed—the quantity its mean update reduces. Neither number tells us whether a group has a useful name or whether an individual assignment should carry a consequence.

Press DATASET to replace the blobs with RINGS. Four centres remain. Before stepping, follow a ring with your eye; then watch where its colour breaks. The grouping follows distance to a centre, which need not follow the form you were tracing.

Press DATASET again for BLOCK, a sample with no planted clusters. The procedure still gives it four groups. Does the confidence of the colour change when there was no group for it to discover? Return to BLOBS and the earlier sample returns. We have changed what the procedure encounters while keeping its demand for four centres. The boundary belongs to that meeting.

<!-- @ -->

At the tutorial table the familiar black sphere returns as one centre you can move. Choose a centre, lift it, and put it somewhere else. The observations stay where they were. Their colours clear until you ask for a new assignment; the interface admits that your intervention has interrupted the answer. Another button moves each centre to its group's mean. You can pause between these operations and see which kind of change you caused.

A point exactly between two centres is given to the lower index. A centre with no assigned points stays where it was. These small decisions are easy to lose inside a finished colour field. They matter whenever we want to know how this particular division came about. The mean can be useful without exhausting the group it summarizes; a boundary can be exact under a rule without becoming an account of what its members are.

The neural-network room introduces learned connections between layers. It will still need an account of what its training examples and error measure ask it to preserve.


---

<!-- Canonical chapter: commons/maps/ML_Neural_Networks/final.md -->

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


---

<!-- Canonical chapter: commons/maps/ML_Perception/final.md -->

# What did the sphere recognise?

The sphere waits in its own bay. Across the wall, a dance phrase invites both hands to follow lines through the air. Here there is no required pose until you supply one.

<!-- @vogue_timeline -->

Choose three arrangements of your hands and give them the names A, B and C. Repeat them. Train the small model, then make a fresh attempt. The sphere may rise, turn or stretch. Something has changed through your examples: the numbers that connect the measured positions to those three labels. The movements of the sphere were written beforehand.

This is a real, limited capacity. The model receives six coordinates: each hand's position relative to the head, expressed in a chosen horizontal frame. It receives no fingers, facial expression, personal history or reason for the gesture. A pose that matters to you may disappear into the same six numbers as another. Two poses you regard as equivalent may remain far apart within this representation.

The arrangement also makes some differences disappear deliberately. Carry the head and hands together across the floor: subtracting the head position removes that translation. The work of deciding what counts as the same begins before any weight is trained. We have built that decision into what the learner can receive.

Give a familiar pose a different name in a new session. The sphere can learn the new association. Its answer has not uncovered an essential property of the pose; neither is the answer arbitrary once the examples, representation and fitting procedure are fixed. Those relations make some outcomes more likely than others. Revising them is part of working with the system.

Test without teaching again. A correct answer on an example used during training tells us less than a correct answer on a fresh attempt. A mistake may come from few examples, overlapping labels, tracking, an omitted distinction or the model itself. Before deciding that the body performed badly, ask which conditions could change. The refusal to act is also designed: a score and a proximity threshold govern when the sphere stays still. They do not make its accepted answers infallible.

The dance nearby gives this distinction particular weight. Following a drawn phrase, fitting hand measurements and judging a performance are different activities. Recognition of a coordinate pattern does not establish what makes a movement expressive, or grant the program authority over the practice from which an encounter draws inspiration.

<!-- @computer_vision_vr -->

Return to the image exhibit and compare the inside of a disk with its edge. The Sobel filter measures local intensity change. A fragment of that edge might belong to several objects. The supplied object names and percentages in this exhibit are not learned predictions from those edges. A computed difference and an interpretation can stand beside each other without the calculation establishing the interpretation.

The new sphere lets us construct one such connection explicitly: examples, labels, fitted parameters, then tests. It also exposes the distance still left between a working connection and the larger meaning we might give it.

Ada itself is being made with AI assistance. The distinction returns to our own work. An impressive result is reason to investigate a capacity; an error is evidence about a particular operation and its conditions. Neither observation settles every future use. What matters here is whether we can inspect the connection, retain the evidence and revise what the system is permitted to do.

<!-- @ -->

This pose lesson keeps an average and loses the order of movement. In Sequence Memory, that loss becomes the next question: what must survive from one moment for the next moment to mean something different?


---

<!-- Canonical chapter: commons/maps/ML_Sequence_Memory/final.md -->

# Two hands, a history

Lift both hands, open them, bring them together. Now move through the same places in reverse. An average can remain unchanged while the gesture becomes another gesture. Perception's held pose gave the sphere six numbers. The phrase study gives those numbers a before and an after.

The familiar sphere returns in the tutorial's study inside this room. We keep its body and change what it can respond to. The full phrase station also remains available in Perception. Repeat a short movement with both hands, then let the fitted paths replay. The sphere follows a midpoint between them. It shows a relation that neither hand makes alone.

The path was fitted from your performances. At each of forty-one moments, the learner kept an average. There may be no performance among your takes that follows that average exactly. It can be a useful common path without being the original, the best, or the one you intended most strongly.

A learned limit admits some variation. Try a new performance without teaching again. A hesitation may fit; a longer pause may not. Here comparison keeps a fixed four-second duration and checks corresponding times. It does not stretch one performance to align with another. That choice makes timing inspectable, but it also means a rejection can concern our clock rather than a failure of the movement.

Both hands must participate, and each is checked separately. This preserves a distinction that a single combined score could lose: one hand can match while the other does something else. It also makes a demand on the person using the study. The demand belongs to this designed exercise; it does not establish what a body ought to do. A different encounter might need another duration, another representation, or another relation between the hands.

Stay with one phrase long enough to distinguish its recording, its average and a fresh test. We can return to the same table for another task. Teach the reverse as a second phrase. An unfamiliar movement can now receive a name. The change is not a discovery that it was secretly wrong before and right afterward. You changed what the system had evidence for.

Then give almost the same phrase two names. Both models may accept it. The program can withhold a choice as ambiguous, separately from finding neither phrase familiar. That difference matters. More insistence on a confident answer would not resolve a distinction absent from the examples.

The preview and the test also do different work. A replay draws the fitted path for you to follow. A fresh test asks what the model can recognise without putting that answer in front of your hands. Once you rehearse from the preview, that encounter is part of the next performance's history too. A clean separation between teaching and testing is something we arrange; it is not supplied by the word “test”.

<!-- @lstms_vr -->

The gate cell offers another way to keep a past. Its spheres set what to retain, what to admit and what to expose. Carry two pale tokens through from a cleared state. Then clear it and carry a dark token followed by a pale one. Both histories end with the same input; the output can differ.

With all three gates at one half, the two pale tokens leave the displayed value at 0.375; dark then pale leaves 0.125. Lower the forget gate to zero and the difference disappears: only the current input remains. The readout lets you check the arithmetic before deciding what to make of the word “memory”.

Those gates are set by hand. This cell does not learn, and its linear rule is not a trained LSTM. The phrase prototype does learn from examples, but keeps an explicit timed path rather than a recurrent hidden state. One word can connect the two encounters without making their mechanisms interchangeable.

<!-- @ -->

The same care returns to the dance. Remembering controller positions does not preserve the whole significance of a phrase. Yet those retained positions can make a new encounter possible: a body teaches, the sphere returns a path, and the body changes its next attempt in relation to that return.

Generative asks what happens after keeping. A replay of this fitted path is still a replay. Before calling a new result an invention, we need to follow what produced it.


---

<!-- Canonical chapter: commons/maps/ML_Generative/final.md -->

# A movement nobody quite made

The sphere traces two paths. They resemble your hands, but the movement is not one you recorded. One arc lifts a little higher; the other follows a difference that accompanied it in your examples. Watch the whole phrase before deciding what has changed.

In the previous room, repetition taught an average route through time. This study keeps the differences too. Each performance departs from the mean in a particular way, and both hands belong to that departure. The generator gives those departures new amounts. Its possibilities come partly from what you offered and partly from a distribution chosen for the program.

Compare the first recording, the mean and a generated sample. The recording has an occasion: you moved. The mean has a calculation. The sample has a seed and a fitted set of variations. Their paths may look similar, while their histories differ. Even the average may be a movement nobody performed exactly.

The same sphere carries all three. That continuity helps us notice the change of operation, but it can also lend a new result the familiarity of an old object. Nothing in its shine tells us whether we are watching a kept trace or a generated one. The controls name the difference because appearance cannot reliably do that work.

Try a seed you do not like. A surprising crossing may be awkward, useful or simply uninteresting. The model has no measure for that judgement. Its preview checks coordinate bounds and asks that both hands move; a body might still find the path difficult. Nor does withholding a path make it worthless. What the display permits and what you might want to try remain different decisions.

Change the examples, then hold the seed still. The result changes because its field of possible differences has changed. If every example repeats the same coordinates, another seed brings no variation. With three takes, this construction has at most two independent directions in which to depart from its average; three very similar takes may offer only one. Many seeds can produce many paths without opening a new direction. That limit belongs to this construction. It does not settle what every generative system could learn, or what a person might discover while responding to one.

Your demonstrations contain deliberate choices alongside fatigue, hesitation and tracking noise. The generator does not know which differences you meant to teach. Watching its variation may help you notice a habit, or suggest a movement you then make your own. That return from generated path to performed movement changes the conditions of the next recording. The study keeps generated output out of its teaching set unless a person makes and records a new performance.

<!-- @generative_adversarial_networks_gans_vr -->

Across the room, the generator and discriminator diagram proposes another relation: a learner whose critic is also learning. Follow where a candidate would originate and where a judgement would return. Its moving scores are scripted; this exhibit does not train those two networks. Our working hand-path generator does fit data, but it has no learned opponent. The two displays offer different kinds of evidence.

In the proposed adversarial exchange, the discriminator learns to distinguish reference examples from generated ones while the generator learns to make that distinction harder. Improving either participant changes the problem faced by the other. They do not share a single meaning of improvement. A falling score needs the examples and the opponent beside it before it can tell us much.

That relation also raises a question our small study leaves open. Who supplies the reference, and what happens to a useful movement that the reference makes difficult to recognise? Repeating one convincing candidate and producing a varied set are different accomplishments. Neither alone says whose possibilities have expanded.

<!-- @ -->

Keep one comparison: what you supplied, what the program produced, and what you wanted from it. In the next room we return to the two phrases taught in Sequence Memory. The generated movement may prompt a new performance, but it is not silently added to those teaching examples. An intention will meet an answer. Their agreement can be investigated; so can their distance.


---

<!-- Canonical chapter: commons/maps/ML_Synthesis/final.md -->

# What I meant, what it answered

Before moving, choose what you intend: A, B, or neither. Then give the sphere a fresh phrase with both hands. It returns an answer. Your declaration stays beside it.

A disagreement has not yet told us who or what failed. You might have performed differently from what you meant, selected the wrong intention, or moved in a way the six recorded coordinates describe poorly. The teaching examples might have made A and B hard to separate. Keeping the two accounts gives us somewhere to begin looking. Replacing your declaration with the model's answer would close that inquiry too soon.

The sphere is familiar now. It has been a point we could hold, a recorder of our hands and a companion to generated movement. Familiarity can make its answer feel more intimate than the comparison it performs. Here the code holds that comparison still: two timed prototypes, their tolerances, a rule for uncertainty. The person who encounters it brings much more than those measurements.

Read the table without asking it for a single score. UNKNOWN means neither taught phrase was accepted. AMBIGUOUS means both were plausible under this rule and too close to choose. If you meant neither, acceptance as A is another kind of disagreement. These situations call for different investigations. Turning them all into failure would lose the distinctions the instrument can actually offer.

The checks belong to particular models. Revise the teaching, then return: the earlier answers remain beside the examples and fitted paths that produced them. This does not prevent change. It gives a change a history. A later agreement need not make an earlier difficulty disappear, and a present limit need not become a claim about what no future model could do.

In Generative, a new path could emerge from differences among your performances. It might prompt a movement you wanted to try. Here we can record the attempt and its intention separately. A path's plausibility, its recognisability and its value to the person performing it remain different questions. The study does not let a generated example quietly become evidence that the recogniser works.

<!-- @anomaly_detection -->

Now find a raised, enlarged point in the anomaly exhibit. Before interpreting it as an error, compare it with an unflagged neighbour and read the active mode. Which numerical comparison put it above the threshold?

In the default mode, the exhibit measures displacement from the sample mean along each coordinate, scales each displacement by the spread on that coordinate, then adds their absolute values. Points meeting the threshold are lifted and enlarged. A numerical decision becomes a spatial distinction.

The pale disc is a rough marker at the average spread, not the boundary. The actual boundary is a diamond in standardised coordinates. A point displaced along both coordinates can cross it differently from one displaced mainly along one. Follow the arithmetic before relying on the appearance of being far from a centre.

The generated outer points are included in the statistics with the central cloud. The population defining the reference therefore includes observations it may subsequently flag. A flag tells us about a point's relation to this population and rule. It does not decide whether the point is an error, a rare valid case or something worth investigating. The alternative mode labelled autoencoder error also uses a hand-written geometric formula here; the label alone is not evidence that an autoencoder was trained.

Choose one flagged point you would keep. State what further observation would help you understand it. Your declared intention was additional information in the hand study. Something equally relevant here may lie outside the coordinates on display.

<!-- @ -->

The moving creature elsewhere in this hall supplies another comparison. Its joint controller updates from a distance-based reward, with a bonus for movement along one direction. That measure differs from your labels, the cluster centres' geometry and the conditions under which the bodies in the first hall persisted. Calling all of these learning does not make their measures interchangeable. The reward's direction, like the phrase's clock, is something someone supplied.

The project making these rooms also uses AI. The reconstruction tests can show that the printed programs run and meet specified assertions. They cannot establish that we chose the right lesson, represented the encounter well or explained everything worth learning. Those decisions remain open to a reader who points to something our test did not ask.

The small learners here expose every parameter and the examples used to fit them. They do not give us the same view into the language model that helped write this book. We can retain its proposed edit, inspect the changed source and run a test; that record still does not expose all the conditions that produced its answer. During this sequence, a printed Gradient example passed a headless test while a rendered test caught its sphere returning to an old position. The later observation changed what we could claim. It did not make the earlier test fraudulent or the whole system understood.

Foundations Crisis follows. Bring that difference between a working answer and the evidence available for it, along with the rule, the observations and the unresolved disagreement. There is more to investigate when they remain distinguishable.
