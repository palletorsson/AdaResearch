from pathlib import Path
ROOT = Path(__file__).resolve().parents[4]
for mode in ('smooth','snap','zero'):
    path = ROOT/f'commons/interactables/joystick_{mode}.tscn'
    s = path.read_text(encoding='utf-8')
    s = s.replace('load_steps=18','load_steps=20')
    s = s.replace('res://addons/godot-xr-tools/interactables/interactable_joystick.gd','res://commons/interactables/joystick_driver.gd')
    s = s.replace('res://addons/godot-xr-tools/interactables/interactable_handle.gd','res://commons/interactables/joystick_handle.gd')
    marker = '[sub_resource type="BoxShape3D" id="1"]'
    s = s.replace(marker,'[ext_resource type="Script" path="res://commons/interactables/physical_joystick.gd" id="Root"]\n[ext_resource type="Script" path="res://commons/interactables/joystick_pointer_body.gd" id="Pointer"]\n\n'+marker)
    s = s.replace('size = Vector3(0.16, 0.16, 0.02)','size = Vector3(0.20, 0.26, 0.026)')
    s = s.replace('margin = 0.12\nradius = 0.04','margin = 0.002\nradius = 0.035')
    name = {'smooth':'JoystickSmooth','snap':'JoystickSnap','zero':'JoystickZero'}[mode]
    s = s.replace(f'[node name="{name}" type="Node3D"]',f'[node name="{name}" type="Node3D"]\nscript = ExtResource("Root")')
    s = s.replace('[node name="Frame" type="StaticBody3D" parent="."]','[node name="Frame" type="StaticBody3D" parent="."]\nposition = Vector3(0, -0.025, -0.005)\nscript = ExtResource("Pointer")')
    marker = '[node name="JoystickBody" type="StaticBody3D" parent="JoystickOrigin/InteractableJoystick"]'
    s = s.replace(marker,marker+'\nscript = ExtResource("Pointer")\ncontrol_path = NodePath("../../..")')
    for part in ('BarCollision','BarMesh'):
        typ = 'CollisionShape3D' if part=='BarCollision' else 'MeshInstance3D'
        marker = f'[node name="{part}" type="{typ}" parent="JoystickOrigin/InteractableJoystick/JoystickBody"]'
        s = s.replace(marker,marker+'\nrotation_degrees = Vector3(90, 0, 0)')
    if mode=='smooth':
        s = s.replace('transform = Transform3D(1, 0, 0, 0, 0, -1, 0, 1, 0, 0, 0, 0.05)\n','')
        marker = '[node name="HandleMesh" type="MeshInstance3D" parent="JoystickOrigin/InteractableJoystick/JoystickBody"]\ntransform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0.1)'
        s = s.replace(marker,marker.replace('0, 0, 0.1)','0, 0, 0.05)'))
        snap = (ROOT/'doc/reports/interfaces-2026-09-21/joystick-console/before/joystick_snap.tscn.txt').read_text(encoding='utf-8')
        points = snap[snap.index('[node name="GrabPointHandLeft"'):snap.index('[node name="HandleOrigin"')]
        s = s.replace('[node name="HandleOrigin"',points+'[node name="HandleOrigin"',1)
    if mode=='zero':
        s = s.replace('default_position = Vector2(0.5, 0.5)','default_on_release = true\ndefault_x_position = 0.0\ndefault_y_position = 0.0')
    path.write_text(s,encoding='utf-8')
path = ROOT/'commons/interactables/InteractableDemo.gd'
s = path.read_text(encoding='utf-8')
s = s.replace('@export var release_reference: bool = false','@export var release_reference: bool = false\n## Physical XY: continuous, detented and returning.\n@export var joystick_reference: bool = false')
s = s.replace('\tif release_reference:', '\tif joystick_reference:\n\t\tvar reference := preload("res://commons/ui/interface_joystick_reference.gd").new()\n\t\treference.name = "JoystickReference"\n\t\tadd_child(reference)\n\t\treturn\n\tif release_reference:',1)
s = s.replace('if "joystick" in scene_path:\n\t\treturn Vector2(0.12, 0.14)','if "joystick" in scene_path:\n\t\treturn Vector2(0.20, 0.26)')
path.write_text(s,encoding='utf-8')
