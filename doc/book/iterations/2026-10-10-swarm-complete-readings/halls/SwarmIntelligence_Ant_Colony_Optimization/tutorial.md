# Ant Colony — two trails underfoot

The spheres now move through a twelve-metre field. Walk between them. The point from the previous hall still has position, velocity and a carrying flag. This time its journey leaves two kinds of trace.

## Learning elements

- Two separate fields: home trail and food trail.
- State chooses which field to read and which to write.
- Destination contact reverses direction and renews the trail strength.
- Reinforcement and evaporation; replacing bodies versus clearing their traces.

## Keep the object; change its information

In ABM a returning point knew the home coordinate. Here it finds its direction from three local samples. A searching point reads **food** and writes **home**. A carrying point reads **home** and writes **food**. The destination coordinates are used for contact and source emission, not as a steering target.

Each floor cell has two strips: blue on its left for home, rose on its right for food. These are two numbers at the same address, not two lanes the point must stay inside. A green cube above a sphere means it carries food. The ring around the selected sphere and its three small sensor marks let you follow one record among the others.

Hold any sphere to pause the colony. Move it beside FOOD, release it, then press ONE TICK. Its carry flag turns on. The next samples come from the other field. Carry that same point to HOME and step again: one delivery, the flag off. Holding does not collect or deliver by itself. The trigger selects a held point for the readout.

## The complete rule

Save `colony.gd` beside the carried `point_body.gd` and the host below. The model stays in a 16×16 periodic plane. One cell now occupies 0.75 m; 24 points replace the previous six, using the same rule. The large room changes the view and reach, not the definition of a cell.

`step()` first checks destination contacts. It then reads the previous fields for every point, commits all movement, fades both fields and deposits into the selected channel. The two destinations replenish only their own cells. A new mark cannot steer a later point during the same tick.

On contact we reverse the model velocity once. This is a declared ant-like turn, not a physical collision. Between contacts the bounded steering from Boids remains. Equal sensor readings keep the direction; a stationary searcher starts east and a stationary returner starts west. There is no hidden pathfinder.

<!-- student-code:colony.gd -->
```gdscript
extends RefCounted
const WIDTH := 16
const COUNT := 24
const DT := 0.05
const SPEED := 3.0
const RESPONSE := 0.5
const MAX_ACCEL := 6.0
const TURN := PI/4.0
const SENSOR_DISTANCE := 1.5
const HOME := Vector2(3,8)
const FOOD := Vector2(12,8)
const CONTACT := 1.0
var retention := 0.995
var deposit_amount := 0.5
var home := PackedFloat32Array()
var food := PackedFloat32Array()
var positions: Array[Vector2] = []
var velocities: Array[Vector2] = []
var carrying: Array[bool] = []
var energy: Array[float] = []
var delivered := 0
var steps := 0

func _init() -> void:
	reset()

func replace_agents() -> void:
	positions.clear()
	velocities.clear()
	carrying.clear()
	energy.clear()
	for i in range(COUNT):
		var direction := Vector2.from_angle(TAU*i/COUNT)
		positions.append(HOME+direction*0.5)
		velocities.append(direction*SPEED)
		carrying.append(false)
		energy.append(1.0)

func reset() -> void:
	home.resize(WIDTH*WIDTH)
	food.resize(WIDTH*WIDTH)
	home.fill(0.0)
	food.fill(0.0)
	delivered = 0
	steps = 0
	replace_agents()

func wrap_position(p: Vector2) -> Vector2:
	return Vector2(fposmod(p.x,WIDTH),fposmod(p.y,WIDTH))

func index_at(p: Vector2) -> int:
	var cell := Vector2i(wrap_position(p).floor())
	return cell.x+cell.y*WIDTH

func heading(i: int) -> Vector2:
	if not velocities[i].is_zero_approx(): return velocities[i].normalized()
	return Vector2.LEFT if carrying[i] else Vector2.RIGHT

func sensor_position(i: int, offset: float) -> Vector2:
	return wrap_position(positions[i]+heading(i).rotated(offset)*SENSOR_DISTANCE)

func sense(i: int, offset: float, read_home: bool) -> float:
	var cell := index_at(sensor_position(i,offset))
	return home[cell] if read_home else food[cell]

func desired_velocity(i: int) -> Vector2:
	var direction := heading(i)
	var left := sense(i,TURN,carrying[i])
	var ahead := sense(i,0.0,carrying[i])
	var right := sense(i,-TURN,carrying[i])
	if left > ahead and left > right:
		direction = direction.rotated(TURN)
	elif right > ahead and right > left:
		direction = direction.rotated(-TURN)
	return direction*SPEED

func deposit(i: int) -> void:
	var cell := index_at(positions[i])
	var amount := deposit_amount*energy[i]
	if carrying[i]:
		food[cell] = minf(8.0,food[cell]+amount)
	else:
		home[cell] = minf(8.0,home[cell]+amount)

func step() -> void:
	var next_positions: Array[Vector2] = []
	var next_velocities: Array[Vector2] = []
	for i in range(positions.size()):
		if carrying[i] and positions[i].distance_to(HOME) < CONTACT:
			carrying[i] = false
			delivered += 1
			velocities[i] = -velocities[i]
			energy[i] = 1.0
		elif not carrying[i] and positions[i].distance_to(FOOD) < CONTACT:
			carrying[i] = true
			velocities[i] = -velocities[i]
			energy[i] = 1.0
		energy[i] = maxf(0.0,energy[i]-DT*0.05)
		var a := ((desired_velocity(i)-velocities[i])/RESPONSE).limit_length(MAX_ACCEL)
		var v := (velocities[i]+a*DT).limit_length(SPEED)
		next_velocities.append(v)
		next_positions.append(wrap_position(positions[i]+v*DT))
	positions = next_positions
	velocities = next_velocities
	for cell in range(home.size()):
		home[cell] *= retention
		food[cell] *= retention
	for i in range(positions.size()):
		deposit(i)
	home[index_at(HOME)] = 8.0
	food[index_at(FOOD)] = 8.0
	steps += 1
```

