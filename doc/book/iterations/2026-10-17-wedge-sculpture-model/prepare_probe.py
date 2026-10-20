from pathlib import Path
HERE=Path(__file__).parent;ROOT=HERE.parents[3]
source=(HERE.parent/'2026-10-17-wedge-grid-route/probe.gd').read_text(encoding='utf-8')
source=source.replace('if n.scene_file_path.ends_with("/prism_block.tscn"):','if n.scene_file_path.ends_with("/prism_block.tscn") and not n.has_meta("sculpture_piece"):')
extra='''\tvar column:=find_scene("/wedge_column.gd")
\tvar model:=find_scene("/wedge_mouse_model.gd")
\tcheck("sculpture and model on platform",column!=null and model!=null)
\tif column!=null:
\t\tcheck("six original prisms compose sculpture",column.pieces.size()==6)
\t\tcheck("sculpture base rests on platform",absf(column.global_position.y-origin.y-1.0)<0.02)
\t\tfor piece in column.pieces:
\t\t\tcheck("original prism retained "+piece.name,piece.scene_file_path.ends_with("/prism_block.tscn") and piece.get_node("StaticBody3D/CollisionShape3D").shape is ConcavePolygonShape3D)
\t\tawait snapshot("platform-sculpture",column.to_global(Vector3(-2.0,1.7,-3.1)),column.to_global(Vector3(0,0.95,0)),49)
\tif model!=null:
\t\tcheck("model plinth rests on platform",absf(model.global_position.y-origin.y-1.0)<0.02)
\t\tcheck("player steers through returning joystick",model.joystick.get_node("JoystickOrigin/InteractableJoystick").default_on_release)
\t\tcheck("model contains seven movable wedge bodies",model.pieces.size()==7)
\t\tcheck("mouse starts at plinth height",absf(model.mouse.global_position.y-model.global_position.y-model.TOP)<0.03)
\t\tawait snapshot("mouse-model",model.to_global(Vector3(1.6,2.1,-2.0)),model.to_global(Vector3(0,0.9,0)),50)
\t\tawait snapshot("model-controls",model.to_global(Vector3(0,1.25,-2.0)),model.to_global(Vector3(0,0.72,0)),53)
\tawait snapshot("sculpture-and-model",origin+Vector3(9.5,3.5,27.5),origin+Vector3(9.5,1.8,32),74)
'''
source=source.replace('\tawait snapshot("first-central-blockers"',extra+'\tawait snapshot("first-central-blockers"',1)
source=source.replace('WEDGE GRID ROUTE','WEDGE SCULPTURE AND MODEL')
source=source.replace('No wearer or comprehension claim.','Sculture and player-controlled model loaded on platform. No wearer or comprehension claim.')
(HERE/'probe.gd').write_text(source,encoding='utf-8')
