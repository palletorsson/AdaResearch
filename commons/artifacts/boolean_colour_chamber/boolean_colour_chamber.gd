extends Node3D
## A common walkable floor beneath different Boolean recipes.
## Geometry stays fixed when the surface changes. No displacement shader.
signal surface_changed(value: int)
@export_enum("path", "lens", "shell", "ring", "cross", "fold") var mode: String = "path"
@export_range(0, 3) var finish: int = 0
@export var controls: bool = true
var surface: ShaderMaterial
var stock: CSGCombiner3D
var status: Label3D
var lamps: Array[OmniLight3D] = []
var built := false
var breathing := false
var elapsed := 0.0
const SurfaceShader = preload("res://commons/artifacts/boolean_colour_chamber/cut_surface.gdshader")
const PALETTES = [Color(.6,.48,1),Color(1,.48,.11),Color(.50,.72,1),Color(.85,.85,.82)]

class SurfaceButton extends StaticBody3D:
 var action: Callable
 func pointer_event(event) -> void:
  # XRToolsPointerEvent.Type.PRESSED; accepts the standard pointer contract.
  if event.event_type == 2: action.call()

func apply_grid_config(config: Dictionary) -> void:
 var next_mode := str(config.get("mode", mode))
 if next_mode in ["path", "lens", "shell", "ring", "cross", "fold"]: mode = next_mode
 finish = clampi(int(config.get("surface", finish)), 0, 3)
 if built: _build()

func _ready() -> void:
 _build()

func _process(delta: float) -> void:
 if breathing:
  elapsed += delta * .22
  surface.set_shader_parameter("clock", elapsed)

func _build() -> void:
 for child in get_children():
  remove_child(child)
  child.queue_free()
 lamps.clear()
 surface = ShaderMaterial.new()
 surface.shader = SurfaceShader
 surface.set_shader_parameter("finish", finish)
 surface.set_shader_parameter("motion", 1.0 if breathing else 0.0)
 stock = CSGCombiner3D.new()
 stock.name = "CarvedBody"
 stock.use_collision = true
 stock.collision_layer = 1
 stock.collision_mask = 1
 add_child(stock)
 match mode:
  "path": _path_space()
  "lens": _lens_space()
  "shell": _shell_space()
  "ring": _ring_space()
  "cross": _cross_space()
  "fold": _fold_space()
 _floor()
 _lights()
 if controls: _controls()
 built = true
 set_finish(finish)

func _box(parent: Node, key: String, size: Vector3, at: Vector3, op: int = 0) -> CSGBox3D:
 var shape := CSGBox3D.new()
 shape.name = key
 shape.size = size
 shape.position = at
 shape.operation = op
 shape.material = surface
 parent.add_child(shape)
 return shape

func _sphere(parent: Node, key: String, radius: float, at: Vector3, op: int = 0) -> CSGSphere3D:
 var shape := CSGSphere3D.new()
 shape.name = key
 shape.radius = radius
 shape.radial_segments = 32
 shape.rings = 20
 shape.smooth_faces = true
 shape.position = at
 shape.operation = op
 shape.material = surface
 parent.add_child(shape)
 return shape

func _cut_group(key: String) -> CSGCombiner3D:
 var cut := CSGCombiner3D.new()
 cut.name = key
 cut.operation = CSGShape3D.OPERATION_SUBTRACTION
 stock.add_child(cut)
 return cut

func _path_space() -> void:
 _box(stock, "Cube", Vector3(11,7,13), Vector3(0,3.5,0))
 var cut := _cut_group("UnionOfPathSpheres")
 for i in 7:
  var z := -7.2 + i*2.4
  var x := sin(i*1.15)*1.2
  _sphere(cut, "PathSphere_%d" % i, 3.35, Vector3(x,2.2,z))
 # Two high bites reveal intersecting cut boundaries above the walk.
 _sphere(cut, "HighAlcove", 2.9, Vector3(-2.1,4.6,-1.4))
 _sphere(cut, "HighOculus", 2.55, Vector3(1.1,6.0,2.8))

func _lens_space() -> void:
 _box(stock, "Cube", Vector3(11,7,13), Vector3(0,3.5,0))
 var cut := _cut_group("IntersectionVoid")
 _sphere(cut, "VolumeA", 4.7, Vector3(-1.5,3.0,0))
 _sphere(cut, "VolumeB", 4.7, Vector3(1.5,3.0,0), CSGShape3D.OPERATION_INTERSECTION)
 # Doorways meet the lens where a standing body has sufficient width.
 _door("Entry", -5.0)
 _door("Exit", 5.0)
 var shaft := CSGCylinder3D.new()
 shaft.name = "LightWell"
 shaft.radius = 1.1
 shaft.height = 5.0
 shaft.position = Vector3(0,6,0)
 shaft.operation = CSGShape3D.OPERATION_SUBTRACTION
 shaft.material = surface
 stock.add_child(shaft)

