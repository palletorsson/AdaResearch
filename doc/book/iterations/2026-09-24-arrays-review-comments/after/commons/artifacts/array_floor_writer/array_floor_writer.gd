extends Node3D
## The existing copy agent now writes the hall's own floor at a readable rate.
## Thresholds and a perimeter route remain; no replacement demonstration grid.
signal state_changed(state: Dictionary)
const Kit=preload("res://commons/artifacts/regularity/room_tools.gd")
class FloorAgent extends "res://commons/hazards/gridagent/grid_agent_base.gd":
	var host:Node3D
	var acted:=false
	func _ready():
		super._ready()
		current_grid=host.grid
		movement_speed=0.65
		operation_interval=2.5
		set_tier("copy")
	func _process_wandering(delta):
		super._process_wandering(delta)
		var p:Vector3=host.grid.parent_node.to_local(global_position)
		p.x=clampf(p.x,2,host.dimensions.x-3)
		p.z=clampf(p.z,3,host.dimensions.z-4)
		p.y=1.15
		global_position=host.grid.parent_node.to_global(p)
		grid_cell_position=Vector3i(roundi(p.x),1,roundi(p.z))
	func _choose_new_wander_direction():
		wander_direction=[Vector3.RIGHT,Vector3.LEFT,Vector3.FORWARD,Vector3.BACK][randi()%4]
	func _change_state(value):
		acted=false
		super._change_state(value)
	func _process_feeding(_delta):
		if not acted:
			acted=true
			host.write_cell(false)
		if state_timer>=1.0:_change_state(AgentState.WANDERING)
	func _process_working(_delta):
		if not acted:
			acted=true
			host.write_cell(true)
		if state_timer>=1.0:_change_state(AgentState.WANDERING)
	func _update_thought_label():
		if thought_label:thought_label.text=host.last_change
var grid:Node
var dimensions:Vector3i
var agent:FloorAgent
var original:Dictionary={}
var changed:Dictionary={}
var last_change:="THE FLOOR IS BEING WRITTEN"
var running:=true
var restoring:=false
var readout:Node
var clock:=0.0
var writes:=0
func _ready() -> void:
	bind_grid.call_deferred()
func bind_grid() -> void:
	var parent:Node=get_parent()
	while parent!=null:
		grid=parent.get_node_or_null("GridStructureComponent")
		if grid!=null:break
		parent=parent.get_parent()
	if grid==null:
		push_error("Array floor writer needs its containing GridSystem")
		return
	dimensions=grid.get_grid_dimensions()
	for cell in grid.cube_positions:
		if editable(cell):original[cell]=true
	agent=FloorAgent.new();agent.host=self
	agent.position=Vector3(0,0.65,0)
	add_child(agent)
	# Fixed entry-side controls; the sphere moves independently of this stand.
	var panel:=Kit.panel(self,"THE FLOOR IS BEING WRITTEN",Vector3(-3,1.2,-15))
	panel.add_button("PAUSE / RESUME").pressed.connect(toggle_running)
	panel.add_button("RESTORE FLOOR").pressed.connect(restore_floor)
	readout=panel.add_readout("")
	refresh()
func editable(cell:Vector3i) -> bool:
	# The existing Molnár pad is a separate support surface. Preserve its walk.
	if cell.x>=7 and cell.x<=13 and cell.z>=13 and cell.z<=19:return false
	return cell.x>=2 and cell.x<dimensions.x-2 and cell.z>=3 and cell.z<dimensions.z-3 and cell.y>=0 and cell.y<=2
func candidates() -> Array[Vector3i]:
	var result:Array[Vector3i]=[]
	for cell in grid.cube_positions:
		if editable(cell) and (cell.y==0 or changed.has(cell)):
			if Vector2(cell.x-agent.grid_cell_position.x,cell.z-agent.grid_cell_position.z).length()<=3:result.append(cell)
	return result
func write_cell(copy:bool) -> bool:
	var cells:=candidates()
	cells.shuffle()
	for source in cells:
		if not copy:
			if grid.remove_cube_at(source.x,source.y,source.z):
				record(source,"CONSUMED");return true
		else:
			var offsets:Array[Vector3i]=[Vector3i.UP,Vector3i.LEFT,Vector3i.RIGHT,Vector3i.FORWARD,Vector3i.BACK]
			offsets.shuffle()
			for offset in offsets:
				var target:=source+offset
				if editable(target) and not grid.has_cube_at(target.x,target.y,target.z) and not occupied(target):
					if grid.add_cube_at(target.x,target.y,target.z):record(target,"COPIED");return true
	return false
func record(cell:Vector3i,verb:String) -> void:
	changed[cell]=true;writes+=1
	last_change="%s [%d, %d, %d]" % [verb,cell.x,cell.y,cell.z]
	refresh();state_changed.emit({"cell":[cell.x,cell.y,cell.z],"operation":verb,"writes":writes})
func occupied(cell:Vector3i) -> bool:
	# Do not materialise a cube through a visitor, or erase a restored copy beneath one.
	var shape:=BoxShape3D.new();shape.size=Vector3(1.15,1.18,1.15)
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape
	query.transform=Transform3D(Basis.IDENTITY,grid.parent_node.to_global(Vector3(cell)+Vector3(0,0.08,0)))
	for hit in get_world_3d().direct_space_state.intersect_shape(query,32):
		if hit.collider is CharacterBody3D and hit.collider!=agent:return true
	return false
func toggle_running() -> void:
	if grid==null or restoring:return
	running=not running;agent.set_physics_process(running);refresh()
func restore_floor() -> void:
	if grid==null:return
	running=false;agent.set_physics_process(false);restoring=true;clock=0
	refresh()
func _physics_process(delta:float) -> void:
	if not restoring:return
	clock+=delta
	if clock<0.2:return
	clock=0
	for cell in changed.keys():
		if occupied(cell):continue
		if original.has(cell):grid.add_cube_at(cell.x,cell.y,cell.z)
		else:grid.remove_cube_at(cell.x,cell.y,cell.z)
		changed.erase(cell)
	if changed.is_empty():
		restoring=false;last_change="FLOOR RESTORED / AGENT PAUSED"
		agent._change_state(agent.AgentState.WANDERING);agent.operation_timer=0
	refresh()
func refresh() -> void:
	if agent!=null:agent._update_thought_label()
	if readout!=null:
		readout.text=("STEP CLEAR TO RESTORE" if restoring else ("WRITING" if running else "PAUSED"))+" / %d CHANGED CELLS" % changed.size()
