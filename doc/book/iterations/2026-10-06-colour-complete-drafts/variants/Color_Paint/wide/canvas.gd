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
