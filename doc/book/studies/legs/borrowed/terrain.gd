extends StaticBody3D
## Borrowed from ch12, Noise, as a small version: a bumpy ground with a collider.
## Contract: height_at(x, z) is the ground's height in metres at a place of the
## room; _ready() builds the mesh and the collider from it and from nothing else.
## Heights come from FastNoiseLite, between 0 and `height`, and fall to the
## floor along the four edges, so that a body can walk on and off. The ground is
## painted GROUND and is on collision layer 1, like the floor of base.tscn.
## It stands where it is put and is not meant to be turned.

const Look := preload("res://supplied/look.gd")

@export var size := Vector2(4.4, 3.0)   # metres, along x and along z
@export var cell := 0.2                 # metres from one corner of the mesh to the next
@export var height := 0.35              # metres: the highest a bump can be
@export var grain := 0.5                # bumps per metre, roughly
@export var noise_seed := 21            # another whole number, another ground
@export var band := 0.012               # metres: how wide the net's lines are

var noise := FastNoiseLite.new()

func _ready() -> void:
	noise.seed = noise_seed
	noise.frequency = grain
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_smooth_group(-1)   # every triangle flat: the facets are what the eye reads as uneven
	var columns := roundi(size.x / cell)
	var rows := roundi(size.y / cell)
	for row in rows:
		for column in columns:
			var a := _corner(column, row)
			var b := _corner(column + 1, row)
			var c := _corner(column + 1, row + 1)
			var d := _corner(column, row + 1)
			for corner: Vector3 in [a, b, c, a, c, d]:   # two triangles, wound clockwise seen from above
				tool.add_vertex(corner)
	tool.generate_normals()
	var mesh := tool.commit()
	var skin := MeshInstance3D.new()
	skin.name = "Skin"
	skin.mesh = mesh
	skin.material_override = Look.paint(Look.GROUND)
	add_child(skin)
	var net_tool := SurfaceTool.new()                   # the same corners again, as a net of thin bands: what makes the bumps readable
	net_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in rows + 1:
		for column in columns + 1:
			if column < columns:
				_band(net_tool, _corner(column, row), _corner(column + 1, row), Vector3(0, 0, band / 2.0))
			if row < rows:
				_band(net_tool, _corner(column, row), _corner(column, row + 1), Vector3(band / 2.0, 0, 0))
	var net := MeshInstance3D.new()
	net.name = "Net"
	net.mesh = net_tool.commit()
	var ink := Look.paint(Look.LINE)
	ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ink.cull_mode = BaseMaterial3D.CULL_DISABLED
	net.material_override = ink
	net.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(net)
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(mesh.get_faces())
	var collider := CollisionShape3D.new()
	collider.shape = shape
	add_child(collider)

## The ground's height at a place of the room, in metres.
func height_at(x: float, z: float) -> float:
	x -= global_position.x
	z -= global_position.z
	var edge := minf(size.x / 2.0 - absf(x), size.y / 2.0 - absf(z))   # metres to the nearest edge
	if edge <= 0.0:
		return 0.0
	var bump := noise.get_noise_2d(x, z) * 0.5 + 0.5                    # 0 to 1
	return global_position.y + 0.005 + height * bump * smoothstep(0.0, 0.8, edge)

func _corner(column: int, row: int) -> Vector3:
	var x := column * cell - size.x / 2.0
	var z := row * cell - size.y / 2.0
	return Vector3(x, height_at(x + global_position.x, z + global_position.z) - global_position.y, z)

## One line of the net: a flat band from a to b, lifted 4 mm off the ground.
func _band(tool: SurfaceTool, a: Vector3, b: Vector3, half: Vector3) -> void:
	var lift := Vector3(0, 0.004, 0)
	for corner: Vector3 in [a - half, b - half, b + half, a - half, b + half, a + half]:
		tool.add_vertex(corner + lift)
