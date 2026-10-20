extends Node3D
## The original five rotated hollow cubes, turned down into an elevator shaft.
## Only their longitudinal length is shortened. The bore stays body-sized.
const Tunnel = preload("res://algorithms/transformation/booleanTunnel/boolean_tunnel.tscn")
const Parts = preload("res://commons/artifacts/rotation_studies/parts.gd")
var tunnel: Node3D

func _ready() -> void:
	tunnel=Tunnel.instantiate()
	tunnel.name="OriginalBooleanTunnel"
	add_child(tunnel)
	tunnel.apply_grid_config({"num_segments":5,"rotation_per_segment":18,
		"segment_vertical_offset":-2.0,"accrual":"ramp"})
	tunnel.basis=Basis(Vector3.RIGHT,PI/2.0).scaled_local(Vector3(.75,.75,.24))
	tunnel.position.y=.12
	# Walking over a twisted outer rim catches feet between its rings. A flush
	# entrance tongue reaches the clear bore; step off its end to descend.
	Parts.box(self,"Entrance",Vector3(2.6,.10,1.0),Vector3(-1.3,-.05,0),Color("d2c2a5"))
	set_meta("source_artifact","boolean_tunnel")
