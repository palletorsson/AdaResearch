"""Supply working-copy launches at surveyed positions; no map/artifact replacement."""
from pathlib import Path
import json
from write_foundations_reconstruction import LESSONS
ROOT=Path(__file__).resolve().parents[1]
STUDY=ROOT/'doc/book/studies/foundations-lineage'
TEMPLATE=(ROOT/'doc/book/studies/noneuclid-lineage/museum.gd').read_text(encoding='utf-8').replace('    # The installed NonEuclideanWing now owns the former (13, 1, 7) bay.\n','')

def main():
    for hall,key,*_ in LESSONS:
        receipt=json.loads((ROOT/'ada_run/encounter_pilot'/hall/'foundations_reconstruction/report.json').read_text())
        assert receipt['passed'],hall
        mount=receipt['observations']['mount']
        # Visual inspection: the gate's noncolliding sign obscured a control at x=4.
        if key=='florensky':mount={'position':[9,0,10],'yaw':3.141592653589793}
        code=TEMPLATE.replace('surface_study.gd',key+'_study.gd').replace('NonEuclidean_Spaces',hall).replace('ada_student_noneuclid_control',f'ada_student_{key}_control').replace('Surface lesson',key.capitalize()+' lesson').replace('StudentSurfaceStudy','Student'+key.capitalize()+'Study')
        if key in ['godel','synthesis']:
            code=code.replace('static func mount(hall: Node3D, lesson: Script)', 'static func mount(hall: Node3D, lesson: Script, setup: Dictionary = {})')
            code=code.replace('    var study = lesson.new()','    var study = lesson.new()\n    for property in setup: study.set(property, setup[property])')
        lines=code.splitlines()
        for i,line in enumerate(lines):
            if 'study.position = Vector3' in line:
                lines[i]='    study.position = Vector3('+', '.join(str(x) for x in mount['position'])+')\n    study.rotation.y = '+str(mount['yaw'])
        (STUDY/(key+'_museum.gd')).write_text('\n'.join(lines)+'\n',encoding='utf-8')
        (STUDY/(key+'.tscn')).write_text(f'''[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="{key}_museum.gd" id="1"]

[node name="{key.capitalize()}InTheMuseum" type="Node3D"]
script = ExtResource("1")
''',encoding='utf-8')
    print('Six museum launchers supplied')

if __name__=='__main__':main()
