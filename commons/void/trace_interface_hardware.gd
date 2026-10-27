extends RefCounted
## Dress the existing Trace instruments. Recorders, viewports, controls and
## archive coordinates stay owned by their original museum apparatus.
const Hardware := preload("res://commons/void/lines_interface_hardware.gd")
const Mount := preload("res://commons/void/ceiling_display_mount.gd")
const Print := preload("res://commons/void/array_control_hardware.gd")

static func attach_later(source: Node3D, kind: String) -> void:
	# Diptych panels rebuild on deferred config; DrawDot seats its panel in
	# physics against the actual curated plinth. Fit those final live surfaces.
	if not is_instance_valid(source) or not source.is_inside_tree(): return
	var tree := source.get_tree()
	await tree.physics_frame
	if not is_instance_valid(source) or not source.is_inside_tree() or source.is_queued_for_deletion(): return
	await tree.physics_frame
	if is_instance_valid(source) and source.is_inside_tree() and not source.is_queued_for_deletion():
		attach(source,kind)

static func attach(source: Node3D, kind: String) -> void:
	if not is_instance_valid(source) or source.is_queued_for_deletion(): return
	if Hardware._floor(source) == null: return
	if kind == "bead":
		var panel: Node3D=source._data_panel
		if not source._data_mount_ready: return
		_data_panel(panel, "existing")
		return
	if kind == "grid":
		var grid: Node3D=source.get_node("SavedTraceGrid")
		_data_panel(grid._data_panel,"existing")
		grid.get_node("ArchiveStem").material_override=Hardware._cream()
		grid.get_node("ArchiveBracket").material_override=Hardware._steel()
		var plate: MeshInstance3D=grid._data_panel.get_node("PagingBackplate")
		plate.material_override=Mount.material("384249",.9)
		for key in ["PreviousPage","AutoPages","NextPage"]:
			_rect_button(grid._data_panel.get_node(key))
		return
	if source.has_node("ArchitecturalHardware"):
		Hardware._connect(source.get_node("ArchitecturalHardware"))
		return
	match kind:
		"sampling":
			var h := Hardware._root(source)
			source.get_node("Case").material_override=Hardware._cream()
			source.get_node("Controls").material_override=Hardware._cream()
			source.get_node("Stand").material_override=Hardware._steel()
			Mount.box(h,"ServiceBack",Vector3(0,1.72,-.13),Vector3(2.76,1.66,.16),Hardware._cream())
			_vents(h,Vector3(.95,1.72,-.215),8)
			for key in source.buttons:
				source.get_node(str(key)+"Cap").material_override=Mount.material("384249",.88)
			# Original keys remain at 80 cm; do not lift the interaction volumes.
			Mount.box(h,"LegendStrip",Vector3(0,.59,.12),Vector3(1.9,.10,.025),Hardware._cream())
			Print.mark(h,"TRACE / ONE MOVEMENT / THREE GRAINS",Vector3(0,.59,.135),Vector2(1.72,.048))
			h.set_meta("port",Vector3(0,2.59,-.15))
			Hardware._connect(h)
		"hand_telemetry_diptych":
			# A deferred config or an editor rebuild may not have both panels yet.
			# Validate the complete source before creating a reusable hardware root.
			var panels: Array[Node3D] = []
			for side in ["left","right"]:
				var panel := source.get_node_or_null("Panel_"+side) as Node3D
				if panel == null or panel.is_queued_for_deletion() or not panel.has_node("Bezel"): return
				panels.append(panel)
			var h := Hardware._root(source)
			for panel in panels:
				panel.get_node("Bezel").material_override=Hardware._cream()
				Mount.box(h,"ServiceBack",Vector3(panel.position.x,source.panel_height*.5+.1,-.12),
					Vector3(source.panel_width+.16,source.panel_height+.16,.13),Hardware._cream())
			# Complete the existing shared pipe mount up to the real slab.
			h.set_meta("port",Vector3(0,source.panel_height+.47,-.36))
			Hardware._connect(h)
		"trace_paint_box":
			var h := Hardware._root(source)
			# Keep all four sides of the drawing volume open. Feed the plinth
			# behind its rear edge, rather than through the hand's volume.
			Mount.box(h,"ControlFace",Vector3(0,.30,.300),Vector3(.56,.39,.016),Hardware._cream())
			for key in ["Title","Status","Dimensions"]:
				source.get_node(key).position.z=.315
			Mount.box(h,"ServiceBack",Vector3(0,.30,-.34),Vector3(.50,.50,.08),Hardware._steel())
			_vents(h,Vector3(.14,.30,-.385),5)
			_rect_button(source.get_node("Clear/PushButton"))
			h.set_meta("support","existing")
			h.set_meta("port",Vector3(0,.55,-.40))
			Hardware._connect(h)

static func _data_panel(panel: Node3D, support: String) -> void:
	if panel.has_node("ArchitecturalHardware"):
		Hardware._connect(panel.get_node("ArchitecturalHardware"))
		return
	panel.get_node("Casing/Shell").material_override=Hardware._cream()
	panel.get_node("Casing/MetalRim").material_override=Hardware._steel()
	var h := Hardware._root(panel)
	Mount.box(h,"ServiceBack",Vector3(0,0,-.10),
		Vector3(panel.size_m.x+.07,panel.size_m.y+.07,.07),Hardware._cream())
	h.set_meta("support",support)
	h.set_meta("port",Vector3(0,panel.size_m.y*.5+.04,-.14))
	Hardware._connect(h)

static func _rect_button(button: Node3D) -> void:
	# Original spring, Area3D, pointer target, audio and pressed signal remain.
	var cap: MeshInstance3D=button.get_node("Button/ButtonMesh")
	var mesh := BoxMesh.new()
	mesh.size=Vector3(.075,.045,.035)
	cap.mesh=mesh
	button.get_node("ButtonBase").hide()
	button.get_node("AccentRing").hide()

static func _vents(host: Node3D, at: Vector3, count: int) -> void:
	for i in count:
		Mount.box(host,"ServiceVent",at+Vector3(0,(i-(count-1)*.5)*.045,0),
			Vector3(.20,.012,.006),Hardware._steel())
