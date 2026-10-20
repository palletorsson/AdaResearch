extends RefCounted
## Solid construction-site scenery. Independent of the four teaching artifacts.

const PREFABS := {
	"live_junction": preload("res://commons/void/live_junction.tscn"),
	"wall_charger": preload("res://commons/void/model_b_charger.tscn"),
	"arrival_crate": preload("res://commons/void/arrival_crate.tscn"),
	"interface_floor": preload("res://commons/void/interface_floor.tscn"),
	"interface_wall": preload("res://commons/void/interface_wall.tscn"),
	"interface_pillar": preload("res://commons/void/interface_pillar.tscn"),
	"interface_ceiling_l": preload("res://commons/void/interface_ceiling_l.tscn"),
	"interface_ceiling_j": preload("res://commons/void/interface_ceiling_j.tscn"),

	"portal_ferry": preload("res://commons/void/portal_ferry.tscn"),
	"portal_span": preload("res://commons/void/portal_span.tscn"),
	"cube_walkway": preload("res://commons/void/cube_walkway.tscn"),
	"tetrahedron_blocker": preload("res://commons/artifacts/primitive_encounters/tetrahedron_blocker.tscn"),
	"pyramid_blocker": preload("res://commons/artifacts/primitive_encounters/pyramid_blocker.tscn"),
	"wedge_blocker": preload("res://commons/artifacts/primitive_encounters/wedge_blocker.tscn"),
	"platform_block": preload("res://commons/artifacts/primitive_encounters/platform_block.tscn"),
	"blue_barricade": preload("res://commons/artifacts/do_not_cross_barrier/do_not_cross_barrier.tscn"),
	"warning_tape": preload("res://commons/artifacts/do_not_cross_barrier/do_not_cross_barrier.tscn"),
	"steel_barrier": preload("res://commons/artifacts/steel_barricade/steel_barricade.tscn"),
	"traffic_cone": preload("res://commons/primitives/trafficcone/trafficcone.tscn"),
	"workbench": preload("res://commons/artifacts/hangar_worktable/hangar_worktable.tscn"),
	"point_light_switch": preload("res://commons/void/point_light_switch.tscn"),
	"pallet": preload("res://commons/artifacts/wood_pallet/wood_pallet.tscn"),
	"barrier": preload("res://commons/artifacts/concrete_barrier/concrete_barrier.tscn"),
	"fence": preload("res://commons/artifacts/fence_segment/fence_segment.tscn"),
	"work_light": preload("res://commons/artifacts/construction_site/work_light.tscn"),
	"scaffold_tarp": preload("res://commons/artifacts/construction_site/scaffold_tarp.tscn"),
	"striped_barricade": preload("res://commons/artifacts/construction_site/striped_barricade.tscn"),
	"chainlink_panel": preload("res://commons/artifacts/construction_site/chainlink_panel.tscn"),
	"unfinished_wall": preload("res://commons/artifacts/construction_site/unfinished_wall.tscn")
}

