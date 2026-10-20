"""Write the focused ABM reconstruction and its two readings; preserve the encounter."""
from pathlib import Path
import shutil
R=Path(__file__).resolve().parents[1]
ID='SwarmIntelligence_Agent_Based_Modeling_ABM'
S=R/'doc/book/studies/swarm-through-the-hands'/ID
M=R/'commons/maps'/ID
O=R/'doc/book/iterations/2026-10-10-abm-what-the-point-carries'
S.mkdir(parents=True,exist_ok=True)
def write(p,s):p.write_bytes(s.encode('utf8'))
def text(p):return p.read_text(encoding='utf8')
shutil.copy2(R/'doc/book/studies/swarm-through-the-hands/SwarmIntelligence_Boids_Algorithm/point_body.gd',S/'point_body.gd')
write(S/'foragers.gd','''extends RefCounted
const WIDTH := 16
const DT := 0.05
const SPEED := 3.0
const RESPONSE := 0.5
const MAX_ACCEL := 6.0
const TURN := PI / 4.0
const SENSOR_DISTANCE := 1.5
const HOME := Vector2(3,8)
const FOOD := Vector2(12,8)
const CONTACT := 1.0
var retention := 0.92
var return_speed := 3.0
var values := PackedFloat32Array()
var positions: Array[Vector2] = []
var velocities: Array[Vector2] = []
var carrying: Array[bool] = []
var delivered := 0
var steps := 0

func _init() -> void:
	reset()

func replace_agents() -> void:
	positions.assign([Vector2(3,7.4), Vector2(4.2,7.4), Vector2(5.4,7.4),
		Vector2(3,8.6), Vector2(4.2,8.6), Vector2(5.4,8.6)])
	velocities.clear()
	carrying.clear()
	for i in range(positions.size()):
		velocities.append(Vector2(SPEED,0))
		carrying.append(false)

func reset() -> void:
	values.resize(WIDTH*WIDTH)
	values.fill(0.0)
	delivered = 0
	steps = 0
	replace_agents()

func wrap_position(p: Vector2) -> Vector2:
	return Vector2(fposmod(p.x,WIDTH),fposmod(p.y,WIDTH))

func index_at(p: Vector2) -> int:
	var cell := Vector2i(wrap_position(p).floor())
	return cell.x + cell.y*WIDTH

func sensor_position(i: int, offset: float) -> Vector2:
	var heading := velocities[i].angle() if not velocities[i].is_zero_approx() else 0.0
	return wrap_position(positions[i] + Vector2.from_angle(heading+offset)*SENSOR_DISTANCE)

func sense(i: int, offset: float) -> float:
	return values[index_at(sensor_position(i,offset))]

func search_velocity(i: int) -> Vector2:
	var direction := velocities[i].normalized() if not velocities[i].is_zero_approx() else Vector2.RIGHT
	var left := sense(i,TURN)
	var ahead := sense(i,0.0)
	var right := sense(i,-TURN)
	if left > ahead and left > right:
		direction = direction.rotated(TURN)
	elif right > ahead and right > left:
		direction = direction.rotated(-TURN)
	return direction*SPEED

func step() -> void:
	var next_positions: Array[Vector2] = []
	var next_velocities: Array[Vector2] = []
	var next_carrying: Array[bool] = []
	for i in range(positions.size()):
		var has_food := carrying[i]
		var arrived_home := has_food and positions[i].distance_to(HOME) < CONTACT
		if arrived_home:
			has_food = false
			delivered += 1
		elif not has_food and positions[i].distance_to(FOOD) < CONTACT:
			has_food = true
		var desired: Vector2
		if has_food:
			desired = (HOME-positions[i]).normalized()*return_speed
		elif arrived_home:
			desired = Vector2(SPEED,0)
		else:
			desired = search_velocity(i)
		var a := ((desired-velocities[i])/RESPONSE).limit_length(MAX_ACCEL)
		var v := (velocities[i]+a*DT).limit_length(SPEED)
		next_velocities.append(v)
		next_positions.append(wrap_position(positions[i]+v*DT))
		next_carrying.append(has_food)
	positions = next_positions
	velocities = next_velocities
	carrying = next_carrying
	for cell in range(values.size()):
		values[cell] *= retention
	for i in range(positions.size()):
		if carrying[i]:
			var cell := index_at(positions[i])
			values[cell] = minf(8.0,values[cell]+1.0)
	steps += 1
''')
write(S/'study.gd','''extends Node3D
const Foragers = preload("foragers.gd")
const PointBody = preload("point_body.gd")
const CELL := 0.16
const HEIGHT := 1.02
var model = Foragers.new()
var points: Array[Node3D] = []
var cargo: Array[MeshInstance3D] = []
var tiles: Array[MeshInstance3D] = []
var sensors: Array[MeshInstance3D] = []
var caption: Label3D
var witness := 0
var playing := false
var elapsed := 0.0

func place(p: Vector2) -> Vector3:
	return Vector3((p.x-8.0)*CELL,HEIGHT,-(p.y-8.0)*CELL)

func record(p: Vector3) -> Vector2:
	return model.wrap_position(Vector2(p.x/CELL+8.0,-p.z/CELL+8.0))

func tile(size: Vector3, colour: Color) -> MeshInstance3D:
	var body := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	body.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.5
	body.material_override = material
	add_child(body)
	return body

func label(words: String, at: Vector3, size: int = 24) -> Label3D:
	var text := Label3D.new()
	text.text = words
	text.position = at
	text.font_size = size
	text.pixel_size = 0.002
	add_child(text)
	return text

func destination(p: Vector2, colour: Color, words: String) -> void:
	var body := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = Foragers.CONTACT*CELL-0.005
	ring.outer_radius = Foragers.CONTACT*CELL+0.005
	ring.rings = 48
	ring.ring_segments = 6
	body.mesh = ring
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	body.material_override = material
	add_child(body)
	body.position = place(p)-Vector3.UP*0.06
	label(words,place(p)+Vector3(0,0.30,-0.22),20)

func _ready() -> void:
	tile(Vector3(2.7,0.08,2.7),Color("242832")).position.y = HEIGHT-0.13
	for y in range(Foragers.WIDTH):
		for x in range(Foragers.WIDTH):
			var cell := tile(Vector3(CELL*0.94,0.015,CELL*0.94),Color("283c46"))
			cell.position = place(Vector2(x+0.5,y+0.5))-Vector3.UP*0.075
			tiles.append(cell)
	for i in range(model.positions.size()):
		var point = PointBody.new()
		if i == 0: point.tint = Color("ef8bad")
		add_child(point)
		point.action_pressed.connect(func(_source): choose(i))
		points.append(point)
		cargo.append(tile(Vector3.ONE*0.06,Color("a0ef82")))
	for colour in ["67c8df","ffffff","dc92ae"]:
		sensors.append(tile(Vector3(0.035,0.02,0.035),Color(colour)))
	destination(Foragers.HOME,Color("fac35f"),"HOME")
	destination(Foragers.FOOD,Color("a0ef82"),"FOOD")
	label("WHAT THE POINT CARRIES",Vector3(0,2.28,-1.3),32)
	caption = label("",Vector3(0,1.88,-1.3),22)
	label("Cube above point: carrying / gold cells: shared trace",Vector3(0,1.49,-1.3),18)
	var actions := [toggle_play, single_step, replace, restart]
	for i in range(4):
		var button = preload("res://commons/interactables/push_button.tscn").instantiate()
		button.name = ["Run","Step","Replace","Reset"][i]
		button.position = Vector3((i-1.5)*0.72,0.85,1.60)
		button.rotation.x = deg_to_rad(-25.0)
		add_child(button)
		button.pressed.connect(actions[i])
		label(["RUN / PAUSE","ONE TICK","REPLACE AGENTS","CLEAR ALL"][i],button.position+Vector3(0,0.17,0),16)
	paint()

func choose(i: int) -> void:
	if points[i].held():
		witness = i
		paint()

func toggle_play() -> void:
	playing = not playing
	paint()

func any_held() -> bool:
	for point in points:
		if point.held(): return true
	return false

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
		while elapsed+0.000001 >= Foragers.DT:
			model.step()
			elapsed = maxf(0.0,elapsed-Foragers.DT)
	paint()

func paint() -> void:
	for i in range(tiles.size()):
		tiles[i].material_override.albedo_color = Color("283c46").lerp(Color("f4d889"),model.values[i]/8.0)
	for i in range(points.size()):
		if not points[i].held(): points[i].position = place(model.positions[i])
		cargo[i].visible = model.carrying[i]
		cargo[i].position = to_local(points[i].global_position)+Vector3.UP*0.14
	var offsets := [Foragers.TURN,0.0,-Foragers.TURN]
	for i in range(sensors.size()):
		sensors[i].visible = not model.carrying[witness]
		sensors[i].position = place(model.sensor_position(witness,offsets[i]))-Vector3.UP*0.03
	var v: Vector2 = model.velocities[witness]
	caption.text = "Point %d / %s / delivered %d\\nv (%.2f, %.2f) cells/s / tick %d\\nL %.2f / F %.2f / R %.2f / %s" % [
		witness,"RETURN + DEPOSIT" if model.carrying[witness] else "SEARCH",model.delivered,
		v.x,v.y,model.steps,model.sense(witness,Foragers.TURN),model.sense(witness,0),
		model.sense(witness,-Foragers.TURN),"RUN" if playing else "PAUSE"]

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1: toggle_play()
		elif event.keycode == KEY_2: single_step()
		elif event.keycode == KEY_3: replace()
		elif event.keycode == KEY_R: restart()
''')
write(S/'study.tscn','''[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="study.gd" id="1"]

[node name="ForagingStudy" type="Node3D"]
script = ExtResource("1")
''')
def code(name):return '<!-- student-code:'+name+' -->\n```gdscript\n'+text(S/name).rstrip()+'\n```\n'
t='''# What the point carries

## Learning elements

- Agent state: searching or carrying food
- Contact as a state transition
- A different response from the same body
- Shared trail versus individual state
- Replacing agents versus clearing the whole model

## Start in the existing hall

Find the colony display. Watch a point reach food and turn towards the nest. Its position has changed, but something else has changed too: it now carries food. The display's ANTS control replaces the population while keeping its field. RESET clears the field as well. Try both after a trail has formed.

Continue with the **same PointBody from Boids**. Keep its appearance, pickup and trigger. Bring back Physarum's three samples and one shared trace. Boids taught us to read the old state before committing the next; keep that discipline here. Boids already was an agent-based model. This lesson adds a discrete state that selects a different behaviour.

The small reconstruction isolates that operation. The existing colony also has finite food, random wandering, food quality and recruitment. We leave those mechanisms in the exhibit. Here food is inexhaustible, all points know the nest position, and they can detect food only inside its contact ring. This is a controlled study of transitions, not a reproduction of every colony feature.

## What changes at contact?

`carrying[i]` belongs to point `i`. It is a Boolean: `false` while searching, `true` while returning. A small green cube above the sphere makes that state visible. Colour alone does not carry the distinction.

| State before the tick | Observation | State and action on this tick |
| --- | --- | --- |
| Searching | Outside food ring | Read three old trail samples; steer towards the strongest, keeping direction on ties. |
| Searching | Inside food ring | Carry food; request a return towards the known nest; leave a trace. |
| Returning | Outside home ring | Keep returning and depositing; ignore trail samples. |
| Returning | Inside home ring | Deliver once; stop carrying; request an eastward departure; stop depositing. |

Contact is a distance **strictly below one cell**, checked at the start of the tick. Movement follows; arriving during that movement is noticed next tick. The rings show that threshold. This is model contact, not a Godot rigid-body collision. These points can overlap.

The return changes the desired velocity, not the current velocity instantly. We keep the familiar response time and acceleration cap. A point moving right can carry food and still move right briefly while it turns. After delivery the one-tick eastward request starts another search; subsequent ticks read the trail again.

## The complete model

Save these three files together. The scene belongs under an empty Node3D in your prepared museum working area. Day Zero supplies the player, camera, lighting, XRTools and the named `push_button.tscn` control. No prebuilt sphere, mesh path or hidden scene node is required. Attach `study.gd` to that Node3D; it creates its own display. The supplied `study.tscn` does the same.

Save **foragers.gd**. Positions and velocities retain the familiar sixteen-cell plane and fixed 0.05-second tick. `next_carrying` joins the next-position and next-velocity arrays. Every search reads the old shared field. Only after all bodies have chosen do we fade the field and add deposits from returning points.

'''+code('foragers.gd')+'''
`replace_agents()` restores the six starting records but does not touch `values`, `delivered` or `steps`. `reset()` clears those three shared records too, then restores the agents. Neither operation changes the selected retention or return speed. Reusing the six rendered spheres is an implementation convenience; “replace” here means replace their simulated records.

The field stores one scalar per cell. A returning point adds one unit, capped at eight; each tick retains 92% of the previous amount. Searching points read it but do not deposit. A mark carries no identity or direction. A brighter route is not proof of a shorter or better route.

### The same point

This is the unchanged PointBody from Boids. Keep your existing file or use this identical copy.

<details>
<summary>point_body.gd — carried in full</summary>

'''+code('point_body.gd')+'''
</details>

### The display and controls

Save **study.gd**. The host maps one cell to 0.16 metres on the same XZ plane. The grid shows the shared trace; the cube follows its point's carry flag. Hold any point to pause the entire model and relocate it. Its velocity is cleared; its carry flag stays. Use the held trigger to inspect that point. Release it, then press ONE TICK to test contact. Holding does not pick up model food: a simulation tick does.

The three small samples are visible only while the selected point searches: cyan left, white ahead, pink right. The readout still reports their values during return, but the returning point ignores them.

<details>
<summary>study.gd — complete museum host</summary>

'''+code('study.gd')+'''
</details>

Use the nearby buttons or keys **1** Run/Pause, **2** One Tick, **3** Replace Agents and **R** Clear All. Reset and replace work only when every point is released; presses while holding are ignored. No simulation ticks pass while you hold a point; release resumes only if Run was active. Points return to the display plane when released.

## Predict, then try

Pause. Carry the pink point into the food ring, release and advance one tick. Its green cube appears. Because holding cleared its velocity, the first return tick gives it a small leftward velocity. Move this carrying point into the home ring and advance one tick. The cube disappears and delivered increases once. Another tick there must not count the same delivery again.

Let a trail form. Pause and REPLACE AGENTS. The points lose their cargo and return to the initial arrangement; the marks, tick count and delivered total remain. CLEAR ALL removes those records too. Name which part of the model each button resets before using it.

For an independent edit, set `return_speed` to **1.5**. At position `(8,8)`, velocity `(0,0)`, carrying `true`, predict one tick: desired velocity `(-1.5,0)`, acceleration `(-3,0)`, new velocity `(-0.15,0)`, new position `(7.9925,8)`. The default return speed gives `(-0.3,0)` and `(7.985,8)`. Execute both; do not judge only by the animation.

The supplied checks reconstruct the printed files and exercise both transitions, old-field sensing, bounded movement, reset scope and the speed edit. Faulty versions that never collect, erase the field on replacement or count delivery repeatedly must be detected. Synthetic pickup tests check the carried class and the host; they do not certify physical headset comfort.

## What travels onward

Carry the same point, its return flag, and the distinction between individual and shared state. The next colony splits the field into **home and food channels**. Each state will choose which channel it reads and which it writes. We are not adding a new kind of creature to explain that change.

<!-- @navigator_noise -->
## Optional study — what reaches the point

- True and observed obstacle distance
- Threshold and waypoint state
- Missing observation: stop or retain a command
- Replayed input and measured outcome

Beside the colony, the inherited sphere follows a known course. Hold the world and start fixed; change the range reading and compare the responses. The [complete navigator companion](../../artifacts/navigator_noise/tutorial.md) prints its model, carried point, constrained handle, stage and scene. It is a separate study of observation and policy; this lesson's tests cover the foraging reconstruction.
'''
write(M/'tutorial.md',t)
# Keep the companion encounter and existing colony controls; focus the opening on state.
old=text(O/'before/final.md')
optional=old.split('<!-- @navigator_noise -->',1)[1].split('<!-- @ -->',1)[0]
f='''# What returns with the point

<!-- @ant_colony_optimization -->

A point reaches food and turns back. Follow it instead of following the whole colony. The same small body is now doing something else. What it carries changes which information matters: the trail that helped it search gives way to the known direction home.

The turn does not explain itself. From above, a changed path can look like a decision, an intention, even relief. Here we can inspect the rule that changes the path. A stored condition switches the response. That account is precise enough for this point; calling the point a person would require much more.

Wait until a route becomes visible. Raise EVAPORATE, use RESET and watch the beginning again. The food returns to the same places and qualities; the ants begin from the same seeded conditions. Keep ANTS steady. This time the ground forgets faster. The route needs repeated visits to remain visible. Its apparent stability is work continuing.

Now change ANTS. The control replaces the population but leaves its field. New travellers encounter marks made by bodies that are gone. RESET does something larger: the marks disappear too. A fresh population and a fresh world are different beginnings.

Look at a broad trail and a narrow one. Width and persistence are different qualities. A crowded passage can keep renewing marks that individually last very little time. A quieter passage can retain a few visits for longer. The picture gathers these histories into brightness; it does not tell you which history made it without another comparison.

MODE makes further arrangements available. Communication adds recruitment at the nest and tandem pairs; Multi-Source adds a bias towards richer food. These are specific additions. The word “agent” does not give the model an unlimited account of acting together. Its food, senses and possible responses have been chosen.

<!-- @ -->

<!-- @navigator_noise -->
'''+optional.strip()+'''

<!-- @ -->

In the next hall, the returning point keeps its state. The ground gains a distinction: a trace towards food is no longer the same channel as a trace towards home.
'''
write(M/'final.md',f)
print('Written complete ABM sources and focused readings; production exhibit unchanged.')
