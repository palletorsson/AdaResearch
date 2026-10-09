extends "res://doc/book/iterations/2026-09-19-tiling-review/opening/probes/capture_opening.gd"

func run() -> void:
	map_name="Pattern_Disco"
	await super.run()

func values(n: Node3D) -> Array:
	var result: Array=[]
	for z in n.floor_node.grid_depth:
		for x in n.floor_node.grid_width:
			result.append(n.value_at(x,z,n.floor_node.grid_width,n.floor_node.grid_depth))
	return result

func test_disco() -> void:
	await super.test_disco()
	var n:Node3D=artifacts.disco_controls
	var seq:Node3D=artifacts.step_sequencer
	check(n.sequencer==seq,"pulse expiry listens only to this hall's bound musical sequencer")
	seq.set_process(false);seq.stop();n.running=false;n.phase=5;n.paint()
	var arrangement:=values(n)
	var colours:Array=n.floor_node.tile_colors.duplicate()
	var pattern:int=n.pattern
	if n.colour:
		n.cycle_palette()
		check(values(n)==arrangement and n.pattern==pattern and n.phase==5,"palette changes no source values, arrangement or phase")
		check(n.floor_node.tile_colors!=colours,"palette changes the visible tile colours through the palette function")
	else:
		check(n.palette==0 and n.floor_node.monochrome,"earlier Array hall retains its monochrome presentation")
	var palette:int=n.palette
	n.cycle_pattern()
	check(n.palette==palette and n.phase==0,"pattern change preserves palette and resets phase zero")
	n.phase=5;n.paint();arrangement=values(n)
	var interval:float=n.interval
	n.cycle_speed()
	check(n.interval!=interval and values(n)==arrangement and n.palette==palette and n.phase==5,"speed changes interval without editing arrangement, palette or phase")
	seq.play();seq._playhead_position=7;seq._on_bpm_changed(60.0)
	n.interval=seq._step_interval;n.elapsed=0.07
	check(n.phase==5 and seq._playhead_position==7 and n.elapsed!=seq._step_timer,"matching intervals preserves separate clock phase and playhead")
	seq.stop();n.running=true;n._process(n.interval)
	check(n.phase==6 and not seq._is_playing,"visual clock advances with musical clock stopped")
	n.running=false;n.paint();colours=n.floor_node.tile_colors.duplicate()
	var mesh_id:RID=n.floor_node.multimesh.get_rid()
	seq.emit_signal("step_triggered",1,3)
	check(n.phase==6 and values(n)!=[] and n.floor_node.tile_colors!=colours,"music flashes a held floor without advancing its pattern")
	await create_timer(0.8).timeout
	check(n.floor_node.tile_colors==colours,"musical flash expires while the visual pattern is held")
	seq.emit_signal("step_triggered",1,2)
	n._process(0.1)
	seq.emit_signal("step_triggered",2,4)
	n._process(0.06)
	var current:Array=n.floor_node.tile_colors
	check(current[2]==colours[2] and current[4]!=colours[4],"each column expires independently of a later musical event")
	n._process(0.1)
	check(n.floor_node.tile_colors==colours,"all musical columns return to the held values")
	seq.emit_signal("step_triggered",1,2);n._process(0.1)
	seq.emit_signal("step_triggered",2,2);n._process(0.1)
	check(n.floor_node.tile_colors[2]!=colours[2] and n.phase==6,"same-column event renews its lifetime without advancing held phase")
	n._process(0.06)
	check(n.floor_node.tile_colors==colours,"renewed column expires after its latest event")
	seq.emit_signal("step_triggered",0,0)
	if n.colour:n.cycle_palette()
	n.cycle_pattern();colours=n.floor_node.tile_colors.duplicate()
	n._process(0.2)
	check(n.floor_node.tile_colors==colours and n.phase==0,"flash expiry uses current palette and pattern after controls change")
	n.running=true;n.elapsed=0.0
	seq.emit_signal("step_triggered",1,4);n._process(n.interval+0.01)
	check(n.phase==1 and n.running,"running visual pattern still advances normally after a musical event")
	check(n.floor_node.multimesh.get_rid()==mesh_id,"clock and palette controls preserve floor geometry")
	seq.stop();n.pattern=0;n.palette=1 if n.colour else 0;n.phase=0;n.running=false;n.paint()
