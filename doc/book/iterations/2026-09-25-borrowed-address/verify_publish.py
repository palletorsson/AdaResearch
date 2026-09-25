from pathlib import Path
import re,json,hashlib,shutil,difflib,html
R=Path(__file__).resolve().parents[4];H=Path(__file__).resolve().parent
read=lambda p:p.read_text(encoding="utf-8-sig")
load=lambda p:json.loads(read(p))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
checks=[]
def check(name,ok):
 checks.append({"name":name,"passed":bool(ok)})
 if not ok:raise AssertionError(name)
for rel in ["commons/maps/Noise_Inside_Noise/map_data.json","commons/maps/sequences/noise.json","algorithms/randomness/noisesphere/noisesphere.gd","algorithms/randomness/noisesphere/noisesphere.tscn"]:
 check("preserved "+rel,(H/"before"/rel).read_bytes()==(R/rel).read_bytes())
oldstudy=read(H/"before/algorithms/randomness/noisesphere/warp_study.gd")
newstudy=read(R/"algorithms/randomness/noisesphere/warp_study.gd")
expected=oldstudy.replace("var relief: bool = false","var relief: bool = true")
# Only opt into relief on arrival and forward the existing selected direction.
line="\tif enclosure != null: enclosure.select_direction(PROBES[sample_index], self)\n"
check("shared sampler and all original controls preserved",newstudy.replace(line,"")==expected)
core=load(R/"commons/data/museum_core_encounters.json");oldcore=load(H/"before/commons/data/museum_core_encounters.json")
strip=lambda d:{k:v for k,v in d.items() if k not in ["text_sha256","map_sha256","local_review"]}
check("primary role and other hall metadata preserved",strip(core["rooms"]["Noise_Inside_Noise"])==strip(oldcore["rooms"]["Noise_Inside_Noise"]))
for key,name in [("text_sha256","final.md"),("map_sha256","map_data.json")]:check("current hash "+name,core["rooms"]["Noise_Inside_Noise"][key]==sha(R/"commons/maps/Noise_Inside_Noise"/name))
old=read(H/"before/commons/maps/Noise_Inside_Noise/final.md");new=read(R/"commons/maps/Noise_Inside_Noise/final.md")
check("all original mathematical excerpts retained",all(block in new for block in re.findall(r"```.*?```",old,re.S)))
check("encounter anchors and order retained",re.findall(r"<!-- @.*?-->",old)==re.findall(r"<!-- @.*?-->",new))
check("orb return and closing retained",old[old.index("<!-- @dark_sphere -->"):]==new[new.index("<!-- @dark_sphere -->"):])
check("projection and finite sampling argument retained",all(paragraph in new for paragraph in old.split("\n\n") if paragraph.startswith(("Walk to the side", "There is another small difference", "Look for a narrow streak", "At amount zero"))))
check("vertex shader excerpt is actual implementation","VERTEX += direction * UV.x * UV.y * relief_depth;" in read(R/"algorithms/randomness/noisesphere/enclosing_relief.gdshader") and "VERTEX += direction * UV.x * UV.y * relief_depth;" in new)
check("current notes keep dark orb supporting","supporting" in read(R/"commons/maps/Noise_Inside_Noise/artifacts.md"))
for part in ["museum-runtime.json","before-view/museum-runtime.json"]:
 d=load(H/part);check("passing native run "+part,d["passed"] and not d["failures"])
runtime=load(H/"museum-runtime.json")
check("65 focused native assertions",len(runtime["checks"])==65 and all(x["passed"] for x in runtime["checks"]))
for row in runtime["walks"]:check("body route: "+row["tag"],row["passed"])
for row in runtime["rays"]:check("floor ray: "+row["tag"],row["passed"])
check("15 synthetic clicks through actual museum pointer",len(runtime["desktop_input"])==15 and all(r["emissions"]==1 and r["hover_matches"] and r["clear_to_button"] for r in runtime["desktop_input"]))
check("no script or shader compile errors",not re.search("SCRIPT ERROR|SHADER ERROR|String formatting error|Failed to load script",read(H/"museum-process.log")))
check("book photograph is unmodified native capture",(R/"doc/book/figures/Noise_Inside_Noise/vertex-relief.png").read_bytes()==(H/"vertex-room.png").read_bytes())
manifest=[];patch=[]
for p in sorted((H/"before").rglob("*")):
 if not p.is_file():continue
 rel=p.relative_to(H/"before");after=H/"after"/rel;after.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(R/rel,after)
 manifest.append({"path":rel.as_posix(),"before_sha256":sha(p),"after_sha256":sha(after)})
 aa=read(p);bb=read(after)
 if rel.as_posix()=="commons/data/museum_core_encounters.json":aa=json.dumps(load(p)["rooms"]["Noise_Inside_Noise"],ensure_ascii=False,indent=2)+"\n";bb=json.dumps(load(after)["rooms"]["Noise_Inside_Noise"],ensure_ascii=False,indent=2)+"\n"
 if aa!=bb:patch.extend(difflib.unified_diff(aa.splitlines(True),bb.splitlines(True),fromfile="before/"+rel.as_posix(),tofile="after/"+rel.as_posix()))
rel=Path("algorithms/randomness/noisesphere/enclosing_relief.gdshader");after=H/"after"/rel;after.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(R/rel,after)
manifest.append({"path":rel.as_posix(),"before_sha256":None,"after_sha256":sha(after),"new":True})
patch.extend(difflib.unified_diff([],read(after).splitlines(True),fromfile="/dev/null",tofile="after/"+rel.as_posix()))
(H/"source-manifest.json").write_text(json.dumps(manifest,indent=2)+"\n",encoding="utf-8")
(H/"changes.diff").write_text("".join(patch),encoding="utf-8")
css="body{margin:30px;background:#f5f1e9;color:#25332f;font:17px/1.6 system-ui}table.diff{width:100%;font:13px/1.5 ui-monospace}td{vertical-align:top;white-space:pre-wrap!important;overflow-wrap:anywhere}.diff_add{background:#d4f0d4}.diff_sub{background:#f7d6da}.diff_chg{background:#ffe7aa}.diff_header{background:#e4e4dc}"
diff=difflib.HtmlDiff(wrapcolumn=64).make_table(old.splitlines(),new.splitlines(),"Before: fixed enclosing sphere","Now: enclosing vertex relief",context=True,numlines=3)
diff="\n".join(line.rstrip() for line in diff.splitlines())
(H/"text-diff.html").write_text('<!doctype html><meta charset="utf-8"><title>Noise Inside Noise — text comparison</title><style>'+css+'</style><p><a href="index.html">Back to review</a></p><h1>The enclosing body receives relief</h1>'+diff,encoding="utf-8")
(H/"text.diff").write_text("".join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile="before/final.md",tofile="after/final.md")),encoding="utf-8")
(H/"verification.json").write_text(json.dumps({"passed":True,"checks":checks,"engine_warnings":[l for l in read(H/"museum-process.log").splitlines() if "WARNING" in l or "ERROR" in l],"other_core_records_changed_concurrently":[k for k,v in oldcore["rooms"].items() if k!="Noise_Inside_Noise" and core["rooms"].get(k)!=v],"scope":runtime["scope"]},indent=2)+"\n",encoding="utf-8")
print(len(checks),"preservation/publication checks passed")
