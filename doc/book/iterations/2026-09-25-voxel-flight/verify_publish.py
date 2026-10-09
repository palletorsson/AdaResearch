from pathlib import Path
import re,json,hashlib,shutil,difflib
R=Path(__file__).resolve().parents[4];H=Path(__file__).resolve().parent
read=lambda p:p.read_text(encoding="utf-8-sig")
load=lambda p:json.loads(read(p))
checks=[]
def check(name,ok):
 checks.append({"name":name,"passed":bool(ok)})
 if not ok:raise AssertionError(name)
a=load(H/"before/commons/maps/Noise_Voxel/map_data.json");b=load(R/"commons/maps/Noise_Voxel/map_data.json")
check("33 by 44 hall with room for 28 m enclosure",b["map_info"]["dimensions"]=={"width":33,"depth":44,"max_height":28})
for layer,rows in b["layers"].items():check("rectangular layer "+layer,len(rows)==44 and all(len(row)==33 for row in rows))
check("recovered interior structure preserved at x+9",all(b["layers"]["structure"][z][x+9]==a["layers"]["structure"][z][x] for z in range(1,15) for x in range(1,14)))
oldutilities=[(x,z,v) for z,row in enumerate(a["layers"]["utilities"]) for x,v in enumerate(row) if v.strip()]
check("every recovered utility retained",all(b["layers"]["utilities"][z][x+9]==v for x,z,v in oldutilities) and sum(bool(v.strip()) for row in b["layers"]["utilities"] for v in row)==len(oldutilities))
artifacts=[v for row in b["layers"]["interactables"] for v in row if v.strip()]
check("all four artifacts retained",len(artifacts)==4 and sorted(v.split(":")[0].split("#")[0] for v in artifacts)==["dark_sphere","perlin_terrain_sculptor","science_screen","voxelnoise"])
check("one metre flight placement",b["layers"]["interactables"][24][16]=="voxelnoise:180#stand:volume#cell_size:1#flight_box:true")
check("bench and screen retain height/config",b["layers"]["interactables"][7][13]==a["layers"]["interactables"][7][4] and b["layers"]["interactables"][4][18]==a["layers"]["interactables"][4][9])
for rel in ["commons/maps/sequences/noise.json","commons/maps/Noise_Voxel/artifact_roles.json","commons/movement/museum_flight_provider.gd"]:check("unchanged file or absence: "+rel,((H/"before"/rel).read_bytes()==(R/rel).read_bytes()) if (H/"before"/rel).exists() else not (R/rel).exists())
def funcs(s):return {m.group(1):m.group(0).rstrip() for m in re.finditer(r"^(?:static )?func (\w+)\(.*?(?=^(?:static )?func |\Z)",s,re.M|re.S)}
rel="algorithms/randomness/voxelnoise/voxelnoise.gd";oldf=funcs(read(H/"before"/rel));newf=funcs(read(R/rel))
for name in ["_generate_chunk","_add_volume_boundary","_effective_iso","_configure_noise","_rebuild_now","_clear_generated","apply_perlin_terrain_controls","apply_perlin_cell_selection"]:check("unchanged core function: "+name,oldf[name]==newf[name])
rel="commons/movement/museum_flight_box.gd";oldf=funcs(read(H/"before"/rel));newf=funcs(read(R/rel))
for name in oldf:check("flight function preserved apart from dimension parameter: "+name,oldf[name]==newf[name].replace("edge_length","EDGE"))
core=load(R/"commons/data/museum_core_encounters.json");before=load(H/"before/commons/data/museum_core_encounters.json")
check("roles and all other hall metadata preserved",{k:v for k,v in core["rooms"]["Noise_Voxel"].items() if k not in ["text_sha256","map_sha256","local_review"]}=={k:v for k,v in before["rooms"]["Noise_Voxel"].items() if k not in ["text_sha256","map_sha256","local_review"]})
for key,name in [("text_sha256","final.md"),("map_sha256","map_data.json")]:check("current hash: "+name,core["rooms"]["Noise_Voxel"][key]==hashlib.sha256((R/"commons/maps/Noise_Voxel"/name).read_bytes()).hexdigest())
old=read(H/"before/commons/maps/Noise_Voxel/final.md");new=read(R/"commons/maps/Noise_Voxel/final.md")
check("code excerpts retained",re.findall(r"```.*?```",old,re.S)==re.findall(r"```.*?```",new,re.S))
check("encounter anchors retained",re.findall(r"<!-- @.*?-->",old)==re.findall(r"<!-- @.*?-->",new))
check("opening threshold argument preserved",old[:old.index("A thin yellow square")]==new[:new.index("A thin yellow square")])
check("component/orb/closing arguments retained",old[old.index("The plate counts groups"):]==new[new.index("The plate counts groups"):])
reg=load(R/"commons/artifacts/registry/randomness.json");oldreg=load(H/"before/commons/artifacts/registry/randomness.json")
check("other registry artifacts preserved",{k:v for k,v in reg["artifacts"].items() if k!="voxelnoise"}=={k:v for k,v in oldreg["artifacts"].items() if k!="voxelnoise"})
check("only voxel description/parameter docs changed",{k:v for k,v in reg["artifacts"]["voxelnoise"].items() if k not in ["description","parameters"]}=={k:v for k,v in oldreg["artifacts"]["voxelnoise"].items() if k not in ["description","parameters"]})
for file,n in [("museum-runtime.json",69),("views-runtime.json",4)]:
 d=load(H/file);check("passing native run "+file,d["passed"] and len(d["checks"])==n and all(x["passed"] for x in d["checks"]))
 for ray in d.get("rays",[]):check("floor ray: "+ray["tag"],ray["passed"])
