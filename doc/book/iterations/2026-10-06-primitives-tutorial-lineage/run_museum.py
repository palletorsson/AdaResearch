from pathlib import Path
import sys,json,shutil,tempfile,subprocess
from build_sources import HERE,ROOT,HALLS
runner=ROOT/'tools/run_encounter_probe.py'
source=runner.read_text(encoding='utf-8').replace("ROOT / 'ada_run/encounter_pilot' / args.room", "ROOT / 'ada_run/encounter_pilot' / (args.room + '_tutorial_20261006')")
namespace={'__name__':'museum_probe','__file__':str(runner)}
exec(compile(source,str(runner),'exec'),namespace)
# Import the supplied font with Godot, at its exact res:// path, without importing the whole museum.
font=HERE/'Primitives_Profiles/JetBrainsMono-Medium.ttf'
relative=font.relative_to(ROOT)
if not font.with_suffix('.ttf.import').exists():
    temp=Path(tempfile.mkdtemp(prefix='ada-profile-font-'))
    (temp/'project.godot').write_text('config_version=5\n')
    (temp/relative).parent.mkdir(parents=True)
    shutil.copyfile(font,temp/relative)
    subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--path',str(temp),'--editor','--import','--quit'],capture_output=True,timeout=60,check=True)
    shutil.copyfile((temp/relative).with_suffix('.ttf.import'),font.with_suffix('.ttf.import'))
    for asset in (temp/'.godot/imported').iterdir():shutil.copyfile(asset,ROOT/'.godot/imported'/asset.name)
for hall in (sys.argv[1:] or HALLS):
    try:
        sys.argv=[str(runner),hall,'--sequence','primitives','--render','--probe',str(HERE/'museum_studies.gd')]
        result=namespace['main']()
        folder=ROOT/'ada_run/encounter_pilot'/(hall+'_tutorial_20261006')
        out=HERE/hall/'museum';out.mkdir(exist_ok=True)
        for name in ['learner-study.png','learner-close.png','held-resolution.png','report.json','source_manifest.json']:
            if (folder/name).exists():shutil.copyfile(folder/name,out/name)
        evidence=json.loads((folder/'report.json').read_text())
        assert evidence['passed'] and len(evidence['checks'])>=5 and (out/'learner-study.png').exists(),hall
        if result:raise RuntimeError(hall+' museum probe failed')
    finally:
        flag=HERE/'archive-backup.json'
        if flag.exists():
            state=json.loads(flag.read_text());target=Path(state['path']).resolve()
            # Only the explicitly named user trace archive can be restored/removed.
            assert target.name=='ada_student_trace.scn' and target.is_absolute()
            if state['existed']:target.write_bytes((HERE/'archive-before.bin').read_bytes())
            elif target.exists():target.unlink()
            flag.unlink()
            if (HERE/'archive-before.bin').exists():(HERE/'archive-before.bin').unlink()
