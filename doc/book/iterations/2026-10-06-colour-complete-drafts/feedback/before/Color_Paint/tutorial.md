# Paint — a mark stays on the surface

**Learning elements**

- Held, active and valid-hit states
- A named action carried from input to an operation
- A ray selecting the first surface it meets
- A world hit converted to a surface address
- Repeated marks accumulating in one image

Take a spray can in the museum. Colour arrives where the nozzle meets a surface; it remains when you turn away. Grid kept one colour at a cell address. Paint keeps many small deposits in a surface image.

We return to PointBody as a small study brush. Its pickup behaviour is already built. The lesson adds the path from a held object and an action to a retained mark. The museum's can shell, mist, wetness, elongated deposits and paint runs are richer than this study's circular soft stamps.

## Continue with the point

Save the four files below together. Keep the exact `point_body.gd` from Lines and Coordinates. Attach `lesson.gd` to a Node3D in an open part of your working museum hall. Keep unit scale throughout. Its local origin is on the floor; the white canvas is centred at Y = 1.5, faces positive Z and measures 4 by 2.5 metres. The point begins 1.5 metres in front of it. The museum supplies the camera, player and configured XR Tools.

Grip the point in VR. Its forward direction is local negative Z, indicated by the small stem. The prepared pickup driver calls its action methods when you press and release the controller trigger. In this study we name that action `spray`. On desktop, press **H** to attach the study brush to the mouse ray, then hold the left mouse button to paint. Press H again to put it down. This adapter is included; it is not a new input-map setup lesson.

## The complete continuation — lesson.gd

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const Canvas = preload("canvas.gd")
const Controls = preload("controls.gd")

@export var ink := Color(0.8, 0.2, 0.6)
var radius := 0.06
var max_distance := 3.0
var automatic := false
var elapsed := 0.0
var held := false
var active := false
var spraying := false
var painting := false
var point: XRToolsPickable
var canvas: MeshInstance3D
var readout: Label3D

func _ready() -> void:
    canvas = Canvas.new()
    canvas.position = Vector3(0, 1.5, 0)
    canvas.rotation.x = PI / 2.0
    add_child(canvas)
    point = PointBody.new()
    point.position = Vector3(0, 1.5, 1.5)
    add_child(point)
    var stem := MeshInstance3D.new()
    var nozzle := BoxMesh.new()
    nozzle.size = Vector3(0.035, 0.035, 0.22)
    stem.mesh = nozzle
    stem.position.z = -0.2
    point.add_child(stem)
    point.picked_up.connect(func(_body): set_held(true))
    point.dropped.connect(func(_body): set_held(false))
    point.action_pressed.connect(func(_body): set_action("spray", true))
    point.action_released.connect(func(_body): set_action("spray", false))
    readout = Label3D.new()
    readout.position = Vector3(0, 2.95, 0)
    readout.font_size = 30
    readout.pixel_size = 0.004
    add_child(readout)
    add_child(Controls.new())

func set_held(value: bool) -> void:
    held = value
    if not held:
        active = false

func set_action(action_name: String, pressed: bool) -> void:
    if action_name == "spray":
        active = pressed and held

func _physics_process(delta: float) -> void:
    elapsed += delta
    manual_step(delta)
    if automatic:
        automatic_step(elapsed, delta)
    readout.text = "MARK" if painting else ("SPRAY / MISS" if spraying else "READY")

func manual_step(delta: float) -> void:
    painting = false
    spraying = held and active
    if not spraying:
        return
    var origin := point.global_position
    var direction := -point.global_basis.z.normalized()
    var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * max_distance, 1, [point.get_rid()])
    query.collide_with_areas = true
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if hit.get("collider") != canvas.receiver:
        return
    painting = canvas.draw_spray(hit.position, direction, radius, ink, 1.0 - exp(-7.0 * delta))

