"""Refresh just the changed native assembly, preserving the rest of the editor."""
import hashlib,json,os,shutil,struct,subprocess,sys
from pathlib import Path
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
from generated_storage import model_directory

def main():
    sys.stdout.reconfigure(encoding="utf8");root=Path(__file__).resolve().parents[1];out=root/"ada_run/transformation14-scale-descent-2026-10-26/export";out.mkdir(parents=True,exist_ok=True)
    models=model_directory(out/"native-models");models.mkdir(parents=True,exist_ok=True)
    slot=acquire_native_slot("Scale descent native editor assembly");stage=stage_runtime()
    args=[os.environ.get("GODOT_EXE","C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"),"--no-window","--rendering-method","gl_compatibility","--path",str(stage),"--xr-mode","off","--script","res://tools/probes/export_scale_descent.gd","--","--no-bridges","--out="+str(models),"--public-base=/void-models"]
    with (out/"engine.log").open("w",encoding="utf8") as log:r=subprocess.run(args,stdout=log,stderr=subprocess.STDOUT,timeout=120,creationflags=subprocess.CREATE_NO_WINDOW)
    text=(out/"engine.log").read_text(encoding="utf8",errors="replace");errors=[s for s in text.splitlines() if s.startswith(("ERROR:","SCRIPT ERROR:"))]
    if r.returncode or errors:print(text[-7000:]);raise RuntimeError("Native assembly export failed")
    result=json.loads((models/"assembly.json").read_text());assert not result["failures"]
    count=0
    for file in models.glob("*.glb"):
        b=file.read_bytes();assert struct.unpack_from("<I",b)[0]==0x46546c67 and struct.unpack_from("<I",b,8)[0]==len(b)
        g=json.loads(b[20:20+struct.unpack_from("<I",b,12)[0]].decode().strip());assert g.get("meshes");count+=1
    public=root.parent/"ada_encyclopedia/public/void-models";manifest_file=public/"manifest.json";old=json.loads(manifest_file.read_text(encoding="utf8"));(out/"before-manifest.json").write_text(json.dumps(old),encoding="utf8")
    old["floors"]["14"]["artifacts"]["sequence"]=result["artifact"]
    for file in models.glob("*.glb"):shutil.copy2(file,public/file.name)
    old.setdefault("source_files",{})["commons/void/rooms.json"]=hashlib.sha256((root/"commons/void/rooms.json").read_bytes()).hexdigest()
    old["revision"]=hashlib.sha256(json.dumps(old).encode()).hexdigest()[:12]
    temp=manifest_file.with_suffix(".scale-descent.tmp");temp.write_text(json.dumps(old,indent=2)+"\n",encoding="utf8");os.replace(temp,manifest_file)
    file=root/"commons/void/line_parts.json";parts=json.loads(file.read_text(encoding="utf8"));parts.setdefault(result["artifact"]["artifact"],{}).update({name:p["default"] for name,p in result["artifact"]["parts"].items()});file.write_text(json.dumps(parts,indent=2)+"\n",encoding="utf8")
    (out/"checks.json").write_text(json.dumps({"passed":True,"models":count,"parts":list(result["artifact"]["parts"]),"revision":old["revision"],"notes":result["notes"]},indent=2),encoding="utf8")
    print("Exported",count,"actual GLBs and",len(result["artifact"]["parts"]),"editable parts")
if __name__=="__main__":main()
