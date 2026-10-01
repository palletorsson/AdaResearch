class_name Globe
extends MeshInstance3D

@export_range(4, 64) var segments: int = 16   # cuts around, like the slices of an orange
@export_range(1, 32) var rings: int = 8       # circles between the two poles

func _ready() -> void:
	build()

func build() -> void:
	segments = clampi(segments, 4, 64)
	rings = clampi(rings, 1, 32)
	var sphere := SphereMesh.new()
	sphere.radial_segments = segments
	sphere.rings = rings
	mesh = sphere

func triangles() -> int:
	var arrays := mesh.surface_get_arrays(0)
	return arrays[Mesh.ARRAY_INDEX].size() / 3
