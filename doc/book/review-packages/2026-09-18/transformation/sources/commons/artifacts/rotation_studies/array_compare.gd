extends Node3D
## Angle grows with row along +z; x/y/z and combined turns across four 2D bands.
## Cube centres stay fixed. No second floor underneath the array.
const Parts = preload("res://commons/artifacts/rotation_studies/parts.gd")
const SPACING := 2.0
const EDGE := 2.04
const BodyComparison = preload("res://commons/artifacts/rotation_studies/array_body_comparison.gd")
@export var show_body_comparison := true
@export_range(2, 10, 1) var rows := 10
@export_range(2, 4, 1) var columns := 4
@export_range(6.0, 12.0, 0.5) var band_spacing := 11.0
@export_range(0.0,20.0,0.5) var row_angle_step := 10.0
var bands: Array[Dictionary] = []
var body_comparison: Node3D

func _ready() -> void:
	# The compact hall reduces the repetitions, never the walker's scale.
	rows = clampi(int(get_meta("config_rows", rows)), 2, 10)
	columns = clampi(int(get_meta("config_columns", columns)), 2, 4)
	band_spacing = maxf(float(get_meta("config_band_spacing", band_spacing)), columns * SPACING + 3.0)
	row_angle_step = clampf(float(get_meta("config_row_angle_step", row_angle_step)), 0.0, 20.0)
	var specs := [
		["X",-1.5*band_spacing,Vector3.RIGHT,-1.0,Color(0.78,0.43,0.30),"SLOPES ACROSS YOUR ROUTE"],
		["Y",-0.5*band_spacing,Vector3.UP,1.0,Color(0.38,0.68,0.46),"TURN IN THE HORIZONTAL PLANE"],
		["Z",0.5*band_spacing,Vector3.BACK,1.0,Color(0.38,0.55,0.78),"RIDGES ALONG YOUR ROUTE"],
		["XYZ",1.5*band_spacing,Vector3.ZERO,1.0,Color(0.62,0.43,0.74),"COMBINED / X THEN Y THEN Z"]]
	for spec in specs:
		var band := Node3D.new()
		band.name = spec[0]
		band.position.x = spec[1]
		add_child(band)
		var cubes: Array[Node3D] = []
		var row_labels: Array[Label3D] = []
		for row in range(rows):
			for column in range(columns):
				var cube := Parts.box(band,"Cube_%02d_%02d" % [row,column],Vector3.ONE*EDGE,Vector3((column-float(columns-1)/2.0)*SPACING,-EDGE/2.0,0.5+row*SPACING),spec[4])
				cube.set_meta("row",row)
				cube.set_meta("column",column)
				cubes.append(cube)
			var tag := Parts.label(band,"%02d / %.1f deg" % [row,row*row_angle_step],Vector3(columns*SPACING/2.0+0.55,0.025,0.5+row*SPACING),24)
			tag.rotation_degrees = Vector3(-90,180,0)
			row_labels.append(tag)
		var heading := Parts.label(band,"",Vector3(0,1.5,-2.6),29)
		var edges := MeshInstance3D.new()
		edges.name="CubeEdges"
		band.add_child(edges)
		bands.append({"id":spec[0],"node":band,"axis":spec[2],"sign":spec[3],"cubes":cubes,"label":heading,"row_labels":row_labels,"edges":edges,"title":spec[5]})
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
		_draw_edges(band)

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
			var a:=Vector3(1 if corner&1 else -1,1 if corner&2 else -1,1 if corner&4 else -1)*(EDGE/2.0+0.002)
			for bit in [1,2,4]:
				if corner&bit:continue
				var other:int=corner|bit
				var b:=Vector3(1 if other&1 else -1,1 if other&2 else -1,1 if other&4 else -1)*(EDGE/2.0+0.002)
				mesh.surface_add_vertex(cube.transform*a)
				mesh.surface_add_vertex(cube.transform*b)
	mesh.surface_end()
	band.edges.mesh=mesh
