extends RefCounted

var columns := 4
var rows := 4
var tile_pixels := 32
var use_rule := true
var exception := false
var exception_cell := Vector2i(1, 2)

func turn_at(column: int, row: int) -> int:
    var turns := (column + row) % 4 if use_rule else 0
    if exception and Vector2i(column, row) == exception_cell:
        turns += 1
    return turns % 4

func make() -> Image:
    assert(columns > 0 and rows > 0 and tile_pixels > 1)
    var image := Image.create(columns * tile_pixels, rows * tile_pixels, false, Image.FORMAT_RGB8)
    for row in rows:
        for column in columns:
            var turns := turn_at(column, row)
            for v in tile_pixels:
                for u in tile_pixels:
                    var source := Vector2i(u, v)
                    for quarter in turns:
                        source = Vector2i(source.y, tile_pixels - 1 - source.x)
                    var black := source.x > source.y
                    image.set_pixel(column * tile_pixels + u, row * tile_pixels + v, Color.BLACK if black else Color.WHITE)
    return image
