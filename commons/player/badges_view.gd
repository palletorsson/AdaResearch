extends Node3D
## THE BADGES COLLATION, SHOWN (2026-11-17). The collation itself is a Control (commons/player/badges_panel.gd), so
## the coming select board can host it as a TAB; until that board exists this node shows the same panel:
##   desktop  as a 2D overlay (a CanvasLayer, drawn after the whole 3D frame: crisp text at the screen's own pixels and
##            no 3D sorting to win), upper middle of the view. V toggles it. (B is taken in the Void: the bridge's spawn
##            menu, commons/bridge/spawn_menu.gd TOGGLE_KEY, made by VRLink the first time the Void is seen, and
##            staging's map loader, vrStaging.gd.)
##   VR       a headset has no 2D overlay: a SubViewport draws the panel onto a quad hanging in the view, no depth test.
##   both     shown 4 s after every collect: the coin calls show_for(4.0) on the group badge_views.
## No attachment to the inventory prism (Palle, 2026-11-17: the prism drum is being replaced by the board).
## Built by badge_layer.gd, one per game.

const PanelLib := preload("res://commons/player/badges_panel.gd")
const TOGGLE_KEY := KEY_V
const OVERLAY_LAYER := 60
const AT := Vector3(0, .1, -.45)      # VR: in the camera's frame
const METRES_PER_PX := .0006          # VR: 520 px (four coins) is 31 cm at 45 cm from the eye
const VR_MAX := Vector2(.40, .30)     # VR: never wider or taller than this (a long path is drawn smaller)
const SCREEN_FILL := Vector2(.94, .84) # desktop: at most this share of the view (a long path is scaled down)

var force_mode := ""                  # a probe's: "desktop" or "vr"
var holder_override: Node3D = null    # a probe's holder for the VR quad instead of the current camera
var panel: Control
var overlay: CanvasLayer
var viewport: SubViewport
var quad: MeshInstance3D
var mode := ""
var _left := 0.0
var _pinned := false
var _size := Vector2i.ZERO
var _renders := 0                     # VR: frames left in which the panel is drawn into the quad's texture again

func _ready() -> void:
	add_to_group("badge_views")
	add_to_group("badge_listeners")
	panel = PanelLib.new();panel.name = "BadgesPanel"
	overlay = CanvasLayer.new();overlay.name = "Overlay";overlay.layer = OVERLAY_LAYER;overlay.visible = false;add_child(overlay)
	viewport = SubViewport.new();viewport.name = "PanelViewport"
	viewport.transparent_bg = true;viewport.disable_3d = true;viewport.gui_disable_input = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(viewport)
	quad = MeshInstance3D.new();quad.name = "Quad";quad.mesh = QuadMesh.new();quad.visible = false
	var m := StandardMaterial3D.new();m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA;m.no_depth_test = true;m.render_priority = 100
	m.albedo_texture = viewport.get_texture()
	quad.material_override = m;quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(quad)
	overlay.add_child(panel)

## Show the collation now, for `seconds` (the coin's collect calls this on the group).
func show_for(seconds := 4.0) -> void:
	_left = maxf(_left, seconds)
	_redraw();_update(0.0)

## Desktop V: shown until V again.
func toggle() -> void:
	_pinned = not _pinned
	_redraw();_update(0.0)

func showing() -> bool:
	return _pinned or _left > 0.0

func badge_collected(_id: String) -> void:
	_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:return
	var k := event as InputEventKey
	if k.keycode != TOGGLE_KEY or k.ctrl_pressed or k.alt_pressed or k.shift_pressed or mode == "vr":return
	toggle()
	get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	_update(delta)

func _vr() -> bool:
	var g: Node = get_tree().get_first_node_in_group("void_game")
	if g != null:return bool(g.get("vr"))
	return XRServer.primary_interface != null and XRServer.primary_interface.is_initialized()

## The panel laid out again; in VR drawn into the quad's texture on the next two frames.
func _redraw() -> void:
	if panel == null:return
	panel.refresh()
	if mode != "vr":return
	var px := Vector2i(ceili(panel.size.x), ceili(panel.size.y))
	if px != _size:
		_size = px;viewport.size = px
		var mpp := minf(METRES_PER_PX, minf(VR_MAX.x / px.x, VR_MAX.y / px.y))
		(quad.mesh as QuadMesh).size = Vector2(px) * mpp
		quad.position.y = -(px.y * mpp) * .5   # its top edge at AT
	_renders = 2   # this frame and the next: the panel's own _draw lands a frame after its refresh

func _update(delta: float) -> void:
	if not is_inside_tree():return
	if _left > 0.0:_left -= delta
	var want := showing()
	var m := force_mode if force_mode != "" else ("vr" if _vr() else "desktop")
	if m != mode:
		mode = m
		panel.reparent(viewport if mode == "vr" else overlay, false)
		panel.position = Vector2.ZERO;panel.scale = Vector2.ONE
		_size = Vector2i.ZERO
		_redraw()
	if mode == "vr":
		overlay.visible = false
		var holder: Node3D = holder_override if holder_override != null else get_viewport().get_camera_3d()
		if holder != null and get_parent() != holder:
			reparent(holder, false)
			transform = Transform3D(Basis(), AT)
		if _renders > 0:
			_renders -= 1;viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		quad.visible = want
	else:
		quad.visible = false
		if want:
			var view := get_viewport().get_visible_rect().size
			var k := minf(1.0, minf(view.x * SCREEN_FILL.x / panel.size.x, view.y * SCREEN_FILL.y / panel.size.y))
			panel.scale = Vector2.ONE * k
			panel.position = Vector2(roundf((view.x - panel.size.x * k) * .5), roundf(view.y * .1))
		overlay.visible = want
	visible = want
