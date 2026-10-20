extends Node3D
## Visual research instruments, not completed museum encounters.
const K = preload("geometry_kernel.gd")
var mode := "disk"
var lines: MeshInstance3D
var mesh: ImmediateMesh
var camera: Camera3D
var travel := 0.5
var status: Label
var capture_mode := false
const PINK = Color(1.0,0.56,0.72)
const GOLD = Color(1.0,0.78,0.3)
const FAINT = Color(0.25,0.39,0.47)
const PALE = Color(0.88,0.94,0.96)

func _ready() -> void:
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--mode="): mode = arg.trim_prefix("--mode=")
        if arg == "--capture": capture_mode = true
    var env := WorldEnvironment.new()
    env.environment = Environment.new()
    env.environment.background_mode = Environment.BG_COLOR
    env.environment.background_color = Color(0.018,0.024,0.033)
    add_child(env)
    camera = Camera3D.new()
    camera.near = 0.015
    add_child(camera)
    camera.current = true
    if mode in ["disk","sphere","ball"]:
        camera.projection = Camera3D.PROJECTION_ORTHOGONAL
        camera.size = 2.0 if mode == "ball" else 2.8
        camera.position = Vector3(0,0,4) if mode == "disk" else Vector3(2.2,1.4,2.7)
        camera.look_at(Vector3.ZERO)
    else:
        camera.fov = 94
    mesh = ImmediateMesh.new()
    lines = MeshInstance3D.new()
    lines.mesh = mesh
    var mat := StandardMaterial3D.new()
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.vertex_color_use_as_albedo = true
    lines.material_override = mat
    add_child(lines)
    for rect in [Rect2(0,0,1280,88),Rect2(0,675,1280,125)]:
        var panel := ColorRect.new()
        panel.position=rect.position
        panel.size=rect.size
        panel.color=Color(0.018,0.024,0.033,0.96)
        add_child(panel)
    var title := Label.new()
    title.position = Vector2(32,25)
    title.add_theme_font_size_override("font_size",28)
    title.text = {
        "disk":"H² / THE BOUNDARY IS NOT A WALL",
        "sphere":"S² / RETURN WITH A DIFFERENT DIRECTION",
        "ball":"H³ / A FINITE WINDOW ON UNBOUNDED SPACE",
        "product":"H² × R / KEEP VERTICAL HEIGHT",
        "inside":"H³ / CURVATURE IN EVERY PLANE"
    }.get(mode,mode)
    add_child(title)
    status = Label.new()
    status.position = Vector2(32,690)
    status.add_theme_font_size_override("font_size",20)
    add_child(status)
    rebuild()
    if capture_mode:
        for i in range(8): await get_tree().process_frame
        await RenderingServer.frame_post_draw
        get_viewport().get_texture().get_image().save_png("res://geometry-"+mode+".png")
        print("CURVED RENDER ",mode," complete")
        get_tree().quit()

func _process(delta: float) -> void:
    if capture_mode: return
    var change := Input.get_axis("ui_left","ui_right")*delta*0.65
    if absf(change) > 0:
        travel = clampf(travel+change,-0.8,0.8)
        rebuild()

func segment(a: Vector3,b: Vector3,colour: Color) -> void:
    mesh.surface_set_color(colour)
    mesh.surface_add_vertex(a)
    mesh.surface_set_color(colour)
    mesh.surface_add_vertex(b)

func circle(radius: float,colour: Color) -> void:
    for i in range(128):
        var t := TAU*i/128.0
        var u := TAU*(i+1)/128.0
        segment(Vector3(cos(t),sin(t),0)*radius,Vector3(cos(u),sin(u),0)*radius,colour)

func marker(p: Vector3,colour: Color) -> void:
    for axis in [Vector3.RIGHT,Vector3.UP,Vector3.BACK]: segment(p-axis*0.012,p+axis*0.012,colour)

func rebuild() -> void:
    mesh.clear_surfaces()
    mesh.surface_begin(Mesh.PRIMITIVE_LINES)
    if mode == "disk": draw_disk()
    elif mode == "sphere": draw_sphere()
    else: draw_network()
    mesh.surface_end()

