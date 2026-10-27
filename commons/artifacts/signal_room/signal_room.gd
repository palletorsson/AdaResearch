extends "res://commons/artifacts/reference_studies/build.gd"
## A reusable room. Viewer, cameras and input belong to the supplied apparatus.
const Score = preload("res://commons/artifacts/signal_room/score.gd")
const FOLD := 18.0 / 24.4
## Default museum envelope; a Void installation can fit the upper surfaces to
## its storey without changing the values, floor display or reachable controls.
@export_range(3.0, 12.0) var room_height := 7.15
var mode := 0
var seed_value := 2026
var row_offset := 0
var values := PackedByteArray()
var display_values := PackedByteArray()
var screen: StandardMaterial3D
var display_texture: ImageTexture
var patch_texture: ImageTexture
var readout: Label3D
var sample_readout: Label3D
var sample_row := 0

func build() -> void:
	var dark := material(Color(0.026, 0.029, 0.034), 0.86)
	var metal := material(Color(0.07, 0.077, 0.085), 0.5, 0.35)
	var edge := emissive(Color(0.30, 0.34, 0.38), 0.5)
	var wall_height := room_height - .15
	var fold_top := room_height - .747
	var fold_uv := FOLD if is_equal_approx(room_height,7.15) else 18.0/(18.0+fold_top)
	# Stable floor: black pixels never remove physical support.
	box(Vector3(0, -0.16, 1), Vector3(14, 0.3, 24), dark, true).name = "StableFloor"
	box(Vector3(0, wall_height/2, -9.3), Vector3(14, wall_height, 0.3), dark, true)
	for side in [-1.0, 1.0]:
		box(Vector3(side * 6.85, wall_height/2, 1), Vector3(0.3, wall_height, 24), dark, true)
		box(Vector3(side * 5.35, 0.006, 0), Vector3(0.025, 0.012, 18.4), edge)
		for z in [-9.0, -3.0, 3.0, 9.0]:
			box(Vector3(side * 6.58, wall_height/2, z), Vector3(0.18, wall_height, 0.18), metal)
		box(Vector3(side * 6.45, room_height-.43, 0), Vector3(0.07, 0.08, 18.3), edge)
	box(Vector3(0, room_height-.10, 1), Vector3(14, 0.2, 24), dark, true)
	for z in [-9.0, -3.0, 3.0, 9.0]:
		box(Vector3(0, room_height-.29, z), Vector3(13.5, 0.22, 0.15), metal)
	# One texture, unfolded across floor and back wall. No cell nodes.
	screen = StandardMaterial3D.new()
	screen.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	screen.cull_mode = BaseMaterial3D.CULL_DISABLED
	screen.disable_fog = true
	screen.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	quad("FloorDisplay", [Vector3(-5.2, 0.003, 9), Vector3(5.2, 0.003, 9), Vector3(5.2, 0.003, -9), Vector3(-5.2, 0.003, -9)], 0, fold_uv, screen)
	quad("FoldDisplay", [Vector3(-5.2, 0.003, -9), Vector3(5.2, 0.003, -9), Vector3(5.2, fold_top, -9), Vector3(-5.2, fold_top, -9)], fold_uv, 1, screen)
	for side in [-1.0, 1.0]:
		# Side monitors echo the full record. Their pixels are not new draws.
		quad("EchoWall", [Vector3(side*6.61,0.35,8.75),Vector3(side*6.61,0.35,-8.75),Vector3(side*6.61,room_height-.75,-8.75),Vector3(side*6.61,room_height-.75,8.75)],0,1,screen)
	# A ceiling strip brings the same addresses above the visitor's head.
	quad("CeilingEcho", [Vector3(-2.2,room_height-.47,9),Vector3(2.2,room_height-.47,9),Vector3(2.2,room_height-.47,-9),Vector3(-2.2,room_height-.47,-9)],0,1,screen)
	box(Vector3(-4.1,0.65,10.8),Vector3(2.35,1.3,0.55),metal,true)
	var patch := screen.duplicate() as StandardMaterial3D
	quad("SixteenCells", [Vector3(-5.02,0.33,11.085),Vector3(-3.92,0.33,11.085),Vector3(-3.92,1.43,11.085),Vector3(-5.02,1.43,11.085)],0,1,patch)
	# Thin ruled grid makes all 16 addresses countable in both modes.
	for line in 5:
		box(Vector3(-5.02+line*0.275,0.88,11.09),Vector3(0.006,1.11,0.007),edge)
		box(Vector3(-4.47,0.33+line*0.275,11.09),Vector3(1.11,0.006,0.007),edge)
	readout = label("", Vector3(0,1.58,11.1), 30, 0.0019)
	sample_readout = label("", Vector3(-4.43,1.65,11.1), 24, 0.0015)
	label("THE SAME VALUES\nDIFFERENT NEIGHBOURS",Vector3(2.8,0.45,11.1),26,0.0019)
	set_pattern(0,2026)
	patch.albedo_texture = patch_texture

