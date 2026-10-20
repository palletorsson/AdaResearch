"""Build the first Swarm lesson; preserve its pre-edit texts once."""
from pathlib import Path
import shutil
R=Path(__file__).resolve().parents[1]
S=R/'doc/book/studies/swarm-through-the-hands/SwarmIntelligence_PhysarumColony'
O=R/'doc/book/iterations/2026-10-10-swarm-a-trace-outside'
M=R/'commons/maps/SwarmIntelligence_PhysarumColony'
def write(p,s):
 p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(s.encode('utf8'))
for p in [M/'tutorial.md',M/'final.md',M/'technical.md',R/'doc/book/course/execution-plan/plan.json']:
 q=O/'before'/p.relative_to(R);q.parent.mkdir(parents=True,exist_ok=True)
 if not q.exists():shutil.copy2(p,q)
S.mkdir(parents=True,exist_ok=True)
shutil.copy2(R/'doc/book/studies/soft-bodies-through-the-hands/Topology_Entropy_Morphogenesis/point_body.gd',S/'point_body.gd')
write(S/'trail.gd','''extends RefCounted
const WIDTH := 16
const SENSOR_DISTANCE := 1.5
const TURN := PI / 4.0
var retention := 0.92
var values := PackedFloat32Array()
var positions: Array[Vector2] = []
var headings: Array[float] = []
var steps := 0

func _init() -> void:
	reset()

func reset() -> void:
	values.resize(WIDTH * WIDTH)
	values.fill(0.0)
	positions.assign([Vector2(4,8), Vector2(12,8), Vector2(8,4),
		Vector2(8,12), Vector2(4,4), Vector2(12,12)])
	headings.assign([0.0, PI, PI/2.0, -PI/2.0, PI/4.0, -3.0*PI/4.0])
	steps = 0

func wrap_position(p: Vector2) -> Vector2:
	return Vector2(fposmod(p.x, WIDTH), fposmod(p.y, WIDTH))

func index_at(p: Vector2) -> int:
	var cell := Vector2i(wrap_position(p).floor())
	return cell.x + cell.y * WIDTH

func sensor_position(agent: int, offset: float) -> Vector2:
	return wrap_position(positions[agent] + Vector2.from_angle(headings[agent] + offset) * SENSOR_DISTANCE)

func sense(agent: int, offset: float) -> float:
	return values[index_at(sensor_position(agent, offset))]

func deposit(p: Vector2) -> void:
	var cell := index_at(p)
	values[cell] = minf(8.0, values[cell] + 1.0)

func step() -> void:
	# Everyone reads the old field before anyone changes it.
	for i in range(positions.size()):
		var left := sense(i, TURN)
		var ahead := sense(i, 0.0)
		var right := sense(i, -TURN)
		if left > ahead and left > right:
			headings[i] += TURN
		elif right > ahead and right > left:
			headings[i] -= TURN
		# Equal readings keep the current heading.
		positions[i] = wrap_position(positions[i] + Vector2.from_angle(headings[i]) * 0.45)
	for cell in range(values.size()):
		values[cell] *= retention
	for p in positions:
		deposit(p)
	steps += 1
''')
write(S/'study.gd','''extends Node3D
const Trail = preload("trail.gd")
const PointBody = preload("point_body.gd")
const CELL := 0.16
const HEIGHT := 1.02
const TICK := 0.15
var trail = Trail.new()
var points: Array[Node3D] = []
var tiles: Array[MeshInstance3D] = []
var sensors: Array[MeshInstance3D] = []
var caption: Label3D
var playing := false
var elapsed := 0.0

func place(p: Vector2) -> Vector3:
	return Vector3((p.x - 8.0) * CELL, HEIGHT, -(p.y - 8.0) * CELL)

func record(p: Vector3) -> Vector2:
	return trail.wrap_position(Vector2(p.x / CELL + 8.0, -p.z / CELL + 8.0))

func finish(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.5
	return material

func tile(size: Vector3, colour: Color) -> MeshInstance3D:
	var body := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	body.mesh = mesh
	body.material_override = finish(colour)
	add_child(body)
	return body

func label(words: String, at: Vector3, size: int = 26) -> Label3D:
	var text := Label3D.new()
	text.text = words
	text.position = at
	text.font_size = size
	text.pixel_size = 0.002
	add_child(text)
	return text

func _ready() -> void:
	var base := tile(Vector3(2.7,0.08,2.7), Color("242832"))
	base.position.y = HEIGHT - 0.13
	for y in range(Trail.WIDTH):
		for x in range(Trail.WIDTH):
			var cell := tile(Vector3(CELL*0.94,0.015,CELL*0.94), Color("283c46"))
			cell.position = place(Vector2(x+0.5,y+0.5)) - Vector3.UP*0.075
			tiles.append(cell)
	for i in range(trail.positions.size()):
		var point = PointBody.new()
		add_child(point)
		point.action_pressed.connect(func(_source): stamp(i))
		points.append(point)
	for colour in [Color("67c8df"), Color("ffffff"), Color("dc92ae")]:
		sensors.append(tile(Vector3(0.04,0.02,0.04), colour))
	caption = label("", Vector3(0,1.9,-1.35), 30)
	label("TRACE OUTSIDE THE POINT", Vector3(0,2.3,-1.35), 34)
	label("L / cyan      F / white      R / pink", Vector3(0,1.58,-1.35))
	var actions := [toggle_play, change_retention, restart]
	var words := ["RUN / PAUSE", "RETENTION", "RESET"]
	for i in range(3):
		var button = preload("res://commons/interactables/push_button.tscn").instantiate()
		button.name = ["Run", "Retention", "Reset"][i]
		button.position = Vector3((i-1)*0.65,0.85,1.6)
		button.rotation.x = deg_to_rad(-25.0)
		add_child(button)
		button.pressed.connect(actions[i])
		label(words[i], button.position+Vector3(0,0.17,0), 22)
	paint()

func stamp(i: int) -> void:
	trail.positions[i] = record(to_local(points[i].global_position))
	trail.deposit(trail.positions[i])
	paint()

func toggle_play() -> void:
	playing = not playing
	paint()

func change_retention() -> void:
	trail.retention = 0.55 if trail.retention > 0.8 else 0.92
	restart()

func restart() -> void:
	trail.reset()
	elapsed = 0.0
	paint()

func _process(delta: float) -> void:
	var holding := false
	for i in range(points.size()):
		if points[i].held():
			holding = true
			trail.positions[i] = record(to_local(points[i].global_position))
	if holding:
		elapsed = 0.0
	elif playing:
		elapsed += minf(delta,0.5)
		while elapsed >= TICK:
			trail.step()
			elapsed -= TICK
	paint()

func paint() -> void:
	for i in range(tiles.size()):
		tiles[i].material_override.albedo_color = Color("283c46").lerp(Color("f4d889"), trail.values[i]/8.0)
	for i in range(points.size()):
		if not points[i].held():
			points[i].position = place(trail.positions[i])
	var offsets := [Trail.TURN, 0.0, -Trail.TURN]
	for i in range(sensors.size()):
		sensors[i].position = place(trail.sensor_position(0,offsets[i])) - Vector3.UP*0.03
	caption.text = "Point 0: L %.2f   F %.2f   R %.2f\\nTick %d  /  keep %.0f%%  /  %s" % [
		trail.sense(0,Trail.TURN), trail.sense(0,0), trail.sense(0,-Trail.TURN),
		trail.steps, trail.retention*100.0, "RUN" if playing else "PAUSE"]

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1: toggle_play()
		elif event.keycode == KEY_2: change_retention()
		elif event.keycode == KEY_R: restart()
''')
write(S/'study.tscn','''[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="study.gd" id="1"]
[node name="TraceOutside" type="Node3D"]
script = ExtResource("1")
''')