for file in ["museum-process.log","views-process.log"]:check("no script/shader/caption errors in "+file,not re.search("SCRIPT ERROR|SHADER ERROR|String formatting error|Failed to load script",read(H/file)))
check("book figure unmodified",(R/"doc/book/figures/Noise_Voxel/flight-from-above.png").read_bytes()==(H/"above-volume.png").read_bytes())
manifest=[];patch=[]
for p in sorted((H/"before").rglob("*")):
 if not p.is_file():continue
 rel=p.relative_to(H/"before");after=H/"after"/rel;after.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(R/rel,after)
 manifest.append({"path":rel.as_posix(),"before_sha256":hashlib.sha256(p.read_bytes()).hexdigest(),"after_sha256":hashlib.sha256(after.read_bytes()).hexdigest()})
 aa=read(p);bb=read(after)
 if rel.as_posix()=="commons/data/museum_core_encounters.json":aa=json.dumps(load(p)["rooms"]["Noise_Voxel"],ensure_ascii=False,indent=2)+"\n";bb=json.dumps(load(after)["rooms"]["Noise_Voxel"],ensure_ascii=False,indent=2)+"\n"
 if rel.as_posix()=="commons/artifacts/registry/randomness.json":aa=json.dumps(load(p)["artifacts"]["voxelnoise"],ensure_ascii=False,indent=2)+"\n";bb=json.dumps(load(after)["artifacts"]["voxelnoise"],ensure_ascii=False,indent=2)+"\n"
 if aa!=bb:patch.extend(difflib.unified_diff(aa.splitlines(True),bb.splitlines(True),fromfile="before/"+rel.as_posix(),tofile="after/"+rel.as_posix()))
(H/"source-manifest.json").write_text(json.dumps(manifest,indent=2)+"\n",encoding="utf-8")
(H/"changes.diff").write_text("".join(patch),encoding="utf-8")
css="body{margin:30px;background:#f5f1e9;color:#25332f;font:17px/1.6 system-ui}table.diff{width:100%;font:13px/1.5 ui-monospace}td{vertical-align:top;white-space:pre-wrap!important;overflow-wrap:anywhere}.diff_add{background:#d4f0d4}.diff_sub{background:#f7d6da}.diff_chg{background:#ffe7aa}.diff_header{background:#e4e4dc}"
diff=difflib.HtmlDiff(wrapcolumn=64).make_table(old.splitlines(),new.splitlines(),"Before: 20 cm cells","Current: metre cells and flight",context=True,numlines=3)
(H/"text-diff.html").write_text('<!doctype html><meta charset="utf-8"><title>Noise Voxel Â· flight text changes</title><style>'+css+'</style><p><a href="index.html">Back to review</a></p><h1>A body that can rise</h1>'+diff,encoding="utf-8")
(H/"text.diff").write_text("".join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile="before/final.md",tofile="after/final.md")),encoding="utf-8")
(H/"verification.json").write_text(json.dumps({"passed":True,"checks":checks,"engine_warnings":[l for file in ["museum-process.log","views-process.log"] for l in read(H/file).splitlines() if "WARNING" in l or "ERROR" in l],"other_core_records_changed_concurrently":[k for k,v in before["rooms"].items() if k!="Noise_Voxel" and core["rooms"].get(k)!=v],"scope":"Actual museum, synthetic keyboard/controller input, physical collision and private probe files. No headset acceptance."},indent=2)+"\n",encoding="utf-8")
print(len(checks),"preservation/publication checks passed")
