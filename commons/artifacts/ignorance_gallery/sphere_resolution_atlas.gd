extends Node3D
const Kit = preload("res://commons/artifacts/ignorance_gallery/gallery_kit.gd")
const Inspect = preload("res://commons/primitives/shared/mesh_inspection.gd")
var specimens: Array[MeshInstance3D]=[]

func _ready() -> void:
	# Rows vary radial segments; columns vary rings. Neither variable means "quality" alone.
	var rings := [1,4,12]
	var radials := [4,8,16,32]
	for r in radials.size():
		for c in rings.size():
			var at := Vector3((c-1)*1.58,0,(r-1.5)*1.85)
			Kit.pedestal(self,at,0.78,0.9)
			var m := SphereMesh.new();m.radius=0.39;m.height=0.78
			m.radial_segments=radials[r];m.rings=rings[c]
			var n := Kit.exhibit(self,m,at+Vector3.UP*1.175,Kit.WHITE,"Sphere_%d_%d"%[radials[r],rings[c]])
			n.add_child(Inspect.overlay(m));specimens.append(n)
			Kit.label(self,"%d AROUND / %d RINGS"%[radials[r],rings[c]],at+Vector3(0,0.55,-0.456),0.00125,PI)
	Kit.lamp(self,Vector3(0,3.2,0),0.8,7)
