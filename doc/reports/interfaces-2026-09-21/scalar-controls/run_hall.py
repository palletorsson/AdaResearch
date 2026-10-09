"""Isolated snapshots of the real museum builder, with private output paths."""
from pathlib import Path
import hashlib, json, re, shutil, subprocess, sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
CASES = {'library': ('Gallery_Furniture', 'gallery', 'vr_component_demo')}

def run(case, variant):
    room, sequence, token = CASES[case]
    out = HERE / variant / case
    out.mkdir(parents=True, exist_ok=True)
    prefix = 'res://' + out.relative_to(ROOT).as_posix() + '/'
    source_path = ROOT / 'commons/scenes/endless_museum.gd'
    source = source_path.read_text(encoding='utf-8')
    replacements = {}
    for name in ['em_inventory.json', 'em_showing_cards.json', 'em_live_footprints.json',
                 'em_bake.json', 'em_layout_walk.json', 'em_adoptions.json', 'em_built.json',
                 'em_foes.json', 'em_boot_last.json', 'em_pack_report.json', 'em_basin_plan.txt']:
        old = 'res://ada_run/' + name
        if old not in source: continue
        replacements[old] = prefix + name
        original = ROOT / 'ada_run' / name
        if original.exists(): shutil.copy2(original, out / name)
        source = source.replace(old, prefix + name)
    (out / 'museum_snapshot.gd').write_text(source, encoding='utf-8')
    scene = (ROOT / 'commons/scenes/endless_museum.tscn').read_text(encoding='utf-8')
    scene = re.sub(r' uid="[^"]+"', '', scene)
    scene = scene.replace('res://commons/scenes/endless_museum.gd', prefix + 'museum_snapshot.gd')
    (out / 'museum_snapshot.tscn').write_text(scene, encoding='utf-8')
    control = json.loads((ROOT / 'ada_run/em_control.json').read_text(encoding='utf-8-sig'))
    control.update(first_chapter=sequence, first_map=room, dollhouse=0)
    for key in ['resume_eye', 'resume_hall', 'resume_yaw', 'resume_pitch']: control.pop(key, None)
    (out / 'control.json').write_text(json.dumps(control), encoding='utf-8')
    for name in ['necklace_hand.json', 'em_overrides.json', 'em_plan.json']:
        shutil.copy2(ROOT / 'ada_run' / name, out / name)
    spec = dict(room=room, sequence=sequence, token=token, run=prefix, case=case)
    (out / 'spec.json').write_text(json.dumps(spec), encoding='utf-8')
    paths = [source_path, ROOT / f'commons/maps/{room}/map_data.json',
             ROOT / 'commons/ui/demo/vr_component_demo.gd',
             ROOT / 'commons/testing/probe_library_hall.gd',
             ROOT / 'ada_run/em_plan.json', ROOT / 'ada_run/em_overrides.json', ROOT / 'ada_run/necklace_hand.json']
    (out / 'sources.json').write_text(json.dumps({str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}, indent=2), encoding='utf-8')
    report = out / 'report.json'
    if report.exists(): report.unlink()
    command = [r'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe', '--path', str(ROOT),
               '--xr-mode', 'off', '--audio-driver', 'Dummy', '--resolution', '1600x1200',
               '--rendering-method', 'mobile', '--log-file', str(out/'engine.log'),
               '--script', 'res://commons/testing/probe_library_hall.gd', '--', prefix+'spec.json', '--em-no-costume']
    with (out/'run.log').open('w', encoding='utf-8') as log:
        try:
            result = subprocess.run(command, stdout=log, stderr=subprocess.STDOUT, timeout=180, creationflags=subprocess.CREATE_NO_WINDOW)
        except subprocess.TimeoutExpired:
            print(case, 'TIMEOUT'); return 124
    if report.exists():
        data = json.loads(report.read_text(encoding='utf-8'))
        print(case, len(data['checks']), 'checks; failures:', data['failures'])
    else: print((out/'run.log').read_text(encoding='utf-8', errors='replace')[-4500:])
    return result.returncode

if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    raise SystemExit(run(sys.argv[1], sys.argv[2] if len(sys.argv)>2 else 'before'))
