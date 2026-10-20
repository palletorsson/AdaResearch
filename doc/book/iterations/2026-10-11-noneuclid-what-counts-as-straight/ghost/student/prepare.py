from pathlib import Path
import re, hashlib, json, math, datetime

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[5]
PACKET = HERE.parent / 'input'
raw = (PACKET / 'tutorial.md').read_bytes()
blocks = re.findall(rb'<!-- student-code:([^ >]+) -->\r?\n```gdscript\r?\n(.*?)```', raw, re.S)
assert len(blocks) == 5
for filename, code in blocks:
    target = HERE / filename.decode('ascii')
    if target.exists():
        raise RuntimeError(f'Refuse overwrite: {target}')
    target.write_bytes(code)

scene = '''[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="surface_study.gd" id="1"]

[node name="SurfaceStudy" type="Node3D"]
script = ExtResource("1")
'''
(HERE / 'reconstructed.tscn').write_text(scene, encoding='utf-8', newline='\n')

def sphere_angles(points):
    # Independent oracle: spherical cosine law using three central arc lengths.
    vertices = [(x / math.sqrt(1+x*x+z*z), 1 / math.sqrt(1+x*x+z*z), z / math.sqrt(1+x*x+z*z)) for x,z in points]
    dot = lambda a,b: sum(x*y for x,y in zip(a,b))
    arcs = [math.acos(dot(vertices[(i+1)%3],vertices[(i+2)%3])) for i in range(3)]
    out = []
    for i in range(3):
        a,b,c = arcs[i],arcs[(i+1)%3],arcs[(i+2)%3]
        out.append(math.degrees(math.acos((math.cos(a)-math.cos(b)*math.cos(c))/(math.sin(b)*math.sin(c)))))
    return dict(angles=out, sum=sum(out), central_arc_lengths=arcs)

predictions = {
    'created_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
    'engine_has_not_run': True,
    'oracle_method': 'Python double precision spherical cosine law, independent of printed tangent method',
    'reference': sphere_angles([(0,0),(1,0),(0,1)]),
    'variation_half_chart': sphere_angles([(0,0),(.5,0),(0,.5)]),
    'default': sphere_angles([(-.7,.4),(.7,.4),(0,-.6)]),
    'numerical': [
        'Reference plane angles [90,45,45], sum 180; spherical sum 199.47122063449; allow .001 degree error.',
        'Independent chart contraction: replace every reference pair by half its value. Plane angles stay [90,45,45] and AB length halves from 1 to .5. Sphere angles become [90,48.1896851042,48.1896851042], sum 186.3793702083; spherical excess shrinks, and arc lengths do not halve exactly.',
        'Spherical sample endpoints equal mapped corners; all 75 edge samples have unit radius and lie in each endpoint great-circle plane. Tangents are unit and perpendicular to corner normal.',
        'Increasing pieces from 1 to 96 preserves analytic angle sum and endpoints, while summed chord length approaches central arc length from below.',
        'North pole plus orthogonal equator directions have three right tangent angles; these inputs do not pass through the hand chart.',
        'Coincident, collinear and relative-near-collinear inputs refuse measurement in both modes; separated points recover.',
        'pieces <= 0 is clamped to one segment; zero-length LineSkin hides and then recovers when length becomes positive.'
    ],
    'behavioral': [
        'Minimal attached host initializes three frozen point bodies, 72 cylinder edges, three corner labels, readout, plane, sphere, face and all three supplied buttons.',
        'Translation (2.3,-.4,1.7) and rotation (.23,.61,-.17) radians with unit scale preserve local geometry and use to_global/to_local correctly.',
        'Synthetic XRToolsPointerEvent report -> supplied pointer method -> area enter -> area button_pressed -> push_button pressed -> host callback changes mode, with actual button pressed/released state transitions.',
        'Mode changes preserve coordinate pairs and point instance IDs; plane return restores measurements. Reset restores defaults while keeping selected mode.',
        'Synthetic desktop callbacks plus a continuous frame driver keep a point held and off surface over multiple physics frames, while the model records local chart coordinates.',
        'During hold, button mode changes and reset are refused; valid keyboard P/S/R also act only after release.',
        'Spherical inverse of centre + (0.24,0.4,-0.12) records (.6,-.3); centre + (2,.5,-3) clamps to (1,-1).',
        'Spherical hand y <= centre.y + .02 is refused, retains last record, and displays refusal; valid motion clears refusal. Exact guard tested without world conversion; transformed boundary uses .019 and .021 to avoid floating transform ambiguity.',
        'On drop, each of six later physics observations agrees with the recorded surface position; plane release restores y=1.12.',
        'Live collinear/coincident records remove plane face and angle labels; separation recovers face/readout. Spherical mode has no flat triangle face.'
    ],
    'limits': ['Experienced AI reconstructing printed code, not a novice learner.', 'Headless engine evidence; synthetic pointer event source and synthetic sustained desktop hand driver; no physical pointing, ray-hit testing, mouse use, headset input, screenshots, or museum behavior tested.', 'No canonical source, author tests, author expected results, reports, prior assessments, chat, handoff, or museum probe read.']
}
(HERE/'predictions.json').write_text(json.dumps(predictions,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
print(json.dumps(predictions,indent=2))
