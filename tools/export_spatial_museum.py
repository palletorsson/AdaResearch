"""Build and export a museum hall with all diagnostic/user writes isolated."""
from pathlib import Path
import argparse, hashlib, json, os, shutil, subprocess
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
from generated_storage import public_directory
from void_log_diagnostics import split_errors

ROOT = Path(__file__).resolve().parents[1]
WEB = ROOT.parent / 'ada_encyclopedia'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('map', nargs='?', default='Trans_Rotation')
    parser.add_argument('--sequence', default='transformation')
    args = parser.parse_args()
    assert args.map.replace('_', '').isalnum() and args.sequence.replace('_', '').isalnum()
    inputs = [f'commons/maps/{args.map}/map_data.json', 'commons/scenes/endless_museum.gd',
              'commons/scenes/em/em_detail.gd', 'commons/data/museum/em_plan.json',
              'commons/data/museum/em_bake.json', 'commons/data/museum/em_overrides.json',
              'commons/data/em_layout.json', 'commons/data/template_patterns.json',
              'ada_run/necklace_hand.json', 'commons/data/spine_artifact_order_hand.json']
    protected = inputs + ['commons/void/rooms.json', 'ada_run/em_layout_walk.json',
                          'ada_run/em_control.json', 'ada_run/em_built.json']
    digest = lambda p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() if (ROOT / p).is_file() else None
    before = {p: digest(p) for p in protected}
    slot = acquire_native_slot('read-only Museum comparison / ' + args.map)
    stage = stage_runtime()
    private = stage / 'comparison'
    private.mkdir()
    for name in ['em_inventory.json', 'em_showing_cards.json', 'em_live_footprints.json',
                 'em_layout_walk.json', 'em_adoptions.json', 'em_built.json', 'em_foes.json',
                 'em_boot_last.json', 'em_pack_report.json', 'em_basin_plan.txt', 'necklace_hand.json']:
        source = ROOT / 'ada_run' / name
        if source.is_file(): shutil.copy2(source, private / name)
    if not (private / 'necklace_hand.json').exists(): (private / 'necklace_hand.json').write_text('{}')
    for name in ['em_bake.json', 'em_overrides.json']:
        shutil.copy2(ROOT / 'commons/data/museum' / name, private / name)
    control = json.loads((ROOT / 'ada_run/em_control.json').read_text(encoding='utf-8-sig'))
    control.update(first_chapter=args.sequence, first_map=args.map, dollhouse=0)
    for key in ['resume_eye', 'resume_hall', 'resume_yaw', 'resume_pitch']: control.pop(key, None)
    (private / 'control.json').write_text(json.dumps(control), encoding='utf-8')
    (private / 'spec.json').write_text(json.dumps({'map':args.map, 'sequence':args.sequence}), encoding='utf-8')
    # Only I/O locations change. Geometry, placement, plan and game-mode code do not.
    source = (ROOT / 'commons/scenes/endless_museum.gd').read_text(encoding='utf-8')
    source = source.replace('res://ada_run/', 'res://comparison/')
    source = source.replace('res://commons/data/museum/em_bake.json', 'res://comparison/em_bake.json')
    (private / 'museum_snapshot.gd').write_text(source, encoding='utf-8')
    out = ROOT / 'ada_run/spatial-comparison' / args.map / 'museum'
    out.mkdir(parents=True, exist_ok=True)
    models = public_directory('spatial-comparison') / args.map / 'museum'
    models.mkdir(parents=True, exist_ok=True)
    headless = os.environ.get('SPATIAL_EXPORT_HEADLESS') == '1'
    command = [os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),
               '--headless' if headless else '--no-window','--path',str(stage),'--rendering-method','gl_compatibility','--xr-mode','off',
               '--script','res://tools/probes/export_spatial_museum.gd','--','--no-bridges',
               '--out='+str(models),'--public-base=/spatial-comparison/'+args.map+'/museum']
    with (out/'export.log').open('w',encoding='utf-8') as log:
        result = subprocess.run(command, stdout=log, stderr=subprocess.STDOUT, timeout=240,
                                creationflags=subprocess.CREATE_NO_WINDOW)
    log = (out/'export.log').read_text(encoding='utf-8',errors='replace')
    errors, shutdown = split_errors(log,'MUSEUM_COMPARISON_EXPORT ',allow_shutdown=result.returncode==0)
    assert all(digest(p)==value for p,value in before.items()), 'Authoring source changed during export'
    assert result.returncode==0 and not errors, (result.returncode,errors,log[-4000:])
    manifest = json.loads((models/'manifest.json').read_text(encoding='utf-8'))
    assert not manifest['failures'] and manifest['objects'] and manifest['structure'].get('url')
    manifest.update(sources={p:before[p] for p in inputs},shutdown_diagnostics=shutdown,renderer='headless geometry' if headless else 'gl_compatibility',
                    source='commons/scenes/endless_museum.gd + current plan/rulings',isolated_outputs=True)
    (models/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
    public = WEB/'public/spatial-comparison'/args.map/'museum'
    public.mkdir(parents=True,exist_ok=True)
    for f in models.iterdir():
        if f.is_file() and f.name!='manifest.json': shutil.copy2(f,public/f.name)
    shutil.copy2(models/'manifest.json',public/'manifest.json')
    receipt={'passed':True,'map':args.map,'objects':len(manifest['objects']),
             'roof_nodes':manifest['roof_nodes'],'source_files_unchanged':before,
             'scope':manifest['scope']}
    (out/'checks.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(receipt,indent=2))


if __name__=='__main__': main()
