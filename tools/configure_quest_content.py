"""Apply the reviewed Quest game/authoring boundary without deleting sources.

Keep main-game dependencies even where their source lives under trials. Re-run
after introducing new trial-based runtime adapters, before exporting Quest.
"""
import argparse, fnmatch, hashlib, json, re
from pathlib import Path
from audit_quest_content import ROOT, runtime_trial_files

OUT=ROOT/'ada_run/quest-content-2026-10-26'
PRESET=ROOT/'export_presets.cfg'

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply',action='store_true')
    args=parser.parse_args()
    deps=runtime_trial_files()
    assert not deps['missing'],deps['missing']
    original=PRESET.read_text(encoding='utf-8')
    end=original.index('[preset.1]')
    android,rest=original[:end],original[end:]
    old=re.search(r'^exclude_filter="(.*)"$',android,re.M).group(1).split(',')
    # Import sidecars are covered by excluding their source; exclude them too
    # so raw JSON/MD include filters cannot carry old authoring receipts.
    deny=set(old)|set(deps['excluded'])|{
        'ada_run/*','ada_run/**','**/evidence/*','**/evidence/**',
        '**/screenshots/*','**/screenshots/**',
        'addons/quest_game_export/*','addons/quest_game_export/**',
    }
    conflicts=[p for p in deps['runtime'] if any(fnmatch.fnmatchcase(p,g) for g in deny)]
    assert not conflicts,conflicts
    # Keep all current legacy museum resources. This policy narrows authoring
    # files; it does not guess dependency closure from JSON-only game registries.
    android=re.sub(r'^exclude_filter=".*"$', 'exclude_filter="'+','.join(sorted(deny))+'"',android,flags=re.M)
    features=re.search(r'^custom_features="(.*)"$',android,re.M).group(1).split(',')
    features=sorted(set(filter(None,features))|{'quest_game'})
    android=re.sub(r'^custom_features=".*"$','custom_features="'+','.join(features)+'"',android,flags=re.M)
    android=re.sub(r'^version/code=\d+$','version/code=4',android,flags=re.M)
    report={'applied':args.apply,'version_code':4,'custom_feature':'quest_game',
            'runtime_trial_files_retained':deps['runtime'],
            'trial_files_excluded':deps['excluded'],
            'exclude_patterns':sorted(deny),'conflicts':conflicts,
            'scope':'Source export policy only; next APK must be inspected before deployment. Existing installed APK unchanged.'}
    OUT.mkdir(parents=True,exist_ok=True)
    if args.apply:
        backup=OUT/'export_presets.before.cfg'
        if not backup.exists(): backup.write_text(original,encoding='utf-8')
        PRESET.write_text(android+rest,encoding='utf-8')
        manifest=ROOT/'addons/quest_game_export/runtime-trial-files.json'
        manifest.write_text(json.dumps({'runtime':deps['runtime'],
            'generated_by':'python tools/configure_quest_content.py --apply',
            'scope':'Main gameplay dependencies only. Trial rooms, evidence and receipts are authoring content.'},indent=2)+'\n',encoding='utf-8')
    report['preset_sha256']=hashlib.sha256(PRESET.read_bytes()).hexdigest()
    (OUT/'policy.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({'applied':args.apply,'version_code':4,'retained':len(deps['runtime']),
                      'excluded_trial_files':len(deps['excluded']),'conflicts':conflicts}))

if __name__=='__main__':main()
