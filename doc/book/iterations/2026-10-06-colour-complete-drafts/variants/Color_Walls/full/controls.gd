# Supplied desktop test adapter; these methods can also receive museum buttons.
extends Node

func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    if event.keycode == KEY_F:
        get_parent().toggle_filter()
    elif event.keycode == KEY_C:
        get_parent().change_first()