func _shell_space() -> void:
 # Joined spherical stock: two bodies produce one envelope.
 _sphere(stock, "OuterA", 4.9, Vector3(-1.65,3.0,-1.5))
 _sphere(stock, "OuterB", 4.9, Vector3(1.65,3.0,1.5))
 var hollow := _cut_group("UnionOfInnerVoids")
 _sphere(hollow, "InnerA", 4.18, Vector3(-1.65,3.0,-1.5))
 _sphere(hollow, "InnerB", 4.18, Vector3(1.65,3.0,1.5))
 # The clear central route is deliberate; the smaller pores frame side views.
 _door("Entry", -5.4)
 _door("Exit", 5.4)
 for i in 5:
  var a := float(i)*TAU/5.0
  _sphere(stock, "Pore_%d" % i, 1.10, Vector3(cos(a)*4.5,4.6,sin(a)*4.0), 2)
 # Flatten underside so the map floor supports the full artifact.
 _box(stock, "BelowFloor", Vector3(20,8,20), Vector3(0,-4.0,0), 2)

func _cylinder(parent: Node, key: String, radius: float, height: float, at: Vector3, rotation_value: Vector3 = Vector3.ZERO, op: int = 0) -> CSGCylinder3D:
 var cut := CSGCylinder3D.new()
 cut.name = key
 cut.radius = radius
 cut.height = height
 cut.sides = 48
 cut.smooth_faces = true
 cut.position = at
 cut.rotation = rotation_value
 cut.operation = op
 cut.material = surface
 parent.add_child(cut)
 return cut

func _ring_space() -> void:
 _box(stock, "Block", Vector3(13,7,13), Vector3(0,3.5,0))
 var ring := CSGTorus3D.new()
 ring.name = "AnnularVoid"
 ring.inner_radius = 1.45
 ring.outer_radius = 5.55
 ring.sides = 64
 ring.ring_sides = 24
 ring.smooth_faces = true
 ring.position.y = 1.35
 ring.operation = CSGShape3D.OPERATION_SUBTRACTION
 ring.material = surface
 stock.add_child(ring)
 _door("Entry", 5.8)
 _door("Exit", -5.8)
 _cylinder(stock,"OffsetLightWell",.95,7,Vector3(3.5,4.5,0),Vector3.ZERO,2)

func _cross_space() -> void:
 _box(stock, "Block", Vector3(13,8,13), Vector3(0,4,0))
 var cuts := _cut_group("CrossingVoids")
 _cylinder(cuts,"NorthSouth",2.55,16,Vector3(0,1.4,0),Vector3(PI*.5,0,0))
 _cylinder(cuts,"EastWest",2.55,16,Vector3(0,1.4,0),Vector3(0,0,PI*.5))
 _cylinder(cuts,"HighDiagonal",1.65,18,Vector3(0,4.25,0),Vector3(PI*.5,PI*.25,0))
 _cylinder(cuts,"SkyShaft",1.4,10,Vector3(0,5,0))

func _fold_space() -> void:
 _box(stock, "Block", Vector3(13,8,13), Vector3(0,4,0))
 var cuts := _cut_group("TiltedBoxVoids")
 for i in 3:
  var sign_value := -1.0 if i%2==0 else 1.0
  var cut := _box(cuts,"Fold_%d"%i,Vector3(5.5,6.0,6.4),Vector3(sign_value*.4,2.1,-4.4+i*4.4))
  cut.rotation = Vector3(0,deg_to_rad(sign_value*10),deg_to_rad(sign_value*22))
 # A narrow inclined slit admits sky without making another walking route.
 var slit := _box(stock,"RoofSlit",Vector3(.7,9,11),Vector3(-2.4,4.5,0),2)
 slit.rotation.z = deg_to_rad(-18)

func _door(key: String, z: float) -> void:
 var door := CSGCylinder3D.new()
 door.name = key
 door.radius = 1.9
 door.height = 5.3
 door.sides = 40
 door.rotation.x = PI*.5
 door.position = Vector3(0,1.45,z)
 door.operation = CSGShape3D.OPERATION_SUBTRACTION
 door.material = surface
 stock.add_child(door)

