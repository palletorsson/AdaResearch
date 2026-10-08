extends "res://commons/artifacts/spine_studies/study_forms.gd"
## A small floor console changes a much larger installation overhead.
const Canopy = preload("res://commons/primitives/pipes/pipe_canopy.gd")
class CanopyButton extends StaticBody3D:
	var action: Callable
	func pointer_event(event) -> void:
		if event.event_type == 2: action.call()
var canopy: Node3D
var buttons: Array[StaticBody3D] = []
var status: Label3D
var probe: ReflectionProbe
var hangers: Node3D

func _ready() -> void:
	canopy = Canopy.new(); canopy.name = "SweptCanopy"; add_child(canopy)
	# Freestanding support frame; the museum roof remains open.
	for x in [-8.25,8.25]:
		for z in [-7.0,7.0]:
			block(Vector3(x,4.0,z),Vector3(0.12,8.0,0.12),Color("454149"),true)
		block(Vector3(x,8.0,0),Vector3(0.12,0.14,14.1),Color("454149"))
	for z in [-7.0,7.0]:
		block(Vector3(0,8.0,z),Vector3(16.6,0.14,0.12),Color("454149"))
	for z in [-6.5,6.5]:
		block(Vector3(0,7.94,z),Vector3(16.5,0.06,0.06),Color("747078"))
	for x in [-6.5,6.5]:
		block(Vector3(x,7.94,0),Vector3(0.06,0.06,13.0),Color("747078"))
	# Long emissive strips are visible in the reflection probe as well as overhead.
	for x in [-7.55,7.55]:
		var strip := block(Vector3(x,7.82,0),Vector3(0.13,0.06,12.4),Color("faf4e8"))
		var glow := material(Color("faf4e8"),true)
		glow.emission_enabled = true; glow.emission = Color("faf4e8"); glow.emission_energy_multiplier = 2.0
		strip.material_override = glow
		var lamp := OmniLight3D.new(); lamp.position = Vector3(x,7.5,2.0)
		lamp.light_color = Color("fff2e8"); lamp.light_energy = 2.0; lamp.omni_range = 13.0
		add_child(lamp)
	probe = ReflectionProbe.new(); probe.position = Vector3(0,4.8,0)
	probe.size = Vector3(18.0,9.4,17.0); probe.max_distance = 32.0
	probe.cull_mask = 1; probe.box_projection = true; probe.interior = false
	probe.update_mode = ReflectionProbe.UPDATE_ONCE
	add_child(probe)
	var panel := Vector3(-6.1,0,4.5)
	block(panel+Vector3(0,0.6,0),Vector3(2.3,1.2,0.45),Color("e8e4dc"),true)
	inscription("THE LINE BECOMES A CEILING",panel+Vector3(0,1.77,0),0.0019)
	status = inscription("",panel+Vector3(0,1.52,0),0.0016,Color("873857"))
	for i in 5:
		var at := panel+Vector3((i%3-1)*0.72,1.08-(i/3)*0.28,0.25)
		var button := CanopyButton.new(); button.name = ["RULE","DIAMETER","REPEAT","FINISH","RESET"][i]
		button.collision_layer = (1<<20)|(1<<22); button.collision_mask = 0
		button.position = at; button.action = control.bind(i); add_child(button); buttons.append(button)
		var shape := CollisionShape3D.new(); var bounds := BoxShape3D.new(); bounds.size = Vector3(0.64,0.22,0.08)
		shape.shape = bounds; button.add_child(shape)
		block(at, bounds.size, Color("493841"))
		inscription(button.name,at+Vector3(0,0,0.05),0.0015,Color("fff5eb"))
	inscription("LOOK UP · ONE RULE, MANY RUNS",panel+Vector3(0,0.3,0.24),0.0015)
	rehang()
	update_status()

func control(index: int) -> void:
	match index:
		0: canopy.rule = (canopy.rule+1)%3
		1: canopy.radius_index = (canopy.radius_index+1)%3
		2: canopy.count_index = (canopy.count_index+1)%3
		3:
			canopy.finish = (canopy.finish+1)%3; canopy.apply_finish(); update_status(); return
		4: canopy.rule = 1; canopy.radius_index = 1; canopy.count_index = 1; canopy.finish = 0
	canopy.rebuild(); rehang(); update_status()

func rehang() -> void:
	if hangers: remove_child(hangers); hangers.queue_free()
	hangers = Node3D.new(); add_child(hangers)
	for coords in canopy.definition.anchors.values():
		var p := Vector3(coords[0],coords[1],coords[2])
		if absf(absf(p.x)-6.5) > 0.01 and absf(absf(p.z)-6.5) > 0.01: continue
		p.y += Canopy.RADII[canopy.radius_index]
		var rod := stroke(PackedVector3Array([p,Vector3(p.x,7.94,p.z)]),Color("737078"),0.012)
		remove_child(rod); hangers.add_child(rod)

func update_status() -> void:
	status.text = "%s · Ø %.2f m · %d\n%s" % [Canopy.RULES[canopy.rule],Canopy.RADII[canopy.radius_index]*2,Canopy.COUNTS[canopy.count_index],Canopy.FINISHES[canopy.finish]]
