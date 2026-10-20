extends Node3D
## Architectural housing + input adapter. The source artifact owns every operation.
## Front is +Z. All five mounts share the same screen, controls and service socket.
const Rack := preload("res://commons/audio/rack_templates/RackTemplates.gd")
const Supply := preload("res://commons/void/hardware_supply.gd")
@export_enum("floor", "wall", "pillar", "ceiling_l", "ceiling_j") var mount_kind := "floor"
var target_id := ""
var source: Node3D
var source_panel: Node3D
var controls: Node3D
var screen: Label3D
var title: Label3D
var ports: Array[Node] = []
var claimed := false
var retry_clock := 0.0
var steel: StandardMaterial3D
var paint: StandardMaterial3D
var dark: StandardMaterial3D
var pink: StandardMaterial3D

func _ready() -> void:
	steel = material("313c45", .6, .55)
	paint = material("e5e0cf", .84)
	dark = material("111d26", .85)
	pink = material("d889a7", .6)
	build_housing()

func material(hex: String, roughness: float, metallic := 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(hex)
	mat.roughness = roughness
	mat.metallic = metallic
	return mat

func box(host: Node3D, at: Vector3, size: Vector3, mat: Material, solid := false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.position = at
	mesh.material_override = mat
	host.add_child(mesh)
	if solid:
		var body := StaticBody3D.new()
		mesh.add_child(body)
		var collider := CollisionShape3D.new()
		var bounds := BoxShape3D.new()
		bounds.size = size
		collider.shape = bounds
		body.add_child(collider)
	return mesh

func beam(a: Vector3, b: Vector3, width: float, mat: Material) -> void:
	var mesh := box(self, (a+b)/2, Vector3(width,width,a.distance_to(b)), mat)
	mesh.look_at(to_global(b), Vector3.FORWARD if absf((b-a).normalized().y)>.95 else Vector3.UP)

func label(host: Node3D, words: String, at: Vector3, pixels: float) -> Label3D:
	var text := Label3D.new()
	text.text = words
	text.font_size = 32
	text.pixel_size = pixels
	text.position = at
	text.outline_size = 0
	text.modulate = Color("e2f0e7")
	host.add_child(text)
	return text

func build_housing() -> void:
	var head := Node3D.new()
	head.name = "Display"
	head.position = Vector3(0,1.62,0)
	head.rotation_degrees.x = -8
	add_child(head)
	box(head, Vector3(0,0,-.12), Vector3(1.26,.76,.32), paint, true)
	box(head, Vector3(0,0,.055), Vector3(1.14,.64,.035), dark)
	for x in [-.62,.62]:
		box(head, Vector3(x,0,.02), Vector3(.07,.82,.42), steel)
		for y in [-.32,.32]:
			box(head, Vector3(x,y,.24), Vector3(.035,.035,.012), paint)
	box(head, Vector3(0,.42,.1), Vector3(1.36,.065,.64), steel)
	box(head, Vector3(0,-.41,.13), Vector3(1.2,.065,.35), steel)
	title = label(head, "ADA / SERVICE "+mount_kind.to_upper(), Vector3(0,.28,.079), .001)
	screen = label(head, "UNASSIGNED\nChoose an artifact in the lab editor.", Vector3(-.51,.17,.079), .001)
	screen.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	screen.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	screen.width = 1000
	screen.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# A tilted steel tray provides a consistent hand surface beneath the display.
	var tray := Node3D.new()
	tray.name = "ControlTray"
	tray.position = Vector3(0,.96,.22)
	tray.rotation_degrees.x = -28
	add_child(tray)
	box(tray,Vector3(0,0,-.045),Vector3(.98,.36,.13),paint,true)
	box(tray,Vector3(0,0,.025),Vector3(.87,.29,.012),dark)
	for x in [-.49,.49]:
		box(tray,Vector3(x,0,.02),Vector3(.045,.40,.18),steel)
	# The attachment expresses where the machine obtains support.
	match mount_kind:
		"floor":
			box(self,Vector3(0,.065,-.16),Vector3(.72,.13,.78),steel,true)
			box(self,Vector3(0,.55,-.23),Vector3(.46,.98,.38),paint,true)
			box(self,Vector3(0,.55,-.025),Vector3(.29,.62,.025),dark)
			for y in [.3,.4,.5,.6,.7]: box(self,Vector3(0,y,-.005),Vector3(.23,.025,.025),steel)
		"wall":
			box(self,Vector3(0,1.45,-.62),Vector3(.64,1.12,.12),steel,true)
			for y in [1.12,1.82]:
				box(self,Vector3(0,y,-.36),Vector3(.46,.13,.53),paint,true)
		"pillar":
			for y in [1.12,1.92]:
				box(self,Vector3(0,y,-.72),Vector3(1.1,.14,.15),steel)
				for x in [-.53,.53]:
					box(self,Vector3(x,y,-1.19),Vector3(.11,.14,1.08),steel)
				box(self,Vector3(0,y,-1.68),Vector3(1.1,.14,.12),steel)
			box(self,Vector3(0,1.55,-.44),Vector3(.35,.25,.5),paint,true)
		"ceiling_l", "ceiling_j":
			var side := -.84 if mount_kind=="ceiling_l" else .84
			box(self,Vector3(side,4.77,-.30),Vector3(.7,.10,.7),steel)
			box(self,Vector3(side,3.20,-.30),Vector3(.24,3.04,.30),paint)
			if mount_kind=="ceiling_l":
				box(self,Vector3(side/2,1.66,-.3),Vector3(absf(side)+.24,.25,.30),paint)
			else:
				box(self,Vector3(side/2,1.25,-.3),Vector3(absf(side)+.24,.25,.30),paint)
				box(self,Vector3(0,1.45,-.3),Vector3(.25,.45,.30),paint)
			for y in [2.3,3.3,4.3]: box(self,Vector3(side,y,-.12),Vector3(.30,.06,.055),steel)
	# Enclosed service hardware connects the cabinet to its structural mount.
	beam(Vector3(.25,1.35,-.22),Vector3(.25,2.2,-.22),.065,steel)
	if mount_kind.begins_with("ceiling"):
		beam(Vector3(.25,2.2,-.22),Vector3(.25,4.8,-.22),.065,steel)
	else:
		beam(Vector3(.25,2.2,-.22),Vector3(.25,2.2,-.65),.065,steel)
	if mount_kind=="floor":
		for x in [-.29,.29]:
			box(self,Vector3(x,.14,-.16),Vector3(.05,.04,.05),paint)
	label(tray,"INPUT / "+mount_kind.to_upper(),Vector3(0,-.16,.05),.00045)

func _process(delta: float) -> void:
	if not is_instance_valid(source):
		retry_clock -= delta
		if not target_id.is_empty() and retry_clock <= 0:
			retry_clock = .05
			bind_source()
		return
	if target_id.is_empty(): return
	if "status" in source and source.status is Label3D:
		screen.text = source.status.text+"\n"+source.values.text
	elif "_readout" in source and is_instance_valid(source._readout):
		screen.text = source._readout.text
	elif "_status_label" in source and is_instance_valid(source._status_label):
		screen.text = source._status_label.text

func bind_source() -> void:
	# Scope to this floor, never another level's identically named artifact.
	var floor_root := get_parent().get_parent()
	var mount := floor_root.get_node_or_null(NodePath(target_id))
	if mount == null: return
	var candidate := mount.get_node_or_null("Artifact") as Node3D
	if candidate == null: return
	var words: Array = []
	var panel: Node3D
	if "controls" in candidate and candidate.controls is Node3D and "records" in candidate:
		panel = candidate.controls
		words = ["RUN / HOLD","NEXT","REPLAY","NEW SEED"]
	elif "_bench" in candidate and is_instance_valid(candidate._bench):
		panel = candidate._bench.get_node_or_null("Panel")
		words = ["REDRAW","NEW SEED","RULE","RESTORE","LOAD x1 / x4"]
	elif "_control_panel" in candidate and candidate._control_panel is Node3D:
		panel = candidate._control_panel
		words = ["WHITE","PINK","BROWN","BLUE","VIOLET","STOP"]
	if panel == null or words.is_empty():
		screen.text = "NO COMPATIBLE INPUT\n"+target_id
		return
	ports.clear()
	for i in range(words.size()):
		var button := panel.find_child("Btn_%d"%i,true,false)
		if button == null: return
		var port := button.get_node_or_null("InteractableAreaButton")
		if port == null or not port.has_signal("button_pressed"): return
		ports.append(port)
	source = candidate
	source_panel = panel
	var rows: Array = []
	for i in range(words.size()):
		if i%3==0: rows.append([])
		rows.back().append({"type":"button","label":words[i],"shape":"rect"})
	controls = Rack.create_panel("",rows,true)
	controls.name = "LiveControls"
	controls.scale = Vector3.ONE*2.45
	controls.position.z = .052
	get_node("ControlTray").add_child(controls)
	for i in range(words.size()):
		controls.find_child("Btn_%d"%i,true,false).get_node("InteractableAreaButton").button_pressed.connect(forward.bind(i))
	# Multiple terminals may intentionally address one artifact. Restore its old
	# controls only when the last architectural connection goes away.
	var count := int(panel.get_meta("void_terminal_count",0))
	if count==0:
		panel.set_meta("void_terminal_visible",panel.visible)
		panel.hide()
		for body in panel.find_children("*","CollisionObject3D",true,false):
			body.set_meta("void_terminal_layers",[body.collision_layer,body.collision_mask])
			body.collision_layer=0
			body.collision_mask=0
		var legacy: Array[Node3D] = []
		if "records" in candidate:
			for child in candidate.get_children():
				if child is Node3D and child != panel and child.position.z < -5.3:
					legacy.append(child)
		elif "_readout" in candidate and is_instance_valid(candidate._readout):
			legacy.append(candidate._readout.get_parent())
		for node in legacy:
			node.set_meta("terminal_old_visible",node.visible)
			node.hide()
			for body in node.find_children("*","CollisionObject3D",true,false):
				body.set_meta("void_terminal_layers",[body.collision_layer,body.collision_mask])
				body.collision_layer=0
				body.collision_mask=0
		panel.set_meta("terminal_legacy",legacy)
	panel.set_meta("void_terminal_count",count+1)
	claimed = true
	title.text = "ADA / "+target_id.to_upper()
	set_meta("bound_artifact",target_id)
	add_supply(floor_root)

func forward(_button: Node, index: int) -> void:
	if index<ports.size() and is_instance_valid(ports[index]):
		# Emit the source button's established contract, retaining all its callbacks.
		ports[index].button_pressed.emit(ports[index])

func add_supply(floor_root: Node3D) -> void:
	var bus := floor_root.get_parent()
	if not "building" in bus: return
	var terminal := Vector3(.25,4.8 if mount_kind.begins_with("ceiling") else 2.2,-.22 if mount_kind.begins_with("ceiling") else -.65)
	Supply.connect_unit(self,terminal)

func _exit_tree() -> void:
	if not claimed or not is_instance_valid(source_panel): return
	var count := maxi(0,int(source_panel.get_meta("void_terminal_count",1))-1)
	source_panel.set_meta("void_terminal_count",count)
	if count>0: return
	source_panel.visible=source_panel.get_meta("void_terminal_visible",true)
	for body in source_panel.find_children("*","CollisionObject3D",true,false):
		var layers: Array = body.get_meta("void_terminal_layers",[])
		if layers.size()==2:
			body.collision_layer=layers[0]
			body.collision_mask=layers[1]
	for node in source_panel.get_meta("terminal_legacy",[]):
		if not is_instance_valid(node): continue
		node.visible=node.get_meta("terminal_old_visible",true)
		for body in node.find_children("*","CollisionObject3D",true,false):
			var layers: Array=body.get_meta("void_terminal_layers",[])
			if layers.size()==2:
				body.collision_layer=layers[0]
				body.collision_mask=layers[1]
