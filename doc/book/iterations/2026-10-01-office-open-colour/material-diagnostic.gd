extends "res://doc/book/iterations/2026-10-01-office-open-colour/probe.gd"

func landing_checks() -> void:
	var grid := hall.get_node_or_null("SimGrid_Color_Walls")
	for i in 3600:
		if grid.has_meta("stage_grid_ready"): break
		await process_frame
	office = find_scene("/color_constellation_office.gd")
	for p in office.office_panes:
		p.hide()
	await shot("diagnostic-no-filter",Vector3(0.65,1.65,-7.1),Vector3(0,1.65,3.0),72)
	var p = office.office_panes[0]
	p.show()
	p.material_override.albedo_color = Color.WHITE
	await shot("diagnostic-white-multiply",Vector3(0.65,1.65,-7.1),Vector3(0,1.65,3.0),72)
	var shader := Shader.new()
	shader.code = "shader_type spatial; render_mode unshaded, blend_mul, cull_disabled, fog_disabled; void fragment() { ALBEDO = vec3(1.0); ALPHA = 1.0; }"
	var sm := ShaderMaterial.new()
	sm.shader = shader
	p.material_override = sm
	await shot("diagnostic-shader-white",Vector3(0.65,1.65,-7.1),Vector3(0,1.65,3.0),72)
	var all_env := root.find_children("*","WorldEnvironment",true,false)
	for e in all_env:
		print("ENV ",e.get_path()," ",e.environment.tonemap_exposure," ",e.environment.tonemap_mode," fog ",e.environment.fog_enabled)
	print("CAM ",camera.attributes, " ",camera.environment)
	print("PANE ",p.transparency, " ",p.material_overlay)
	complete = true
