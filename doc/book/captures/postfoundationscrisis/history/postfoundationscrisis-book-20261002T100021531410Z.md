# postfoundationscrisis: the chapters

## CriticalAlgorithms Algorithmic Bias Visualization

*CriticalAlgorithms_Algorithmic_Bias_Visualization*

# Less room for a distinction

Which differences become difficult to recognise when a representation gives some words less room?


Choose two warm-coloured labels and keep both in view while moving PERSPECTIVE. Compare their changing separation with two grey labels. Stop partway through the movement and notice which words are still easy to distinguish individually.

The warm group compresses into a smaller region while the grey group spreads and moves away. The words themselves remain, but the space available to tell them apart changes. Presence in a representation is therefore different from being represented with useful distinctions.

The source makes the operation inspectable:

```gdscript
var pos := _marginalized_positions_default[i].lerp(
    _marginalized_positions_compressed[i], blend
)
var xf := Transform3D.IDENTITY
xf.origin = pos
_marginalized_multimesh.multimesh.set_instance_transform(i, xf)
```

The index i keeps a word attached to its two authored positions. lerp blends those positions; blend chooses how far the word has travelled. The same operation learned in transformation can make a distinction easier or harder to see. The script calls this perspective, but it changes the represented geometry. It is not a camera command.

An embedding places items in a numerical space so that relations between positions can be used in later calculations. This exhibit stages an authored analogy for that operation. Its positions interpolate between two designed arrangements; they are not measured coordinates from a trained language model. The slider changes the geometry rather than retraining a model or changing only your camera.

That limitation helps keep the question exact. The piece can show what spatial compression does to your ability to separate its labels. It cannot, by itself, establish the distances those same words occupy in an actual system. An empirical claim would need a named model, a documented measurement and a comparison that someone else could check.

Now scrutinise the groups chosen for the sculpture. Words such as “queer”, “disabled” and “refugee” do not name interchangeable experiences. Nor are “normal”, “professional” and “objective” equivalent claims. The exhibit risks repeating a flattening if its two colours become a sufficient account of everyone they contain.

Choose one distinction within a colour that you want the representation to retain. For a future version, compare several groupings and ask the people represented which distinctions matter to them. Greater distance alone will not guarantee a better account, but it can make an otherwise hidden question available.


The applied-ethics room moves from word positions to furniture. A plan can distribute the ability to participate before anyone begins speaking.

---

## CriticalAlgorithms Applied Ethics

*CriticalAlgorithms_Applied_Ethics*

# Before the first person speaks

Who does this room make easiest to address?


Walk around the two miniature rooms. In the long-table plan, locate the head chair and compare its size with the other chairs. In the circular plan, choose one seat and imagine speaking from it. Trace the distances to the other positions rather than simply choosing the greener model.

The long table gives one position a conspicuous role. Its six smaller accompanying chairs carry less visual weight. The other model places six equal chairs around a round table. The comparison changes more than an outline on the floor: it changes relative size, position and the implied relation between participants.

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

Notice how the exhibit colours its own argument. Red singles out authority; green recommends the distributed arrangement. That visual judgement arrives before you have tested whether the plan meets a particular group’s needs. Looking critically at a model includes looking at the persuasion built into its presentation.

Find one use for the head position that you would preserve, then one difficulty the circle would not automatically solve. A designated interpreter, a speaker who needs a clear sightline or someone who cannot easily turn towards every other participant can complicate the familiar good-circle story. These possibilities call for observation with people, not a verdict from chair shapes alone.

A future version could compare actual sightlines and turn-taking across the two plans. The ethical question would become a design question with observable consequences: which participant gained access, which difficulty remained, and what change should follow?


The next room lets two requirements meet without immediately deleting one. Participation can be shared while the resulting claims still conflict.

---

## SpeculativeComputation Paraconsistent Engineering

*SpeculativeComputation_Paraconsistent_Engineering*

# Keeping the disagreement visible

Must one account disappear before two accounts can share a system?


Trace branch A and branch B towards the lit junction. Inspect what remains visible on either side of that meeting point. Before deciding which branch should win, give each one a source and a reason to have arrived there.

The sculpture keeps two versions present around a conflict marker. It does not merge actual files or execute rules of logical inference. Its useful first gesture is spatial: an unresolved relation can be represented without erasing the parts that made the relation difficult.

The source makes the operation inspectable:

```gdscript
func _build_resolved() -> void:
    _build_pillar(branch_a_color, Vector3(0, 0, 0),
        Vector3(0.2, pillar_height, 0.2), "branch A", 0.0, false)
    _build_pillar(branch_b_color, Vector3(BASE_X, 0, 0),
        Vector3(0.2, RESOLVED_STUMP_H, 0.2), "branch B", 0.0, true)
```

There is a second arrangement in the source that this placement does not show. In resolved, A keeps its full height and B becomes a labelled stump. The two builder calls make resolution visible as a change in what remains. That is an authored picture of a decision, not a proof that the decision was warranted.

