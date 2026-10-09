# postfoundationscrisis: the chapters

## CriticalAlgorithms Algorithmic Bias Visualization

*CriticalAlgorithms_Algorithmic_Bias_Visualization*

# Less room for a distinction

Which differences become difficult to recognise when a representation gives some words less room?


Choose two warm-coloured labels and keep both in view while moving COMPRESSION. Compare their changing separation with two grey labels. Stop partway through the movement and notice which words are still easy to distinguish individually. Keep the handle still and move your head. What changes now?

The warm group compresses into a smaller region while the grey group spreads and moves away. The words themselves remain. Their colours and brightness stay fixed while the space available to tell them apart changes. Presence in a representation is therefore different from being represented with useful distinctions.

The source makes the operation inspectable:

```gdscript
var pos := _marginalized_positions_default[i].lerp(
    _marginalized_positions_compressed[i], blend
)
var xf := Transform3D.IDENTITY
xf.origin = pos
_marginalized_multimesh.multimesh.set_instance_transform(i, xf)
```

The index i keeps a word attached to its two authored positions. lerp blends those positions; blend chooses how far the word has travelled. The same operation learned in transformation can make a distinction easier or harder to see. The handle changes the represented geometry. Moving your head gives you another view of it. Those are two different changes.

An embedding places items in a numerical space so that relations between positions can be used in later calculations. This exhibit stages an authored analogy for that operation. Its positions interpolate between two designed arrangements; they are not measured coordinates from a trained language model. The slider changes the geometry rather than retraining a model or changing only your camera.

That limitation helps keep the question exact. The piece can show what spatial compression does to your ability to separate its labels. It cannot, by itself, establish the distances those same words occupy in an actual system. An empirical claim would need a named model, a documented measurement and a comparison that someone else could check.

Press READ when you are ready to consider the grouping. Both groups were chosen. Now scrutinise the groups chosen for the sculpture. Words such as “queer”, “disabled” and “refugee” do not name interchangeable experiences. Nor are “normal”, “professional” and “objective” equivalent claims. The exhibit risks repeating a flattening if its two colours become a sufficient account of everyone they contain.

Choose one distinction within a colour that you want the representation to retain. For a future version, compare several groupings and ask the people represented which distinctions matter to them. Greater distance alone will not guarantee a better account, but it can make an otherwise hidden question available.


The applied-ethics room moves from word positions to furniture. A plan can distribute the ability to participate before anyone begins speaking.

---

## CriticalAlgorithms Applied Ethics

*CriticalAlgorithms_Applied_Ethics*

# Before the first person speaks

Who does this room make easiest to address?


Begin with HEAD. One miniature room waits on the pedestal. Before anyone speaks, where does your eye place the speaker? Walk around the model and compare the large chair at the end with the smaller ones beside the table.

Press CIRCLE. Choose one position and imagine speaking from it. Trace the distances to the others. Then press PAIR to see both plans together. The models become smaller so they fit beside each other; the panel stays where your hand left it.

The long table gives one position a conspicuous role even while every chair has the same colour. Its six smaller accompanying chairs carry less visual weight. The other model places six equal chairs around a round table. The comparison changes more than an outline on the floor: it changes relative size, position and the implied relation between participants.

The source makes the operation inspectable:

```gdscript
for i in 6:
    var a: float = TAU * float(i) / 6.0
    var chair := _make_chair(chair_color_distributed)
    chair.scale = Vector3(s, s, s)
    chair.position = origin + Vector3(cos(a) * 0.4 * s, floor_y + 0.1 * s, sin(a) * 0.4 * s)
    _add_part(chair)
```

Six iterations divide a full turn, TAU, into equal angles. cos and sin place each chair on a ring around origin. The little circle carries the arrays, transformations and waves we have already learned. Equal spacing is what this loop guarantees. Equal opportunity to speak would require another kind of evidence.

These are affordances and invitations. A head position can make it easy to identify a speaker; a circle can support addressing several neighbours around a shared centre. Neither miniature contains actual speech, listening or an agreement about whose turn comes next. The geometry proposes conditions under which those activities might happen.

Leave PAIR in place and press COLOUR. No chair moves. Red now singles out authority; green recommends the distributed arrangement. Does the room seem to have made up its mind? Press NEUTRAL again and see what remains of that judgement. Looking critically at a model includes looking at the persuasion built into its presentation.