func draw_disk() -> void:
    circle(1.0,PALE)
    for i in range(1,7): circle(tanh(i*0.3),FAINT)
    var a := K.from_ball(Vector3(-0.5,-0.28,0))
    var b := K.from_ball(Vector3(0.55,-0.2,0))
    var c := K.from_ball(Vector3(travel*0.3,0.62,0))
    var points: Array[Vector4] = [a,b,c]
    for j in range(3):
        for i in range(80):
            segment(K.to_ball(K.geodesic(points[j],points[(j+1)%3],i/80.0)),K.to_ball(K.geodesic(points[j],points[(j+1)%3],(i+1)/80.0)),PINK)
        marker(K.to_ball(points[j]),GOLD)
    for i in range(9):
        var r := tanh(i*0.24)
        var p := Vector3(-0.62,0.785,0).normalized()*r
        marker(p,GOLD)
    status.text = "Exact geodesics • angle sum %.2f° • curvature radius 1\nGold marks: equal intrinsic steps. Left/right changes the same triangle.\nModel view, not a first-person hyperbolic room." % rad_to_deg(K.triangle_sum(a,b,c))

func draw_sphere() -> void:
    for axis in [Vector3.RIGHT,Vector3.UP,Vector3.BACK]:
        var start := Vector3.UP if axis == Vector3.RIGHT else Vector3.RIGHT
        for i in range(100): segment(start.rotated(axis,TAU*i/100.0),start.rotated(axis,TAU*(i+1)/100.0),FAINT)
    var points := [Vector3.RIGHT,Vector3.UP,Vector3.BACK,Vector3.RIGHT]
    var arrow := Vector3.UP
    for j in range(3):
        var a: Vector3 = points[j]
        var b: Vector3 = points[j+1]
        for i in range(40): segment(a.slerp(b,i/40.0),a.slerp(b,(i+1)/40.0),PINK)
        arrow=K.transport_sphere(arrow,a,b)
    segment(Vector3.RIGHT,Vector3.RIGHT+Vector3.UP*0.4,GOLD)
    segment(Vector3.RIGHT,Vector3.RIGHT+arrow*0.4,PINK)
    status.text="Three right angles, total 270° • same start and finish\nGold tangent before travel; pink tangent after parallel transport: a 90° change.\nA curved two-dimensional surface, not the whole three-dimensional room."

func model_point(v: Vector3) -> Vector4:
    # Seed coordinates choose this finite scaffold; it is not a regular honeycomb.
    if mode == "product":
        return Vector4(v.x,0,v.z,sqrt(1+v.x*v.x+v.z*v.z))
    var r := v.length()
    if r < 0.00001: return K.origin()
    var n := v/r
    return Vector4(n.x*sinh(r),n.y*sinh(r),n.z*sinh(r),cosh(r))

func projected(p: Vector4,height: float) -> Vector3:
    var relative := K.boost(p,Vector3.RIGHT,-travel)
    if mode == "ball": return K.to_ball(relative)
    if mode == "product": return K.h2xr_display(relative,height)
    return K.to_klein(relative)*5.0

func edge(a: Vector3,b: Vector3,colour: Color) -> void:
    var pa := model_point(a)
    var pb := model_point(b)
    for i in range(12):
        var t := i/12.0
        var u := (i+1)/12.0
        segment(projected(K.geodesic(pa,pb,t),lerpf(a.y,b.y,t)),projected(K.geodesic(pa,pb,u),lerpf(a.y,b.y,u)),colour)

func draw_network() -> void:
    # Twenty-five columns joined by two grids; same seed scaffold in both spaces.
    for ix in range(5):
        for iz in range(5):
            var x := (ix-2)*0.7
            var z := (iz-2)*0.7
            var bottom := Vector3(x,-0.65,z)
            var top := Vector3(x,0.65,z)
            edge(bottom,top,PINK)
            for h in [-0.65,0.65]:
                if ix < 4: edge(Vector3(x,h,z),Vector3(x+0.7,h,z),FAINT if h>0 else PALE)
                if iz < 4: edge(Vector3(x,h,z),Vector3(x,h,z+0.7),FAINT if h>0 else PALE)
    if mode == "ball":
        status.text="Poincaré ball model • pink paths are geodesics in H³\nA finite 25-column scaffold; no claim of a regular tessellation or finished hall.\nLeft/right applies an isometry before projection."
    elif mode == "product":
        status.text="First-person central projection • horizontal H², ordinary vertical height\nLeft/right moves the observer %.2f curvature-radius units.\nFinite wire scaffold; desktop mono only. No collision or tracked hands yet." % travel
    else:
        status.text="First-person central projection after an H³ isometry • all planes curve\nLeft/right moves the observer %.2f curvature-radius units.\nFinite wire scaffold; desktop mono only. No collision or tracked hands yet." % travel
