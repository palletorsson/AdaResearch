<<<ADA_BUNDLE>>>
sequence: postfoundationscrisis
file: tutorial.md
maps: 8
<<</ADA_BUNDLE>>>

<<<MAP: CriticalAlgorithms_Algorithmic_Bias_Visualization>>>
# Algorithmic Bias Visualization

A room divided. The left half spacious, the right half cramped. Build allocation as architecture before you write a single line of model code.

Declare the two halves.

```gdscript
@export var left_columns: int = 5
@export var right_columns: int = 2
@export var row_count: int = 8
@export var population_per_side: int = 40
```

Both halves hold the same population. Only the columns differ. The ratio of people to space is the bias.

Place the population into the left half.

```gdscript
func populate_left() -> void:
    for i in population_per_side:
        var col := i % left_columns
        var row := i / left_columns
        spawn_person(Vector3(col, 0.0, row))
```

Row-major placement fills the grid from the left. The crowd has room to breathe; bodies do not overlap.

Place the same count on the right.

```gdscript
func populate_right() -> void:
    for i in population_per_side:
        var col := i % right_columns
        var row := i / right_columns
        spawn_person(Vector3(10.0 + col, 0.0, row))
```

Same loop, smaller denominator. The crowd stacks upward. Rows extend past the room boundary.

Measure the density per side.

```gdscript
func density(side_columns: int) -> float:
    var area := float(side_columns * row_count)
    return float(population_per_side) / area
```

Density is bodies per cell. Left returns 1.0; right returns 2.5. The number on the sign is the felt experience of walking through.

Draw the allocation ratio on a screen.

```gdscript
func update_readout(label: Label3D) -> void:
    var l := density(left_columns)
    var r := density(right_columns)
    label.text = "Left: %.2f\nRight: %.2f\nRatio: %.1fx" % [l, r, r / l]
```

The ratio floats between the two halves. Not an abstraction. A multiplier hovering over heads.

Tint each side by crowding pressure.

```gdscript
func tint_by_density(mesh: MeshInstance3D, d: float) -> void:
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(d * 0.4, 0.2, 0.2, 1.0)
    mesh.material_override = material
```

More bodies, redder floor. Crowding becomes pigment. The bias visualizer is not asking the learner to infer inequality from data; it is making inequality inhabitable.

Reveal the allocation rule that caused the divide.

```gdscript
func show_source_rule(panel: Label3D) -> void:
    panel.text = "RULE: allocate columns ∝ historical_representation"
```

The rule is visible on a plaque. Nothing hidden in weights. The architecture is the classifier.

You have built a room where classification precedes mathematics. Walk through the next map, Applied Ethics, to see what practice looks like once this room is the starting condition.
<<</MAP>>>

<<<MAP: CriticalAlgorithms_Applied_Ethics>>>
# Applied Ethics

Every classifier has an outside. Stage three live cases where the model commits, and show what the commitment costs.

Declare a case record.

```gdscript
class_name EthicsCase
extends Resource

@export var title: String = ""
@export var features: Dictionary = {}
@export var ground_truth: bool = false
@export var stakes: String = ""
```

Each case is a resource. Features drive the model; stakes name who bears the outcome. Keeping them on one object prevents drift.

Run the classifier.

```gdscript
func classify(case: EthicsCase) -> bool:
    var score := 0.0
    for key in case.features:
        score += float(case.features[key]) * weights.get(key, 0.0)
    return score > threshold
```

Linear model, deliberately simple. Complexity is not what makes ethics hard. The threshold is a choice the designer must defend.

Compute the confusion outcome.

```gdscript
func outcome(case: EthicsCase) -> String:
    var predicted := classify(case)
    if predicted and case.ground_truth: return "true_positive"
    if predicted and not case.ground_truth: return "false_positive"
    if not predicted and case.ground_truth: return "false_negative"
    return "true_negative"
```

Four outcomes, not two. False positives and false negatives are the outside of the classifier. The ethics lives there.

Render the outcome on a case plinth.

```gdscript
func label_case(plinth: Label3D, case: EthicsCase) -> void:
    var kind := outcome(case)
    plinth.text = "%s\n%s\n→ %s" % [case.title, case.stakes, kind]
    plinth.modulate = color_for_outcome(kind)
```

