extends "04_surface_frame.gd"

const RULE_NAMES := ["P1 / TRANSLATE", "PM / REFLECT", "PG / GLIDE"]
var rule := 0

func _ready() -> void:
    assert(source.size() % 2 == 0, "This discrete half-height shift needs an even row count.")
    super._ready()
    var card := Label3D.new()
    card.text = "RULE"
    card.position = Vector3(0, 0.9, 2.5)
    card.font_size = 28
    card.pixel_size = 0.002
    add_child(card)

func source_address(address: Vector2i) -> Vector2i:
    var cell := super.source_address(address)
    var tile_column := floori(float(address.x) / source[0].size())
    if rule == 2 and posmod(tile_column, 2) == 1:
        cell.y = posmod(cell.y + source.size() / 2, source.size())
    return cell

func repaint() -> void:
    for address: Vector2i in grid.cells:
        grid.write(address, palette.colours[value_at(address)])

func cycle_rule() -> void:
    rule = (rule + 1) % RULE_NAMES.size()
    reflected = rule != 0
    repaint()

func operation() -> String:
    var local := to_local(control.global_position)
    if absf(local.x) <= 0.2 and local.y >= 0.95 and local.y <= 1.5 and absf(local.z - 2.5) <= 0.25:
        return "RULE"
    return super.operation()

func choose(held: Variant) -> void:
    if operation() == "RULE":
        cycle_rule()
    elif not operation().is_empty():
        super.choose(held)
    else:
        var address := selected_address()
        if address != Vector2i(-1, -1):
            var cell := super.source_address(address)
            source[cell.y][cell.x] = (source[cell.y][cell.x] + 1) % palette.colours.size()
            repaint()

func _process(delta: float) -> void:
    super._process(delta)
    label.text = RULE_NAMES[rule] + "\n" + label.text.replace("GRIP: inspect / TRIGGER at label: change receiver", "GRIP: select / TRIGGER: paint cell or use named action")
