from pathlib import Path
import re,json,hashlib,shutil,difflib,html
R=Path(__file__).resolve().parents[4];H=Path(__file__).resolve().parent
read=lambda p:p.read_text(encoding="utf-8-sig")
load=lambda p:json.loads(read(p))
save=lambda p,d:p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
checks=[]
def check(label,ok):
 checks.append({"name":label,"passed":bool(ok)})
 if not ok:raise AssertionError(label)
# Stable native figure for the current manuscript; snapshots remain independently reviewable.
F=R/"doc/book/figures/Noise_Columns";F.mkdir(parents=True,exist_ok=True)
shutil.copy2(H/"room.png",F/"three-columns.png")
p=R/"commons/maps/Noise_Columns/final.md";text=read(p)
image="![Three columns inside the museum, viewed from the standing approach before their drivers are revealed.](/book-review/doc/book/figures/Noise_Columns/three-columns.png)"
if image not in text:
 needle="watch for a while before you press anything."
 assert text.count(needle)==1
 text=text.replace(needle,needle+"\n\n"+image)
 p.write_text(text,encoding="utf-8")
core_path=R/"commons/data/museum_core_encounters.json";core=load(core_path);core["rooms"]["Noise_Columns"]["text_sha256"]=hashlib.sha256(p.read_bytes()).hexdigest();save(core_path,core)
manifest=[]
for before in sorted((H/"before").rglob("*")):
 if not before.is_file():continue
 rel=before.relative_to(H/"before");now=R/rel;after=H/"after"/rel;after.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(now,after)
 manifest.append({"path":rel.as_posix(),"before_sha256":hashlib.sha256(before.read_bytes()).hexdigest(),"after_sha256":hashlib.sha256(after.read_bytes()).hexdigest()})
save(H/"source-manifest.json",manifest)
original=read(H/"before/commons/maps/Noise_Columns/final.md");current=read(p)
# Only three intended prose paragraphs changed, plus the figure. All anchors/code and later prose remain exact.
oldparagraphs=original.strip().split("\n\n");newparagraphs=current.strip().split("\n\n")
changed=[]
for i,paragraph in enumerate(oldparagraphs):
 if paragraph not in newparagraphs:changed.append(i)
check("exactly three original prose paragraphs changed",len(changed)==3)
check("all code excerpts preserved",re.findall(r"```.*?```",original,re.S)==re.findall(r"```.*?```",current,re.S))
check("all encounter anchors preserved",re.findall(r"<!-- @([^ ]+) -->",original)==re.findall(r"<!-- @([^ ]+) -->",current))
check("all prose after the scalar comparison retained",original[original.index("```gdscript\nvar melt_factor"):]==current[current.index("```gdscript\nvar melt_factor"):])
maprel=Path("commons/maps/Noise_Columns/map_data.json")
check("map bytes unchanged: no artifact or structural loss",(H/"before"/maprel).read_bytes()==(R/maprel).read_bytes())
source=Path("algorithms/proceduralgeneration/hybrid_complex/berninicolumns/MeltingBerniniColumns.gd")
def funcs(s):return {m.group(1):m.group(0) for m in re.finditer(r"^func (\w+)\(.*?(?=^func |\Z)",s,re.S|re.M)}
a=funcs(read(H/"before"/source));b=funcs(read(R/source))
check("same set of production methods",a.keys()==b.keys())
for name in a:
 if name not in ["_build_trio","_update_trio_readout"]:check("unchanged method: "+name,a[name]==b[name])