Each plinth holds a case, a stake, a verdict. The colour codes what kind of mistake was made, if any. The verdict is never just a number.

Colour the outcomes.

```gdscript
func color_for_outcome(kind: String) -> Color:
    match kind:
        "true_positive": return Color(0.2, 0.8, 0.3)
        "true_negative": return Color(0.5, 0.6, 0.5)
        "false_positive": return Color(0.9, 0.4, 0.2)
        "false_negative": return Color(0.8, 0.1, 0.1)
    return Color.WHITE
```

False negatives are the deepest red. A missed call costs more than a miscall when the stakes are unequal. Colour encodes that asymmetry.

Adjust the threshold live.

```gdscript
func _on_threshold_slider_moved(v: float) -> void:
    threshold = lerp(-1.0, 1.0, v)
    for plinth in case_plinths:
        label_case(plinth, plinth.get_meta("case"))
```

The slider is the moral dial. Moving it right reduces false positives and increases false negatives. There is no setting with neither.

Show the aggregate cost.

```gdscript
func aggregate_costs(cases: Array) -> Dictionary:
    var counts := {"fp": 0, "fn": 0}
    for c in cases:
        if outcome(c) == "false_positive": counts.fp += 1
        elif outcome(c) == "false_negative": counts.fn += 1
    return counts
```

The total FP/FN count updates on every slider move. The ethics is not in the model; it is in the choice of where to place the knob.

You have built a room where every classification is a commitment. Carry that framing into Paraconsistent Engineering, which turns contradiction from a fatal system state into an engineered affordance.
<<</MAP>>>

<<<MAP: SpeculativeComputation_Paraconsistent_Engineering>>>
# Paraconsistent Engineering

A database that holds both P and not-P without collapsing into triviality. Build a logic engine that survives contradiction.

Declare the knowledge base.

```gdscript
class_name ParaKB
extends Node

var facts: Array[Dictionary] = []

func assert_fact(subject: String, predicate: String, value: bool, source: String) -> void:
    facts.append({"s": subject, "p": predicate, "v": value, "src": source})
```

Every fact carries its source. Contradictions are tagged rather than resolved. The source makes ex falso impossible: you cannot reason from conflicting sources as though they agreed.

Query a subject without collapsing.

```gdscript
func query(subject: String, predicate: String) -> Array:
    var hits: Array = []
    for f in facts:
        if f.s == subject and f.p == predicate:
            hits.append(f)
    return hits
```

The query returns every match, including disagreements. The caller, not the database, decides what to do with a split. Classical logic would have raised here.

Detect contradictions.

```gdscript
func contradictions() -> Array:
    var groups := {}
    for f in facts:
        var key := f.s + "/" + f.p
        if not groups.has(key): groups[key] = []
        groups[key].append(f)
    var out: Array = []
    for key in groups:
        var values := groups[key].map(func(f): return f.v)
        if true in values and false in values:
            out.append({"key": key, "facts": groups[key]})
    return out
```

Group by subject and predicate. If both true and false appear, the pair is a contradiction. They are logged, not deleted.

Continue inference on the consistent parts.

```gdscript
func consistent_facts() -> Array:
    var bad := {}
    for c in contradictions():
        bad[c.key] = true
    return facts.filter(func(f): return not bad.has(f.s + "/" + f.p))
```

The filter yields the inference-safe subset. Classical reasoning operates here. The contradictory pair is visible on its own spotlight.

Render the sphere of contradictions.

```gdscript
func update_sphere(mesh: MeshInstance3D) -> void:
    var c := contradictions()
    var scale := 1.0 + float(c.size()) * 0.1
    mesh.scale = Vector3.ONE * scale
    var material := mesh.get_active_material(0) as StandardMaterial3D
    material.emission_energy_multiplier = 0.5 + float(c.size()) * 0.2
```

The sphere grows with each held contradiction. Florensky's icon becomes a load-bearing indicator. The system glows brighter the more disagreement it survives.

Offer a provenance tooltip.

