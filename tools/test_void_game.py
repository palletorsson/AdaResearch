"""Native Godot physics, XRTools synthetic-controller and package regression.

Uses real sources in an isolated project; --reuse refreshes a previous stage.
No physical headset is emulated: tracking/controller state is supplied to the
real XRServer, XRController3D and XRTools movement/body implementations.
"""
from pathlib import Path
import configparser
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-18-the-void-playable'
OUT = Path(next((arg.split('=', 1)[1] for arg in sys.argv if arg.startswith('--out=')), str(OUT))).resolve()
WORK = ROOT / 'ada_run/void-game-test'
GODOT = os.environ.get('GODOT_EXE', 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe')
OUT.mkdir(parents=True, exist_ok=True)
WORK.mkdir(parents=True, exist_ok=True)
(WORK / '.gdignore').touch()
sys.stdout.reconfigure(encoding='utf-8')
if '--reuse' in sys.argv and (WORK / 'latest.txt').exists():
    stage = Path((WORK / 'latest.txt').read_text())
else:
    stage = Path(tempfile.mkdtemp(prefix='run-', dir=WORK))
    (WORK / 'latest.txt').write_text(str(stage))
project = stage / 'source'
runtime = stage / 'runtime'
project.mkdir(exist_ok=True)
runtime.mkdir(exist_ok=True)

def copy(relative):
    target = project / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(ROOT / relative, target)

xr_root = ROOT / 'addons/godot-xr-tools'
xr_scenes = {'staging/scene_base.tscn', 'player/player_body.tscn', 'objects/hand_pose_area.tscn', 'objects/pickable.tscn', 'objects/highlight/highlight_ring.tscn', 'effects/fade.tscn'}
for path in xr_root.rglob('*'):
    if not path.is_file() or path.suffix == '.import' or '.git' in path.parts:
        continue
    if path.suffix == '.tscn' and path.relative_to(xr_root).as_posix() not in xr_scenes:
        continue
    copy(path.relative_to(ROOT))
sources = [p.relative_to(ROOT) for p in (ROOT / 'commons/void').glob('*')
           if p.suffix in {'.gd', '.tscn', '.json', '.gdshader'}]
# Sound paths are manifest data rather than script preloads; stage them too.
sources += [p.relative_to(ROOT) for p in (ROOT / 'commons/void/audio').rglob('*')
            if p.suffix in {'.wav', '.ogg', '.mp3'}]
sources += [Path('commons/hazards/biome_ladder/route.gd'), Path('tools/probes/void_game_probe.gd'), Path('tools/probes/void_layout_probe.gd')]
sources += [Path(p) for p in [
    'commons/primitives/origin/origin.tscn', 'commons/primitives/origin/origin.gd',
    'commons/primitives/line/cube_lines.tscn', 'commons/primitives/line/cube_lines.gd',
    'commons/primitives/line/line_static.tscn', 'commons/primitives/line/line_static.gd',
    'commons/primitives/you_are_here/you_are_here.tscn', 'commons/primitives/you_are_here/you_are_here.gd',
    'commons/visualaid/frame_counter/frame_counter_display.tscn', 'commons/visualaid/frame_counter/frame_counter_display.gd',
    'commons/hazards/becoming_catalyst/catalyst_projectile.gd',
    'commons/hazards/becoming_catalyst/catalyst_impact_kit.gd',
    'commons/interactables/artifact_reactions/router.gd',
    'commons/primitives/point/point_condition.gd',
    'commons/primitives/point/point_absent.tscn', 'commons/primitives/point/point_visible.tscn',
    'commons/primitives/point/point_solid.tscn', 'commons/primitives/point/point_pedestal.tscn',
    'commons/primitives/point/interactive_point_origin.tscn', 'commons/primitives/point/interactive_point_origin.gd',
    'commons/primitives/point/point_held.tscn', 'commons/primitives/point/point_held.gd',
    'algorithms/vectors/00_coordinates/CoordinateSystem3M.tscn', 'algorithms/vectors/00_coordinates/CoordinateSystem3M.gd',
    'algorithms/vectors/shared/gadgets/gyroscope_gadget.gd', 'algorithms/vectors/shared/gadgets/gadget_base.gd', 'commons/primitives/line/coordinate_line.gd',
    'commons/primitives/point/coordinate_readout.tscn', 'commons/primitives/point/coordinate_readout.gd',
    'commons/primitives/point/point_mesh.gd', 'commons/render/pbr_kit.gd',
]]
# Follow actual resource references of the curated artifacts, including helpers.
# No production artifact may be replaced with a test stub.
sources += [Path('commons/grid/tag_system.gd'),Path('commons/globals/trace_data.gd'),Path('commons/primitives/line/grid_lines.gd'),Path('tools/probes/void_trace_probe.gd')]
sources += [Path('commons/primitives/shared/grid_material_factory.gd'), Path('commons/primitives/point/xyz_slider_plate.gd')]
sources += [Path('tools/probes/void_avatar_probe.gd')]
sources += [Path('tools/probes/void_museum_rig_probe.gd')]
sources += [Path('tools/probes/void_stream_probe.gd')]
sources += [Path('tools/probes/void_grid_probe.gd'),Path('tools/probes/void_pythagoras_probe.gd'),Path('tools/probes/void_mesh_zone_probe.gd')]
sources += [Path('tools/probes/void_fall_probe.gd')]
sources += [Path('tools/probes/void_site_props_probe.gd')]
sources += [Path('tools/probes/void_coordinates_site_probe.gd')]
sources += [Path('tools/probes/void_lines_site_probe.gd')]
sources += [Path('tools/probes/void_trace_site_probe.gd')]
sources += [Path('tools/probes/void_triangle_site_probe.gd')]
sources += [Path('tools/probes/void_polyhedra_probe.gd')]
sources += [Path('tools/probes/'+name) for name in [
    'void_inventory_probe.gd','void_corner_landings_probe.gd','void_museum_capture.gd']]
sources += [Path(p) for p in ['tools/probes/void_triangle_probe.gd',
    'commons/primitives/line/puzzles/line_snap_puzzle_base.gd',
    'commons/primitives/line/form_constraint.gd', 'commons/primitives/line/geometry_utils.gd',
    'commons/primitives/point/drag_point_set.gd']]
# The engine-vocabulary gallery selects these original scenes by type name.
sources += [p.relative_to(ROOT) for p in (ROOT/'commons/artifacts/ignorance_gallery/prefabs').glob('*.tscn')]
# Original museum objects also use global classes and dynamically selected media.
sources += [Path(p) for p in [
    'commons/artifacts/perlin_terrain_sculptor/perlin_terrain_sculptor.gd',
    'commons/primitives/snappoint/puzzles/snap_point_puzzle_base.gd',
    'commons/context/clipboard/tutorial_text_library.gd',
    'commons/primitives/point/interactive_point_origin_force.tscn',
]]
sources += [p.relative_to(ROOT) for p in (ROOT/'commons/audio/presets').rglob('*.json')]
# These strings are exit destinations, not dependencies of the running floor.
# Their full-project autoloads belong to the separate --menu integration check.
external_routes = {'commons/scenes/vr_staging.tscn', 'commons/hazards/biome_ladder/ladder_world.tscn'}
seen = set(sources)
queue = list(sources)
while queue:
    relative = queue.pop()
    source = ROOT / relative
    if relative.as_posix() == 'commons/hazards/biome_ladder/route.gd': continue
    if source.suffix not in {'.gd','.tscn','.tres','.gdshader','.json'}: continue
    for reference in re.findall(r'"([^"\n]+\.(?:gd|tscn|tres|gdshader|json|ttf|otf|png|jpg|jpeg|webp|svg|wav|ogg|mp3|glb|gltf|exr|hdr))"', source.read_text(encoding='utf-8-sig',errors='replace')):
        reference = reference.split("'")[0]
        target = Path(reference.removeprefix("res://")) if reference.startswith("res://") else relative.parent / reference
        if target.as_posix() in external_routes: continue
        if target not in seen and (ROOT / target).is_file():
            seen.add(target); queue.append(target)
sources = sorted(seen)
for relative in sources:
    copy(relative)
# Only the registry entries dynamically requested by these scenes, with real
# definitions. Copying the entire museum registry would import unrelated worlds.
registry = {}
for file in sorted((ROOT/'commons/artifacts/registry').glob('*.json')):
    registry.update(json.loads(file.read_text(encoding='utf-8-sig')).get('artifacts',{}))
registry_dir=project/'commons/artifacts/registry'
registry_dir.mkdir(parents=True,exist_ok=True)
(registry_dir/'void_dependencies.json').write_text(json.dumps({'artifacts':{
    key:registry[key] for key in ['interactive_point_origin_force']
}}),encoding='utf-8')
shutil.copy2(ROOT / 'tools/probes/void_game_probe.gd', project / 'void_game_probe.gd')
(project / 'project.godot').write_text('''config_version=5
[application]
config/name="The Void / physics verification"
run/main_scene="res://commons/void/void.tscn"
[autoload]
TraceData="*res://commons/globals/trace_data.gd"
XRToolsUserSettings="*res://addons/godot-xr-tools/user_settings/user_settings.gd"
XRToolsRumbleManager="*res://addons/godot-xr-tools/rumble/rumble_manager.gd"
[filesystem]
import/blender/enabled=false
[display]
window/size/viewport_width=1600
window/size/viewport_height=1000
[physics]
3d/physics_engine="Jolt Physics"
3d/solver/contact_max_allowed_penetration=0.001
[rendering]
renderer/rendering_method="gl_compatibility"
''', encoding='utf-8')
(project / 'staging_type_probe.gd').write_text('''extends RefCounted
static func assign_scene(scene: XRToolsSceneBase) -> XRToolsSceneBase:
    return scene
''', encoding='utf-8')
(project / 'doc').mkdir(exist_ok=True)
(project / 'doc/.gdignore').touch()
(project / 'doc/sentinel.txt').write_text('Must not ship.')

def invoke(label, args, cwd, timeout=120, known_menu_material_issue=False):
    path = OUT / f'{label}.log'
    with path.open('w', encoding='utf-8') as log:
        proc = subprocess.Popen([GODOT, *args], cwd=cwd, stdout=log, stderr=subprocess.STDOUT,
                                creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0)
        try:
            code = proc.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait()
            code = 124
    text = path.read_text(encoding='utf-8', errors='replace')
    print(f'{label}: exit {code}', flush=True)
    errors = [line for line in text.splitlines() if line.startswith('ERROR:')]
    unexpected = [line for line in errors if not (known_menu_material_issue and line == 'ERROR: Parameter "material" is null.')]
    if code or 'SCRIPT ERROR' in text or 'Parse Error' in text or unexpected:
        print(text[-12000:], flush=True)
        raise RuntimeError(f'{label} failed')
    return {'exit_code': code, 'clean_log': not errors, 'known_menu_material_errors': len(errors)}

try:
    invoke('import', ['--headless', '--path', str(project), '--editor', '--import'], project, 180)
    if '--trace' in sys.argv:
        invoke('trace', ['--headless','--fixed-fps','60','--path',str(project),'--xr-mode','off','--script','res://tools/probes/void_trace_probe.gd','--','--out='+str(OUT)], project,180)
        if '--capture' in sys.argv:
            invoke('trace-capture', ['--no-window','--path',str(project),'--rendering-method','mobile','--xr-mode','off','--script','res://tools/probes/void_trace_probe.gd','--','--capture','--out='+str(OUT)],project,120)
        raise SystemExit(0)
    if '--stage-only' in sys.argv: raise SystemExit(0)
    if '--layout-only' in sys.argv:
        invoke('layout', ['--no-window', '--path', str(project), '--rendering-method', 'forward_plus', '--xr-mode', 'off', '--script',
                         'res://tools/probes/void_layout_probe.gd', '--', '--out=' + str(OUT)], project)
        (OUT/'receipt.json').write_text(json.dumps({'passed': True, 'scope': 'Architecture and native screenshots', 'stage': str(stage), 'source_equals_stage': all((ROOT / r).read_bytes() == (project / r).read_bytes() for r in sources)}, indent=2))
        raise SystemExit(0)
    invoke('physics', ['--headless', '--fixed-fps', '60', '--path', str(project), '--xr-mode', 'off', '--script',
                      'res://tools/probes/void_game_probe.gd', '--', '--out=' + str(OUT)], project)
    if (OUT/'editor-roundtrip.json').exists():
        invoke('editor-runtime', ['--headless', '--fixed-fps', '60', '--path', str(project), '--xr-mode', 'off', '--script',
               'res://tools/probes/void_game_probe.gd', '--', '--out='+str(OUT), '--editor-roundtrip', '--void-start-floor=3',
               '--void-draft='+str(OUT/'editor-roundtrip.json')], project)
    if '--package' in sys.argv:
        presets = configparser.ConfigParser(interpolation=None)
        presets.read(ROOT / 'export_presets.cfg', encoding='utf-8')
        android = next(presets[s] for s in presets.sections() if presets[s].get('platform') == '"Android"')
        (project / 'export_presets.cfg').write_text(f'''[preset.0]
name="Void regression"
platform="Windows Desktop"
runnable=true
export_filter="all_resources"
include_filter={android['include_filter']}
exclude_filter={android['exclude_filter']}
script_export_mode={android['script_export_mode']}
[preset.0.options]
binary_format/architecture="x86_64"
''', encoding='utf-8')
        package = runtime / 'void.pck'
        invoke('export', ['--headless', '--path', str(project), '--export-pack', 'Void regression', str(package)], project, 180)
        invoke('package', ['--headless', '--fixed-fps', '60', '--path', str(runtime), '--main-pack', str(package), '--xr-mode', 'off',
                          '--script', 'res://void_game_probe.gd', '--', '--out=' + str(OUT), '--package'], runtime)
    if '--capture' in sys.argv:
        invoke('capture', ['--no-window', '--path', str(project), '--rendering-method', 'forward_plus', '--xr-mode', 'off',
                          '--script', 'res://tools/probes/void_game_probe.gd', '--', '--out=' + str(OUT), '--capture'], project)
    if '--mobile-capture' in sys.argv:
        mobile_out = OUT / 'mobile'
        mobile_out.mkdir(exist_ok=True)
        invoke('mobile-capture', ['--no-window', '--path', str(project), '--rendering-method', 'mobile', '--xr-mode', 'off',
                                 '--script', 'res://tools/probes/void_game_probe.gd', '--', '--out=' + str(mobile_out), '--capture'], project)
    menu_result = None
    if '--menu' in sys.argv:
        # The existing menu emits null-material cleanup errors even without
        # loading the game. Preserve and report that baseline; do not suppress
        # script errors or any other engine error from the integration test.
        baseline = invoke('menu-baseline', ['--headless', '--path', str(ROOT), '--xr-mode', 'off',
                          '--script', 'res://tools/probes/void_menu_probe.gd', '--', '--no-bridges', '--void-menu-only'], ROOT, 80, True)
        menu_result = invoke('menu', ['--headless', '--path', str(ROOT), '--xr-mode', 'off',
                             '--script', 'res://tools/probes/void_menu_probe.gd', '--', '--no-bridges', '--out=' + str(OUT)], ROOT, 80, True)
        assert menu_result['known_menu_material_errors'] == baseline['known_menu_material_errors']
        assert json.loads((OUT/'menu-checks.json').read_text())['passed']
        menu_result['baseline'] = baseline
        (OUT/'menu-receipt.json').write_text(json.dumps(menu_result, indent=2))
    receipt = {'passed': True, 'stage': str(stage), 'sources': {str(r): hashlib.sha256((ROOT / r).read_bytes()).hexdigest() for r in sources},
               'source_equals_stage': all((ROOT / r).read_bytes() == (project / r).read_bytes() for r in sources),
               'scope': 'Native Jolt physics and real XRTools with synthetic tracker inputs; no physical headset test. PCK option uses Android exclusions on Windows.', 'menu': menu_result}
except Exception as exc:
    receipt = {'passed': False, 'stage': str(stage), 'error': str(exc)}
(OUT / 'receipt.json').write_text(json.dumps(receipt, indent=2))
raise SystemExit(0 if receipt['passed'] else 1)