check("no non-trio/configuration changes",read(H/"before"/source).split("func _build_trio")[0]==read(R/source).split("func _build_trio")[0])
seq=load(R/"commons/maps/sequences/noise.json");seq_old=load(H/"before/commons/maps/sequences/noise.json")
expected=["MeltingBerniniScene","dark_sphere","synthesis_stand"]
q=seq["sequences"]["noise"];oldq=seq_old["sequences"]["noise"]
check("sequence order unchanged",q["maps"]==oldq["maps"])
check("three existing book encounters match core",core["rooms"]["Noise_Columns"]["primary_tokens"]==expected)
check("three existing encounters match sequence group",next(x for x in q["artifact_groups"] if x["map"]=="Noise_Columns")["artifacts"]==expected)
for item in oldq["artifact_groups"]:
 if item["map"]!="Noise_Columns":check("other group preserved: "+item["map"],item==next(x for x in q["artifact_groups"] if x["map"]==item["map"]))
registryrel=Path("commons/artifacts/registry/randomness.json");reg=load(R/registryrel)["artifacts"];oldreg=load(H/"before"/registryrel)["artifacts"]
check("registry entries preserved",reg.keys()==oldreg.keys())
check("other registry entries unchanged",all(reg[k]==v for k,v in oldreg.items() if k!="MeltingBerniniScene"))
# Current shared core may receive independent work; list it without concealing or overwriting it.
oldcore=load(H/"before/commons/data/museum_core_encounters.json")["rooms"]
concurrent=[k for k in core["rooms"] if k!="Noise_Columns" and core["rooms"][k]!=oldcore.get(k)]
check("no unrelated core records lost",all(k in core["rooms"] for k in oldcore))
check("map hash still current",core["rooms"]["Noise_Columns"]["map_sha256"]==hashlib.sha256((R/maprel).read_bytes()).hexdigest())
check("learner verification stays pending",core["rooms"]["Noise_Columns"]["learner_verified"] is False)
runtime=load(H/"museum-runtime.json")
check("native museum passed",runtime["passed"])
check("four walking approaches passed",len(runtime["walks"])==4 and all(x["passed"] for x in runtime["walks"]))
check("floor ray passed",all(x["passed"] for x in runtime["rays"]))
log=read(H/"museum-process.log")
check("no script or shader compile error",not re.search(r"SCRIPT ERROR|SHADER ERROR",log))
save(H/"verification.json",{"checks":checks,"passed":True,"concurrent_core_changes":concurrent,"runtime_checks":len(runtime["checks"]),"walks":len(runtime["walks"]),"limits":"Private museum snapshot. Controlled desktop pointer and CharacterBody paths. No headset, learner, Quest or full-sequence acceptance; live bake and save untouched."})
css="body{margin:30px;background:#f5f1e9;color:#25332f;font:17px/1.6 system-ui}table.diff{width:100%;font:13px/1.5 ui-monospace}td{vertical-align:top;white-space:pre-wrap!important;overflow-wrap:anywhere}.diff_add{background:#d4f0d4}.diff_sub{background:#f7d6da}.diff_chg{background:#ffe7aa}.diff_header{background:#e4e4dc}"
diff=difflib.HtmlDiff(wrapcolumn=66).make_table(original.splitlines(),current.splitlines(),"Before","Current",context=True,numlines=3)
(H/"text-diff.html").write_text('<!doctype html><meta charset="utf-8"><title>Noise Columns · exact text differences</title><style>'+css+'</style><p><a href="index.html">Back to the museum review</a></p><h1>Three paragraphs and one native figure</h1>'+diff,encoding="utf-8")
(H/"text.diff").write_text("".join(difflib.unified_diff(original.splitlines(True),current.splitlines(True),fromfile="before/final.md",tofile="after/final.md")),encoding="utf-8")
(H/"changes.diff").write_text("".join("".join(difflib.unified_diff(read(H/"before"/row["path"]).splitlines(True),read(H/"after"/row["path"]).splitlines(True),fromfile="before/"+row["path"],tofile="after/"+row["path"])) for row in manifest if row["before_sha256"]!=row["after_sha256"]),encoding="utf-8")
print(f"{len(checks)} preservation/publication checks; {len(runtime['checks'])} museum checks, four walks, one floor ray passed.")
print("Concurrent core changes:",concurrent)