func _floor() -> void:
 var floor_body := StaticBody3D.new()
 floor_body.name = "LevelFloor"
 var col := CollisionShape3D.new()
 var shape := BoxShape3D.new()
 shape.size = Vector3(14,.2,17)
 col.shape = shape
 floor_body.position.y = -.10
 floor_body.add_child(col)
 var visual := MeshInstance3D.new()
 var mesh := BoxMesh.new()
 mesh.size = shape.size
 visual.mesh = mesh
 var mat := StandardMaterial3D.new()
 mat.albedo_color = Color(.10,.115,.14)
 mat.metallic = .25
 mat.roughness = .32
 visual.material_override = mat
 floor_body.add_child(visual)
 add_child(floor_body)
 # Small lit inlays remain level. They mark the shared route without a raised rail.
 var inlays: Array[Vector3] = []
 if mode == "ring":
  for i in 16:
   var a := float(i)*TAU/16.0
   inlays.append(Vector3(sin(a)*3.5,.005,cos(a)*3.5))
  inlays.append(Vector3(0,.005,6.0))
  inlays.append(Vector3(0,.005,-6.0))
 else:
  for z in [-6.0,-3.0,0.0,3.0,6.0]: inlays.append(Vector3(0,.005,z))
 for at in inlays:
  var tile := MeshInstance3D.new()
  var plane := BoxMesh.new()
  plane.size = Vector3(.07,.009,.40)
  tile.mesh = plane
  tile.position = at
  if mode == "ring" and absf(at.z)<5: tile.rotation.y = atan2(at.z,-at.x)
  var light_mat := StandardMaterial3D.new()
  light_mat.albedo_color = Color(.50,.58,.67)
  light_mat.emission_enabled = true
  light_mat.emission = Color(.22,.29,.4)
  tile.material_override = light_mat
  add_child(tile)

func _lights() -> void:
 for at in [Vector3(-1.5,3.3,-3.0),Vector3(1.5,3.5,1.3),Vector3(0,2.8,5.0)]:
  var lamp := OmniLight3D.new()
  lamp.position = at
  lamp.omni_range = 10.0
  lamp.light_energy = 1.7
  lamp.shadow_enabled = false
  lamps.append(lamp)
  add_child(lamp)

func set_finish(value: int) -> void:
 finish = clampi(value,0,3)
 if surface: surface.set_shader_parameter("finish", finish)
 for i in lamps.size():
  lamps[i].light_color = PALETTES[finish].lerp(Color.WHITE, .38+i*.16)
 if is_instance_valid(status):
  status.text = ["PEARL", "AMBER", "CHROME", "CHALK"][finish] + (" / DRIFT" if breathing else " / STILL")
 surface_changed.emit(finish)

func toggle_motion() -> void:
 breathing = not breathing
 surface.set_shader_parameter("motion", 1.0 if breathing else 0.0)
 set_finish(finish)

func _text(parent: Node, text: String, at: Vector3, scale_px: float = .002) -> Label3D:
 var label := Label3D.new()
 label.text = text
 label.font_size = 28
 label.pixel_size = scale_px
 label.position = at
 label.modulate = Color(.9,.91,.95)
 parent.add_child(label)
 return label

func _controls() -> void:
 var panel := Node3D.new()
 panel.name = "MaterialPlinth"
 panel.position = Vector3(2.6,0,7.2)
 add_child(panel)
 var body := StaticBody3D.new()
 var mesh := MeshInstance3D.new()
 var box := BoxMesh.new()
 box.size = Vector3(.90,1.12,.34)
 mesh.mesh = box
 var mat := StandardMaterial3D.new()
 mat.albedo_color = Color(.04,.05,.065)
 mesh.material_override = mat
 body.position.y = .56
 body.add_child(mesh)
 var shape := CollisionShape3D.new()
 var bs := BoxShape3D.new()
 bs.size = box.size
 shape.shape = bs
 body.add_child(shape)
 panel.add_child(body)
 status = _text(panel, "", Vector3(0,1.45,.18), .0016)
 _text(panel, "SAME SPACE / ANOTHER SKIN", Vector3(0,1.65,.18), .0013)
 for i in 4:
  _button(panel, ["PEARL", "AMBER", "CHROME", "CHALK"][i], Vector3(-.315+i*.21,1.22,.19), func(): set_finish(i))
 _button(panel, "DRIFT", Vector3(0,.96,.19), toggle_motion, Vector3(.36,.12,.07))

func _button(parent: Node, title: String, at: Vector3, action: Callable, size: Vector3 = Vector3(.17,.14,.07)) -> void:
 var button := SurfaceButton.new()
 button.name = "Button_"+title
 button.action = action
 button.position = at
 button.collision_layer = (1 << 20) | (1 << 22)
 button.collision_mask = 0
 var shape := CollisionShape3D.new()
 var box := BoxShape3D.new()
 box.size = size
 shape.shape = box
 button.add_child(shape)
 var mi := MeshInstance3D.new()
 var bm := BoxMesh.new()
 bm.size = size
 mi.mesh = bm
 var mat := StandardMaterial3D.new()
 mat.albedo_color = Color(.22,.25,.3)
 mi.material_override = mat
 button.add_child(mi)
 parent.add_child(button)
 _text(button,title,Vector3(0,0,.04),.0014)