`read_home` selects one array in `sense()`. In `deposit()`, a carrying point writes food; a searching point writes home. The opposite channel is untouched by that deposit. Both still evaporate in the field update. Energy declines with time since a destination, so a point cannot lay an equally strong trail forever.

Food is inexhaustible. The field wraps at its edges; the home and food contact tests use direct distance. The spheres can overlap and do not push you. This is a small foraging model, not a simulation of ant biology or evidence that the shortest route has been found. The hall's historical ACO title includes optimization methods that require a stated cost and a comparison; this lesson isolates their shared-trace mechanism.

## Put the same point into the room

The prepared museum supplies its floor, player, camera, lights, XRTools and `commons/interactables/push_button.tscn`. Create a Node3D at the centre of a clear 12×12 m working area, with another metre at each end for the controls, and attach `study.gd`. Its local origin is floor level. The permanent exhibit in this hall runs this same host; when reconstructing it, use a working copy of the hall and replace the existing `ant_colony_walk` instance so you do not stack two displays.

The host creates every sphere and field strip in code. PointBody itself is unchanged. Its mesh and collision shape are both enlarged threefold for this room; its rigid-body root stays unscaled. The points travel at 0.8 m above the floor. Hold one to bring it closer. Two matching banks of controls let you pause and step from either end of the field. Keys 1, 2, 3 and R provide the same actions on desktop. The supplied host batches the 512 strips into two MultiMeshes; rendering this many cells does not require one draw per strip.

<details><summary>Carried point_body.gd — complete, unchanged</summary>

<!-- student-code:point_body.gd -->
```gdscript
extends XRToolsPickable
## Point Lines' frozen point construction, made smaller for the hand model.
var tint := Color("25212a")
var desktop_pointer: WeakRef

func _init() -> void:
	freeze = true
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	release_mode = XRToolsPickable.ReleaseMode.FROZEN
	ranged_grab_method = XRToolsPickable.RangedMethod.NONE
	collision_layer = 4
	collision_mask = 0
	var surface := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.085
	sphere.height = 0.17
	sphere.radial_segments = 24
	sphere.rings = 12
	surface.mesh = sphere
	add_child(surface)
	var boundary := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.085
	boundary.shape = shape
	add_child(boundary)

func _ready() -> void:
	super._ready()
	var finish := StandardMaterial3D.new()
	finish.albedo_color = tint
	finish.roughness = 0.24
	get_child(0).material_override = finish

func held() -> bool:
	return is_picked_up() or (desktop_pointer != null and desktop_pointer.get_ref() != null)

func on_desktop_grab(pointer: Node) -> void:
	desktop_pointer = weakref(pointer)

func on_desktop_drop(_pointer: Node) -> void:
	desktop_pointer = null
```

</details>

<details><summary>study.gd — complete room and interaction host</summary>

