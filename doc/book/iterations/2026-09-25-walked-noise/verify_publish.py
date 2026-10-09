from pathlib import Path
import re,json,hashlib,shutil,difflib
R=Path(__file__).resolve().parents[4];H=Path(__file__).resolve().parent
read=lambda p:p.read_text(encoding="utf-8-sig")
load=lambda p:json.loads(read(p))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
checks=[]
def check(name,ok):
 checks.append({"name":name,"passed":bool(ok)})
 if not ok:raise AssertionError(name)
for rel in ["commons/maps/Noise_Space_10/map_data.json","commons/maps/sequences/noise.json","commons/context/walkgrids/NoiseSpace.gd","commons/context/walkgrids/noise_space.tscn","commons/context/walkgrids/TopologySpace.gd","commons/maps/Noise_Space_10/critical.md"]:
 check("preserved "+rel,(H/"before"/rel).read_bytes()==(R/rel).read_bytes())
rel="commons/context/walkgrids/noise_walk_study.gd"
expected=read(H/"before"/rel).replace("var ground: Node3D","var ground: Node3D\nvar walked_trail: Node3D",1)
expected=expected.replace('\trefresh_profile()\n\nfunc can_rebuild()', '\trefresh_profile()\n\twalked_trail = load("res://commons/context/walkgrids/noise_walk_trace.gd").new()\n\tadd_child(walked_trail)\n\twalked_trail.build(ground)\n\nfunc can_rebuild()',1)
expected=expected.replace('\theight_index = clampi(index,0,HEIGHTS.size()-1)','\tif walked_trail != null: walked_trail.clear()\n\theight_index = clampi(index,0,HEIGHTS.size()-1)',1)
check("only attach recorder and clear after accepted height changes",read(R/rel)==expected)
old=read(H/"before/commons/maps/Noise_Space_10/final.md");new=read(R/"commons/maps/Noise_Space_10/final.md")
check("all original code excerpts retained",re.findall(r"```.*?```",old,re.S)==re.findall(r"```.*?```",new,re.S))
check("all original paragraphs retained except ROUTE B observation",all(par in new for par in old.split("\n\n") if not par.startswith("Now choose ROUTE B.")))
check("anchors and order retained",re.findall(r"<!-- @.*?-->",old)==re.findall(r"<!-- @.*?-->",new))
check("dated measurements, cave and shelter argument retained",old[old.index("The display gives"):]==new[new.index("The display gives"):])
core=load(R/"commons/data/museum_core_encounters.json");oldcore=load(H/"before/commons/data/museum_core_encounters.json")
strip=lambda d:{k:v for k,v in d.items() if k not in ["text_sha256","map_sha256","local_review"]}
check("primary selection and other metadata retained",strip(core["rooms"]["Noise_Space_10"])==strip(oldcore["rooms"]["Noise_Space_10"]))
for key,name in [("text_sha256","final.md"),("map_sha256","map_data.json")]:check("current hash "+name,core["rooms"]["Noise_Space_10"][key]==sha(R/"commons/maps/Noise_Space_10"/name))
runtime=load(H/"museum-runtime.json")
check("native run passed",runtime["passed"] and not runtime["failures"])
check("30 focused native assertions",len(runtime["checks"])==30 and all(x["passed"] for x in runtime["checks"]))
check("7 synthetic clicks through museum pointer",len(runtime["desktop_input"])==7 and all(r["emissions"]==1 and r["hover_matches"] and r["clear_to_button"] for r in runtime["desktop_input"]))
check("no script or shader errors",not re.search("SCRIPT ERROR|SHADER ERROR|Failed to load script",read(H/"museum-process.log")))
check("book image unmodified",(R/"doc/book/figures/Noise_Space_10/walked-route.png").read_bytes()==(H/"walked-room.png").read_bytes())
manifest=[];patch=[]
for p in sorted((H/"before").rglob("*")):
 if not p.is_file():continue
 rel=p.relative_to(H/"before");after=H/"after"/rel;after.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(R/rel,after)
 manifest.append({"path":rel.as_posix(),"before_sha256":sha(p),"after_sha256":sha(after)})
 aa=read(p);bb=read(after)
 if rel.as_posix()=="commons/data/museum_core_encounters.json":aa=json.dumps(load(p)["rooms"]["Noise_Space_10"],ensure_ascii=False,indent=2)+"\n";bb=json.dumps(load(after)["rooms"]["Noise_Space_10"],ensure_ascii=False,indent=2)+"\n"
 if aa!=bb:patch.extend(difflib.unified_diff(aa.splitlines(True),bb.splitlines(True),fromfile="before/"+rel.as_posix(),tofile="after/"+rel.as_posix()))
rel=Path("commons/context/walkgrids/noise_walk_trace.gd");after=H/"after"/rel;after.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(R/rel,after)
manifest.append({"path":rel.as_posix(),"before_sha256":None,"after_sha256":sha(after),"new":True})
patch.extend(difflib.unified_diff([],read(after).splitlines(True),fromfile="/dev/null",tofile="after/"+rel.as_posix()))
(H/"source-manifest.json").write_text(json.dumps(manifest,indent=2)+"\n",encoding="utf-8")
(H/"changes.diff").write_text("".join(patch),encoding="utf-8")
css="body{margin:30px;background:#f5f1e9;color:#25332f;font:17px/1.6 system-ui}table.diff{width:100%;font:13px/1.5 ui-monospace}td{vertical-align:top;white-space:pre-wrap!important;overflow-wrap:anywhere}.diff_add{background:#d4f0d4}.diff_sub{background:#f7d6da}.diff_chg{background:#ffe7aa}.diff_header{background:#e4e4dc}"
diff=difflib.HtmlDiff(wrapcolumn=64).make_table(old.splitlines(),new.splitlines(),"Before: a proposed route","Now: the walk leaves a line",context=True,numlines=3)
diff="\n".join(line.rstrip() for line in diff.splitlines())
(H/"text-diff.html").write_text('<!doctype html><meta charset="utf-8"><title>Noise Space 10 — text comparison</title><style>'+css+'</style><p><a href="index.html">Back to review</a></p><h1>The walk leaves a line</h1>'+diff,encoding="utf-8")
(H/"text.diff").write_text("".join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile="before/final.md",tofile="after/final.md")),encoding="utf-8")
(H/"verification.json").write_text(json.dumps({"passed":True,"checks":checks,"engine_warnings":[l for l in read(H/"museum-process.log").splitlines() if "WARNING" in l or "ERROR" in l],"other_core_records_changed_concurrently":[k for k,v in oldcore["rooms"].items() if k!="Noise_Space_10" and core["rooms"].get(k)!=v],"scope":runtime["scope"]},indent=2)+"\n",encoding="utf-8")
print(len(checks),"preservation/publication checks passed")
