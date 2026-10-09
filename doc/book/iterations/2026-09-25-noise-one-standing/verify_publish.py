from pathlib import Path
import re,json,hashlib,shutil,difflib
R=Path(__file__).resolve().parents[4];H=Path(__file__).resolve().parent
read=lambda p:p.read_text(encoding="utf-8-sig")
load=lambda p:json.loads(read(p))
checks=[]
def check(name,ok):
 checks.append({"name":name,"passed":bool(ok)})
 if not ok:raise AssertionError(name)
maprel=Path("commons/maps/Noise_One/map_data.json");a=load(H/"before"/maprel);b=load(R/maprel)
check("two metres of approach space added",a["map_info"]["dimensions"]["depth"]==11 and b["map_info"]["dimensions"]["depth"]==13)
for layer,rows in a["layers"].items():
 for i,row in enumerate(rows):check("old row retained: %s %d"%(layer,i),row==b["layers"][layer][i if i==0 else i+2])
 check("new rows match purpose: "+layer,b["layers"][layer][1:3]==[(["w"]+["1"]*11+["w"]) if layer=="structure" else [" "]*13 for _ in range(2)])
check("all other top-level map data preserved",all(a[k]==b[k] for k in a if k not in ["map_info","layers"]))
check("all other map info preserved",all(a["map_info"][k]==b["map_info"][k] for k in a["map_info"] if k not in ["dimensions","museum"]))
check("only depth dimension changes",{k:v for k,v in a["map_info"]["dimensions"].items() if k!="depth"}=={k:v for k,v in b["map_info"]["dimensions"].items() if k!="depth"})
check("museum settings retained except approach clearance",{k:v for k,v in a["map_info"]["museum"].items() if k!="sculpture_clear_rects"}=={k:v for k,v in b["map_info"]["museum"].items() if k!="sculpture_clear_rects"})
for rel in ["commons/resourses/shaders/noiseTorus.gdshader","algorithms/randomness/noisetorus/noisetorus.tscn","algorithms/randomness/noiselayers/noiselayers.gd","algorithms/randomness/noiselayers/noiselayers_stage.gd","algorithms/randomness/noiselayers/noiselayers.tscn","commons/maps/sequences/noise.json"]:
 check("unchanged file: "+rel,(H/"before"/rel).read_bytes()==(R/rel).read_bytes())
rel="algorithms/randomness/noisetorus/noisetorus.gd"
def funcs(s):return {m.group(1):m.group(0) for m in re.finditer(r"^func (\w+)\(.*?(?=^func |\Z)",s,re.M|re.S)}
f=funcs(read(H/"before"/rel));g=funcs(read(R/rel))
check("production methods retained",f.keys()==g.keys())
for name in f:
 if name!="_build_pair":check("unchanged method: "+name,f[name]==g[name])
