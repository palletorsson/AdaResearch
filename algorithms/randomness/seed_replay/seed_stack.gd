extends RefCounted
## Visible evidence for the seed comparison. Inspection never advances the RNG.
const Stage = preload("res://commons/artifacts/randomness_space/museum_exhibit_stage.gd")
const INFO_X := 0.84
const BODY_LEFT := -1.34
const BODY_RIGHT := 1.66
const CONTROL_HEIGHT := 1.63

static func centre(demo: Node3D, index: int) -> Vector3:
	# The first window starts near the floor. A hand-height control band separates
	# it from REPLAY; the upper pair retains the ordinary narrow frame spacing.
	var y: float = 0.10 + demo._grid_height*0.5
	if index>0:
		y=CONTROL_HEIGHT+0.38+demo._grid_height*0.5+(index-1)*(demo._grid_height+0.155)
	return Vector3(-0.64,y,0)

## A continuous case joins the open glass bays, inset readouts and hand controls.
## Nothing is put behind the panes: they remain windows through the instrument.
static func build_body(demo: Node3D) -> void:
	var old := demo.get_node_or_null("SeedCabinet")
	if old:
		demo.remove_child(old); old.queue_free()
	var body := Node3D.new(); body.name="SeedCabinet"; demo.add_child(body)
	var top: float = centre(demo,2).y+demo._grid_height*0.5+0.30
	var bottom: float = centre(demo,0).y-demo._grid_height*0.5-0.042
	var width := BODY_RIGHT-BODY_LEFT
	var mid := (BODY_RIGHT+BODY_LEFT)*0.5
	var frame := Color("283639")
	var trim := Color("a48d63")
	var inset := Color("1e2b30")
	# One base and two full-height sides. Colliders stay behind the control faces.
	Stage.box(body,Vector3(mid,bottom*0.5,-0.06),Vector3(width,bottom,0.36),frame,true).name="Base"
	Stage.box(body,Vector3(mid,0.045,0),Vector3(width+0.09,0.09,0.48),Color("182427"),true)
	for x in [BODY_LEFT,BODY_RIGHT]:
		Stage.box(body,Vector3(x,top*0.5,-0.04),Vector3(0.075,top,0.24),frame,true)
	# The right readout surface is part of the case, not three floating signs.
	Stage.box(body,Vector3(INFO_X,(bottom+top)*0.5,-0.06),Vector3(1.56,top-bottom,0.12),inset,true).name="ReadoutFace"
	Stage.box(body,Vector3(0.045,top*0.5,0.015),Vector3(0.06,top,0.17),frame,true)
	for index in 3:
		var y: float = centre(demo,index).y-demo._grid_height*0.5-0.06
		Stage.box(body,Vector3(mid,y,0.015),Vector3(width,0.10,0.17),frame)
		Stage.box(body,Vector3(mid,y+0.045,0.105),Vector3(width-0.08,0.009,0.008),trim)
	Stage.box(body,Vector3(mid,top-0.13,0.015),Vector3(width,0.26,0.17),frame).name="Header"
	# The solid control band belongs between START and REPLAY, not below START.
	var band_bottom: float = centre(demo,0).y+demo._grid_height*0.5+0.042
	var band_top: float = centre(demo,1).y-demo._grid_height*0.5-0.042
	Stage.box(body,Vector3(mid,(band_bottom+band_top)*0.5,-0.06),Vector3(width,band_top-band_bottom,0.36),frame,true).name="ControlBand"
	Stage.box(body,Vector3(-0.64,CONTROL_HEIGHT,0.124),Vector3(1.21,0.50,0.012),inset)
	Stage.box(body,Vector3(INFO_X,CONTROL_HEIGHT,0.124),Vector3(1.48,0.54,0.012),inset)
	var mark:=Marker3D.new(); mark.name="StandingPosition"
	mark.position=Vector3(INFO_X,0,0.80); body.add_child(mark)

static func fit_controls(panel: Node3D) -> void:
	panel.set_meta("em_embedded_control",true)
	var factor: float = minf(2.6,1.42/float(panel.get_meta("panel_w")))
	panel.position=Vector3(INFO_X,CONTROL_HEIGHT,0.16)
	panel.rotation=Vector3.ZERO
	panel.scale=Vector3.ONE*factor

static func caption(parent: Node3D, words: String, at: Vector3, size: int = 22) -> Label3D:
	var label := Stage.label(parent,words,at)
	label.font_size=size
	label.pixel_size=0.0018
	label.outline_size=2
	return label

static func draw_readouts(demo: Node3D, parent: Node3D) -> void:
	for index in demo.column_count():
		var y := centre(demo,index).y
		var skip: int = demo.extra_draws if index==demo.comparison_target() and demo.extra_on() else 0
		var mapping: String = demo.mapping_description() if index==demo.comparison_target() and demo.mapping_study else "RGB · [0, 1]"
		caption(parent,mapping,Vector3(INFO_X,y+0.17,0.06))
		var values: PackedFloat32Array = demo.raw_prefix(index,mini(24,demo.draws_per_grid()))
		for i in values.size():
			var h: float = 0.008 + values[i]*0.16
			Stage.box(parent,Vector3(INFO_X-0.59+i*0.051,y-0.08+h*0.5,0.04),Vector3(0.033,h,0.018),Color("72d5c0"))
		caption(parent,"DRAWS %d–%d / %d per window" % [skip+1,skip+values.size(),demo.draws_per_grid()],Vector3(INFO_X,y-0.14,0.06),19)
		caption(parent,"First draws: %.3f  %.3f  %.3f" % [values[0],values[1],values[2]],Vector3(INFO_X,y-0.23,0.06),20)
		var agreement := "Three draws → one coloured pane"
		if index>0:
			var a: PackedColorArray = demo.column_colors(0)
			var b: PackedColorArray = demo.column_colors(index)
			var equal := 0
			for i in a.size():
				if a[i]==b[i]: equal+=1
			agreement = "%d / %d panes match START" % [equal,a.size()]
		caption(parent,agreement,Vector3(INFO_X,y-0.40,0.06),24)
		var change := "Same generator · same RGB rule"
		if index==1:
			change = "Restarted from the same seed"
			if skip>0: change = "%d draw(s) skipped before colouring" % skip
		caption(parent,change,Vector3(INFO_X,y-0.51,0.06),19)