<!-- student-code:study.gd -->
```gdscript
extends Node3D
const Colony = preload("colony.gd")
const PointBody = preload("point_body.gd")
const CELL := 0.75
const HEIGHT := 0.8
const BLUE := Color("49c9ef")
const ROSE := Color("ef789d")
var model = Colony.new()
var points: Array[Node3D] = []
var cargo: Array[MeshInstance3D] = []
var home_tiles: MultiMeshInstance3D
var food_tiles: MultiMeshInstance3D
var sensors: Array[MeshInstance3D] = []
var captions: Array[Label3D] = []
var selection: MeshInstance3D
var witness := 0
var playing := true
var elapsed := 0.0

func place(p: Vector2) -> Vector3:
	return Vector3((p.x-8.0)*CELL,HEIGHT,-(p.y-8.0)*CELL)

func record(p: Vector3) -> Vector2:
	return model.wrap_position(Vector2(p.x/CELL+8.0,-p.z/CELL+8.0))

func finish(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.4
	return material

func tile(size: Vector3, colour: Color) -> MeshInstance3D:
	var body := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	body.mesh = mesh
	body.material_override = finish(colour)
	add_child(body)
	return body

func ring(radius: float, colour: Color) -> MeshInstance3D:
	var body := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius-0.035
	mesh.outer_radius = radius+0.035
	mesh.rings = 48
	mesh.ring_segments = 8
	body.mesh = mesh
	body.material_override = finish(colour)
	add_child(body)
	return body

func label(words: String, at: Vector3, size: int = 32) -> Label3D:
	var text := Label3D.new()
	text.text = words
	text.position = at
	text.font_size = size
	text.pixel_size = 0.004
	text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(text)
	return text

func field(offset: float) -> MultiMeshInstance3D:
	var body := MultiMeshInstance3D.new()
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.use_colors = true
	var mesh := BoxMesh.new()
	mesh.size = Vector3(CELL*0.43,0.012,CELL*0.9)
	batch.mesh = mesh
	batch.instance_count = Colony.WIDTH*Colony.WIDTH
	body.multimesh = batch
	var material := finish(Color.WHITE)
	material.vertex_color_use_as_albedo = true
	body.material_override = material
	add_child(body)
	for y in range(Colony.WIDTH):
		for x in range(Colony.WIDTH):
			var at := place(Vector2(x+0.5,y+0.5))
			at.x += offset
			at.y = 0.035
			batch.set_instance_transform(x+y*Colony.WIDTH,Transform3D(Basis.IDENTITY,at))
	return body

func _ready() -> void:
	tile(Vector3(12.1,0.02,12.1),Color("111822")).position.y = 0.015
	home_tiles = field(-CELL*0.23)
	food_tiles = field(CELL*0.23)
	for i in range(model.positions.size()):
		var point = PointBody.new()
		point.tint = Color("eae7e0") if i%2 == 0 else Color("25212a")
		# Enlarge the existing geometry and grab shape, not the rigid-body root.
		point.get_child(0).scale = Vector3.ONE*3.0
		point.get_child(1).shape.radius *= 3.0
		add_child(point)
		point.action_pressed.connect(func(_source): choose(i))
		points.append(point)
		cargo.append(tile(Vector3.ONE*0.15,Color("a0ef82")))
	for colour in [BLUE,Color.WHITE,ROSE]:
		sensors.append(tile(Vector3(0.12,0.04,0.12),colour))
	selection = ring(0.34,Color("ffd16d"))
	for target in [Colony.HOME,Colony.FOOD]:
		var is_home: bool = target == Colony.HOME
		var at := place(target)
		at.y = 0.10
		ring(Colony.CONTACT*CELL,BLUE if is_home else ROSE).position = at
		label("HOME / BLUE" if is_home else "FOOD / ROSE",at+Vector3.UP*2.0)
	for side in [-1,1]:
		var z: float = side*6.5
		var bank_x: float = -side*3.5
		label("TWO TRAILS UNDERFOOT",Vector3(0,3.3,z),52)
		captions.append(label("",Vector3(bank_x,1.95,z),22))
		label("Hold: pause + move   /   held trigger: select",Vector3(bank_x,1.45,z),16)
		tile(Vector3(3.65,0.08,0.5),Color("303747")).position = Vector3(bank_x,0.88,z)
		var actions := [toggle_play,single_step,replace,restart]
		for i in range(4):
			var button = preload("res://commons/interactables/push_button.tscn").instantiate()
			button.name = ["Run","Step","Replace","Reset"][i]+str(side)
			button.position = Vector3(bank_x+(i-1.5)*1.0,0.95,z)
			button.rotation.x = deg_to_rad(-25.0)
			if side < 0: button.rotation.y = PI
			add_child(button)
			button.pressed.connect(actions[i])
			var words := label(["RUN / PAUSE","ONE TICK","REPLACE POINTS","CLEAR ALL"][i],button.position+Vector3.UP*0.25,20)
			words.pixel_size = 0.0025
	paint()

func choose(i: int) -> void:
	if points[i].held(): witness = i
	paint()

func any_held() -> bool:
	for point in points:
		if point.held(): return true
	return false

func toggle_play() -> void:
	playing = not playing
	paint()

func single_step() -> void:
	playing = false
	elapsed = 0.0
	if not any_held(): model.step()
	paint()

func replace() -> void:
	if any_held(): return
	model.replace_agents()
	playing = false
	elapsed = 0.0
	paint()

func restart() -> void:
	if any_held(): return
	model.reset()
	playing = false
	elapsed = 0.0
	paint()

func _process(delta: float) -> void:
	for i in range(points.size()):
		if points[i].held():
			model.positions[i] = record(to_local(points[i].global_position))
			model.velocities[i] = Vector2.ZERO
	if any_held():
		elapsed = 0.0
	elif playing:
		elapsed += minf(delta,0.5)
		while elapsed+0.000001 >= Colony.DT:
			model.step()
			elapsed = maxf(0.0,elapsed-Colony.DT)
	paint()

func paint() -> void:
	for i in range(model.home.size()):
		home_tiles.multimesh.set_instance_color(i,Color("142430").lerp(BLUE,model.home[i]/8.0))
		food_tiles.multimesh.set_instance_color(i,Color("241b29").lerp(ROSE,model.food[i]/8.0))
	for i in range(points.size()):
		if not points[i].held(): points[i].position = place(model.positions[i])
		cargo[i].visible = model.carrying[i]
		cargo[i].position = to_local(points[i].global_position)+Vector3.UP*0.4
	selection.position = to_local(points[witness].global_position)-Vector3.UP*0.24
	var offsets := [Colony.TURN,0.0,-Colony.TURN]
	for i in range(sensors.size()):
		sensors[i].position = place(model.sensor_position(witness,offsets[i]))
		sensors[i].position.y = 0.13
	var returning: bool = model.carrying[witness]
	for text in captions:
		text.text = "Point %d / %s / delivered %d\nREAD %s  /  LEAVE %s\nL %.2f   F %.2f   R %.2f  / tick %d / %s" % [witness,
			"RETURN" if returning else "SEARCH",model.delivered,"HOME" if returning else "FOOD",
			"FOOD" if returning else "HOME",model.sense(witness,Colony.TURN,returning),
			model.sense(witness,0,returning),model.sense(witness,-Colony.TURN,returning),model.steps,
			"HELD" if any_held() else ("RUN" if playing else "PAUSE")]

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1: toggle_play()
		elif event.keycode == KEY_2: single_step()
		elif event.keycode == KEY_3: replace()
		elif event.keycode == KEY_R: restart()
```

</details>

The host keeps painting while paused. Holding a point records its position in the host's local frame and zeros its velocity. Release projects it back onto the field plane. Its carrying flag and energy stay with it. REPLACE POINTS restores the starting population but keeps both fields, deliveries and tick count. CLEAR ALL resets those records too; it retains your retention and deposit settings. Reset actions wait until all points are released.

## Predict, then change something

Pause the room. Put a searching point at FOOD. Predict: it becomes a returner, reads blue and leaves rose. Move that carrying point to HOME. Predict the reverse, with one delivery. Now replace the points: the marks remain. Clear all: the fields are empty until the next tick replenishes the destination cells.

For an independent code change, set `deposit_amount` to 0.25 instead of 0.5. A point with energy 1 deposits 0.25 into an empty cell when you call `deposit()` directly. On a tick, energy falls first to 0.9975, so its new mark is 0.249375 before another point adds anything. Test a cell away from the two sources. The other channel must remain zero. Explain why fading alone would not establish which channel was written.

Carry this distinction onward: the trace is stored outside the point. Particle Swarm Optimization replaces the trails and carrying flag with personal and shared records of scored positions. The PointBody class stays; the colony behaviour does not. We will have to ask what makes a position “best”.
