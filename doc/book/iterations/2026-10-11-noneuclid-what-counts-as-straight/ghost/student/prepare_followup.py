from pathlib import Path
import json,hashlib,datetime
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[5]
target=HERE/'probe_delayed.gd'
manifest=HERE/'followup_02_frozen.json'
assert not target.exists() and not manifest.exists()
text=(HERE/'probe.gd').read_text(encoding='utf-8')
text=text.replace('const Pointer = preload("res://addons/godot-xr-tools/events/pointer_event.gd")','var Pointer')
text=text.replace('const Scene = preload("reconstructed.tscn")','var Scene')
text=text.replace('attempt_01_engine.json','attempt_02_engine.json').replace('"attempt":1','"attempt":2')
text=text.replace('func run() -> void:\n    numerical()', '''func run() -> void:
    await frames(3)
    Pointer = load("res://addons/godot-xr-tools/events/pointer_event.gd")
    Scene = load("res://doc/book/iterations/2026-10-11-noneuclid-what-counts-as-straight/ghost/student/reconstructed.tscn")
    numerical()''')
text=text.replace('    check("host_named_attachment",host.name == "SurfaceStudy")','''    for word in ["Plane","Sphere","Reset"]:
        for component in ["HandPoseArea","InteractableAreaButton/Rumbler"]:
            var child = host.get_node(word+"/"+component)
            var script = child.get_script()
            check("dependency_"+word+"_"+component,script != null and script.can_instantiate(),"script attached and can instantiate")
    check("host_named_attachment",host.name == "SurfaceStudy")''')
target.write_text(text,encoding='utf-8',newline='\n')
data={
 'frozen_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),
 'hypothesis':'The first attempt preloaded the host scene before SceneTree autoload startup, so declared XRTools singleton names were unresolved during dependency compilation. Deferring scene loading until three frames after startup may remove compilation failures without any source changes.',
 'prediction':'All original 103 assertions should still pass. Six new supplied-component script attachment/can_instantiate checks should pass. XRToolsUserSettings and XRToolsRumbleManager compile errors should be absent. No prediction that unrelated startup UID/Jolt warnings disappear.',
 'source_changes':'No changes to any of five reconstructed tutorial listings or prepared project. Only new harness load timing plus six dependency checks; original probe, predictions and evidence retained.',
 'probe_sha256':hashlib.sha256(target.read_bytes()).hexdigest(),
 'new_dependencies_read_sha256':{p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in ['addons/godot-xr-tools/rumble/rumbler.gd','addons/godot-xr-tools/player/player_body.gd']},
 'new_reading_trail':['Read entire rumbler.gd, a scene-declared dependency; read player_body.gd lines 501-540, an XRTools transitive dependency named by first-run compiler diagnostics. No other new project source read.']
}
manifest.write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
print(json.dumps(data,indent=2))
