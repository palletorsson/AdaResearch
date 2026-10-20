"""Supply small pointer consoles; keep the reviewed colour operations unchanged."""
from prepare import HERE, HALLS, put
import re

BASE='''# Supplied museum pointer targets and Day Zero preview keys.
extends Node3D

class Target extends StaticBody3D:
    var action: Callable
    func pointer_event(event) -> void:
        # XRToolsPointerEvent.PRESSED; release and movement do not activate.
        if event.event_type == 2:
            action.call()

var buttons: Array[StaticBody3D] = []

func add_target(title: String, at: Vector3, width: float, action: Callable) -> void:
    var target := Target.new()
    target.position = at
    target.collision_layer = 1
    target.collision_mask = 0
    target.action = action
    add_child(target)
    buttons.append(target)
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(width, 0.12, 0.05)
    mesh.mesh = box
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.08, 0.08, 0.08)
    mesh.material_override = material
    target.add_child(mesh)
    var boundary := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = box.size
    boundary.shape = shape
    target.add_child(boundary)
    var label := Label3D.new()
    label.text = title
    label.font_size = 24
    label.pixel_size = 0.0015
    label.position.z = 0.03
    target.add_child(label)
'''

GRID='''
func _ready() -> void:
    var titles := ["X+", "Z+", "COLOUR", "PALETTE", "RULE"]
    for i in titles.size():
        add_target(titles[i], Vector3(i * 0.32, 0.16, 1.8), 0.29, activate.bind(i))

func activate(command: int) -> void:
    var study := get_parent()
    match command:
        0: study.select_address(Vector2i((study.selected.x + 1) % 5, study.selected.y))
        1: study.select_address(Vector2i(study.selected.x, (study.selected.y + 1) % 5))
        2: study.paint_selected()
        3: study.next_palette()
        4: study.apply_rule()

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        var command := [KEY_X, KEY_Z, KEY_C, KEY_P, KEY_R].find(event.keycode)
        if command >= 0:
            activate(command)
'''
WALLS='''
func _ready() -> void:
    add_target("FILTER / OPAQUE", Vector3(-0.45, 1.1, 1.6), 0.85, activate.bind(0))
    add_target("COLOUR", Vector3(0.45, 1.1, 1.6), 0.65, activate.bind(1))

func activate(command: int) -> void:
    if command == 0:
        get_parent().toggle_filter()
    elif command == 1:
        get_parent().change_first()

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_F:
            activate(0)
        elif event.keycode == KEY_C:
            activate(1)
'''

def main():
    for hall,tail in [('Color_Grid_Pallet',GRID),('Color_Walls',WALLS)]:
        put(HERE/hall/'controls.gd',BASE+tail)
    p=HERE/'Color_Grid_Pallet/grid_surface.gd'
    put(p,p.read_text().replace('X / Z: select   C: colour   P: palette   R: rule','X+ / Z+: select   COLOUR: leave a colour'))
    for hall in HALLS:
        path=HERE/hall/'tutorial.md'
        t=path.read_text(encoding='utf-8')
        def block(m):
            name=m.group(1)
            return '<!-- student-code:'+name+' -->\n```gdscript\n'+(HERE/hall/name).read_text(encoding='utf-8').rstrip()+'\n```'
        t=re.sub(r'<!-- student-code:([^>]+) -->\s*```gdscript\n.*?^```',block,t,flags=re.M|re.S)
        put(path,t)
    print('Pointer consoles supplied; printed support and source files agree.')

if __name__=='__main__': main()