```gdscript
func tooltip_for(c: Dictionary) -> String:
    var lines: Array = []
    for f in c.facts:
        lines.append("%s → %s (%s)" % [str(f.v), f.src, f.p])
    return "\n".join(lines)
```

Each contradiction opens its sources. The engineer reads the disagreement as data, not as failure. The tool treats reality as multi-voiced.

Wire the live inference stage to the clean subset.

```gdscript
func infer_new_facts() -> void:
    var base := consistent_facts()
    for rule in inference_rules:
        var derived := rule.apply(base)
        for d in derived:
            assert_fact(d.s, d.p, d.v, "derived:" + rule.name)
```

Inference runs on the consistent subset and writes new facts back with a derivation source. The sphere does not explode. The database keeps working.

You have built a database that refuses to collapse under contradiction. The next map, Situated Computation, turns this refusal into a design constraint on how any system occupies its perspective.
<<</MAP>>>

<<<MAP: SpeculativeComputation_Situated_Computation>>>
# Situated Computation

Three viewing platforms, one dataset, three different pictures. Build objectivity as the careful accounting of perspective.

Declare a standpoint.

```gdscript
class_name Standpoint
extends Resource

@export var name: String = ""
@export var origin: Vector3 = Vector3.ZERO
@export var filter_weights: Dictionary = {}
@export var color: Color = Color.WHITE
```

Each platform is a standpoint. The origin is where the observer stands. The filter is what the standpoint can see.

Build three standpoints.

```gdscript
func build_standpoints() -> Array[Standpoint]:
    var sps: Array[Standpoint] = []
    sps.append(make_standpoint("analyst", Vector3(-5, 2, 0), {"metrics": 1.0}))
    sps.append(make_standpoint("user", Vector3(0, 1.7, 5), {"friction": 1.0}))
    sps.append(make_standpoint("archivist", Vector3(5, 2, 0), {"history": 1.0}))
    return sps
```

The analyst sees metrics. The user feels friction. The archivist traces history. No viewpoint is a superset of another.

Project the dataset through a standpoint.

```gdscript
func project(records: Array, sp: Standpoint) -> Array:
    var out: Array = []
    for r in records:
        var score := 0.0
        for key in sp.filter_weights:
            score += float(r.get(key, 0.0)) * sp.filter_weights[key]
        out.append({"record": r, "score": score})
    return out
```

The standpoint scores each record against its own weights. The same record receives three different scores. The dataset is the same; the readings diverge.

Render records as heights on a platform.

```gdscript
func render_column(parent: Node3D, record: Dictionary, score: float) -> void:
    var column := MeshInstance3D.new()
    column.mesh = BoxMesh.new()
    column.scale = Vector3(0.2, max(0.05, score), 0.2)
    column.position = record.get("position", Vector3.ZERO)
    parent.add_child(column)
```

Each record becomes a column whose height is the standpoint's score. The three platforms tell three different stories about the same city.

Label each platform with its accountability.

```gdscript
func label_platform(label: Label3D, sp: Standpoint) -> void:
    var keys: Array = sp.filter_weights.keys()
    label.text = "%s sees: %s" % [sp.name, ", ".join(keys)]
```

The sign names what this standpoint attends to. Nothing is hidden; nothing is pretended to be neutral. Accountability replaces the view from nowhere.

Mark disagreement bands between platforms.

```gdscript
func disagreement(records: Array, sps: Array) -> Array:
    var out: Array = []
    for r in records:
        var scores: Array = sps.map(func(s): return project_one(r, s))
        var spread: float = scores.max() - scores.min()
        out.append({"record": r, "spread": spread})
    return out
```

Records with high spread are precisely where the perspectives matter most. The spread is not noise to smooth away. It is the evidence.

Colour the highest-spread records across all platforms.

```gdscript
func highlight_spread(columns: Array, spreads: Array, threshold: float) -> void:
    for i in columns.size():
        if spreads[i].spread > threshold:
            (columns[i] as MeshInstance3D).modulate = Color(1.0, 0.6, 0.2)
```

Orange bands ring the contested records across all three platforms simultaneously. The controversy is structured, not scattered.

