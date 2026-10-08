extends Node3D
## Reusable pipe, tube or cable with the existing glassware port contract.
const Surface = preload("res://commons/primitives/pipes/swept_tube.gd")
const Network = preload("res://commons/primitives/pipes/run_network.gd")
const Ports = preload("res://commons/glass_rack/GlassSegmentPorts.gd")
var record: Dictionary = {}
var skin: MeshInstance3D

func configure(points: PackedVector3Array, radius := 0.08, kind := "tube", sides := 16, colour := Color("d877a2"), sag := 0.5) -> void:
	record = {"points":points,"radius":radius,"kind":kind,"sides":sides,"colour":colour}
	if kind == "cable": Network.shape_cable(record,sag)
	if skin: remove_child(skin); skin.queue_free(); skin = null
	var built: Dictionary = Surface.build(record.points,radius,sides,radius*0.22 if kind == "pipe" else 0.0)
	if built.is_empty(): return
	skin = MeshInstance3D.new(); skin.mesh = built.mesh; add_child(skin)
	var material := StandardMaterial3D.new(); material.albedo_color = colour
	material.roughness = 0.65 if kind == "cable" else 0.28
	material.metallic = 0.5 if kind == "pipe" else 0.0
	skin.material_override = material
	var path: PackedVector3Array = record.points
	Ports.apply_ports(self,{"in":Ports.create_port(path[0],path[0]-path[1],radius),"out":Ports.create_port(path[-1],path[-1]-path[-2],radius)})
