from pathlib import Path
import re,json,hashlib,shutil,difflib
R=Path(__file__).resolve().parents[4];H=Path(__file__).resolve().parent
read=lambda p:p.read_text(encoding="utf-8-sig")
load=lambda p:json.loads(read(p))
checks=[]
def check(name,ok):
 checks.append({"name":name,"passed":bool(ok)})
 if not ok:raise AssertionError(name)
rel="commons/maps/Noise_Voxel/map_data.json";a=load(H/"before"/rel);b=load(R/rel)
for layer,rows in a["layers"].items():
 for z,row in enumerate(rows):
  for x,v in enumerate(row):
   if "voxelnoise#stand:volume" in str(v):a["layers"][layer][z][x]=v.replace("voxelnoise#stand:volume","voxelnoise:180#stand:volume")
a["map_info"]["description"]=b["map_info"]["description"]
check("only volume yaw and map description changed",a==b)
for rel in ["commons/maps/sequences/noise.json","commons/maps/Noise_Voxel/artifact_roles.json"]:
 if (H/"before"/rel).exists():check("unchanged: "+rel,(H/"before"/rel).read_bytes()==(R/rel).read_bytes())
def funcs(s):return {m.group(1):m.group(0).rstrip() for m in re.finditer(r"^(?:static )?func (\w+)\(.*?(?=^(?:static )?func |\Z)",s,re.M|re.S)}
for rel,names in [("commons/artifacts/perlin_terrain_sculptor/perlin_terrain_sculptor.gd",["contract_noise","contract_value","contract_bias","contract_occupied","_generate_terrain","_rebuild_multimesh","toggle_cut","cell_report","occupancy_report"]),("algorithms/randomness/voxelnoise/voxelnoise.gd",["_generate_chunk","_add_volume_boundary","_effective_iso","_configure_noise","_rebuild_now","_clear_generated"])]:
 a=funcs(read(H/"before"/rel));b=funcs(read(R/rel))
 for name in names:check("unchanged algorithm: "+name,a[name]==b[name])
old=read(H/"before/commons/maps/Noise_Voxel/final.md");new=read(R/"commons/maps/Noise_Voxel/final.md")
check("only one former paragraph altered",sum(p not in new.strip().split("\n\n") for p in old.strip().split("\n\n"))==1)
check("code excerpts retained",re.findall(r"```.*?```",old,re.S)==re.findall(r"```.*?```",new,re.S))
check("all encounter anchors retained",re.findall(r"<!-- @.*?-->",old)==re.findall(r"<!-- @.*?-->",new))
check("entire volume/orb/closing argument retained",old[old.index("<!-- @voxelnoise -->"):]==new[new.index("<!-- @voxelnoise -->"):])
core=load(R/"commons/data/museum_core_encounters.json");prior=load(H/"before/commons/data/museum_core_encounters.json")
check("Noise Voxel roles and other metadata retained",{k:v for k,v in core["rooms"]["Noise_Voxel"].items() if k not in ["text_sha256","map_sha256","local_review"]}=={k:v for k,v in prior["rooms"]["Noise_Voxel"].items() if k not in ["text_sha256","map_sha256","local_review"]})
for key,name in [("text_sha256","final.md"),("map_sha256","map_data.json")]:check("current hash: "+name,core["rooms"]["Noise_Voxel"][key]==hashlib.sha256((R/"commons/maps/Noise_Voxel"/name).read_bytes()).hexdigest())
rt=load(H/"museum-runtime.json");check("42 native checks pass",rt["passed"] and len(rt["checks"])==42 and all(c["passed"] for c in rt["checks"]))
check("six walking segments pass",len(rt["walks"])==6 and all(c["passed"] for c in rt["walks"]))
check("two floor rays pass",len(rt["rays"])==2 and all(c["passed"] for c in rt["rays"]))
log=read(H/"museum-process.log");check("no script/shader errors",not re.search(r"SCRIPT ERROR|SHADER ERROR",log))
figure=R/"doc/book/figures/Noise_Voxel/selected-slice.png";check("figure is unmodified native render",figure.read_bytes()==(H/"slice-low.png").read_bytes())
manifest=[];patch=[]
for p in sorted((H/"before").rglob("*")):
 if not p.is_file():continue
 rel=p.relative_to(H/"before");after=H/"after"/rel;after.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(R/rel,after)
 manifest.append({"path":rel.as_posix(),"before_sha256":hashlib.sha256(p.read_bytes()).hexdigest(),"after_sha256":hashlib.sha256(after.read_bytes()).hexdigest()})
 aa=read(p);bb=read(after)
 if rel.as_posix()=="commons/data/museum_core_encounters.json":
  aa=json.dumps(load(p)["rooms"]["Noise_Voxel"],ensure_ascii=False,indent=2)+"\n";bb=json.dumps(load(after)["rooms"]["Noise_Voxel"],ensure_ascii=False,indent=2)+"\n"
 if aa!=bb:patch.extend(difflib.unified_diff(aa.splitlines(True),bb.splitlines(True),fromfile="before/"+rel.as_posix(),tofile="after/"+rel.as_posix()))
(H/"source-manifest.json").write_text(json.dumps(manifest,indent=2)+"\n",encoding="utf-8")
(H/"changes.diff").write_text("".join(patch),encoding="utf-8")
css="body{margin:30px;background:#f5f1e9;color:#25332f;font:17px/1.6 system-ui}table.diff{width:100%;font:13px/1.5 ui-monospace}td{vertical-align:top;white-space:pre-wrap!important;overflow-wrap:anywhere}.diff_add{background:#d4f0d4}.diff_sub{background:#f7d6da}.diff_chg{background:#ffe7aa}.diff_header{background:#e4e4dc}"
diff=difflib.HtmlDiff(wrapcolumn=64).make_table(old.splitlines(),new.splitlines(),"Before","Current",context=True,numlines=3)
(H/"text-diff.html").write_text('<!doctype html><meta charset="utf-8"><title>Noise Voxel · exact text differences</title><style>'+css+'</style><p><a href="index.html">Back to the museum review</a></p><h1>One phrase, one encounter, one native photograph</h1>'+diff,encoding="utf-8")
(H/"text.diff").write_text("".join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile="before/final.md",tofile="after/final.md")),encoding="utf-8")
(H/"figure-provenance.json").write_text(json.dumps({"file":figure.relative_to(R).as_posix(),"source":"slice-low.png","method":"Unretouched actual museum render; camera eye 1.7 m; selected cell (17,6,9), frame 1.3 m; threshold 0; seed 31415","sha256":hashlib.sha256(figure.read_bytes()).hexdigest()},indent=2)+"\n",encoding="utf-8")
(H/"verification.json").write_text(json.dumps({"passed":True,"checks":checks,"engine_warnings":[l for l in log.splitlines() if "WARNING" in l or "ERROR" in l],"other_core_records_changed_concurrently":[k for k,v in prior["rooms"].items() if k!="Noise_Voxel" and core["rooms"].get(k)!=v],"scope":"Private actual museum; injected native button events and controlled walking. No headset, ray aiming, learner or Quest acceptance."},indent=2)+"\n",encoding="utf-8")
print(len(checks),"preservation/publication checks passed")