func automatic_step(time: float, delta: float) -> void:
    var uv := Vector2(0.5 + 0.3 * sin(time), 0.5 + 0.3 * sin(time * 1.3))
    var hit: Vector3 = canvas.world_at(uv)
    canvas.draw_spray(hit, -canvas.global_basis.y.normalized(), radius, ink, 1.0 - exp(-7.0 * delta))
```

Run and aim at the canvas. **READY** means the manual brush is not active. **SPRAY / MISS** means it is active but has no accepted canvas hit. **MARK** means the current step reached the receiver and deposited colour. These are state readouts; the reduced study has no particle mist.

## Permission, aim, address

Picking up the point sets `held`. An action press can set `active` only while held. Releasing the action clears it; dropping the point clears it too. Calling `set_action` with another name does nothing. Those conditions decide whether `manual_step` may attempt a mark.

The ray begins at the point and travels along its forward axis, up to `max_distance`. It excludes the point's own physics body. `collide_with_areas` lets it find the canvas receiver, which is an Area3D. The first hit must be that receiver. A miss or another object in front of the canvas leaves the image unchanged.

The hit position belongs to the world. The canvas converts it with `to_local`, then divides local X and Z by its width and height to obtain a UV address between zero and one. The canvas was turned upright as a whole; its local drawing plane is still XZ. This lets the same address calculation work when the study is moved or turned.

`draw_spray` blends the ink into existing pixels near that address. Closer pixels receive more. The amount `1 - exp(-7 * delta)` describes an accumulation rate: with a stationary brush and the same soft weight, shorter time steps approach the colour in smaller increments. Rasterisation and pixel rounding still affect the result. This is a simple deposit model, not a physical aerosol simulation.

## Make and keep a mark

1. Paint briefly at the centre. Hold still longer: the same region grows closer to the ink colour. Move away and release. The earlier mark remains.
2. Change `radius` from 0.06 to 0.12. The physical radius doubles. Width and height are converted separately, so the 4 by 2.5 metre canvas does not stretch a circular stamp into an oval.
3. Restore the radius. Set `max_distance` to 1.0. At the initial point position the surface is out of reach; pressing produces no mark. Restore 3.0 and it is reachable again.

Choose another ink colour and use it over an existing mark while the study is running, through the inspector's Remote view. `@export` exposes `ink` there: select the running study node and edit its Ink property. The image keeps its previous contents and the new deposits blend into them. Restarting this study creates a fresh white image; saving it across sessions is not part of this lesson.

## Another caller, the same receiver

Set `automatic` to true and run. `automatic_step` supplies a moving UV address through two sine functions, maps it back to the canvas and calls the same `draw_spray` method. It does not require the manual brush to be held. Manual and automatic callers accumulate in the same image.

For an independent continuation, change the second sine rate from 1.3 to 2.0. Predict how its repeated path differs. Keep the manual controls working while the path runs. The canvas should not need a second renderer for another source of marks.

## Supplied receiver — canvas.gd

<!-- student-code:canvas.gd -->
```gdscript
# Supplied small image receiver. Shares the museum's XZ-plane coordinate convention.
# Soft circular stamps accumulate; aerosol grains, oblique stretching, runs and fading are omitted.
extends MeshInstance3D

const SIZE := Vector2(4, 2.5)
const PIXELS := Vector2i(512, 320)
var receiver: Area3D
var image: Image
var texture: ImageTexture
var deposits := 0

func _ready() -> void:
    var plane := PlaneMesh.new()
    plane.size = SIZE
    mesh = plane
    image = Image.create(PIXELS.x, PIXELS.y, false, Image.FORMAT_RGBA8)
    image.fill(Color.WHITE)
    texture = ImageTexture.create_from_image(image)
    var surface := StandardMaterial3D.new()
    surface.albedo_texture = texture
    surface.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material_override = surface
    receiver = Area3D.new()
    receiver.collision_layer = 1
    receiver.collision_mask = 0
    var boundary := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(SIZE.x, 0.02, SIZE.y)
    boundary.shape = box
    receiver.add_child(boundary)
    add_child(receiver)

