extends Node3D
## A finite delivery, then unhurried sorting. No fresh draws between partitions.
const Model = preload("sorting_model.gd")
const Cube = preload("sorting_cube.gd")
const Stage = preload("res://commons/artifacts/randomness_space/museum_exhibit_stage.gd")
const Rack = preload("res://commons/audio/rack_templates/RackTemplates.gd")
const PAPER := Color("eee9db")
const INK := Color("283439")
const PINK := Color("e65c9c")
const BLACK := Color("303038")
const GOLD := Color("c19039")
const EDGE := 0.24
var model = Model.new()
var cubes: Array = []
var dividers: Array = []
var pictures: Node3D
var ways: Label3D
var status: Label3D
var compartment_label: Label3D
var caption: Label3D
var button: Node3D
var delivered := 0
var delivering := false
var picture_patterns := []

func _ready() -> void:
	set_meta("em_keep_scale", true)
	set_meta("em_visibility_bounds", AABB(Vector3(-1.4,0,-0.65),Vector3(2.8,2.25,1.8)))
	build()
	refresh()

func label(parent: Node3D, text: String, pos: Vector3, size: int = 34, pixel: float = 0.0018, colour: Color = INK) -> Label3D:
	var l := Label3D.new()
	l.text = text; l.position = pos; l.font_size = size; l.pixel_size = pixel
	l.modulate = colour; l.outline_size = 0
	parent.add_child(l)
	return l

func slot_position(slot: int) -> Vector3:
	return Vector3(-0.54 + slot * 0.48, 1.14, 0.25)

func build() -> void:
	var light := OmniLight3D.new()
	light.position=Vector3(0,2.8,1.15); light.light_color=Color("fff3db")
	light.light_energy=1.8; light.omni_range=3.5; light.shadow_enabled=false
	add_child(light)
	Stage.box(self,Vector3(0,0.96,0.15),Vector3(2.8,0.12,1.5),PAPER,true)
	for x in [-1.17,1.17]:
		for z in [-0.4,0.65]: Stage.box(self,Vector3(x,0.45,z),Vector3(0.08,0.9,0.08),INK,true)
	# A shallow tray with a reachable front; four sites make WAYS finite.
	Stage.box(self,Vector3(0.18,1.07,-0.06),Vector3(2.04,0.12,0.035),INK,true)
	for x in [-0.84,1.2]: Stage.box(self,Vector3(x,1.07,0.25),Vector3(0.035,0.12,0.65),INK,true)
	for i in 4:
		var pad := Stage.box(self,slot_position(i)-Vector3.UP*0.115,Vector3(0.34,0.014,0.34),Color("d4cdbb"))
		pad.name = "Site"+str(i+1)
		var l := label(self,str(i+1),Vector3(slot_position(i).x,1.023,0.56),26)
		l.rotation.x=-PI/2
		var c := Cube.new()
		c.name = "Cube"+str(i+1); c.cube_id = i
		c.freeze = true; c.release_mode = 1; c.gravity_scale = 0
		c.collision_layer = 6; c.collision_mask = 0; c.enabled = false
		c.ranged_grab_method = 2
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new(); box.size=Vector3.ONE*EDGE; mesh.mesh=box
		mesh.material_override=Stage.material(PINK if Model.COLOURS[i]==1 else BLACK)
		c.add_child(mesh)
		var shape := CollisionShape3D.new(); shape.name="CollisionShape3D"; shape.shape=BoxShape3D.new(); shape.shape.size=Vector3.ONE*EDGE
		c.add_child(shape); shape.disabled=true
		add_child(c); c.visible=false; cubes.append(c)
		c.placement_requested.connect(func(body): settle.call_deferred(body))
		c.lifted.connect(func(_body): refresh(); refresh.call_deferred())
	for gap in 3:
		var divider := Stage.box(self,Vector3(-0.30+gap*0.48,1.105,0.25),Vector3(0.025,0.17,0.62),GOLD,true)
		dividers.append(divider)
	# Open tube: individual vertical staves leave a real bore and visible cubes.
	for i in 20:
		var a := TAU*i/20.0
		var stave := Stage.box(self,Vector3(-1.1+cos(a)*0.21,1.70,0.25+sin(a)*0.21),Vector3(0.059,0.8,0.022),INK)
		stave.rotation.y=-a+PI/2
	Stage.box(self,Vector3(-1.1,2.19,0.22),Vector3(0.52,0.18,0.02),PAPER).material_override.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	label(self,"KEPT BATCH\n2 PINK + 2 BLACK",Vector3(-1.1,2.19,0.24),25,0.0015)
	# WAYS is a picture board directly behind the objects, not a second console.
	Stage.box(self,Vector3(0.18,1.66,-0.47),Vector3(2.16,1.16,0.055),PAPER).material_override.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	ways=label(self,"",Vector3(0.18,2.10,-0.425),48)
	label(self,"Same colour counts in each box",Vector3(0.18,1.98,-0.425),27,0.0018)
	pictures=Node3D.new(); pictures.name="PossibleArrangements"; add_child(pictures)
	compartment_label=label(self,"",Vector3(0.18,1.29,-0.425),25)
	Stage.box(self,Vector3(0.18,0.96,0.94),Vector3(0.62,0.12,0.38),PAPER,true)
	button=preload("res://commons/interactables/push_button.tscn").instantiate()
	button.name="Next"; Rack.make_button_rectangular(button)
	button.rotation=Vector3.ZERO; button.position=Vector3(0.18,1.025,0.94)
	button.released_color=INK; button.pressed_color=GOLD
	button.get_node("ButtonBase/BaseMesh").mesh=button.get_node("ButtonBase/BaseMesh").mesh.duplicate()
	button.get_node("ButtonBase/CollisionShape3D").shape=button.get_node("ButtonBase/CollisionShape3D").shape.duplicate()
	button.get_node("ButtonBase/BaseMesh").mesh.size=Vector3(0.50,0.01,0.24)
	button.get_node("ButtonBase/CollisionShape3D").shape.size=Vector3(0.50,0.02,0.24)
	button.get_node("Button/ButtonMesh").mesh.size=Vector3(0.46,0.024,0.20)
	button.get_node("Button/CollisionShape3D").shape.size=Vector3(0.46,0.028,0.20)
	button.get_node("AccentRing").mesh.size=Vector3(0.49,0.014,0.23)
	button.get_node("InteractableAreaButton/CollisionShape3D").shape.size=Vector3(0.48,0.06,0.22)
	add_child(button); button.pressed.connect(advance)
	caption=label(button.get_node("Button"),"",Vector3(0,0.016,0),29,0.0013,PAPER)
	caption.rotation.x=-PI/2
	status=label(self,"",Vector3(0.18,1.21,-0.425),25,0.0016)
	label(self,"Lift a cube. Drop over another spot to swap.",Vector3(0.18,1.13,-0.425),24,0.0016)

