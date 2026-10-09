extends Node3D
## F6 desktop study of the same artifacts used by the map. No museum state writes.
const Chamber = preload("res://commons/artifacts/boolean_colour_chamber/boolean_colour_chamber.tscn")
const PointerEvent = preload("res://addons/godot-xr-tools/events/pointer_event.gd")
var player: CharacterBody3D
var camera: Camera3D
var pitch := 0.0
var travel := Vector2.ZERO
var rooms: Array[Node3D] = []

func _ready() -> void:
 var env := WorldEnvironment.new()
 var e := Environment.new()
 e.background_mode = Environment.BG_SKY
 var sky := Sky.new()
 var sm := ProceduralSkyMaterial.new()
 sm.sky_top_color = Color(.10,.15,.30)
 sm.sky_horizon_color = Color(.72,.65,.62)
 sm.ground_bottom_color = Color(.025,.025,.05)
 sm.ground_horizon_color = Color(.35,.32,.40)
 sky.sky_material = sm
 e.sky = sky
 e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 e.ambient_light_color = Color(.42,.47,.65)
 e.ambient_light_energy = .65
 e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
 env.environment = e
 add_child(env)
 var sunlight := DirectionalLight3D.new()
 sunlight.rotation_degrees = Vector3(-40,20,0)
 sunlight.light_energy = 1.0
 add_child(sunlight)
 for i in 3:
  var room = Chamber.instantiate()
  room.mode = ["path","lens","shell"][i]
  room.finish = i
  room.position = Vector3(i*17,0,0)
  add_child(room)
  rooms.append(room)
 # Continuous apron for walking between the three entrances.
 var floor_body := StaticBody3D.new()
 var cs := CollisionShape3D.new()
 var bs := BoxShape3D.new()
 bs.size = Vector3(52,.2,5)
 cs.shape = bs
 floor_body.position = Vector3(17,-.10,9.4)
 floor_body.add_child(cs)
 var mi := MeshInstance3D.new()
 var bm := BoxMesh.new()
 bm.size = bs.size
 mi.mesh = bm
 var mat := StandardMaterial3D.new()
 mat.albedo_color = Color(.07,.08,.105)
 mi.material_override = mat
 floor_body.add_child(mi)
 add_child(floor_body)
 _player()
 if "--verify" in OS.get_cmdline_user_args():
  var probe = load("res://probe.gd").new()
  add_child(probe)
  probe.run(self)
 else:
  Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
  var hud := Label.new()
  hud.text = "BOOLEAN COLOUR SPACES  /  WASD walk  /  mouse look  /  click material buttons
1 Pearl path   2 Amber lens   3 Chrome shell  /  Esc release mouse"
  hud.position = Vector2(18,18)
  add_child(hud)

func _player() -> void:
 player = CharacterBody3D.new()
 player.name = "StudyWalker"
 player.collision_layer = 2
 player.collision_mask = 1
 var col := CollisionShape3D.new()
 var cap := CapsuleShape3D.new()
 cap.radius = .30
 cap.height = 1.8
 col.shape = cap
 col.position.y = .90
 player.add_child(col)
 camera = Camera3D.new()
 camera.position.y = 1.70
 camera.fov = 78
 camera.near = .08
 player.add_child(camera)
 add_child(player)
 player.position = Vector3(0,.03,8.0)
 camera.make_current()

func _unhandled_input(event) -> void:
 if "--verify" in OS.get_cmdline_user_args(): return
 if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
  player.rotate_y(-event.relative.x*.002)
  pitch = clampf(pitch-event.relative.y*.002,-1.4,1.4)
  camera.rotation.x = pitch
 if event is InputEventKey and event.pressed:
  if event.keycode == KEY_ESCAPE: Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
  if event.keycode in [KEY_1,KEY_2,KEY_3]:
   var i := int(event.keycode-KEY_1)
   player.position = Vector3(i*17,.03,8)
   player.rotation = Vector3.ZERO
   pitch = 0
   camera.rotation = Vector3.ZERO
 if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
  if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
   Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
   return
  var hit := pointer_hit(camera.global_position,camera.global_position-camera.global_basis.z*4.0)
  if not hit.is_empty() and hit.collider.has_method("pointer_event"):
   if event.pressed: PointerEvent.pressed(camera,hit.collider,hit.position)
   else: PointerEvent.released(camera,hit.collider,hit.position)

func pointer_hit(from: Vector3, to: Vector3) -> Dictionary:
 var query := PhysicsRayQueryParameters3D.create(from,to,1 | (1<<20) | (1<<22))
 return get_world_3d().direct_space_state.intersect_ray(query)

func _physics_process(delta: float) -> void:
 if player == null or "--verify" in OS.get_cmdline_user_args(): return
 var input := Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W))).normalized()
 var direction := player.basis*Vector3(input.x,0,input.y)
 player.velocity = Vector3(direction.x*3.2,player.velocity.y-9.8*delta,direction.z*3.2)
 player.move_and_slide()
 if player.position.y < -5: player.position = Vector3(0,.03,8)
