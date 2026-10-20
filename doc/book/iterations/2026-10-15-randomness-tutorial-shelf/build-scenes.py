from pathlib import Path

ROOT=Path(__file__).resolve().parents[4]
OUT=ROOT/'doc/book/studies/randomness-shelf'
parts=['''[gd_scene load_steps=14 format=3]

[ext_resource type="Script" path="direct_randomness.gd" id="1"]
[ext_resource type="Script" path="shelf_notebook.gd" id="2"]
[ext_resource type="Script" path="shelf_controls.gd" id="3"]

[sub_resource type="StandardMaterial3D" id="Dark"]
albedo_color = Color(0.11, 0.16, 0.18, 1)
roughness = 0.55
[sub_resource type="StandardMaterial3D" id="Paper"]
albedo_color = Color(0.84, 0.81, 0.72, 1)
roughness = 0.85
[sub_resource type="StandardMaterial3D" id="Colour"]
albedo_color = Color(0.9, 0.3, 0.2, 1)
roughness = 0.4
[sub_resource type="StandardMaterial3D" id="Mark"]
albedo_color = Color(0.95, 0.54, 0.18, 1)
[sub_resource type="SphereMesh" id="Sphere"]
radius = 0.1
height = 0.2
[sub_resource type="BoxMesh" id="Cube"]
size = Vector3(0.22, 0.22, 0.22)
[sub_resource type="BoxMesh" id="Face"]
size = Vector3(0.13, 0.13, 0.005)
[sub_resource type="BoxMesh" id="Rod"]
size = Vector3(0.8, 0.008, 0.008)
[sub_resource type="BoxMesh" id="Board"]
size = Vector3(3.35, 0.06, 0.72)
[sub_resource type="BoxMesh" id="Leg"]
size = Vector3(0.065, 1.16, 0.065)

[node name="RandomnessShelf" type="Node3D"]
script = ExtResource("1")
[node name="Notebook" type="Node" parent="."]
script = ExtResource("2")
[node name="Controls" type="Node3D" parent="."]
script = ExtResource("3")
[node name="Shelf" type="MeshInstance3D" parent="."]
position = Vector3(0, 1.16, 0)
mesh = SubResource("Board")
material_override = SubResource("Paper")
''']
def mesh(name,parent,resource,material,xyz):
    parts.append(f'\n[node name="{name}" type="MeshInstance3D" parent="{parent}"]\nposition = Vector3({xyz})\nmesh = SubResource("{resource}")\nmaterial_override = SubResource("{material}")\n')
def label(name,text,xyz,size=30):
    parts.append(f'\n[node name="{name}" type="Label3D" parent="."]\nposition = Vector3({xyz})\ntext = "{text}"\nfont_size = {size}\npixel_size = 0.002\nmodulate = Color(0.85,0.89,0.87,1)\noutline_size = 3\n')
for i,(name,x) in enumerate([('Move',-1.1),('Scale',-0.2),('Rotate',0.6),('Colour',1.3)]):
    parts.append(f'\n[node name="{name}" type="Node3D" parent="."]\nposition = Vector3({x}, 1.43, 0)\n')
    mesh('Cube' if name=='Rotate' else 'Point',name,'Cube' if name=='Rotate' else 'Sphere','Colour' if name=='Colour' else 'Dark','0, 0, 0')
    label(name+'Label',['POSITION','SCALE','ROTATION','COLOUR'][i],f'{x}, 1.67, 0',30)
mesh('Line','Move','Rod','Mark','0, 0, -0.025')
mesh('Face','Rotate/Cube','Face','Mark','0, 0, 0.114')
for i,x in enumerate([-1.5,1.5]):
    for j,z in enumerate([-.25,.25]):mesh(f'Leg{i}{j}','.','Leg','Dark',f'{x}, 0.58, {z}')
label('Title','ONE NUMBER / FOUR CONSEQUENCES','0, 2.14, 0',40)
label('Readout','Loading...','0, 1.93, 0',31)
label('Status','NEXT reads one stored value. REPLAY returns to the first.','0, 0.71, 0.43',21)
(OUT/'shelf.tscn').write_text(''.join(parts),encoding='utf-8')

(OUT/'preview.tscn').write_text('''[gd_scene load_steps=5 format=3]
[ext_resource type="PackedScene" path="shelf.tscn" id="1"]
[sub_resource type="Environment" id="Environment"]
background_mode = 1
background_color = Color(0.035, 0.055, 0.065, 1)
ambient_light_source = 3
ambient_light_color = Color(0.8, 0.85, 0.9, 1)
ambient_light_energy = 0.75
tonemap_mode = 0
[sub_resource type="PlaneMesh" id="FloorMesh"]
size = Vector2(20,20)
[sub_resource type="StandardMaterial3D" id="FloorMat"]
albedo_color = Color(0.12, 0.16, 0.17, 1)
roughness = 0.9
[node name="ShelfPreview" type="Node3D"]
[node name="Shelf" parent="." instance=ExtResource("1")]
[node name="WorldEnvironment" type="WorldEnvironment" parent="."]
environment = SubResource("Environment")
[node name="Light" type="DirectionalLight3D" parent="."]
rotation_degrees = Vector3(-40,-25,0)
light_energy = 1.1
[node name="Floor" type="MeshInstance3D" parent="."]
mesh = SubResource("FloorMesh")
material_override = SubResource("FloorMat")
[node name="Camera" type="Camera3D" parent="."]
position = Vector3(0,2.5,4.5)
rotation_degrees = Vector3(-16,0,0)
current = true
fov = 43.0
[node name="UI" type="CanvasLayer" parent="."]
[node name="Bar" type="HBoxContainer" parent="UI"]
offset_left = 24.0
offset_top = 24.0
theme_override_constants/separation = 12
'''+''.join(f'''
[node name="{name}" type="Button" parent="UI/Bar"]
custom_minimum_size = Vector2(110,44)
text = "{name.upper()}"
''' for name in ['Next','Replay','Keep','Load'])+'''
[node name="Help" type="Label" parent="UI"]
offset_left = 24.0
offset_top = 80.0
text = "NEXT: one number changes four properties.  REPLAY: read the same eight again."
[connection signal="pressed" from="UI/Bar/Next" to="Shelf" method="next_sample"]
[connection signal="pressed" from="UI/Bar/Replay" to="Shelf" method="replay"]
[connection signal="pressed" from="UI/Bar/Keep" to="Shelf/Notebook" method="save_trial"]
[connection signal="pressed" from="UI/Bar/Load" to="Shelf/Notebook" method="load_trial"]
''',encoding='utf-8')
print('Built shelf and standalone desktop preview scenes.')
