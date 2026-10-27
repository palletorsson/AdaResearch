extends Node3D
## Angle grows with row along +z; x/y/z and combined turns across four 2D bands.
## Cube centres stay fixed. No second floor underneath the array.
const Parts = preload("res://commons/artifacts/rotation_studies/parts.gd")
const Witness = preload("res://commons/artifacts/rotation_studies/cube_witness.gd")
const SPACING := 2.0
const EDGE := 2.04
const BodyComparison = preload("res://commons/artifacts/rotation_studies/array_body_comparison.gd")
@export var show_body_comparison := true
@export_range(2, 10, 1) var rows := 10
@export_range(2, 4, 1) var columns := 4
@export_range(6.0, 12.0, 0.5) var band_spacing := 11.0
@export_range(0.0,20.0,0.5) var row_angle_step := 10.0
@export_enum("ALL", "X", "Y", "Z", "XYZ") var single_axis := "ALL"
@export var tower_band_positions: Dictionary = {}
@export var cube_edge := EDGE
@export var cube_pitch := SPACING
@export var walkway_height := 3.0
var bands: Array[Dictionary] = []
var body_comparison: Node3D
var tower_row := false
var tower_walkways := false

func _ready() -> void:
	# The compact hall reduces the repetitions, never the walker's scale.
	rows = clampi(int(get_meta("config_rows", rows)), 2, 10)
	tower_row = bool(get_meta("config_tower_row", false))
	tower_walkways = bool(get_meta("config_tower_walkways", false))
	cube_edge = clampf(float(get_meta("config_cube_edge", cube_edge)), .5, 3.0)
	cube_pitch = clampf(float(get_meta("config_cube_pitch", cube_pitch)), .5, 4.0)
	walkway_height = float(get_meta("config_walkway_height", walkway_height))
	single_axis = str(get_meta("config_single_axis", single_axis)).to_upper()
	if single_axis not in ["ALL", "X", "Y", "Z", "XYZ"]: single_axis = "ALL"
	columns = 1 if tower_row or (tower_walkways and single_axis == "ALL") else clampi(int(get_meta("config_columns", columns)), 1 if tower_walkways else 2, 4)
	var configured_positions = get_meta("config_tower_band_positions", tower_band_positions)
	if configured_positions is Dictionary: tower_band_positions = configured_positions
	show_body_comparison = bool(get_meta("config_show_body_comparison", show_body_comparison))
	band_spacing = maxf(float(get_meta("config_band_spacing", band_spacing)), columns * SPACING + 3.0)
	row_angle_step = clampf(float(get_meta("config_row_angle_step", row_angle_step)), 0.0, 20.0)
	var specs := [
		["X",-1.5*band_spacing,Vector3.RIGHT,-1.0,Color(0.78,0.43,0.30),"SLOPES ACROSS YOUR ROUTE"],
		["Y",-0.5*band_spacing,Vector3.UP,1.0,Color(0.38,0.68,0.46),"TURN IN THE HORIZONTAL PLANE"],
		["Z",0.5*band_spacing,Vector3.BACK,1.0,Color(0.38,0.55,0.78),"RIDGES ALONG YOUR ROUTE"],
		["XYZ",1.5*band_spacing,Vector3.ZERO,1.0,Color(0.62,0.43,0.74),"COMBINED / X THEN Y THEN Z"]]
	for spec in specs:
		if single_axis != "ALL" and spec[0] != single_axis: continue
		var band := Node3D.new()
		band.name = spec[0]
		band.position.x = spec[1]
		add_child(band)
		var cubes: Array[Node3D] = []
		var row_labels: Array[Label3D] = []
		for row in range(rows):
			for column in range(columns):
				var cube := Parts.box(band,"Cube_%02d_%02d" % [row,column],Vector3.ONE*cube_edge,Vector3((column-float(columns-1)/2.0)*cube_pitch,-cube_edge/2.0,cube_pitch/4.0+row*cube_pitch),spec[4])
				cube.set_meta("row",row)
				cube.set_meta("column",column)
				cubes.append(cube)
			var tag := Parts.label(band,"%02d / %.1f deg" % [row,row*row_angle_step],Vector3(columns*cube_pitch/2.0+0.55,0.025,cube_pitch/4.0+row*cube_pitch),24)
			if cube_edge <= 1.0: tag.pixel_size = .0035
			tag.rotation_degrees = Vector3(-90,180,0)
			row_labels.append(tag)
		var heading := Parts.label(band,"",Vector3(0,1.5,-2.6),29)
		var edges := MeshInstance3D.new()
		edges.name="CubeEdges"
		band.add_child(edges)
		var witnesses := MeshInstance3D.new()
		witnesses.name = "FaceWitnesses"
		band.add_child(witnesses)
		bands.append({"id":spec[0],"node":band,"axis":spec[2],"sign":spec[3],"cubes":cubes,"label":heading,"row_labels":row_labels,"edges":edges,"witnesses":witnesses,"title":spec[5]})
	# Compact the cubes, never the two differently sized test bodies.
	# Their world-space collision capsules remain 0.44 m and 1.2 m wide.
	if tower_walkways:
		# Four physical routes, not a row of objects to look at. Keep the
		# original 2.04 m cubes and 2 m pitch relative to the visitor's body.
		# A 3 m bank lifts the whole comparison clear of the tower slab;
		# falling off returns to the observation floor, never an invisible lid.
		for i in range(bands.size()):
			bands[i].node.position = Vector3(0 if single_axis != "ALL" else (i - 1.5) * 4.0, walkway_height, -(rows-1)*cube_pitch/2.0-cube_pitch/4.0)
			var at = tower_band_positions.get(bands[i].id)
			if at is Array and at.size() == 3:
				bands[i].node.position = Vector3(float(at[0]), float(at[1]), float(at[2]))
			bands[i].label.position = Vector3(0, 1.5, -2.0)
			if cube_edge <= 1.0:
				bands[i].label.pixel_size = .004
				bands[i].label.position = Vector3(0, .9, -1.4)
	elif tower_row:
		# One six-angle row per axis, joined end to end across the storey.
		# The factory's original array layout remains the default elsewhere.
		for i in range(bands.size()):
			bands[i].node.scale = Vector3.ONE * 0.5
			bands[i].node.position = Vector3((i - 1.5) * 7.8, 2.0, 0)
			for cube: Node3D in bands[i].cubes:
				cube.position = Vector3((int(cube.get_meta("row")) - float(rows - 1) / 2.0) * 2.6, -EDGE / 2.0, 0)
			for row in range(rows):
				bands[i].row_labels[row].position = Vector3((row - float(rows - 1) / 2.0) * 2.6, 0.025, 1.7)
			bands[i].label.position = Vector3(0, 2.3, -1.6)
	elif bool(get_meta("config_tower_bands", false)):
		for i in range(bands.size()):
			bands[i].node.scale = Vector3.ONE*0.5
			bands[i].node.position = Vector3((i-1.5)*2.7,2.0,0)
	apply_gradient()
	if show_body_comparison:
		body_comparison = BodyComparison.new()
		body_comparison.name = "BodyComparison"
		add_child(body_comparison)
		body_comparison.setup(self)

