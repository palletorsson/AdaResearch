# Supplied desktop test adapter. Museum console bindings call the same methods.
extends Node

func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    var study := get_parent()
    match event.keycode:
        KEY_X:
            study.select_address(Vector2i((study.selected.x + 1) % 5, study.selected.y))
        KEY_Z:
            study.select_address(Vector2i(study.selected.x, (study.selected.y + 1) % 5))
        KEY_C:
            study.paint_selected()
        KEY_P:
            study.next_palette()
        KEY_R:
            study.apply_rule()