func uv_at(world_hit: Vector3) -> Vector2:
    var p := to_local(world_hit)
    return Vector2(p.x / SIZE.x + 0.5, p.z / SIZE.y + 0.5)

func world_at(uv: Vector2) -> Vector3:
    return to_global(Vector3((uv.x - 0.5) * SIZE.x, 0, (uv.y - 0.5) * SIZE.y))

func draw_spray(world_hit: Vector3, direction: Vector3, radius_m: float, colour: Color, opacity: float) -> bool:
    if radius_m <= 0 or opacity <= 0:
        return false
    var normal := global_basis.y.normalized()
    if -normal.dot(direction.normalized()) < 0.22:
        return false
    var uv := uv_at(world_hit)
    if uv.x < 0 or uv.x > 1 or uv.y < 0 or uv.y > 1:
        return false
    var centre := uv * Vector2(PIXELS)
    var extent := Vector2(radius_m / SIZE.x, radius_m / SIZE.y) * Vector2(PIXELS)
    var wrote := false
    for y in range(maxi(0, floori(centre.y - extent.y)), mini(PIXELS.y, ceili(centre.y + extent.y))):
        for x in range(maxi(0, floori(centre.x - extent.x)), mini(PIXELS.x, ceili(centre.x + extent.x))):
            var offset := (Vector2(x + 0.5, y + 0.5) / Vector2(PIXELS) - uv) * SIZE
            var weight := clampf(1.0 - offset.length() / radius_m, 0, 1)
            var amount := clampf(opacity, 0, 1) * weight
            if amount > 0:
                image.set_pixel(x, y, image.get_pixel(x, y).lerp(colour, amount))
                wrote = true
    if not wrote:
        return false
    texture.update(image)
    deposits += 1
    return true
```

The receiver rejects invalid radii, empty deposits, outside addresses and rays facing away or too obliquely. It allocates the image once, blends into its pixels, then updates the texture shown by the material. Its support code is visible so the mark has no hidden implementation. The lesson's focus is connecting the known body and action to this surface operation; GPU feedback, wet-paint chemistry and drip motion remain outside this reduced model.

## Supplied desktop adapter — controls.gd

<!-- student-code:controls.gd -->
```gdscript
# Supplied desktop adapter. H engages/releases a mouse-aimed study brush.
# XR uses the inherited body's pickup and action signals instead.
extends Node

var engaged := false

func _unhandled_input(event: InputEvent) -> void:
    var study := get_parent()
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_H:
        engaged = not engaged
        study.set_held(engaged)
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and engaged:
        study.set_action("spray", event.pressed)

func _process(_delta: float) -> void:
    if not engaged:
        return
    var camera := get_viewport().get_camera_3d()
    if camera == null:
        return
    var mouse := get_viewport().get_mouse_position()
    var direction := camera.project_ray_normal(mouse)
    var at := camera.project_ray_origin(mouse) + direction * 0.5
    var point: Node3D = get_parent().point
    point.global_position = at
    point.look_at(at + direction)
```

## Inherited body — point_body.gd

<!-- student-code:point_body.gd -->
```gdscript
extends XRToolsPickable

const RADIUS := 0.14

func _init() -> void:
    freeze = true
    freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
    release_mode = XRToolsPickable.ReleaseMode.FROZEN
    ranged_grab_method = XRToolsPickable.RangedMethod.NONE
    collision_layer = 4
    collision_mask = 196615

    var surface := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = RADIUS
    sphere.height = RADIUS * 2.0
    surface.mesh = sphere
    add_child(surface)

    var boundary := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = RADIUS
    boundary.shape = shape
    add_child(boundary)
```

Paint leaves state on a surface. Walls next asks what happens when a surface changes the view through it while its physical boundary stays put.