func any_held() -> bool:
	return cubes.any(func(c): return c.held())

func advance() -> void:
	if delivering or any_held(): return
	if delivered<4:
		deliver_batch()
		return
	model.stage=(model.stage+1)%4
	refresh()

func deliver_batch() -> void:
	delivering=true; refresh()
	# Fill the far end first so later deliveries never pass through a seated cube.
	for i in range(3,-1,-1):
		var c: Node3D=cubes[model.occupants[i]]
		c.position=Vector3(-1.1,1.96,0.25); c.visible=true
		var tween:=create_tween()
		tween.tween_property(c,"position",Vector3(-1.1,1.14,0.25),0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(c,"position",slot_position(i),0.65).set_trans(Tween.TRANS_SINE)
		await tween.finished
		delivered+=1
		refresh()
	# No repeated production or timeout. These same bodies remain in the hall.
	delivering=false
	for c in cubes:
		c.enabled=true
		c.get_node("CollisionShape3D").disabled=false
	refresh()

func settle(cube: Node3D) -> void:
	if delivering or delivered!=4 or cube.held(): return
	var from: int=model.occupants.find(cube.cube_id)
	var local:=to_local(cube.global_position)
	var target:=clampi(roundi((local.x+0.54)/0.48),0,3)
	var valid:=absf(local.x-slot_position(target).x)<0.32 and absf(local.z-0.25)<0.42 and local.y>0.9 and local.y<1.8
	if valid and not cubes[model.occupants[target]].held(): model.exchange(from,target)
	for i in 4:
		var c: Node3D=cubes[model.occupants[i]]
		if c.held(): continue
		c.freeze=true; c.linear_velocity=Vector3.ZERO; c.angular_velocity=Vector3.ZERO
		c.global_transform=global_transform*Transform3D(Basis.IDENTITY,slot_position(i))
	refresh()

func refresh() -> void:
	for gap in 3:
		var active: bool=Model.PARTITIONS[model.stage][gap]!=Model.PARTITIONS[model.stage][gap+1]
		dividers[gap].visible=active
		dividers[gap].get_child(0).get_child(0).set_deferred("disabled",not active)
	for child in pictures.get_children():
		pictures.remove_child(child); child.queue_free()
	picture_patterns=[]
	if delivered==4 and not any_held(): picture_patterns=model.arrangements()
	ways.text="WAYS  " + (str(picture_patterns.size()) if not picture_patterns.is_empty() else "—")
	caption.text="WAIT" if delivering else ("DROP FOUR" if delivered<4 else ("ADD DIVIDER" if model.stage<3 else "ONE BOX"))
	status.text="Four cubes are arriving…" if delivering else ("Press DROP FOUR to begin." if delivered<4 else ("Place the cube to count." if any_held() else "Paused. Sort, or add a divider."))
	if delivered==4 and not any_held() and model.stage==3: status.text="Four boxes. ONE BOX removes the dividers."
	compartment_label.text=str(model.stage+1)+(" BOX" if model.stage==0 else " BOXES")+"  ·  SAME FOUR CUBES"
	for n in picture_patterns.size():
		var pattern: Array=picture_patterns[n]
		var p:=Vector3(-0.53+(n%3)*0.71,1.78-floori(n/3.0)*0.27,-0.425)
		var current: bool=pattern==model.colours()
		Stage.box(pictures,p,Vector3(0.64,0.20,0.015),GOLD if current else Color("d1cbbd"))
		Stage.box(pictures,p+Vector3(0,0,0.01),Vector3(0.622,0.182,0.012),PAPER)
		for i in 4:
			Stage.box(pictures,p+Vector3(-0.225+i*0.15,0,0.026),Vector3(0.10,0.10,0.017),PINK if pattern[i]==1 else BLACK)
			if i<3 and Model.PARTITIONS[model.stage][i]!=Model.PARTITIONS[model.stage][i+1]:
				Stage.box(pictures,p+Vector3(-0.15+i*0.15,0,0.031),Vector3(0.012,0.16,0.012),INK)
		if current: label(pictures,"HERE",p+Vector3(0,-0.13,0.026),19,0.0014)
	for child in pictures.get_children():
		if child is MeshInstance3D: child.material_override.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