func apply_gradient() -> void:
	for band in bands:
		for cube: Node3D in band.cubes:
			var degrees := float(cube.get_meta("row"))*row_angle_step
			cube.basis = rotation_for_band(band,degrees)
		for row in range(rows): band.row_labels[row].text="%02d / %.1f deg" % [row,row*row_angle_step]
		band.label.text="%s / %d x %d CUBES\n%s\nWALK +Z / 0 TO %.1f DEGREES" % [band.id,columns,rows,band.title,(rows-1)*row_angle_step]
		if tower_walkways and single_axis != "ALL":
			band.label.text="%s / %s / %d x %d CUBES\nSAME CUBES / SAME ANGLES\nWALK +Z / 0 TO %.1f DEGREES" % [band.id,"WIDE" if columns > 1 else "SINGLE",columns,rows,(rows-1)*row_angle_step]
		if tower_row:
			band.label.text="%s / SAME CUBE\n0 TO %.1f DEGREES" % [band.id,(rows-1)*row_angle_step]
		_draw_edges(band)
		var poses: Array[Transform3D] = []
		for cube: Node3D in band.cubes:
			# These cubes sit in the floor: mark the top, since a side face is buried.
			poses.append(cube.transform * Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3.ZERO))
		band.witnesses.mesh = Witness.build(cube_edge / 2.0, poses)

func rotation_for_band(band: Dictionary, degrees: float) -> Basis:
	var radians := deg_to_rad(degrees)
	if band.id=="XYZ":
		# Rightmost acts first: X(-), then Y(+), then Z(+), in band coordinates.
		return Basis(Vector3.BACK,radians)*Basis(Vector3.UP,radians)*Basis(Vector3.RIGHT,-radians)
	return Basis(band.axis,radians*float(band.sign))

func _draw_edges(band: Dictionary) -> void:
	# One line mesh per band keeps all 40 individual cubes legible without
	# adding hundreds of separate edge objects or any extra collision.
	var mesh := ImmediateMesh.new()
	var material := StandardMaterial3D.new()
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color=Color(0.12,0.15,0.19)
	mesh.surface_begin(Mesh.PRIMITIVE_LINES,material)
	for cube: Node3D in band.cubes:
		for corner in range(8):
			var a:=Vector3(1 if corner&1 else -1,1 if corner&2 else -1,1 if corner&4 else -1)*(cube_edge/2.0+0.002)
			for bit in [1,2,4]:
				if corner&bit:continue
				var other:int=corner|bit
				var b:=Vector3(1 if other&1 else -1,1 if other&2 else -1,1 if other&4 else -1)*(cube_edge/2.0+0.002)
				mesh.surface_add_vertex(cube.transform*a)
				mesh.surface_add_vertex(cube.transform*b)
	mesh.surface_end()
	band.edges.mesh=mesh