def code(name):return '<!-- student-code:'+name+' -->\n```gdscript\n'+(S/name).read_text(encoding='utf8').rstrip()+'\n```\n'
tutorial='''# Physarum — a trace outside the point

## Learning elements

- Three local samples: left, ahead, right.
- Steering toward the strongest sample; an explicit tie rule.
- A shared field that outlives a moving point.
- Deposit and retention as opposing parts of feedback.
- A repeated start for a fair comparison.

## Encounter

In the existing Endless Museum, follow a bright connection in **PhysarumColony**. Watch it after the anchor arrangement changes. The dots move on; a trace can remain. The exhibit combines sensing, movement, deposition, diffusion, decay and emitting anchors. Our small study isolates one relation: **a point reads what earlier movement left in the ground, then adds to it**.

We continue with PointBody, the small frozen, grabbable sphere carried through the earlier hand studies. We do not remake its mesh or pickup behaviour. Arrays, loops, local coordinates and separate update phases are already available. Here the new object is the shared trace. It belongs to the field, not to an individual point.

## Where the code runs

Work in the prepared Ada project, with XR Tools and the museum's player, camera and light already installed. Create a folder for this lesson and put the three scripts below in it. Attach `study.gd` to a new, unscaled Node3D at floor level in a clear museum study bay, facing the visitor along local +Z. Allow a 2.7 m square and an approach to its three buttons. This is a student study beside the existing exhibit. It does not replace the colony.

`point_body.gd` is carried unchanged from the previous hand studies; its complete source appears at the end for reconstruction. The only other supplied component is `res://commons/interactables/push_button.tscn`, the museum's physical button. We instantiate it explicitly and connect its `pressed` signal. There are no unnamed scene objects to find. An empty scene running only this Node3D still needs the Day Zero environment and player to be visible and interactive.

## Keep one record outside the body

The model uses a 16 × 16 field. Each cell holds a number from 0 to 8. The flat array address is `x + y * WIDTH`, returning to Grid. Agent positions are continuous two-dimensional coordinates measured in **cells**; the display turns one cell into 0.16 metres. Increasing field y points along the study's local −Z. Each agent carries a position and heading, with no destination or map of a route.

At each tick, sample 1.5 cells away at left, ahead and right. Turn 45 degrees only when one side is strictly stronger than both other readings. On a tie, keep the heading. Move 0.45 cells, wrapping at the square's edges. This periodic boundary is an explicit simplification; the large exhibit turns agents back near its boundary.

All six agents read the old field. After their moves, multiply every cell by `retention`, then add 1 at each new position, capped at 8. A retention of 0.92 means **keep 92 percent each tick**, not lose 92 percent. Separating reading from writing prevents a later agent from receiving an earlier agent's new deposit during the same tick. We reuse the update discipline from Cellular Automata.

Save as `trail.gd`:

'''+code('trail.gd')+'''
`sense()` reads without changing the record. `deposit()` changes one cell. `step()` connects them. The heading update changes this agent's direction, but does not change any field sample another agent can read in that tick. There is no diffusion in this small study, no food and no anchor emission. Ties do not add random wandering. These omissions keep the first comparison legible; they are not claims that the study reproduces the whole exhibit or an organism.

## Let the same points show it

The host creates six instances of the carried point and a tiled display. Tiles show field strength; the cyan, white and pink marks show **point 0's** sensor positions. Its three readings appear above the table. The point remains a kinematic teaching object: this is a rule for its position, not a physical force simulation.

The simulation advances one model tick every 0.15 seconds. Holding any point pauses the whole model, so you can examine a sample. Move a point over the table and press its trigger to deposit a mark. Release it to return to the plane and continue. Motion alone while held does not paint. A placement beyond an edge wraps into the periodic field. The three nearby buttons run/pause, switch retention and reset; desktop keys are **1**, **2** and **R**. The usual desktop point interaction remains supplied by the museum.

Save as `study.gd`:

'''+code('study.gd')+'''
`place()` and `record()` translate between the model's cell coordinates and the study's local metre coordinates. `to_local()` matters when a held point is parented to the controller. A translated or rotated study therefore still records the same local position. Keep its scale at one.

The retention button resets the field and all agent positions to the same start while keeping the chosen retention. It preserves whether the simulation was running. Compare at the same tick count. A frame stall is capped at half a second to avoid a long catch-up; this display is not a wall-clock scientific simulation.

## Reconstruct the carried point

This is the existing `point_body.gd`, included in full so the dependency is available. Its sphere, material and frozen release are unchanged. The study attaches new behaviour to its `action_pressed` signal.

'''+code('point_body.gd')+'''
## Make a prediction that can fail

Pause. Follow point 0's three small sensor marks. Pick up another point, put it over the cyan mark and trigger once; move that point away without triggering again. The left reading should still be 1: the mark belongs to the field. Release and run. Point 0 should turn toward that mark on the next tick. Move the deposit to the pink mark and predict the opposite turn. Equal left and right readings leave its heading unchanged.

Then reset and run to tick 40 with retention 0.92. Reset again at 0.55 and compare at tick 40. These are the same initial points, not two unrelated random samples. The lower retention weakens an unvisited mark sooner; once choices diverge, you should not expect the two final trajectories to match.

For an independent change, move one starting position in `reset()`. Predict which three cells it will sample first. Check those cell values, rather than judging the picture alone. You should be able to explain how an agent responds to an absent neighbour's trace without sending that neighbour a message.

## Carry onward

Keep the same point, its position and the field lookup. In FlowFields we will supply **directions** at field addresses. The agents will read that field without writing it. Similar collective movement can therefore have a different cause.

The model is a small teaching reduction of sensor–motor trail feedback, informed by Jeff Jones's [research on simple agents and emergent transport networks](https://arxiv.org/abs/1503.06579). It does not demonstrate a shortest-path guarantee. [The Nature of Code's autonomous agents](https://natureofcode.com/autonomous-agents/) is a useful companion for the later transition from a carried moving body to steering and flocking.
'''
write(M/'tutorial.md',tutorial)
p=M/'final.md';text=p.read_text(encoding='utf8').replace('five hundred agents rewrite','many agents rewrite');write(p,text)
print('Wrote complete Physarum lesson and three student scripts; reflections retained except unsupported count.')