You have built a triple viewing station where perspective is declared before measurement. The next map, Collective Knowledge, turns three standpoints into four reasoning agents who must share a commons.
<<</MAP>>>

<<<MAP: SpeculativeComputation_Collective_Knowledge>>>
# Collective Knowledge

Four reasoning agents, each with a different logic, share one question. Build a commons from systems that cannot individually complete themselves.

Declare an agent.

```gdscript
class_name LogicAgent
extends Node

@export var agent_name: String = ""
@export var logic_style: String = "classical"
@export var color: Color = Color.WHITE

func reason(question: String) -> Dictionary:
    return {"agent": agent_name, "claim": null, "confidence": 0.0}
```

The base class returns a null claim. Each subclass overrides `reason` with its own method. Logic_style is a declaration, not a reduction.

Subclass a classical reasoner.

```gdscript
class ClassicalAgent extends LogicAgent:
    func reason(q: String) -> Dictionary:
        var base := proof_search(q)
        return {"agent": agent_name, "claim": base.claim, "confidence": base.strength}
```

Classical proof search, bounded. It returns its best claim with a confidence. If the search fails, the claim is null and the confidence is zero.

Subclass a fuzzy reasoner.

```gdscript
class FuzzyAgent extends LogicAgent:
    func reason(q: String) -> Dictionary:
        var truth: float = fuzzy_eval(q)
        return {"agent": agent_name, "claim": truth > 0.5, "confidence": abs(truth - 0.5) * 2.0}
```

Fuzzy agents return values between zero and one. The claim is a thresholded projection. The confidence is the distance from ambivalence.

Run all agents on one question.

```gdscript
func collect_reports(q: String) -> Array:
    var reports: Array = []
    for agent in agents:
        reports.append(agent.reason(q))
    return reports
```

Every agent answers. No voting yet. The commons is the collection of answers, each stamped with its agent.

Read disagreements as data.

```gdscript
func disagreement_score(reports: Array) -> float:
    if reports.size() < 2: return 0.0
    var yes := 0
    var no := 0
    for r in reports:
        if r.claim == true: yes += 1
        elif r.claim == false: no += 1
    return min(yes, no) * 2.0 / float(reports.size())
```

Even agreement yields 1.0, full agreement yields 0.0. The score names the structure of disagreement without resolving it.

Render each report on a lectern.

```gdscript
func render_lectern(lectern: Node3D, report: Dictionary) -> void:
    var label := lectern.get_node("Label3D") as Label3D
    label.text = "%s\n%s (%.0f%%)" % [report.agent, str(report.claim), report.confidence * 100.0]
    label.modulate = report.get("color", Color.WHITE)
```

Four lecterns, four claims, four confidences. The learner walks between them and reads the commons as an architectural arrangement rather than a verdict.

Let the mediation stage observe without voting.

```gdscript
func mediate(reports: Array) -> Dictionary:
    return {
        "spread": disagreement_score(reports),
        "consensus": reports.filter(func(r): return r.claim == true).size(),
        "dissent": reports.filter(func(r): return r.claim == false).size(),
    }
```

The mediator reports structure, not resolution. The learner decides what the commons means. Gödel said single systems cannot contain themselves; the commons is how several such systems stay in relation.

You have built a four-lectern commons where incompleteness becomes collective. The next map, Rhizome Network, converts this non-hierarchy from a reasoning posture into a physical topology.
<<</MAP>>>

<<<MAP: SpeculativeComputation_Rhizome_Network>>>
# Rhizome Network

No root. No trunk. No privileged path. Build a cave system where any chamber connects to any other.

Declare a node set.

```gdscript
class_name RhizomeNode
extends Node3D

@export var id: String = ""
@export var neighbors: Array[String] = []
```

Each node is a Node3D with an id and a neighbour list. No parent field. No depth. No rank.

Build the network.

```gdscript
func build_network(ids: Array[String]) -> void:
    for id in ids:
        var n := RhizomeNode.new()
        n.id = id
        nodes[id] = n
        add_child(n)
```

Every id becomes a node. The nodes exist as siblings under the same parent. Nothing is a root.

Connect any two nodes.

