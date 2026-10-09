extends Node3D
## Optional gallery in the same course project; the existing input rigs are reused.

const Gallery = preload("gallery.gd")
const DesktopPlayer = preload("res://prepared/desktop_player.gd")
const XRPlayer = preload("res://prepared/xr_player.gd")
var gallery := Gallery.new()
var player: Node3D
var xr_active := false
var interface: OpenXRInterface

func _ready() -> void:
    add_child(gallery)
    interface = XRServer.find_interface("OpenXR")
    xr_active = interface != null and interface.is_initialized()
    if xr_active:
        player = XRPlayer.new()
        get_viewport().use_xr = true
        DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
        interface.session_focussed.connect(_resume)
        interface.session_visible.connect(_pause)
        interface.session_stopping.connect(_pause)
    else:
        player = DesktopPlayer.new()
    player.position = gallery.spawn
    player.reset_requested.connect(reset_arrival)
    add_child(player)
    if xr_active:
        player.set_input_active(interface.get_session_state()==OpenXRInterface.SESSION_STATE_FOCUSED)
    else:
        var layer := CanvasLayer.new()
        var help := Label.new()
        help.text = "RINGS OF ASH   /   Click to look · WASD to walk · R to return · Esc for cursor"
        help.position = Vector2(24,20)
        help.add_theme_font_size_override("font_size",14)
        help.add_theme_color_override("font_shadow_color",Color("16151c"))
        help.add_theme_constant_override("shadow_offset_x",1)
        help.add_theme_constant_override("shadow_offset_y",1)
        layer.add_child(help)
        add_child(layer)

func _physics_process(_delta: float) -> void:
    var y: float = player.body.global_position.y if xr_active else player.global_position.y
    if y < -3.0:
        reset_arrival()

func reset_arrival() -> void:
    player.position = gallery.spawn
    if not xr_active:
        player.velocity = Vector3.ZERO

func _pause() -> void:
    player.set_input_active(false)

func _resume() -> void:
    player.set_input_active(true)
    var rate := interface.get_display_refresh_rate()
    if rate > 0:
        Engine.physics_ticks_per_second = int(rate)
