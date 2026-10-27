"""Bounded, OS-locked batch25 integration; no trial-owned files changed."""
import sys, subprocess, json
from pathlib import Path
sys.stdout.reconfigure(encoding='utf8')
ROOT=Path(__file__).resolve().parents[3]
sys.path.insert(0,str(ROOT/'tools'))
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
batch=Path(__file__).resolve().parent
with acquire_native_slot('Codex desktop hand reparent and dice hook',timeout=55):
    p=ROOT/'commons/void/desktop_hand.gd'
    s=p.read_text(encoding='utf8')
    if '_reenable_on_enter' not in s:
        s=s.replace('var shared_grab := false','var shared_grab := false\nvar _reenable_on_enter := false\nvar _restore_ability_source := false')
        old='func _exit_tree() -> void:\n\tset_enabled(false)'
        new='''# Scale portals transiently reparent this hand. Preserve its enabled state,
# while an explicitly disabled recovery hand remains disabled on re-entry.
func _enter_tree() -> void:
	if _reenable_on_enter:
		_reenable_on_enter = false
		set_enabled(true)
	if _restore_ability_source and is_instance_valid(ability):
		ability.desktop_source = self
	_restore_ability_source = false

func _exit_tree() -> void:
	_reenable_on_enter = enabled
	_restore_ability_source = is_instance_valid(ability) and ability.desktop_source == self
	set_enabled(false)'''
        assert s.count(old)==1
        p.write_text(s.replace(old,new),encoding='utf8')
    p=ROOT/'commons/void/floor_content.gd'; s=p.read_text(encoding='utf8')
    if '"dice_throw": "dice_throw_local"' not in s:
        old='item.artifact in ["random_object_spawner", "Random_Rotate_Random_XYZ", "galton_board"]'
        assert s.count(old)==1
        s=s.replace(old,'item.artifact in ["random_object_spawner", "Random_Rotate_Random_XYZ", "galton_board", "dice_throw"]')
        old='\t\t\t"galton_board": "galton_board_local",'
        assert s.count(old)==1
        s=s.replace(old,old+'\n\t\t\t"dice_throw": "dice_throw_local",')
        p.write_text(s,encoding='utf8')
    stage=stage_runtime()
    files=['commons/void/desktop_hand.gd','commons/void/floor_content.gd','commons/void/trials/randomness_04/dice_throw_local.gd']
    with (batch/'hand-dice-compile.log').open('w',encoding='utf8') as out:
        r=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--path',str(stage),'--xr-mode','off','--script','res://commons/testing/check_compile.gd','--','--no-bridges','--files='+','.join('res://'+f for f in files)],stdout=out,stderr=subprocess.STDOUT,timeout=45,creationflags=subprocess.CREATE_NO_WINDOW)
    log=(batch/'hand-dice-compile.log').read_text(encoding='utf8'); errors=[x for x in log.splitlines() if 'SCRIPT ERROR' in x or x.startswith('ERROR:')]
    report={'passed':r.returncode==0 and not errors,'exit_code':r.returncode,'errors':errors,'files':files,'scope':'compile only; focused native checks pending'}
    (batch/'hand-dice-compile.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
    print(json.dumps(report)); assert report['passed']
