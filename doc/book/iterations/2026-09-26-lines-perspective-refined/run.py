from pathlib import Path
p=Path.cwd()/'tools/run_encounter_probe.py'
s=p.read_text(encoding='utf-8').replace("ROOT / 'ada_run/encounter_pilot' / args.room", "ROOT / 'ada_run/encounter_pilot' / (args.room + '_perspective_refined')")
exec(compile(s,str(p),'exec'),{'__name__':'__main__','__file__':str(p)})