Try a concrete disagreement. One report says a door is open; another says it is closed. Adding times may reconcile the reports. Adding the door’s identity may reveal that they concern different doors. Preserving provenance gives us ways to investigate before treating every difference as a contradiction about the same thing at the same time.

Formal paraconsistency concerns the inference rules themselves. In a paraconsistent logic, a contradiction need not license an arbitrary conclusion. It does not mean accepting every claim or abandoning the distinction between supported and unsupported inference. [Basu and Roy’s research paper starts from this failure of explosion when developing more general definitions.](https://arxiv.org/abs/2112.00357)

The current junction is an analogy for retaining a conflict, not a demonstration of that formal property. The next useful addition would expose a small rule table: after entering both a proposition and its negation, which consequences remain available, and which unrelated conclusion still cannot be derived?

Return to the pillars and imagine a resolution that shortens one to a stump. What information should remain so the decision can later be reconsidered? Keeping a source, a date and the rejected alternative does not make revision automatic, but it prevents a settled display from hiding how settlement occurred.


Situated computation takes up that provenance. Four panels will judge one subject differently, and their positions will become part of what the judgement tells you.

---

## SpeculativeComputation Situated Computation

*SpeculativeComputation_Situated_Computation*

# Four verdicts about the same subject

What changes when the subject stays the same but the source of the judgement changes?


Read the subject identifier on all four panels. Keep it fixed in your comparison, then note the verdict, the confidence and the footer on each. Look back at the first panel after reading the others: it has not become a different subject because another description is available.

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


Follow a packet from one of the rim nodes into the central structure. Watch the new facet appear. During one growth cycle, compare a contribution from a node you have already seen with one from a new source. The number of contributions and the number of contributing sources need not increase together.

The exhibit turns contribution into an arrival event. A packet comes from one of twelve positions and adds a piece to a shared form. The form grows to a fixed capacity and starts again. Its visible coherence comes from an assembly rule that knows where to place each arriving facet.

The source makes the operation inspectable:

```gdscript
_placed += 1
_edits += 1
# count distinct contributors this version
if peer_idx >= 0 and peer_idx < _seen_peers.size() and not bool(_seen_peers[peer_idx]):
    _seen_peers[peer_idx] = true
    _contributors += 1
```

Every accepted facet increments the edit count. The Boolean array _seen_peers lets the same source count only once within a version. On the next version those flags clear while the totals persist. A number labelled CONTRIBUTORS can therefore outgrow the twelve source positions. The code tells us what was counted more precisely than the label does.

That is a simulation of accretion, not a live collaborative editor. The peers are generated positions rather than people logged into the museum, and the incoming material is accepted without a dispute over its content. The animation demonstrates one way many sources can feed one object while leaving the harder question of validation open.

Collective knowledge needs more than participation counts. A contribution may repeat an error, correct an earlier claim, supply a missing case or disagree with an accepted account. Those actions can add little to a simple count while changing the usefulness of the shared result dramatically.

The previous room kept four viewpoints separate. Here the common centre can make their differences disappear into a continuous object. Follow a facet and ask what you can still recover about its origin after it joins the whole. Does the shape preserve a reason for accepting that contribution, or only the fact that something arrived?

For a proposed extension, mark one contribution as disputed and keep its source visible. Let revision change an existing piece instead of always adding another. The comparison would show how maintaining knowledge differs from celebrating uninterrupted growth.


The rhizome will make the pattern of connection itself grow. A shared result can have many contributors while its network still develops uneven centres.

---

## SpeculativeComputation Rhizome Network

*SpeculativeComputation_Rhizome_Network*

# Growing without a named root

Can local connections build a network without first choosing its centre?


Watch for a new node and follow the segments it adds. Compare a crowded part of the structure with a sparse part. Predict which existing nodes are likely to receive the next connections, then check the new shoot against your prediction.

The exhibit starts with two nodes. A new shoot is placed within a bounded region and linked to up to three of the nearest existing nodes. Repeating this rule builds a graph from local proximity. The node and edge counts record its growth until the forty-node capacity is reached and the display starts again.

The source makes the operation inspectable:

```gdscript
var targets: Array = _nearest_indices(pos, links_per_node)
var new_idx: int = _add_node(pos)
if new_idx < 0:
    return
var t: int = 0
while t < targets.size():
    _add_edge(new_idx, int(targets[t]))
    t += 1
```

The neighbour search runs before the new node is inserted, so the shoot cannot select itself. It can only select nodes already present. Up to three nearest neighbours receive a link. The rule creates a graph without declaring a family tree; it also gives earlier and nearby nodes opportunities that later or distant nodes do not have.

No vertex is assigned a root role. There is no stored family tree telling every later node to descend from one privileged ancestor. Multiple connections permit the growing structure to contain routes that differ from a simple parent-and-child hierarchy.

The rule still has consequences worth inspecting. Earlier nodes are available to be chosen for longer, and spatially well-placed nodes can attract many nearby additions. A network without a designated root can develop busy regions and uneven degrees. “No root” describes part of the construction; it does not prove that every participant has equal influence.

Find a node with several visible links. Imagine removing it and predict whether the remaining pieces would still connect. Graph theory gave us the tools to ask this precisely. The present exhibit does not offer deletion, so treat the prediction as a proposed test rather than evidence that every rhizome repairs itself.

The peer-production tool gathered contributions at one centre. This growth rule distributes connections through space, but geometry still acts as a gatekeeper: being nearby makes a relationship available. A future variant could let a new node choose a distant connection and compare the network’s routes and dependencies afterwards.


The assembly laboratory adds a catalogue and a target arrangement. When connections must form a recognisable body, we can ask which bodies the catalogue has already imagined.

---

## AdvancedLaboratory Lab Equipment Simulation

*AdvancedLaboratory_Lab_Equipment_Simulation*

# The inventory before the body

How can one collection of parts become several recognisable structures?


Choose a recognisable piece in the floating inventory and keep it in view as an assembly begins. Watch it approach a position and acquire relations to other pieces. Stay through another floating phase and a later assembly. Notice whether the same part instance keeps its shape and colour when it takes a new role.

The scene alternates floating and assembling phases, with about ten seconds assigned to each. It moves through authored assemblies drawn from a catalogue that includes bodies, furniture and other structures. Bond lines update between the assigned parts as they move towards their targets.

The source makes the operation inspectable:

```gdscript
var to_target = target_pos - global_position

# Spring force toward target
velocity = (velocity + to_target * dock_spring * delta) * dock_damp
global_position += velocity * delta
```

Here the restoring force returns from the earlier halls. The vector to_target points from a part to its assigned destination. The spring changes velocity and velocity changes position. A moving piece can look as if it has found its place, although another file already supplied the target. dock_damp is applied each frame, which also makes the settling depend on the update rate. The clock remains inside the body we are watching.

There are two distinct descriptions at work. The catalogue defines available kinds of part: shapes, sizes, colours and related properties. An assembly chooses instances, assigns target positions, reapplies shapes from the catalogue, and declares connections. Movement towards those targets is then produced by a damped spring calculation. A recognisable whole results from a specification together with a procedure for approaching it.

This is not a simulation establishing chemical bonds or discovering molecular structures from physical laws. A line between two pieces represents a declared relation. A structure named Molecule or DNAHelix belongs to the exhibit’s authored vocabulary, and the name cannot supply the chemistry that its movement does not calculate.

The rhizome selected neighbours by proximity. Here the assembly already describes where things should end up. Neither method is unrestricted: one inherits a spatial growth rule, the other a catalogue and a target. Understanding those constraints lets us ask for a meaningful variation.

Imagine a body this catalogue makes awkward to describe. Would you need a new kind of part, another connection, or merely different positions for existing pieces? That is a proposed design exercise for a future editable version. The present automatic cycle lets you begin by observing how much changes while the inventory remains available.


The final ledger asks us to record the consequences of those choices. A useful catalogue permits construction while also defining what its builder has to struggle to express.

---

## PostCrisis Synthesis

*PostCrisis_Synthesis*

# One choice you can answer for

Can you name one person a useful design choice could leave out?


Read one complete pair on the ledger before it scrolls away. Choose a concrete case, such as a short name field and someone whose name exceeds it. Say what the designer probably gained, what the person encounters, and one change that could reduce the difficulty.

The exhibit cycles through prewritten examples of choices and exclusions. Six lines remain visible at once, and an amber mark accompanies a new entry. Its form resembles an accumulating record, but these entries are examples: it is not recording your visit, saving your discussion or certifying that any problem has been repaired.

The source makes the operation inspectable:

```gdscript
_entries.push_front(line)
while _entries.size() > visible_lines:
    _entries.pop_back()
_count += 1
```

A line enters at the front; another leaves when the buffer is full. The counter survives that loss. We met a running count near the point at the beginning of the museum. Here counting and remembering separate in four lines of code. The machine can announce progress while the evidence of an earlier problem has already disappeared.

An accountable record would connect a decision with evidence about its effect and someone able to revisit it. Naming an excluded case is a beginning. It becomes useful when it leads to an action, an observation after the action, and a decision about what to change next.

Return mentally to one room you have just walked. Perhaps a slider was difficult to reach, a number concealed several different conditions, or a label promised a computation the exhibit could not yet perform. Choose one case small enough to inspect. State the intended experience, the present obstacle and the smallest improvement that would let you test the difference.

Now ask where else the same relation occurs. A readable control, a preserved alternative or a visible source can be a reusable principle. Reusing it still requires checking the new room: the same height may not suit every body, and the same explanatory sequence may not suit every concept. Generalisation is a claim to test through another encounter.

The ledger does not absolve a choice by displaying its cost. Some exclusions call for repair, some for another route, and some for changing the category that made the case disappear. The response should stay attached to the person’s actual difficulty rather than becoming a decorative admission of imperfection.


Go back to a chosen room with one question, one proposed change and one observable consequence. The museum’s next version begins with that specific return.

---