Find one use for the head position that you would preserve, then one difficulty the circle would not automatically solve. A designated interpreter, a speaker who needs a clear sightline or someone who cannot easily turn towards every other participant can complicate the familiar good-circle story. These possibilities call for observation with people, not a verdict from chair shapes alone.

WATCH puts another arrangement beside the long table: eight backed seats face outward around a raised centre. Follow one seat’s direction with your eyes. The ring has returned, but its invitation has changed. There is no watcher inside the model; the arrangement gives you a question to take to one.

Return to PAIR, then press VACANT. The furniture goes; the walls remain. An empty room still has sides, an opening and a scale. Removing the chairs has not removed every decision.

A future version could compare actual sightlines and turn-taking across the two plans. The ethical question would become a design question with observable consequences: which participant gained access, which difficulty remained, and what change should follow?


The next room lets two requirements meet without immediately deleting one. Participation can be shared while the resulting claims still conflict.

---

## SpeculativeComputation Paraconsistent Engineering

*SpeculativeComputation_Paraconsistent_Engineering*

# Keeping the disagreement visible

Must one account disappear before two accounts can share a system?


Trace branch A and branch B towards the lit junction. Look from the side. The light hangs between them, but do the branches actually meet? Press MARKER to take the glow away. Before deciding which branch should win, give each one a source and a reason to have arrived there.

Press OVERLAP. The feet keep their places while the branches lean inward and pass through one another. Walk around the crossing. Nothing has been cut to make room. The renderer lets both forms remain; deciding what their meeting means is still ahead of us.

The sculpture keeps two versions present around a conflict marker. It does not merge actual files or execute rules of logical inference. Its useful first gesture is spatial: an unresolved relation can be represented without erasing the parts that made the relation difficult.

The source makes the operation inspectable:

```gdscript
func _build_resolved() -> void:
    _build_pillar(branch_a_color, Vector3(0, 0, 0),
        Vector3(0.2, pillar_height, 0.2), "branch A", 0.0, false)
    _build_pillar(branch_b_color, Vector3(BASE_X, 0, 0),
        Vector3(0.2, RESOLVED_STUMP_H, 0.2), "branch B", 0.0, true)
```

Before pressing RESOLVED, choose what you would keep. Then look down for B. A keeps its full height and takes the centre; B becomes a labelled stump. Did the decision agree with yours? The two builder calls make resolution visible as a change in what remains. That is an authored picture of a decision, not a proof that the decision was warranted.

Press FORK. Both branches regain their height and lean apart. If the marker is visible, it has dropped between their feet. Distance has changed; no new reason has been given for either account. Return to OVERLAP when you want to see what settlement shortened.

Try a concrete disagreement. One report says a door is open; another says it is closed. Adding times may reconcile the reports. Adding the door’s identity may reveal that they concern different doors. Preserving provenance gives us ways to investigate before treating every difference as a contradiction about the same thing at the same time.

