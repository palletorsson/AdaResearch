extends "res://commons/artifacts/spine_films/film_stage.gd"
const E = preload("res://commons/artifacts/spine_films/early/geometry.gd")
const Field = preload("res://algorithms/color/pillarcolorcollection/hsv_field.gdshader")
var columns: Array[MeshInstance3D] = []
var ceiling: MeshInstance3D
var marker: MeshInstance3D
var source: Node3D
var origin_frame: Node3D

func _build() -> void:
	title_text = "Colour makes an edge disappear"
	phases.assign(["One address, dark to light", "A field of colour", "The ceiling meets the columns", "Separate them; find the edge"])
	notes.assign(["Hue and saturation stay fixed while value rises.","These addresses use the museum's HSV function.","Matching colours make the boundary difficult to see.","The fog-like effect comes from matching surfaces, not simulated fog."])
	source_paths.assign(["res://algorithms/color/pillarcolorcollection/pillarcolorcollection.gd","res://algorithms/color/pillarcolorcollection/hsv_field.gdshader"])
	source=load(source_paths[0]).new()
	origin_frame=Node3D.new(); display.add_child(origin_frame)
	# Keep the original field coordinates and shader offsets, then reduce the
	# complete explanation uniformly to fit the monitor camera.
	origin_frame.scale=Vector3.ONE*0.25
	origin_frame.position=Vector3(-1.6,0,-2.4)
	for z in range(7):
		for x in range(5):
			var at := Vector3(float(x)*3.2,0,float(z)*3.2)
			var hsv: Vector3=source.call("hsv_at",at)
			var shape:=CylinderMesh.new();shape.height=4.14;shape.top_radius=0.48;shape.bottom_radius=0.48;shape.radial_segments=24
			var column:=E.mesh(origin_frame,shape,E.WHITE)
			column.position=at+Vector3(0,2.53,0)
			var mat:=ShaderMaterial.new();mat.shader=Field
			mat.set_shader_parameter("field_mode",1)
			mat.set_shader_parameter("sample_hsv",Vector3(hsv.x,hsv.y,1))
			mat.set_shader_parameter("bottom_y",-2.07);mat.set_shader_parameter("top_y",2.07)
			column.material_override=mat;columns.append(column)
	var plane:=PlaneMesh.new();plane.size=Vector2(15.2,21.6)
	ceiling=E.mesh(origin_frame,plane,E.WHITE)
	ceiling.position=Vector3(6.4,4.6,9.6)
	ceiling.material_override=source.call("make_field_material",2,0.0,0.0)
	marker=E.sphere(origin_frame,Vector3(6.4,0.46,9.6),0.65,E.WHITE)
	E.box(display,Vector3(0,-0.1,0),Vector3(4.5,0.2,6),E.INK)
	evidence={"column_count":35,"shader":Field.resource_path,"same_hsv_mapping":true,"volumetric_fog":false,"geometry_note":"simplified cylinders retain the source field's coordinates and material rule"}
	frame_scene(Vector3(0,0.6,0),8.2,0.48,0.035)

func _draw(time: float) -> void:
	var p:=phase_index(time);var u:=phase_progress(time)
	for i in range(columns.size()):columns[i].visible=p>0 or i==17
	marker.visible=p==0
	var h:=lerpf(0.46,4.6,smoothstep(0,1,u))
	marker.position=Vector3(6.4,h,9.6)
	marker.material_override.albedo_color=source.call("sample_volume",marker.position)
	marker.material_override.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	ceiling.visible=p>=2
	var gap:=lerpf(3.4,0,smoothstep(0,0.7,u)) if p==2 else 0.0
	if p==3:gap=sin(clampf((u-0.3)/0.7,0,1)*PI)*3.4
	ceiling.position.y=4.6+gap
	evidence["ceiling_height"]=ceiling.position.y

func _exit_tree() -> void:
	if is_instance_valid(source):source.free()
