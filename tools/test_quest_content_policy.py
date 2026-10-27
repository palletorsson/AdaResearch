"""Real small PCK export proves the Quest boundary without building/installing APK.

Uses an isolated project and OS native mutex; never changes a player's saves.
"""
import json, re, shutil, subprocess
from pathlib import Path
from void_native_slot import acquire_native_slot

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'ada_run/quest-content-2026-10-26'
FIX=OUT/'policy-fixture'
GODOT='C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'

def write(rel,text):
    p=FIX/rel;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(text,encoding='utf-8')

def main():
    OUT.mkdir(parents=True,exist_ok=True)
    (OUT/'.gdignore').write_text('\n',encoding='utf-8')
    policy=json.loads((OUT/'policy.json').read_text(encoding='utf-8'))
    assert policy['applied'] and not policy['conflicts']
    assert re.search(r'^version/code=4$',(ROOT/'export_presets.cfg').read_text(),re.M)
    for rel in ('addons/quest_game_export/plugin.cfg','addons/quest_game_export/plugin.gd',
                'addons/quest_game_export/exporter.gd','addons/quest_game_export/runtime-trial-files.json',
                'commons/void/room_source.gd','commons/void/trials/session.gd'):
        target=FIX/rel;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/rel,target)
    write('project.godot','''config_version=5
[application]
config/name="Quest Content Policy Fixture"
run/main_scene="res://main.tscn"
[editor_plugins]
enabled=PackedStringArray("res://addons/quest_game_export/plugin.cfg")
[rendering]
renderer/rendering_method="gl_compatibility"
''')
    write('export_presets.cfg','''[preset.0]
name="PolicyCheck"
platform="Windows Desktop"
runnable=true
custom_features="quest_game"
export_filter="all_resources"
include_filter="*.json,*.md"
exclude_filter="addons/quest_game_export/*"
script_export_mode=2
[preset.0.options]
binary_format/architecture="x86_64"
''')
    write('main.tscn','''[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://main.gd" id="1"]
[node name="PolicyCheck" type="Node"]
script=ExtResource("1")
''')
    write('main.gd','''extends Node
const Source=preload("res://commons/void/room_source.gd")
func _ready() -> void:
	var checks := {
		"quest_game_feature":OS.has_feature("quest_game"),
		"trials_disabled":not Source.trials_available(),
		"explicit_trial_does_not_replace_main":Source.selected("chains_studies").is_empty(),
		"trial_manifest_not_read":Source.definition("chains_studies").is_empty(),
		"game_data_kept":FileAccess.file_exists("res://commons/void/rooms.json"),
		"runtime_adapter_kept":ResourceLoader.exists("res://commons/void/trials/session.gd"),
		"authoring_trial_not_packaged":not ResourceLoader.exists("res://commons/void/trials/new_future_trial/trial.tscn"),
		"authoring_json_not_packaged":not FileAccess.file_exists("res://commons/void/trials/new_future_trial/rooms.json"),
		"trial_manifest_not_packaged":not FileAccess.file_exists("res://commons/void/trials/playable.json"),
		"run_receipt_not_packaged":not FileAccess.file_exists("res://ada_run/receipt.json"),
		"evidence_not_packaged":not FileAccess.file_exists("res://commons/void/trials/new_future_trial/evidence/checks.json"),
		"export_plugin_not_packaged":not FileAccess.file_exists("res://addons/quest_game_export/runtime-trial-files.json"),
		"export_plugin_code_not_packaged":not ResourceLoader.exists("res://addons/quest_game_export/plugin.gd")
	}
	var passed := true
	for value in checks.values():passed=passed and bool(value)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--receipt="):FileAccess.open(arg.trim_prefix("--receipt="),FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"checks":checks},"  "))
	get_tree().quit(0 if passed else 1)
''')
    write('commons/void/rooms.json','{"floors":[]}')
    write('commons/void/trials/playable.json','{"trials":{}}')
    write('commons/void/trials/new_future_trial/rooms.json','{}')
    write('commons/void/trials/new_future_trial/trial.tscn','[gd_scene format=3]\n[node name="DraftOnly" type="Node"]\n')
    write('commons/void/trials/new_future_trial/evidence/checks.json','{}')
    write('commons/void/trials/new_future_trial/evidence/.gdignore','\n')
    # Same error as reported: JPEG-signature bytes with a .png name. It must
    # never be handed to the PNG importer in this ignored evidence directory.
    (FIX/'commons/void/trials/new_future_trial/evidence/not-a-png.png').write_bytes(b'\xff\xd8\xff\xe0not-png')
    write('ada_run/receipt.json','{"private_test_receipt":true}')
    slot=acquire_native_slot('Quest content policy isolated PCK export and load',timeout=60)
    with (OUT/'policy-export.log').open('w',encoding='utf-8') as log:
        r=subprocess.run([GODOT,'--headless','--editor','--path',str(FIX),'--export-pack','PolicyCheck',str(OUT/'policy-test.pck')],stdout=log,stderr=subprocess.STDOUT,timeout=90,creationflags=subprocess.CREATE_NO_WINDOW)
    logs=(OUT/'policy-export.log').read_text(encoding='utf-8',errors='replace')
    assert r.returncode==0 and 'SCRIPT ERROR:' not in logs and not re.search(r'^ERROR:',logs,re.M),logs[-6000:]
    runtime=OUT/'policy-runtime';runtime.mkdir(exist_ok=True)
    with (OUT/'policy-runtime.log').open('w',encoding='utf-8') as log:
        r=subprocess.run([GODOT,'--headless','--path',str(runtime),'--main-pack',str(OUT/'policy-test.pck'),'--','--receipt='+str(OUT/'policy-test.json')],stdout=log,stderr=subprocess.STDOUT,timeout=30,creationflags=subprocess.CREATE_NO_WINDOW)
    report=json.loads((OUT/'policy-test.json').read_text(encoding='utf-8'))
    logs=(OUT/'policy-runtime.log').read_text(encoding='utf-8',errors='replace')
    assert r.returncode==0 and report['passed'] and not re.search(r'^(ERROR:|SCRIPT ERROR:)',logs,re.M),logs
    print(json.dumps(report,indent=2))

if __name__=='__main__':main()