static func build(building: Node3D, host: Node3D, item: Dictionary, definition: Dictionary) -> StaticBody3D:
	var dimensions: Array = definition.size
	var size := Vector3(float(dimensions[0]), float(dimensions[1]), float(dimensions[2]))
	var body := StaticBody3D.new()
	body.name = "Prop_" + str(item.id)
	body.position = Vector3(float(item.position[0]), 0, float(item.position[1]))
	body.rotation_degrees.y = float(item.facing)
	body.scale = Vector3.ONE * float(item.get("scale", 1.0))
	body.set_meta("kind", item.kind)
	host.add_child(body)
	var collider := CollisionShape3D.new()
	var bounds := BoxShape3D.new()
	bounds.size = size
	collider.shape = bounds
	collider.position.y = size.y / 2.0
	if definition.get("collision", "bounds") == "parts":
		# Open scaffold bays and stud gaps must not become invisible solid boxes.
		collider.free()
	else:
		body.add_child(collider)
	if PREFABS.has(str(item.kind)):
		var prefab: Node3D = PREFABS[str(item.kind)].instantiate()
		prefab.name = "Prefab"
		if "target_id" in prefab: prefab.target_id = str(item.get("target", ""))
		for key in definition.get("settings",{}): prefab.set(key,definition.settings[key])
		body.add_child(prefab)
		return body
	var finish: StandardMaterial3D = building.material(Color(str(item.get("color", definition.color))), 0.83, 0.15 if item.kind == "container" else 0.0)
	var dark: StandardMaterial3D = building.material(Color("343b3d"), 0.7, 0.4)
	building.box(body, "Shell", Vector3(0, size.y/2, 0), size - Vector3(0.06, 0.04, 0.06), finish, false)
	if item.kind == "container":
		# Repeated corrugations share one draw per long side.
		for side in [-1, 1]:
			var placements: Array[Vector3] = []
			var rib_count := maxi(2, roundi((size.z-0.34)/0.25)+1)
			for i in range(rib_count): placements.append(Vector3(side*(size.x/2-0.025), size.y/2, -size.z/2+0.17+i*(size.z-0.34)/(rib_count-1)))
			_repeat(body, Vector3(0.05, size.y-0.18, 0.07), placements, finish)
			for z in [-size.z/2+0.05, size.z/2-0.05]:
				building.box(body, "CornerPost", Vector3(side*(size.x/2-0.05), size.y/2, z), Vector3(0.10,size.y,0.10), dark, false)
			for y in [0.05, size.y-0.05]:
				building.box(body, "SideRail", Vector3(side*(size.x/2-0.05),y,0),Vector3(0.10,0.10,size.z),dark,false)
			building.box(body, "Door", Vector3(side*size.x/4,size.y/2,size.z/2-0.035),Vector3(size.x/2-0.07,size.y-0.16,0.04),finish,false)
			for dx in [-0.30,0.30]:
				building.box(body, "LockingBar",Vector3(side*size.x/4+dx,size.y/2,size.z/2-0.01),Vector3(0.035,size.y-0.30,0.02),dark,false)
		var stencil := Label3D.new()
		stencil.text = "ADA / " + str(item.id).to_upper().replace("-", " ")
		stencil.font_size = 48
		stencil.pixel_size = 0.002
		stencil.modulate = Color("d6d8cb")
		stencil.outline_size = 0
		stencil.position = Vector3(-size.x/2-0.003,size.y*0.76,0)
		stencil.rotation_degrees.y = -90
		body.add_child(stencil)
	else:
		for side in [-1, 1]:
			for x in [-size.x/2+0.07,size.x/2-0.07]:
				building.box(body,"CrateUpright",Vector3(x,size.y/2,side*(size.z/2-0.04)),Vector3(0.14,size.y,0.08),dark,false)
			for y in [0.09,size.y-0.09]:
				building.box(body,"CrateBand",Vector3(0,y,side*(size.z/2-0.04)),Vector3(size.x,0.18,0.08),dark,false)
			var seams: Array[Vector3] = []
			for i in range(1,8): seams.append(Vector3(-size.x/2+size.x*i/8.0,size.y/2,side*(size.z/2-0.028)))
			_repeat(body,Vector3(0.012,size.y-0.36,0.02),seams,dark)
		for x in [-size.x*0.28,size.x*0.28]:
			building.box(body,"TopStrap",Vector3(x,size.y-0.01,0),Vector3(0.06,0.02,size.z),dark,false)
	return body

static func _repeat(host: Node3D, size: Vector3, positions: Array[Vector3], finish: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = mesh
	batch.instance_count = positions.size()
	for i in range(positions.size()): batch.set_instance_transform(i,Transform3D(Basis.IDENTITY,positions[i]))
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = batch
	instance.material_override = finish
	host.add_child(instance)