func label(text_value: String, at: Vector3, font: int, pixel: float) -> Label3D:
	var node := Label3D.new()
	node.text = text_value
	node.position = at
	node.font_size = font
	node.pixel_size = pixel
	node.modulate = Color(0.72,0.75,0.78)
	node.outline_size = 0
	add_child(node)
	return node

func quad(title: String, corners: Array, v0: float, v1: float, surface: Material) -> void:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(corners)
	arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array([Vector2(0,v0),Vector2(1,v0),Vector2(1,v1),Vector2(0,v1)])
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0,1,2,0,2,3])
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var instance := mesh_at(mesh, Vector3.ZERO, surface)
	instance.name = title
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func set_pattern(which: int, next_seed: int = 2026) -> void:
	mode = clampi(which,0,2)
	seed_value = next_seed
	row_offset = 0
	values = Score.make_values(mode,seed_value)
	refresh_display()

func step_rows(amount: int = 1) -> void:
	row_offset = posmod(row_offset+amount,Score.ROWS)
	refresh_display()

func inspect_rows(row: int) -> void:
	sample_row = clampi(row,0,Score.ROWS-4)
	refresh_patch()
	state_changed.emit(evidence)

func refresh_display() -> void:
	display_values.resize(Score.COUNT)
	var picture := Image.create(Score.COLUMNS,Score.ROWS,false,Image.FORMAT_RGB8)
	for row in Score.ROWS:
		for column in Score.COLUMNS:
			var value: int = values[posmod(row+row_offset,Score.ROWS)*Score.COLUMNS+column]
			display_values[row*Score.COLUMNS+column] = value
			picture.set_pixel(column,row,Color(0.88,0.9,0.92) if value else Color(0.006,0.007,0.009))
	if display_texture == null:
		display_texture = ImageTexture.create_from_image(picture)
	else:
		display_texture.update(picture)
	screen.albedo_texture = display_texture
	evidence = {"mode":Score.NAMES[mode],"seed":seed_value,"columns":Score.COLUMNS,"rows":Score.ROWS,"zeros":Score.COUNT-values.count(1),"ones":values.count(1),"neighbour_changes":Score.neighbour_changes(values),"neighbour_pairs":Score.ROWS*(Score.COLUMNS-1)+(Score.ROWS-1)*Score.COLUMNS,"offset":row_offset,"shannon_bits_per_symbol":1.0,"automatic_animation":false}
	readout.text = "%s   /   SEED %d\n2048 BLACK   2048 WHITE   /   H = 1 bit\n%d of 7920 neighbour pairs differ" % [Score.NAMES[mode].to_upper(),seed_value,evidence.neighbour_changes]
	refresh_patch()
	state_changed.emit(evidence)

func refresh_patch() -> void:
	var patch := Image.create(4,4,false,Image.FORMAT_RGB8)
	for row in 4:
		for column in 4:
			var value: int = display_values[(sample_row+row)*Score.COLUMNS+column+6]
			# Upright console: row zero at the top, unlike the floor's near edge.
			patch.set_pixel(column,3-row,Color(0.88,0.9,0.92) if value else Color(0.006,0.007,0.009))
	if patch_texture == null:
		patch_texture = ImageTexture.create_from_image(patch)
	else:
		patch_texture.update(patch)
	sample_readout.text = "ROWS %03d–%03d / COLS 06–09" % [sample_row,sample_row+3]
