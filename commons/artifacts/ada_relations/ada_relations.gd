extends Node3D
## Read-only, sourced project relationships. No inferred similarity links.
const DATA := "res://commons/artifacts/ada_relations/data.json"
const KINDS := ["walk", "dependency", "concept", "shared", "history"]
const TITLES := ["SPINE / recommended order", "DEPENDS ON / plan declarations", "CONCEPT RETURNS / plan declarations", "SHARED ARTIFACT / placed token", "TIMELINE / selected dated reviews"]
var data: Dictionary
var mode := 0
var selected := 0
var detail := false
var visual: Node3D
var controls: Array[StaticBody3D] = []
var shown_edges: Array = []
var shown_nodes: Array[String] = []
var positions: Dictionary = {}
var caption: Label3D
var evidence: Dictionary = {}
class AtlasButton extends StaticBody3D:
	var action: Callable
	func pointer_event(event) -> void:
		if event.event_type == 2: action.call()
func _ready() -> void:
	data = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	for i in range(data.nodes.size()):
		if data.nodes[i].id == "graphtheory": selected = i
	for i in range(4):
		var button := AtlasButton.new();button.position = Vector3(-1.8 + i * 1.2, 0.92, 2)
		button.collision_layer = (1 << 20) | (1 << 22);button.collision_mask = 0
		var shape := BoxShape3D.new();shape.size = Vector3(1.05, 0.2, 0.08)
		var hit := CollisionShape3D.new();hit.shape = shape;button.add_child(hit)
		box(shape.size,Vector3.ZERO,Color("8c6487"),button)
		words(["VIEW", "PREVIOUS", "NEXT", "HALLS / ALL"][i], Vector3(0,0,0.055), 25, button)
		button.action = [func(): mode = (mode + 1) % 5; redraw(),func(): choose(selected-1),func(): choose(selected+1),func(): detail = not detail; redraw()][i]
		add_child(button);controls.append(button)
	redraw()
func choose(index: int) -> void:
	selected = posmod(index, data.nodes.size());redraw()
func collect_edges() -> Array:
	var result: Array = [];var sid: String = data.nodes[selected].id
	if detail:
		var maps: Array = data.nodes[selected].maps
		if mode == 0:
			for i in range(maps.size()-1): result.append({"a":maps[i],"b":maps[i+1],"kind":"walk","evidence":[{"source":data.nodes[selected].source}]})
		else:
			for e in data.edges:
				if e.kind != KINDS[mode]: continue
				for proof in e.evidence:
					if mode in [1,2] and proof.get("from","") in maps and proof.get("to","") in maps:
						result.append({"a":proof["from"],"b":proof.to,"kind":e.kind,"evidence":[proof]})
		# Shared view is intentionally global: source snapshot aggregates cross-sequence sharing.
	else:
		for e in data.edges:
			if e.kind == KINDS[mode] and (mode == 0 or e.a == sid or e.b == sid): result.append(e)
	return result
