extends RefCounted

const SIDE := 256
const GAIN := 0.03
const REPEATS := Vector2(3, 3)

static func build() -> Dictionary:
    var height := Image.create(SIDE, SIDE, false, Image.FORMAT_RF)
    for y in SIDE:
        for x in SIDE:
            var uv := Vector2(x + 0.5, y + 0.5) / SIDE
            var address := uv * REPEATS
            var tile := address - address.floor()
            var distance := tile.distance_to(Vector2(0.5, 0.5))
            var value := 1.0 - smoothstep(0.22, 0.38, distance)
            height.set_pixel(x, y, Color(value, 0, 0))

    var normal := Image.create(SIDE, SIDE, false, Image.FORMAT_RGB8)
    var step := 1.0 / SIDE
    for y in SIDE:
        for x in SIDE:
            var left := height.get_pixel(posmod(x - 1, SIDE), y).r
            var right := height.get_pixel((x + 1) % SIDE, y).r
            var above := height.get_pixel(x, posmod(y - 1, SIDE)).r
            var below := height.get_pixel(x, (y + 1) % SIDE).r
            var du := (right - left) / (2.0 * step)
            var dv := (below - above) / (2.0 * step)
            var direction := Vector3(-du * GAIN, dv * GAIN, 1).normalized()
            var encoded := direction * 0.5 + Vector3.ONE * 0.5
            normal.set_pixel(x, y, Color(encoded.x, encoded.y, encoded.z))
    return {
        "height": ImageTexture.create_from_image(height),
        "normal": ImageTexture.create_from_image(normal)
    }
