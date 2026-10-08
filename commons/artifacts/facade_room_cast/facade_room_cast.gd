extends Node3D
## One void definition, two results: stock minus void; stock intersect void.
## Reuses the facade library locally. Existing facade scenes are not changed.
const Openings = preload("res://commons/facade_parts/parts/opening_parts.gd")
const Cornices = preload("res://commons/facade_parts/parts/cornice_parts.gd")
const Materials = preload("res://commons/facade_parts/facade_materials.gd")
const PLAN = "res://commons/facade_parts/presets/nyc_tenement.json"
const ROOM_ORIGIN = Vector3(-6,0,0)
const CAST_ORIGIN = Vector3(6,0,0)
var room: CSGCombiner3D
var positive: CSGCombiner3D
var room_void: CSGCombiner3D
var cast_void: CSGCombiner3D
var plaster: StandardMaterial3D
var stock_material: StandardMaterial3D
var facade: Node3D
var source_plan: Dictionary

func _ready() -> void:
 source_plan = JSON.parse_string(FileAccess.get_file_as_string(PLAN))
 plaster = Materials.plaster(Color(.70,.67,.61),.88)
 var wall_hex: String = source_plan.get("materials",{}).get("wall","#8B4513")
 stock_material = Materials.stone(Color.html(wall_hex).lightened(.16))
 room = _result("Room",ROOM_ORIGIN,CSGShape3D.OPERATION_SUBTRACTION)
 positive = _result("Positive",CAST_ORIGIN,CSGShape3D.OPERATION_INTERSECTION)
 room_void = room.get_node("Interior")
 cast_void = positive.get_node("Interior")
 _facade()
 _ground()
 _lighting()
 _label("THE ROOM",ROOM_ORIGIN+Vector3(0,.35,4.65))
 _label("THE ROOM'S VOLUME",CAST_ORIGIN+Vector3(0,.35,4.65))

func _result(key: String, at: Vector3, operation: int) -> CSGCombiner3D:
 var result := CSGCombiner3D.new()
 result.name = key
 result.position = at
 result.use_collision = true
 result.collision_layer = 1
 result.collision_mask = 1
 add_child(result)
 _box(result,"Stock",Vector3(8,5,7),Vector3(0,2.5,0),0,stock_material if operation==2 else plaster)
 var interior := _interior()
 interior.operation = operation
 result.add_child(interior)
 return result

func _interior() -> CSGCombiner3D:
 var v := CSGCombiner3D.new()
 v.name = "Interior"
 # The room is open down to the separate finished floor at y=0.
 _box(v,"RoomVolume",Vector3(5.8,4.0,4.5),Vector3(-.4,1.85,.45))
 var alcove := CSGSphere3D.new()
 alcove.name = "CurvedAlcove"
 alcove.radius = 2.35
 alcove.radial_segments = 48
 alcove.rings = 28
 alcove.smooth_faces = true
 alcove.position = Vector3(1.2,1.85,-.65)
 alcove.material = plaster
 v.add_child(alcove)
 # Same dimensions as the existing single_door(2.0,3.3) and rect_window(2,2).
 _box(v,"Doorway",Vector3(1.4,3.136,2),Vector3(-2,1.468,3.2))
 _box(v,"Window",Vector3(1.4,1.6,1.8),Vector3(1.6,2.4,3.2))
 _box(v,"WindowReveal",Vector3(1.75,1.92,.65),Vector3(1.6,2.4,2.6))
 # Subtract from the void: these become room mouldings and marks in the positive.
 _box(v,"SkirtingImpression",Vector3(.24,.22,4.5),Vector3(-3.3,.11,.45),2)
 _box(v,"RailImpression",Vector3(.28,.16,4.5),Vector3(-3.3,3.35,.45),2)
 return v

func _box(parent: Node, key: String, size: Vector3, at: Vector3, operation: int = 0, mat: Material = null) -> CSGBox3D:
 var box := CSGBox3D.new()
 box.name = key
 box.size = size
 box.position = at
 box.operation = operation
 box.material = mat if mat else plaster
 parent.add_child(box)
 return box

func _facade() -> void:
 facade = Node3D.new()
 facade.name = "ExistingFacadeParts"
 facade.position = ROOM_ORIGIN
 add_child(facade)
 var window_params: Dictionary = {"wall_depth":.25}
 # Borrow the actual ground-floor window parameters from the existing plan.
 for placement in source_plan.get("placements",[]):
  if placement.get("row",-1)==4 and placement.get("part","")=="rect_window":
   window_params.merge(placement.get("params",{}),true)
   break
 var window = Openings.rect_window(2,2,window_params)
 window.name = "WindowFrame"
 window.position = Vector3(.6,1.4,3.5)
 _remove_parts(window,["GlassPane"])
 facade.add_child(window)
 var door = Openings.single_door(2,3.3,{"wall_depth":.25})
 door.name = "DoorFrame"
 door.position = Vector3(-3,0,3.5)
 _remove_parts(door,["DoorVoid","UpperPanel","LowerPanel","Handle"])
 facade.add_child(door)
 var shelf = Cornices.cornice_shelf(8,.45,{"projection":.23})
 shelf.position = Vector3(-4,4.55,3.5)
 facade.add_child(shelf)
 var dentils = Cornices.dentil_band(8,.20,{"block_w":.16,"block_h":.14,"block_d":.14,"count":30})
 dentils.position = Vector3(-4,4.4,3.5)
 facade.add_child(dentils)
 var band = Cornices.string_course(8,.12,{"depth":.10})
 band.position = Vector3(-4,3.9,3.5)
 facade.add_child(band)

func _remove_parts(parent: Node, names: Array) -> void:
 for key in names:
  var node = parent.get_node_or_null(NodePath(key))
  if node:
   parent.remove_child(node)
   node.free()

func _ground() -> void:
 var body := StaticBody3D.new()
 body.name = "SharedGround"
 body.position.y = -.10
 var col := CollisionShape3D.new()
 var shape := BoxShape3D.new()
 shape.size = Vector3(26,.2,16)
 col.shape = shape
 body.add_child(col)
 var mesh := MeshInstance3D.new()
 var box := BoxMesh.new()
 box.size = shape.size
 mesh.mesh = box
 mesh.material_override = Materials.stone(Color(.32,.30,.27),.9)
 body.add_child(mesh)
 add_child(body)

func _lighting() -> void:
 for spec in [[ROOM_ORIGIN+Vector3(-.5,3.5,.8),Color(1,.96,.88),.35],[CAST_ORIGIN+Vector3(-3,4.8,4.5),Color(1,.97,.92),.50],[CAST_ORIGIN+Vector3(3,3,-3),Color(.86,.91,1),.24]]:
  var lamp := OmniLight3D.new()
  lamp.position = spec[0]
  lamp.light_color = spec[1]
  lamp.light_energy = spec[2]
  lamp.omni_range = 10
  lamp.shadow_enabled = true
  add_child(lamp)

func _label(words: String, at: Vector3) -> void:
 var label := Label3D.new()
 label.text = words
 label.font_size = 32
 label.pixel_size = .003
 label.modulate = Color(.85,.80,.68)
 label.position = at
 add_child(label)