```gdscript
func connect_nodes(a: String, b: String) -> void:
    if a == b: return
    if not nodes[a].neighbors.has(b):
        nodes[a].neighbors.append(b)
    if not nodes[b].neighbors.has(a):
        nodes[b].neighbors.append(a)
```

Connections are bidirectional. The edge is not owned by either endpoint. The rhizome is a relation, not a possession.

Draw the edges.

```gdscript
func draw_edges(immediate: MeshInstance3D) -> void:
    var mesh := ImmediateMesh.new()
    mesh.surface_begin(Mesh.PRIMITIVE_LINES)
    for id in nodes:
        for n_id in nodes[id].neighbors:
            mesh.surface_add_vertex(nodes[id].global_position)
            mesh.surface_add_vertex(nodes[n_id].global_position)
    mesh.surface_end()
    immediate.mesh = mesh
```

Edges are pure line segments. No arrowheads, no weights, no hierarchy. The visual grammar refuses to name a direction.

Compute reachability without spanning tree.

```gdscript
func reachable_from(start: String) -> Array[String]:
    var seen: Array[String] = [start]
    var frontier: Array[String] = [start]
    while not frontier.is_empty():
        var here := frontier.pop_back()
        for n_id in nodes[here].neighbors:
            if not seen.has(n_id):
                seen.append(n_id)
                frontier.append(n_id)
    return seen
```

Flood fill, not BFS tree. The function returns the set of reachable ids without implying an order. Any start point is a centre, which means none is.

Walk the rhizome from the player.

```gdscript
func step_from(here: String, target: String) -> String:
    for n_id in nodes[here].neighbors:
        if n_id == target: return n_id
    return nodes[here].neighbors.pick_random()
```

If the target is adjacent, go to it. Otherwise, pick any neighbour. The walk is not a plan; it is a traversal that accepts non-hierarchy.

Colour-code chambers by their degree.

```gdscript
func color_by_degree() -> void:
    for id in nodes:
        var d: int = nodes[id].neighbors.size()
        var t: float = clamp(d / 6.0, 0.0, 1.0)
        tint_chamber(nodes[id], Color(1.0, 1.0 - t, 0.4))
```

Degree replaces rank. High-degree chambers glow warmer, not because they are important but because they are more connected. Connectedness is a property, not a privilege.

You have built a cave system that grows the way thought should. The next map, Lab Equipment Simulation, returns to formalization with the rhizome carried as a lesson.
<<</MAP>>>

<<<MAP: AdvancedLaboratory_Lab_Equipment_Simulation>>>
# Lab Equipment Simulation

A clean bench, a molecular designer, a void pit under the floor. Build formalization that knows its own edges.

Declare an atom.

```gdscript
class_name Atom
extends RigidBody3D

@export var element: String = "C"
@export var valence: int = 4
var bonds: Array = []
```

Each atom carries its element, its valence, and its current bond list. The valence is the rule; the bond list is what the rule has allowed.

Snap atoms to valence.

```gdscript
func can_bond(a: Atom, b: Atom) -> bool:
    if a.bonds.size() >= a.valence: return false
    if b.bonds.size() >= b.valence: return false
    return true
```

An atom with full valence refuses new bonds. The rule is enforced at the point of attempt, not afterwards.

Form the bond.

```gdscript
func bond_atoms(a: Atom, b: Atom) -> void:
    if not can_bond(a, b): return
    a.bonds.append(b)
    b.bonds.append(a)
    spawn_bond_mesh(a, b)
```

The bond is symmetric and visible. A cylinder appears between the two atoms when the rule succeeds. When it fails, nothing happens and the learner sees why.

Constrain bond geometry.

```gdscript
func enforce_bond_angles(a: Atom) -> void:
    match a.valence:
        2: set_linear(a)
        3: set_trigonal(a)
        4: set_tetrahedral(a)
```

Carbon spreads to tetrahedral, nitrogen to trigonal, oxygen to linear. The formal rule has a geometric consequence. The bench expresses chemistry as posture.

Render the void pit.

```gdscript
func reveal_pit_under(cell: Vector2i) -> void:
    var pit := preload("res://commons/maps/elements/void_pit.tscn").instantiate()
    pit.position = Vector3(cell.x, -4.0, cell.y)
    add_child(pit)
```

