"""Materials: carry the receiver and point; teach height versus normal data."""
from pathlib import Path
import hashlib,json,re,shutil
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-10-materials-light-without-height'
MAP=ROOT/'commons/maps/Shader_11_QueerRubber'
PRIOR=ROOT/'doc/book/iterations/2026-10-10-patterns-the-same-circle/learner/printed'
OUT.mkdir(parents=True,exist_ok=True);(OUT/'before').mkdir(exist_ok=True)
for name in ['final.md','map_data.json']:
    if (MAP/name).exists() and not (OUT/'before'/name).exists():shutil.copy2(MAP/name,OUT/'before'/name)
edits={
'point_body.gd':[
 ('const RADIUS := 0.14','const RADIUS := 0.14\nvar surface := MeshInstance3D.new()'),
 ('    var surface := MeshInstance3D.new()\n',''),
 ('    add_child(boundary)','    add_child(boundary)\n\nfunc coat(material: Material) -> void:\n    surface.material_override = material')],
'shaping.gd':[
 ('const Circle = preload("circle.gdshader")','const Relief = preload("relief.gdshader")\nconst Maps = preload("relief_maps.gd")'),
 ('var radius := 0.30\nvar shift := 0.0\nvar soft := false','var strength := 0.6\nvar roughness := 0.35\nvar mode := 0\nvar maps: Dictionary'),
 ('    material.shader = Circle','    material.shader = Relief\n    maps = Maps.build()\n    material.set_shader_parameter("height_map", maps.height)\n    material.set_shader_parameter("normal_map", maps.normal)\n    material.set_shader_parameter("texel", Vector2.ONE / Maps.SIDE)\n    material.set_shader_parameter("height_gain", Maps.GAIN)'),
 ('    control.action_pressed.connect(toggle_edge)','    control.coat(material)\n    control.action_pressed.connect(next_mode)\n    var lamp := OmniLight3D.new()\n    lamp.position = Vector3(-1.3, 2.4, 1.8)\n    lamp.omni_range = 4.0\n    lamp.light_energy = 5.0\n    lamp.shadow_enabled = true\n    add_child(lamp)'),
 ('func toggle_edge(_point) -> void:\n    soft = not soft\n    update_rule()','func next_mode(_point) -> void:\n    mode = (mode + 1) % 3\n    update_rule()'),
 ('''    var height := local_point.y
    shift = local_point.x - 0.65
    radius = clampf(0.30 + (height - 1.2) * 0.38, 0.08, 0.46)
    material.set_shader_parameter("radius", radius)
    material.set_shader_parameter("shift", shift)
    material.set_shader_parameter("softness", 0.045 if soft else 0.0)
    readout.text = "Raise: radius %.2f | Sideways: shift %.2f\\nTrigger: %s edge" % [
        radius, shift, "soft" if soft else "hard"
    ]''','''    strength = clampf(0.6 + (local_point.y - 1.2) * 2.0, 0.0, 1.0)
    roughness = clampf(0.35 + (local_point.x - 0.65) * 0.5, 0.05, 0.95)
    material.set_shader_parameter("strength", strength)
    material.set_shader_parameter("roughness", roughness)
    material.set_shader_parameter("mode", mode)
    readout.text = "%s | Raise: relief %.2f | Sideways: roughness %.2f\\nTrigger: next reading" % [
        ["FLAT", "HEIGHT MAP", "NORMAL MAP"][mode], strength, roughness
    ]''')]
}
blocks={};incoming={}
for name,changes in edits.items():
    p=PRIOR/name;incoming[name]={'path':p.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
    code=p.read_text(encoding='utf-8').rstrip()
    for old,new in changes:
        assert code.count(old)==1,(name,old);code=code.replace(old,new)
    blocks[name]=code
blocks['relief_maps.gd']='''extends RefCounted

const SIDE := 256
const GAIN := 0.03
const REPEATS := Vector2(3, 3)

static func build() -> Dictionary:
    var height := Image.create(SIDE, SIDE, false, Image.FORMAT_RF)
    for y in SIDE:
        for x in SIDE:
            var uv := Vector2(x + 0.5, y + 0.5) / SIDE
            var address := uv * REPEATS
            var tile := address - address.floor()
            var distance := tile.distance_to(Vector2(0.5, 0.5))
            var value := 1.0 - smoothstep(0.22, 0.38, distance)
            height.set_pixel(x, y, Color(value, 0, 0))

    var normal := Image.create(SIDE, SIDE, false, Image.FORMAT_RGB8)
    var step := 1.0 / SIDE
    for y in SIDE:
        for x in SIDE:
            var left := height.get_pixel(posmod(x - 1, SIDE), y).r
            var right := height.get_pixel((x + 1) % SIDE, y).r
            var above := height.get_pixel(x, posmod(y - 1, SIDE)).r
            var below := height.get_pixel(x, (y + 1) % SIDE).r
            var du := (right - left) / (2.0 * step)
            var dv := (below - above) / (2.0 * step)
            var direction := Vector3(-du * GAIN, dv * GAIN, 1).normalized()
            var encoded := direction * 0.5 + Vector3.ONE * 0.5
            normal.set_pixel(x, y, Color(encoded.x, encoded.y, encoded.z))
    return {
        "height": ImageTexture.create_from_image(height),
        "normal": ImageTexture.create_from_image(normal)
    }
'''.rstrip()
blocks['relief.gdshader']='''shader_type spatial;
render_mode cull_disabled;

uniform sampler2D height_map : repeat_enable, filter_linear;
uniform sampler2D normal_map : hint_normal, repeat_enable, filter_linear;
uniform vec2 texel = vec2(0.00390625);
uniform float height_gain = 0.03;
uniform float strength = 0.6;
uniform float roughness = 0.35;
uniform int mode = 0;
uniform vec4 colour : source_color = vec4(0.42, 0.18, 0.10, 1.0);

void fragment() {
    vec3 encoded = vec3(0.5, 0.5, 1.0);
    if (mode == 1) {
        float left = texture(height_map, UV - vec2(texel.x, 0.0)).r;
        float right = texture(height_map, UV + vec2(texel.x, 0.0)).r;
        float above = texture(height_map, UV - vec2(0.0, texel.y)).r;
        float below = texture(height_map, UV + vec2(0.0, texel.y)).r;
        float du = (right - left) / (2.0 * texel.x);
        float dv = (below - above) / (2.0 * texel.y);
        vec3 direction = normalize(vec3(-du * height_gain, dv * height_gain, 1.0));
        encoded = direction * 0.5 + 0.5;
    } else if (mode == 2) {
        encoded = texture(normal_map, UV).rgb;
    }
    NORMAL_MAP = encoded;
    NORMAL_MAP_DEPTH = strength;
    ALBEDO = colour.rgb;
    ROUGHNESS = roughness;
}
'''.rstrip()
chain={'incoming':incoming,'edits':edits,'replaced_shader':{'path':(PRIOR/'circle.gdshader').relative_to(ROOT).as_posix(),'sha256':hashlib.sha256((PRIOR/'circle.gdshader').read_bytes()).hexdigest()},'new_files':['relief.gdshader','relief_maps.gd']}
(OUT/'continuation.json').write_text(json.dumps(chain,indent=2)+'\n',encoding='utf-8')
def listing(name,lang):return f'<!-- student-code:{name} -->\n```{lang}\n{blocks[name]}\n```'
t='''# Materials — light without height

## Learning elements

- A lit material: base colour and roughness.
- Surface normals and the tangent frame.
- A height map stores values; neighbouring values give slopes.
- A normal map stores encoded directions.
- Change shading while retaining the mesh, silhouette and collision.

In the furnished room, choose STUDY. Move ROUGH and walk around the sphere and cube. The highlight changes, but the bodies keep their shapes. RIM adds another response, tied to the eye. The sofa, chair and vase show how the same material reads on different forms.

Our reconstruction asks a smaller question: can the circle from Patterns appear raised without raising any geometry? Keep the flat square as a witness. The same material will also cover the cube's front square and the point you hold.

## What we carry and what changes

Keep Patterns' `shaping.gd` and `point_body.gd`: the two receivers, cube, collider construction, shared material, local coordinates and hand action remain. The new `coat()` method gives the point's existing surface a material; it creates no replacement sphere. The `circle.gdshader` file is replaced by `relief.gdshader`. Add `relief_maps.gd` to make the data it reads. All four resulting files are printed below.

Hold the pattern fixed at three repeats, radius 0.30 and a gradual edge from 0.22 to 0.38. Its values now become height data. We also make a normal map from those values. The two maps are prepared once, not rebuilt each frame.

For this comparison, the hand controls change jobs. Trigger cycles **FLAT → HEIGHT MAP → NORMAL MAP**. Height controls the strength of the shading relief; sideways movement controls roughness. Neither gesture moves the surface's vertices. We add one fixed local lamp, printed in the host, to make the relief readable alongside the museum lighting.

Open `res://doc/book/studies/shaders-lineage/Materials.tscn` and Run Current Scene in the existing AdaResearch project. The supplied launcher adds the study to the furnished Materials hall. It points to the four sibling files in `res://doc/book/iterations/2026-10-10-materials-light-without-height/learner/printed/`. Edit those files, or change the launcher's `LESSON` preload to your saved `shaping.gd`. The museum supplies its player, camera, floor and bundled XR Tools. Every lesson-owned mesh, collider, label and lamp comes from the printed code.

## relief_maps.gd — prepare two readings

'''+listing('relief_maps.gd','gdscript')+'''

The first loop samples our repeated circle into a 256 × 256 image. It is the same multiply–fold–distance operation from Patterns. Red stores one floating-point value per sample; the other channels are unused. No metres have moved. `GAIN` chooses how strongly a slope in these normalized UV coordinates tilts the shading normal.

The second loop looks one texel left, right, above and below. Subtract opposite heights and divide by their two-texel separation: an estimate of the slope along each axis. `posmod` wraps a negative neighbour to the last column or row. The opposite edge supplies the other neighbour, matching the repeated texture.

A normal is a direction perpendicular to the surface. For a level patch its local direction is `(0, 0, 1)`. Where height rises toward the right, the normal leans left. Image rows increase downward, so this map uses `(-du, +dv, 1)` before normalization: the positive green axis points up the texture, as in Godot's OpenGL-style normal convention. The mesh supplies the tangent frame that turns those local directions into directions on the body. Our QuadMesh and SphereMesh supply UVs and tangents; arbitrary imported meshes need those too.

The RGB map encodes a direction from −1…1 into 0…1 by multiplying by 0.5 and adding 0.5. A flat direction becomes `(0.5, 0.5, 1)`, the familiar pale blue. Godot uses the red and green components and reconstructs the positive third component. RGB8 rounds these values; the encoded map is an approximation of the original slopes. The height image retains floating-point samples. Both textures are data, not display colours.

## relief.gdshader — choose what the surface reads

'''+listing('relief.gdshader','glsl')+'''

FLAT supplies the unperturbed tangent-space direction. HEIGHT MAP reads four heights and calculates the direction at each fragment. This is bump mapping from a height field. NORMAL MAP instead reads the direction prepared by the second loop. It saves those slope calculations at runtime, but that alone is not a measured performance result.

`texture` samples an image at UV coordinates. `texel` is the spacing of adjacent samples. Linear filtering blends nearby samples; repeat wrapping joins opposite image edges. The normal sampler has `hint_normal`, not `source_color`: its RGB numbers encode directions. `NORMAL_MAP` accepts that encoded tangent-space direction; `NORMAL_MAP_DEPTH` controls its influence. At zero strength both methods return to the mesh normal. At intermediate strengths this is a shading control, not a height in metres.

There is no `unshaded` flag now: lamps can affect the result. ALBEDO keeps one base colour, so the changing light response is visible. ROUGHNESS changes the spread of the specular highlight; it does not change friction or create microscopic geometry. No `vertex()` stage or collision update is present.

## shaping.gd — continue the same study

'''+listing('shaping.gd','gdscript')+'''

`maps.height` and `maps.normal` are the two textures created by the helper. The host connects them to the shader uniforms. It also passes their texel spacing and slope gain. `coat(material)` puts that same material on the held point, while the two square receivers retain their earlier connection.

The point starts at local `(0.65, 1.2, 1.2)`: strength 0.6, roughness 0.35. Raising it 0.2 metres reaches full strength; lowering it 0.3 metres reaches zero. Horizontal movement changes roughness within 0.05–0.95. The label declares the current reading. Mode cycling uses the remainder after division by three, returning to FLAT after NORMAL MAP.

## point_body.gd — expose the existing surface

'''+listing('point_body.gd','gdscript')+'''

The mesh reference now lives on the class so `coat()` can reach it. Its radius, collision, pickup and frozen release behaviour are the ones already earned. The point's surface can answer to light while the same body answers to your hand.

## Predict, change, explain

Start at FLAT. Pick up the point and press the trigger for HEIGHT MAP. Watch the circle edges catch the fixed lamp. Change to NORMAL MAP without moving your hand. The relief should remain close, with small differences from interpolation and RGB8 rounding. Return to FLAT. The square's outer edge and the sphere's outline have not grown bumps.

Lower the point to local Y = 0.9. Both relief modes now return to the flat shading. Raise it to Y = 1.4. Keep that height while moving sideways: roughness changes, not the slope data. Look at a grazing angle; the apparent raised circles still stop at an unchanged edge. You cannot catch a hand on one.

For an independent variation, change `REPEATS` in `relief_maps.gd` from `(3, 3)` to `(4, 2)` and rerun. Both maps are rebuilt from that one edit. Predict the count, aspect and slope changes before comparing the two modes. Four repeats compress the horizontal change into less UV space, so its slope also becomes steeper at the same gain. This exact variation is tested. Then choose another count or gain and explain what remains fixed.

The maps use normalized UV units. The same pattern therefore has different physical sizes on the large square, small square and sphere; it is not a calibrated common bump height in metres. On the sphere, UVs compress near the poles. Use the flat receiver to judge the method before interpreting the curved one.

## Back among the furniture

The installed rim study asks about surface direction and viewing direction. Its emission follows the eye; our normal maps alter how a lit surface is read. Return to STUDY and walk between the sphere and cube. Plastic, velvet and oil are named surface recipes here; the names do not establish fibres, liquid or a changed collision body.

Carry the distinction into Water: a surface may look raised because its shading normals changed, or its vertices may actually move. The next lesson makes that second operation visible and keeps its physical support separate.

References: Godot's [spatial shader interface](https://docs.godotengine.org/en/4.6/tutorials/shaders/shader_reference/spatial_shader.html) defines NORMAL_MAP and NORMAL_MAP_DEPTH; its [normal-map documentation](https://docs.godotengine.org/en/4.6/tutorials/3d/standard_material_3d.html#normal-map) describes the OpenGL convention and tangent-space use. The example above constructs its own data from the preceding circle rule.
'''
(MAP/'tutorial.md').write_text(t,encoding='utf-8')
r=(OUT/'before/final.md').read_text(encoding='utf-8')
a=r.index('The crossing leaves');b=r.index('<!-- @shader_11_queerrubber -->')
r=r[:a]+'''The room offers a sofa, a chair, a vase, a sphere and a cube. One recipe covers them all. Choose STUDY; turn ROUGH; walk around the bodies. The highlight spreads or tightens, but the sofa does not soften beneath that name. The same material has different things to say on a curved surface and a flat face.

In the tutorial study, the circle acquires apparent relief. Change from the flat reading to the height map, then to the normal map. The lamp finds slopes where the mesh has none. Look along the square's edge: it has not lifted. The hand and the eye receive different accounts of the same body. Neither account needs to be mistaken; they are being answered by different parts of the construction.

Beside this furnished room, eight piers retain a lane for the earlier collection.[^piers] Five bodies stand on low round stages, turning under three coloured lamps, with a name at each foot and pink text above.[^stage] Leave the controls and walk around them.

'''+r[b:]
r=re.sub(r'```glsl\n.*?```\n\n','',r,flags=re.S)
r=r.replace("Here is the second, from the ring's own code:","The ring compares its surface direction with the direction toward the eye.")
r=r.replace('The last line is the one to hold on to. The rainbow is written into EMISSION:','The rainbow is written into emission:')
r=r.replace('Its cyan edge is the rim you saw on the ring, cubed:','Its cyan edge concentrates the same response near the rim.')
r=r.replace('Now the lamps. Pink on the left,','Now the old collection\'s three lamps. Pink on the left,')
r=r.replace('The lamps here light everything they reach and are blocked by nothing,','Those three lamps light the surfaces they reach without consulting shadow occlusion,')
r=r.replace('To the clock: everything turns,','To the clock: these five specimens turn,')
r=r.replace('The columns stand through all this, the museum\'s own furniture on a four-metre beat, and the coloured light lands on them too. They are the one thing in the hall that answers to nothing. A column is placed, and stays.','The columns stand through all this, and the coloured light lands on them too. Their placement stays fixed; their appearance still answers to the light. Staying in place is not the same as remaining unaffected.')
r=r.replace("and the hall's script contains no", "and the five-body collection script contains no")
r=r.replace('The next hall has water in it. Take the ring\'s rainbow with you, and the question of what it would take for a surface to notice that you are standing in front of a lamp.','The next hall has water in it. Take the apparent relief with you. There, the surface will also move its vertices. What the eye calls a rise will need another account, and what supports your feet will remain another question.')
a=r.index('[^piers]:');b=r.index('\n\n[^stage]:',a)
r=r[:a]+'''[^piers]: The current map is 34 × 18 cells, with the eight piers retained from the earlier colonnade and a furnished side bay. The old 14 × 14 description belongs to the previous layout.'''+r[b:]
r=r.replace('Every rim in this hall is written to EMISSION.','The rims discussed in the five-body collection and the furnished STUDY use EMISSION. The learner relief shader adds no emission.')
r=r.replace('Their product is large', 'Their dot product is large')
r=r.replace('The pink highlight from the lamp on the left does not come with you; it stays on the side that faces the lamp.', 'The pink reflection also changes as you move, but it depends on the lamp as well as the eye. It cannot follow the whole rim in the same way.')
r=r.replace('To the lamps: their direction, colour and distance, and no more.', 'To those three lamps: their direction, colour and distance, without their shadows.')
(MAP/'final.md').write_text(r,encoding='utf-8')
(OUT/'BRIEF.md').write_text('''# Materials reconstruction contract

MAKE: same point/cube/squares; compare flat, height-derived normals, encoded normal map under light.
BRING: Patterns host/PointBody, circle field, arrays/images, local frame and named uniforms.
GIVEN: prepared museum/player/XR Tools; source-visible mount. Printed host adds its own fixed lamp.
BUILD: prepare height + direction textures once; four-sample central slopes; encode tangent-space direction; NORMAL_MAP + depth; point coat method. Y → strength, X → roughness, trigger → three readings. Pattern held fixed until exercise.
CHECK: height data, normal directions, GPU relief and parity, zero strength, changed lamp, unchanged silhouette/mesh/collider, local frame; 4×2 variant; missing normal output, missing sampler, wrong slope sign must fail.
LATER: vertex displacement and geometry subdivision in Water. No fibre/fluid/friction simulation or metre-calibrated relief claim.

Four complete files visible. Anchored predecessor edits + new files; teacher-authored tests are not a human-learning result. Existing installation preserved; learner launcher adds this working study inside it.
''',encoding='utf-8')
print('Materials manuscripts and continuation written.')