Formal paraconsistency concerns the inference rules themselves. In a paraconsistent logic, a contradiction need not license an arbitrary conclusion. It does not mean accepting every claim or abandoning the distinction between supported and unsupported inference. [Basu and Roy’s research paper starts from this failure of explosion when developing more general definitions.](https://arxiv.org/abs/2112.00357)

The current junction is an analogy for retaining a conflict, not a demonstration of that formal property. The next useful addition would expose a small rule table: after entering both a proposition and its negation, which consequences remain available, and which unrelated conclusion still cannot be derived?

Return to RESOLVED and find the small name beside B. A label remains, but it tells us little about what has been lost. What information should remain so the decision can later be reconsidered? Keeping a source, a date and the rejected alternative does not make revision automatic, but it prevents a settled display from hiding how settlement occurred.


Situated computation takes up that provenance. Four panels will judge one subject differently, and their positions will become part of what the judgement tells you.

---

## SpeculativeComputation Situated Computation

*SpeculativeComputation_Situated_Computation*

# Four verdicts about the same subject

What changes when the subject stays the same but the source of the judgement changes?


Begin with FOOTNOTE on the four inward-facing panels. Read the subject identifier on each. Keep it fixed in your comparison, then note the verdict, the confidence and the small address below. Look back at the first panel after reading the others: it has not become a different subject because another description is available.

SUBJECT #4729 appears as ORDERLY, CREATIVE, DANGEROUS or IRRELEVANT across the four positions. The associated percentages differ too. The room makes a judgement’s location visible instead of presenting one description as if it came from nowhere.

The source makes the operation inspectable:

```gdscript
var pos := global_position
var key := _resolve_quadrant_key(pos)
var verdict: Dictionary = QUADRANT_VERDICTS.get(key, QUADRANT_VERDICTS["NW"])

_verdict_label.text = verdict.label
_verdict_label.modulate = verdict.color
_confidence_label.text = "confidence %d%%" % int(verdict.confidence * 100.0)
_footer_label.text = "view from %s (%.1f, %.1f)" % [key, pos.x, pos.z]
```

The dictionary supplies a verdict and a confidence; the footer supplies a location. There is a revealing extra decision: this hall explicitly assigns NW, NE, SW and SE through its map tokens. That override takes precedence over the position-based fallback. The four-way disagreement has been composed for us. The percentages have not been earned by measuring the subject.

These are four authored readouts. Each panel retains the verdict assigned to it; your movement changes which panel you read. The percentages are supplied examples, not calibrated probabilities calculated from evidence about a real person. A high number in this room therefore cannot establish that its description is more trustworthy than a lower number.

Stay with DANGEROUS. Read its 92%, then press COVER. A strip lies across the address. The verdict and the number remain. Has the claim become easier to accept, or harder to ask about? Press FOOTNOTE to uncover the place it was speaking from. Nothing new has been learned about the subject.

Now press WITNESS. The panel acquires a marked base, a height rule and an eye above it. Walk to its side. This eye has no sensor; it is part of the frame. Does giving the claim a visible body make you trust it more? Its 92% has still earned no additional evidence. Return to FOOTNOTE and take that suspicion to another panel.

Separate four parts of a claim: the subject, what is asserted, how certain the speaker appears, and the conditions under which the assertion was produced. Keeping the subject constant helps expose changes in the other parts. It does not imply that all four predicates have the same meaning or answer the same question.

Choose DANGEROUS and ask what evidence would make that judgement accountable. Dangerous to whom, under which circumstances, and according to what consequence? Then apply an equally precise question to CREATIVE. A favourable word also needs criteria; situatedness is not a licence to stop checking an appealing claim.

For the room’s next experiment, each panel could reveal a distinct criterion and the observation it used. A visitor could then compare disagreement caused by different evidence with disagreement caused by different definitions. The current four views supply the scaffold for that comparison.

A small spider moves among the readouts. It can notice and follow you; its controller can bite. The panels do not direct this creature, and their confidence numbers do not describe its behaviour. For now, keep the two encounters distinguishable: an assigned judgement on a screen, and a rule that acts on a body. What would we need to observe before calling either one dangerous?


Collective knowledge asks how contributions from different positions can become a common object without losing the evidence and disagreement that make it revisable.

---

## SpeculativeComputation Collective Knowledge

*SpeculativeComputation_Collective_Knowledge*

# More contributions than contributors

When many marks accumulate, what makes the result knowledge rather than a pile?


Follow a packet from one of the rim nodes into the central structure. Watch the new facet appear. During one growth cycle, compare a contribution from a node you have already seen with one from a new source. The number of contributions and the number of contributing sources need not increase together. Press FLOW to hold the arrivals. The work can wait while you look.

The exhibit turns contribution into an arrival event. A packet comes from one of twelve positions and adds a piece to a shared form. At sixty pieces this workbench holds its form until you choose VERSION; FLOW starts the arrivals again. Its visible coherence comes from an assembly rule that knows where to place each arriving facet.

Press COLOUR. The smooth progression from purple to teal gives way to the colours of the sources. Nothing has moved. Some pieces that looked like neighbours now belong to different contributors; distant pieces may share one. Press PIECE to follow a piece back to its numbered rim node. The common form has kept an address for each arrival.

The source makes the counting operation inspectable:

```gdscript
_placed += 1
_edits += 1
# count distinct contributors this version
if peer_idx >= 0 and peer_idx < _seen_peers.size() and not bool(_seen_peers[peer_idx]):
    _seen_peers[peer_idx] = true
    _contributors += 1
```

Every accepted facet increments the addition count. The Boolean array _seen_peers lets the same source count only once within a version. On the next version those flags clear while the totals persist. In the earlier display, a number labelled CONTRIBUTORS could therefore outgrow the twelve source positions. That number is now called PARTICIPATIONS. SOURCES counts distinct nodes in this version; EVER counts distinct nodes across versions. The old discrepancy was useful: it showed how a label could quietly turn repeated attendance into an expanding community.

That is a simulation of accretion, not a live collaborative editor. The peers are generated positions rather than people logged into the museum, and the incoming material is accepted without a dispute over its content. The animation demonstrates one way many sources can feed one object while leaving the harder question of validation open.

Collective knowledge needs more than participation counts. A contribution may repeat an error, correct an earlier claim, supply a missing case or disagree with an accepted account. Those actions can add little to a simple count while changing the usefulness of the shared result dramatically.

The previous room kept four viewpoints separate. Here the common centre can make their differences disappear into a continuous object. Switch COLOUR back to ORDER, then recover a piece with PIECE. Its source remains in the record even when the surface no longer shows it. Does the shape preserve a reason for accepting that contribution, or only the fact that something arrived?

Choose a piece and press DISPUTE. Its frame turns red. Press REVISE and watch that same piece turn and change height. The pile has not gained a piece; the revision count has increased. The source is still named, and the change is attributed to VISITOR. The red frame stays. A change has happened, but who agreed that the dispute was settled?

Here revision is a geometric operation we have supplied. It has no evidence to weigh and no argument to answer. The original and previous poses remain in the record, but there is no complete history you can browse. Keeping a name and a trace makes reconsideration possible; it does not perform the reconsideration for us.

Before pressing VERSION, look once more at the disputed piece. The next form starts empty. Its current source count begins again while additions and participations carry on; EVER does not count an old source as a new one. The device keeps only the previous version in memory. What would have to survive for someone else to understand why you changed that piece?


The rhizome will make the pattern of connection itself grow. A shared result can have many contributors while its network still develops uneven centres.

---

## SpeculativeComputation Rhizome Network

*SpeculativeComputation_Rhizome_Network*

# Another way through


From outside, you can follow several passages with your eyes. One rises across another. Openings disappear into the tangle. There seems to be a way through.

Inside, the wall takes away that view. The passage divides. A coloured light gathers at a junction; further on, another opening offers another direction. You can leave a place and find it again without walking back along the way you came.

Try returning to the violet light by a different passage. What did you recognise first: the colour, the opening, the direction from which you expected it? A place can become familiar before you can draw its position in the whole.

We began with a line to walk. Here the line divides and meets another. The return is possible because the connections contain a circuit. A branching tree could offer many directions too, but, if its branches never rejoin, coming back would require retracing part of your route. One added connection can change what a journey is.

Above the lower passages, a longer route climbs and comes down elsewhere. From outside, two paths may seem to intersect. Inside, one passes over the other. You cannot turn at that crossing. Nearness is not yet a relation you can enter.

The distinction has followed us from the drawn line. A crossing on a screen may conceal a difference in depth. The triangle gave a surface to the image; here the surface surrounds you, supports your feet and keeps two journeys apart. The engine must decide where it holds. Your body encounters that decision as a floor, a slope, a wall.

These passages begin as connections between positions. For this encounter, their junctions and heights have been composed so that we can walk several returns, including the upper crossing. The small growing network nearby follows a different rule. It has not secretly designed this cave.

To give a connection room, the cave calculation opens a volume around it. Where two such volumes meet, their interiors join. There must be no leftover wall sealing the junction. A small line of code performs this union:

```gdscript
air[index] = minf(air[index], passage)
```

Each sample holds a signed value: negative inside a passage, positive outside it. The smaller value lets either passage admit the sample. The surface extractor finds the boundary afterwards. A line becomes a volume; overlapping volumes can become a shared interior.

But the width matters. Make a passage wider and it may meet a neighbour that its centre line never touched. Make it narrower and the drawn connection can remain while the body loses its way through. We have not escaped geometry by drawing a network. We have acquired another place to work on it.

Deleuze and Guattari give the rhizome multiple entryways and connections between unlike things. Their map is something that can be made and altered in contact with the world.[^SpeculativeComputation_Rhizome_Network--1] The invitation exceeds this cave. We can enter its relations and choose among them; we cannot yet make a new opening in its wall. That is a desire the encounter can produce. Where would you put one? Which two places would become neighbours?

There is pleasure in finding another way. There can also be shelter in the turn that takes you out of sight, or company at a junction where separate routes arrive. These possibilities give a connection more than one use. A space can be legible to a drawing and still hold something for the body to discover.


The small grower offers a different kind of arrival. A new point appears and reaches towards points already there. An older point can receive a relation it could not have anticipated. The newcomer cannot reach into its own future.

Hold the growth and compare one link with three. The positions stay. Some of the ways between them disappear. You have changed no point's address, yet moving through the network would be a different undertaking.

Here we can inspect the rule more closely. Each arrival chooses nearby earlier points. There is no declared root, but proximity and time still make some points more available than others. Removing a busy point asks a further question: which relations survive without it? The model can restore the point and its former links. Inventing a new connection would be another act.

The ring does not spread with the shoots. The machine keeps finding new places inside a boundary it chose before the network began. Something is growing, but its territory has already been given.

That boundary is easier to see at this scale. Inside the cave, its equivalent was a wall. We can enjoy what these rules make possible and still want to change where they stop.


The museum has an onward direction. You have just spent time returning, approaching from another side, making a route that was yours to choose. Carry that desire into the assembly laboratory. There, the available parts will ask what other body they could become.

[^SpeculativeComputation_Rhizome_Network--1]: Gilles Deleuze and Félix Guattari, *A Thousand Plateaus*, translated by Brian Massumi (University of Minnesota Press, 1987), “Introduction: Rhizome,” especially pp. 7–15. Connection, heterogeneity, rupture and a modifiable map extend beyond the shape of a branching object. The cave offers a material experiment in passages and returns; it does not make a network's complexity a guarantee of freedom.

---

## AdvancedLaboratory Lab Equipment Simulation

*AdvancedLaboratory_Lab_Equipment_Simulation*

# Where a body is expected


A hand waits at the end of an arm. Take it a little farther than an arm ought to reach. The elbow stays behind. The slender connection follows, becoming longer. Let go.

The body keeps your alteration.

It stands close to your height, with warm metal joints and just enough between them for you to recognise shoulders, knees, a head. You may already have begun correcting it. Bringing the hand back. Making the two sides agree. Nobody in the room asked for symmetry; perhaps you brought that instruction with you.

Try leaving the hand somewhere else. Move around the body. From one side it is reaching; from another, falling. Lower its head towards the hand. A few displacements make a gesture, and the gesture makes you read the whole arrangement again. The little spheres have no expression. Where did the expression enter?

Across the floor, a larger assembly is finding its places without you. Scattered pieces approach one another. Lines join them. A body appears, or a chair, and later something with more legs. The unused pieces gather along the wall. Stay long enough to see an arrangement loosen and another begin.

One piece carries an amber ring. Follow it. The ring stays with the same carrier, but the shape inside can change. What was a sphere can become a panel. A torso and a seat need not be made from different stuff here; the program gives one instance another mesh and another job. If the next arrangement needs more carriers, it can make them. This inventory has permissions that a cupboard of physical parts would not have.

Yet the apparent freedom has a destination. Before a piece begins to move, its place has been written in the assembly file. The approach uses a restoring force we met earlier:

```gdscript
var to_target = target_pos - global_position

velocity = (velocity + to_target * dock_spring * delta) * dock_damp
global_position += velocity * delta
```

The first line measures the difference between where the piece is and where it is expected. That difference changes its velocity; velocity carries it towards the expected place. There is movement to watch, an approach to wait for. The destination has not been discovered by the moving piece.

A body can look as though it is coming into being while it is coming into agreement with a description.

Return to the joint you moved. Here your hand supplies a different destination. Its position is recorded in the little body's own coordinates:

```gdscript
targets[index] = to_local(handle.global_position)
```

We are back with a point, a local space, a line between points. The first rooms have not been left behind. You now have enough of their operations to move a hand without moving a shoulder, to lengthen a forearm, to put a knee where this figure has never had one. Let go and the pose remains while the other assembly continues its cycle. There is time to walk around what you have done.

There is also a useful resistance to notice. Moving the hand does not pull the elbow after it. The gold connection follows its endpoints, but it does not enforce the length of a bone. This model can hold a gesture your muscles could not sustain. What looks like a limb is, here, a declared relation drawn across a distance.

The body began with thirteen joints and twelve connections. Those connections remain when you stretch it. You have changed its geometry; you have not yet given it another way to connect. To grow an extra arm would require more than moving the existing hand. The desire is easy to feel before the missing operation is easy to name.

In the source, the hand is still called `l_hand`, wherever you put it. A name can survive the proportions that made it seem obvious. How far can this arrangement travel from its familiar outline before you cease to see a body? And how much of that limit belongs to the arrangement, rather than to what you have learned to recognise?

The rhizome gave us passages through connections. Here a connection helps something become legible as a body, and your own body reaches into that description. The catalogue offers spheres, rods and panels. The assembly supplies roles and neighbours. You have been allowed to revise positions. Each permission opens a different part of the question: what bodies are possible?

Eventually a joint meets the edge of its working space. There is still a room around this experiment, a limit someone supplied. You can want another connection, a different part, more room. The useful next question is which of these your desired body needs.


Leave the pose a little unlike the one you found. Releasing a changed joint now keeps it for the final hall, where the pose will stand beside the one this body began with. You can leave the room and meet the difference again. What will have survived the journey?

---

## PostCrisis Synthesis

*PostCrisis_Synthesis*

# The body that returned


Look for the hand you moved.

It has crossed the threshold without making the journey. Beyond the ledger, an amber body holds the last pose kept in the Assembly Laboratory. The blue body beside it holds the starting arrangement. Walk between them. The elbow, the lowered head, the hand left too far away: a difference you made in another room can now be met from another side.

If you came straight here, the amber space will be empty. There is a place for a record, but no pose has yet been kept. That emptiness belongs to the work too.

The two bodies need not be dramatically different. Perhaps you moved one hand and decided that was enough. Perhaps you made the figure almost unrecognisable. Each still has thirteen joints and twelve connections. The totals agree. The bodies may no longer seem to.

At the beginning of the museum, a counter was already running before we could read it. We could follow its increase without knowing everything that had happened. Here a count of released edits tells us that someone did something. Looking from one body to the other lets us ask what changed. Neither tells us why.

The amber figure was made again from a record of positions. The program did not need to remember how your hand found them. A hesitation, a sweep around the head, an accidental drop: several different gestures can finish at the same coordinates. The figure keeps the destination. You may still feel the movement that is absent from it.

The hand has arrived. Your hand is missing.


Come close enough to read the ledger. It names the Assembly Laboratory, gives the time of the last kept change, counts the joints displaced from their starting places, and reports that the twelve connections remain. Its account comes from the same record as the amber body. Waiting in front of it does not add another achievement.

After a changed joint is released, the program writes its record:

```gdscript
file.store_string(JSON.stringify(record,"\t"))
```

The line is short because the choice of what to remember has already been made. The record contains the starting and released coordinates, the named joints and their connections. Those are enough to reconstruct this pair. They are not enough to reconstruct the encounter between your body and the figure.

Earlier, drawing a trace meant choosing which positions of the hand could be retained. Here we have chosen less: a destination after release. The missing path saves work and storage. It also closes a question. From this record alone, we cannot ask whether the hand moved carefully, reluctantly or with delight. Increasing the precision of its final coordinates would not recover the movement.

The choice is useful. It lets a change survive the room that produced it. It lets you return to the Assembly Laboratory and find the pose again, ready for another alteration. But usefulness does not settle which questions ought to remain possible.

What would you want the record to keep next? The path of the hand might let you compare two ways of arriving. Another version of the pose might let you undo a decision without having to imitate your earlier self. A note might keep the reason you tried it. Each addition would make another kind of return available. None would keep the whole event.

For now, the ledger holds one latest pose. Another released change replaces it. It is labelled as the last kept pose; it does not identify who made it. Before calling a record ours, we have to ask what connects it to us.

There is another absence you can see without opening the file. The amber body can have a longer arm, but it still has the same connections as the blue one. The previous room allowed you to revise positions. It did not yet allow another hand to grow. The record preserves that permission and that limit together.

Or remember a form you wanted to enter. A branch with no passage through it, a body you could see but could not inhabit. The question need not begin with a fault. Desire can also locate the next piece of work. What would have to change for that encounter to become possible?

Choose one alteration you still want to make. Give it somewhere to happen. A new connection in the body; a passage through the branch; a memory that keeps two alternatives. We can build the operation, then discover what its arrival changes. A possibility that helps one body may obstruct another. The next encounter is where that consequence becomes something we can inspect.


This is a place to turn around. You have a body to return to and enough of its construction to ask for something it cannot yet do. The ending leaves that request open.

The clock is still running. There is something you wanted to make.

---