One floor cell drops away to show the underside. The laboratory is clean above and unresolved below. Formal systems rest on something they cannot themselves justify.

Label the pit.

```gdscript
func label_pit(label: Label3D) -> void:
    label.text = "axioms (unproven)"
    label.modulate = Color(0.8, 0.8, 0.3)
```

The plaque names what the pit is. Not an error. A foundation.

Let the learner build a molecule.

```gdscript
func _on_designer_submit() -> void:
    var mol := designer.get_current_molecule()
    if validate_valence(mol):
        anchor_on_bench(mol)
    else:
        flash_error(designer)
```

The designer either accepts a valid molecule or flashes red. The error is visible, local, and revisable. Formalization works — inside its scope.

Carry the finished molecule to the archive shelf.

```gdscript
func archive_molecule(mol: Node3D) -> void:
    var slot := shelf.get_next_free_slot()
    if slot == null: return
    mol.reparent(slot)
    mol.position = Vector3.ZERO
```

The shelf preserves the build. The lab does not consume its outputs. Earlier maps' caution is built into the furniture.

You have built a lab where formal rules hold on the bench and unproven axioms sit one cell below the floor. The final map, PostCrisis Synthesis, gathers the arc into a closing sentence.
<<</MAP>>>

<<<MAP: PostCrisis_Synthesis>>>
# PostCrisis Synthesis

One plinth, one sentence, no ornament. Close the arc by compressing it.

Declare the plinth.

```gdscript
class_name SynthesisPlinth
extends Node3D

@export var sentence: String = ""
@export var font_size: int = 48
```

A single export: the sentence. The plinth is a vehicle for one line. Anything else would be a new teaching.

Compose the sentence from the arc.

```gdscript
const ARC_SENTENCE := "Knowing the limits of formalization, we build systems that hold their outside."
```

The sentence names what the sequence discovered. Not a conclusion; a practice. The learner carries it forward.

Render the sentence on the plinth.

```gdscript
func render_sentence(label: Label3D) -> void:
    label.text = ARC_SENTENCE
    label.font_size = font_size
    label.modulate = Color(1.0, 1.0, 0.95)
    label.outline_size = 4
```

Cream text, thin outline, generous kerning. The plinth is a publication, not a monument.

Place the plinth off-centre.

```gdscript
func place_plinth(pos: Vector3) -> void:
    plinth_node.position = pos
    plinth_node.rotation.y = deg_to_rad(-12.0)
```

The angle breaks the gallery axis. The sentence refuses to be the centre of the room. The learner has to walk toward it at a slight turn.

Place four empty plinths around it.

```gdscript
func place_memory_plinths(positions: Array) -> void:
    for p in positions:
        var m := preload("res://commons/maps/elements/memory_plinth.tscn").instantiate()
        m.position = p
        add_child(m)
```

Empty plinths ring the sentence. Each represents a map of the arc. The emptiness invites the learner to remember what stood on each.

Write the door threshold.

```gdscript
func write_threshold(label: Label3D) -> void:
    label.text = "continue →"
    label.modulate = Color(0.9, 0.9, 0.9)
    label.font_size = 32
```

The exit does not say goodbye. It says continue. The arc is open-ended by design.

Fade the lighting toward the door.

```gdscript
func gradient_light(env: WorldEnvironment) -> void:
    var e := env.environment
    e.ambient_light_color = Color(0.7, 0.7, 0.75)
    e.ambient_light_energy = 0.4
    e.ssao_enabled = false
```

Cool, even light. No spotlight on the sentence. The gallery is a reading room, not a shrine. Reading rooms assume the reader.

Connect the teleporter.

```gdscript
func on_teleport_ready(t: Node3D) -> void:
    t.set_meta("destination", "next_arc_start")
    t.enable()
```

The teleporter holds a destination meta, not a hardcoded path. The next arc is a reference. The learner steps forward carrying what they have learned.

You have closed the post-foundations arc with one sentence on one plinth. Carry the question into whatever you build next.
<<</MAP>>>
