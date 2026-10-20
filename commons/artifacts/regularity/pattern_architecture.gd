extends Node3D
## Opt-in receiver for actual map floor/wall cells. Each machine can become its source.
const Kit = preload("res://commons/artifacts/regularity/room_tools.gd")
const SOURCE_TOKENS := ["pattern_machine_a","pattern_machine_c","pattern_machine_d","pattern_mill"]
const SOURCE_NAMES := ["LOOM","KALEIDOSCOPE","STAMP PRESS","PATTERN MILL"]
const TINTS := [Color.WHITE,Color("ffd2ef"),Color("b4f4ff"),Color("ffe5ac")]
var source_index := 0
var tint_index := 0
var target := 0
var held := false
var repeat_size := 4.0
var sources: Dictionary = {}
var skins: Array[MeshInstance3D] = []
var readout: Label
var elapsed := 0.0
var built := false

func _ready() -> void:
	# A neutral floor makes the separate sample carpets readable on arrival.
	# This is an initial display choice; the existing target control stays available.
	if str(get_meta("config_target", "")) == "walls": target = 1
	var p := Kit.panel(self,"DRESS THE ARCHITECTURE",Vector3(0,1.2,0))
	p.add_button("SOURCE").pressed.connect(cycle_source)
	p.add_button("TARGET").pressed.connect(cycle_target)
	p.add_button("LIVE / HOLD").pressed.connect(toggle_hold)
	readout = p.add_readout("FINDING MACHINES")
	var lower := Kit.panel(self,"PATTERN / COLOUR",Vector3(0,0.88,-0.38))
	lower.add_button("REPEAT SIZE").pressed.connect(cycle_repeat)
	lower.add_button("TINT").pressed.connect(cycle_tint)
	lower.add_button("RESET").pressed.connect(reset)
	_build_skins.call_deferred()

func _build_skins() -> void:
	var grid: Node3D = get_parent()
	while grid != null and not str(grid.name).begins_with("SimGrid_"): grid = grid.get_parent()
	if grid == null: return
	var map_name := str(grid.name).trim_prefix("SimGrid_")
	var path := "res://commons/maps/"+map_name+"/map_data.json"
	if not FileAccess.file_exists(path): return
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var rows: Array = data.layers.structure
	var base := grid.to_local(global_position)
	# All floor cells and exposed vertical faces, batched into just two meshes.
	var floor_st := SurfaceTool.new()
	var wall_st := SurfaceTool.new()
	floor_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	wall_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in rows.size():
		for x in rows[z].size():
			var h := str(rows[z][x]).to_float()
			if h < 1.0: continue
			# The controller can be seated above the floor by the museum.
			# Map skins stay on the grid, including its height, not on that stand.
			var centre := Vector3(x,0,z)-base
			if h == 1.0:
				quad(floor_st,centre+Vector3(-0.5,0.026,-0.5),Vector3(1,0,0),Vector3(0,0,1))
			else:
				for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
					var xx: int = x+d.x
					var zz: int = z+d.y
					if xx<0 or zz<0 or zz>=rows.size() or xx>=rows[zz].size(): continue
					var other := maxf(1.0,str(rows[zz][xx]).to_float())
					if other >= h: continue
					var face := centre+Vector3(d.x*0.516,other-1.0,d.y*0.516)
					var across := Vector3(0,0,1) if d.x!=0 else Vector3(1,0,0)
					quad(wall_st,face-across*0.5,across,Vector3(0,h-other,0))
	for pair in [[floor_st,"FLOOR"],[wall_st,"WALLS"]]:
		var n := MeshInstance3D.new()
		n.name = "Architecture"+pair[1]
		n.mesh = pair[0].commit()
		n.material_override = Kit.material(Color.WHITE)
		n.material_override.cull_mode = BaseMaterial3D.CULL_DISABLED
		n.material_override.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		n.set_meta("receiver",pair[1])
		add_child(n)
		skins.append(n)
	built = true
	refresh()

func quad(st: SurfaceTool, origin: Vector3, u: Vector3, v: Vector3) -> void:
	var points := [origin,origin+u,origin+u+v,origin+v]
	var uv := [Vector2.ZERO,Vector2(u.length(),0),Vector2(u.length(),v.length()),Vector2(0,v.length())]
	# Continuous floor coordinates; wall addresses use their horizontal axis and height.
	var offset := Vector2(origin.x,origin.z) if absf(v.y)<0.01 else Vector2(origin.z if absf(u.z)>0.5 else origin.x,origin.y)
	for i in [0,1,2,0,2,3]:
		st.set_normal(u.cross(v).normalized())
		st.set_uv(uv[i]+offset)
		st.add_vertex(points[i])

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed<0.4: return
	elapsed = 0.0
	if sources.size()<4:
		for n in Kit.room_root(self).find_children("*","Node3D",true,false):
			var token := str(n.get_meta("artifact_lookup_name",""))
			if token in SOURCE_TOKENS: sources[token] = n
	if not held: refresh()

func source_texture() -> Texture2D:
	var n: Node = sources.get(SOURCE_TOKENS[source_index])
	if not is_instance_valid(n): return null
	# Every machine already owns a live proof/carpet texture; bind its actual output.
	var mat = n.get("_carpet_material" if SOURCE_TOKENS[source_index]=="pattern_machine_c" else "_carpet_mat")
	return mat.albedo_texture if mat is StandardMaterial3D else null

func refresh() -> void:
	var tex := source_texture()
	if tex != null and not held:
		for n in skins:
			if target==1 and n.get_meta("receiver")=="FLOOR": continue
			if target==2 and n.get_meta("receiver")=="WALLS": continue
			n.material_override.albedo_texture = tex
			n.material_override.albedo_color = TINTS[tint_index]
			n.material_override.uv1_scale = Vector3.ONE/repeat_size
	if readout != null:
		readout.text = "%s / %s / %s / %.0fm output" % [SOURCE_NAMES[source_index],["ROOM","WALLS","FLOOR"][target],"HELD" if held else ("LIVE" if tex!=null else "WAIT"),repeat_size]

func cycle_source() -> void:
	source_index = (source_index+1)%SOURCE_TOKENS.size()
	held = false
	refresh()

func cycle_target() -> void:
	target = (target+1)%3
	refresh()

func toggle_hold() -> void:
	held = not held
	if held:
		for n in skins:
			var tex: Texture2D = n.material_override.albedo_texture
			if tex != null: n.material_override.albedo_texture = ImageTexture.create_from_image(tex.get_image())
	refresh()

func cycle_repeat() -> void:
	repeat_size = 2.0 if repeat_size>=8.0 else repeat_size*2.0
	refresh()

func cycle_tint() -> void:
	tint_index = (tint_index+1)%TINTS.size()
	refresh()

func reset() -> void:
	held = false
	target = 0
	source_index = 0
	tint_index = 0
	repeat_size = 4.0
	refresh()