old=read(H/"before/commons/maps/Noise_One/final.md");new=read(R/"commons/maps/Noise_One/final.md")
check("only two original prose paragraphs altered",sum(p not in new.strip().split("\n\n") for p in old.strip().split("\n\n"))==2)
check("code excerpts preserved",re.findall(r"```.*?```",old,re.S)==re.findall(r"```.*?```",new,re.S))
check("book encounter anchors retained",re.findall(r"<!-- @.*?-->",old)==re.findall(r"<!-- @.*?-->",new))
check("entire terrain and closing prose retained",old[old.index("<!-- @noiselayers -->"):]==new[new.index("<!-- @noiselayers -->"):])
core=load(R/"commons/data/museum_core_encounters.json");prior=load(H/"before/commons/data/museum_core_encounters.json")
check("every primary role list preserved",all(core["rooms"][k]["primary_tokens"]==v["primary_tokens"] for k,v in prior["rooms"].items()))
check("no role-related core fields changed in Noise One",{k:v for k,v in core["rooms"]["Noise_One"].items() if k not in ["text_sha256","map_sha256","local_review"]}=={k:v for k,v in prior["rooms"]["Noise_One"].items() if k not in ["text_sha256","map_sha256","local_review"]})
for key,name in [("text_sha256","final.md"),("map_sha256","map_data.json")]:check("core hash current: "+name,core["rooms"]["Noise_One"][key]==hashlib.sha256((R/"commons/maps/Noise_One"/name).read_bytes()).hexdigest())
reg=load(R/"commons/artifacts/registry/randomness.json")["artifacts"];oldreg=load(H/"before/commons/artifacts/registry/randomness.json")["artifacts"]
check("registry records retained",reg.keys()==oldreg.keys())
check("only noisetorus description and interpretation changed in registry",all(reg[k]==v for k,v in oldreg.items() if k!="noisetorus") and {k:v for k,v in reg["noisetorus"].items() if k not in ["description","qfep_connection"]}=={k:v for k,v in oldreg["noisetorus"].items() if k not in ["description","qfep_connection"]})
runtime=load(H/"museum-runtime.json");check("48 native museum checks pass",runtime["passed"] and len(runtime["checks"])==48)
check("five walking routes pass",len(runtime["walks"])==5 and all(x["passed"] for x in runtime["walks"]))
check("two floor rays pass",len(runtime["rays"])==2 and all(x["passed"] for x in runtime["rays"]))
log=read(H/"museum-process.log");check("no script/shader compile errors",not re.search(r"SCRIPT ERROR|SHADER ERROR",log))
warnings=[x for x in log.splitlines() if "WARNING" in x or "ERROR" in x]
(H/"verification.json").write_text(json.dumps({"passed":True,"checks":checks,"engine_warnings":warnings,"scope":"Private museum snapshot, injected native pointer events and controlled CharacterBody routes; no headset, learner or Quest performance acceptance."},indent=2)+"\n",encoding="utf-8")
manifest=[];patch=[]
for p in sorted((H/"before").rglob("*")):
 if not p.is_file():continue
 rel=p.relative_to(H/"before");after=H/"after"/rel;after.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(R/rel,after)
 manifest.append({"path":rel.as_posix(),"before_sha256":hashlib.sha256(p.read_bytes()).hexdigest(),"after_sha256":hashlib.sha256(after.read_bytes()).hexdigest()})
 if p.read_bytes()!=after.read_bytes():patch.extend(difflib.unified_diff(read(p).splitlines(True),read(after).splitlines(True),fromfile="before/"+rel.as_posix(),tofile="after/"+rel.as_posix()))
(H/"source-manifest.json").write_text(json.dumps(manifest,indent=2)+"\n",encoding="utf-8");(H/"changes.diff").write_text("".join(patch),encoding="utf-8")
css="body{margin:30px;background:#f5f1e9;color:#25332f;font:17px/1.6 system-ui}table.diff{width:100%;font:13px/1.5 ui-monospace}td{vertical-align:top;white-space:pre-wrap!important;overflow-wrap:anywhere}.diff_add{background:#d4f0d4}.diff_sub{background:#f7d6da}.diff_chg{background:#ffe7aa}.diff_header{background:#e4e4dc}"
diff=difflib.HtmlDiff(wrapcolumn=64).make_table(old.splitlines(),new.splitlines(),"Before","Current",context=True,numlines=3)
(H/"text-diff.html").write_text('<!doctype html><meta charset="utf-8"><title>Noise One · exact text differences</title><style>'+css+'</style><p><a href="index.html">Back to the museum review</a></p><h1>Two passages and a native museum figure</h1>'+diff,encoding="utf-8")
(H/"text.diff").write_text("".join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile="before/final.md",tofile="after/final.md")),encoding="utf-8")
figure=R/"doc/book/figures/Noise_One/standing-pair.png";check("book figure is an unchanged native image",figure.read_bytes()==(H/"room.png").read_bytes())
(H/"figure-provenance.json").write_text(json.dumps({"file":figure.relative_to(R).as_posix(),"source":"room.png","method":"Native actual museum render, declared held time 2 seconds, sample zero; no retouching","sha256":hashlib.sha256(figure.read_bytes()).hexdigest()},indent=2)+"\n",encoding="utf-8")
# Include the final image identity check in the published verification.
d=load(H/"verification.json");d["checks"]=checks;(H/"verification.json").write_text(json.dumps(d,indent=2)+"\n",encoding="utf-8")
print(len(checks),"preservation/publication checks passed.")
