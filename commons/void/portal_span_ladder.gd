extends "res://commons/primitives/combines/combine_portals.gd"
## Equal physical dimensions, increasing tessellation. No object-scale ladder.
@export var outside_diameter := 4.0
var pink_material: StandardMaterial3D

func spawn_portals() -> void:
	# Change the TorusMesh dimensions itself, not its transform or segment counts.
	if _base_mesh!=null:
		# The source scene's resource is shared with other museum instances.
		_base_mesh = _base_mesh.duplicate() as TorusMesh
		_base_portal.mesh = _base_mesh
		_base_mesh.inner_radius = outside_diameter*.5-.45
		_base_mesh.outer_radius = outside_diameter*.5
		_base_portal.scale = Vector3.ONE
		_base_portal.position.y = outside_diameter*.5
	super.spawn_portals()
	for i in _portals.size():
		var portal: MeshInstance3D=_portals[i]
		portal.scale=Vector3.ONE
		portal.position.y=outside_diameter*.5
		for light in portal.find_children("*","OmniLight3D",true,false): light.hide()
	if has_node("ExperimentPanel"):
		get_node("ExperimentPanel").position=Vector3(2.3,1.35,2.2)
	for camera in find_children("*","Camera3D",true,false): camera.current=false

func _update_selection() -> void:
	# Selection still updates the resolution readout; every ring stays translucent pink.
	if pink_material==null:
		pink_material = StandardMaterial3D.new()
		pink_material.albedo_color = Color(Color("ff4f9a"),.78)
		pink_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		pink_material.roughness = .55
		pink_material.metallic = 0.0
		_base_portal.material_override = pink_material
	selected_portal = clampi(selected_portal,0,maxi(0,_portals.size()-1))
	for portal in _portals: portal.material_override=pink_material
	if has_node("ExperimentPanel"): get_node("ExperimentPanel").update_readout()