func redraw() -> void:
	if visual != null: remove_child(visual);visual.queue_free()
	visual = Node3D.new();add_child(visual)
	shown_nodes.clear();shown_edges.clear();positions.clear()
	box(Vector3(6,0.12,4),Vector3(0,0.76,0),Color("34394a"))
	words("ADA / WHAT CONNECTS THE WORK?",Vector3(0,3.8,-0.7),42)
	words(TITLES[mode],Vector3(0,3.51,-0.7),28)
	var selected_node: Dictionary = data.nodes[selected]
	var ids: Array = [];var names: Array = []
	if mode == 4:
		for item in data.history: ids.append(item.source);names.append(item.date+"\n"+item.title)
	elif detail:
		for mid in selected_node.maps: ids.append(mid);names.append(mid.replace("_"," "))
	else:
		for i in range(data.nodes.size()): ids.append(data.nodes[i].id);names.append("%02d / %s" % [i+1,data.nodes[i].id.replace("_"," ")])
	var cols := 5 if ids.size() > 16 else 4
	var rows := ceili(float(ids.size()) / cols)
	for i in range(ids.size()):
		var row := i / cols;var col := i % cols
		if row % 2 == 1: col = cols - 1 - col
		var p := Vector3((float(col)-(cols-1)*0.5)*(4.8/cols),1.02+row*0.27,1.1-row*(2.5/maxi(rows-1,1)))
		positions[ids[i]] = p;shown_nodes.append(ids[i])
		var color := Color("d9b169") if ids[i] == selected_node.id else Color("b4d5ce")
		box(Vector3(0.55,0.18,0.35),p,color)
		box(Vector3(0.12,0.19,0.08),p+Vector3(0,0.05,0.16),Color("333945"))
		words(wrap_label(names[i],18),p+Vector3(0,0.27,0),19)
	if mode == 4:
		for i in range(ids.size()-1): shown_edges.append({"a":ids[i],"b":ids[i+1],"kind":"history"})
	else: shown_edges = collect_edges()
	var loops := 0
	for e in shown_edges:
		if not positions.has(e.a) or not positions.has(e.b): continue
		if e.a == e.b: loops += 1;continue
		var color: Color = [Color("b9bdc9"),Color("e2ae63"),Color("d78fba"),Color("7fcccd"),Color("c9bfa8")][mode]
		rod(positions[e.a]+Vector3.UP*0.04,positions[e.b]+Vector3.UP*0.04,color,mode != 3)
	var context := "Selected: %s / %d halls" % [selected_node.id,selected_node.maps.size()]
	if mode == 0: context += "\nOrder is the walk, not elapsed time."
	elif mode == 1: context += "\nPrerequisite -> dependent. Draft plans are not proof of mastery."
	elif mode == 2: context += "\nDeclared introduction -> return. No inferred semantic similarities."
	elif mode == 3: context += "\nSame placement token; not the same live object."
	else: context = "Eight selected review-folder dates. Not first invention or full history."
	if detail and mode == 3: context += "\nUse ALL for cross-sequence shared tokens."
	context += "\n%d represented relations; %d within-sequence groups; %d source references outside current spine." % [shown_edges.size(),loops,data.omissions.size()]
	caption = words(context,Vector3(0,3.08,-0.7),21)
	words("VIEW changes relation / PREVIOUS and NEXT select sequence / HALLS shows its rooms",Vector3(0,0.42,1.8),20)
	evidence = {"kind":KINDS[mode],"selected":selected_node.id,"detail":detail,"nodes":shown_nodes.duplicate(),"edges":shown_edges.duplicate(true)}
func wrap_label(s: String, width: int) -> String:
	var lines: Array[String] = [];var line := ""
	for word in s.split(" "):
		if line.length()+word.length()+1 > width: lines.append(line);line = ""
		line += (" " if not line.is_empty() else "") + word
	lines.append(line);return "\n".join(lines)
func box(size: Vector3, at: Vector3, color: Color, parent: Node = null) -> void:
	var mesh := BoxMesh.new();mesh.size = size;solid(mesh,at,color,parent)
func solid(mesh: Mesh, at: Vector3, color: Color, parent: Node = null) -> MeshInstance3D:
	var n := MeshInstance3D.new();n.mesh = mesh;n.position = at
	var m := StandardMaterial3D.new();m.albedo_color = color;m.roughness = 0.7;n.material_override = m
	(parent if parent != null else visual).add_child(n);return n
func words(s: String, at: Vector3, size: int, parent: Node = null) -> Label3D:
	var n := Label3D.new();n.text=s;n.position=at;n.font_size=size;n.pixel_size=0.003
	(parent if parent != null else visual).add_child(n);return n
func rod(a: Vector3, b: Vector3, color: Color, directed: bool) -> void:
	var distance := a.distance_to(b)
	if distance < 0.001:return
	var mesh := CylinderMesh.new();mesh.top_radius=0.012;mesh.bottom_radius=0.012;mesh.height=distance
	var n := solid(mesh,(a+b)*0.5,color);n.quaternion=Quaternion(Vector3.UP,(b-a).normalized())
	if directed:
		var cone := CylinderMesh.new();cone.top_radius=0;cone.bottom_radius=0.042;cone.height=0.1
		var arrow := solid(cone,a.lerp(b,0.65),color);arrow.quaternion=n.quaternion
