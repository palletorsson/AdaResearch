import io, json, os, re, glob, collections

ROOT = r"C:\Users\palle\Documents\GitHub\AdaResearch_46"
def read(p):
    try: return io.open(p, encoding='utf-8', errors='replace').read()
    except Exception: return ""
def res(p): return os.path.join(ROOT, p.replace("res://", "").replace("/", os.sep))

tok2scene = {}
for rf in glob.glob(os.path.join(ROOT, "commons/artifacts/registry/*.json")):
    try: d = json.loads(read(rf))
    except Exception: continue
    if not isinstance(d, dict): continue
    d = d.get("artifacts", d)
    if not isinstance(d, dict): continue
    for tok, ent in d.items():
        if isinstance(ent, dict):
            sp = ent.get("scene") or ent.get("scene_path")
            if isinstance(sp, str) and sp.endswith(".tscn"):
                tok2scene[tok] = sp

rx_script = re.compile(r'path="(res://[^"]+\.gd)"')
tok2scripts = {}
for tok, sp in tok2scene.items():
    fp = res(sp)
    tok2scripts[tok] = rx_script.findall(read(fp)) if os.path.exists(fp) else []

# ---------------- rung tests, each a single decidable grep ------------------
CFG   = re.compile(r"func apply_grid_config")

TOUCH = re.compile(r"InteractableArea"
                   r"|\bbutton_pressed\b"
                   r"|\bslider_moved\b"
                   r"|is_button_pressed"
                   r"|_on_body_entered"
                   r"|func _input\s*\("
                   r"|func _unhandled_input\s*\("
                   r"|XRToolsPickable|\bpicked_up\b|\bdropped\b")

# DRIVEN = both halves must hold.
#   3a: the artifact OWNS a live position source (body, or handles it spawned)
DRIVE_SRC = re.compile(r"XROrigin3D|xr_origin"
                       r"|GRAB_SPHERE|HANDLE_SCENE|grab_sphere_point"
                       r"|_grab_point|draw_sphere|_draw_sphere"
                       r"|get_camera_3d\s*\(\)")
#   3b: that position enters a container the algorithm iterates, or rebuilds it
DRIVE_SINK = re.compile(r"(_?(trail_)?points|vertices|_pts|samples|handles|nodes|seeds|_loop)"
                        r"\s*\.\s*append\s*\("
                        r"|_handles_changed|_update_geometry_from_handles"
                        r"|_rebuild_(trail|mesh|final_mesh|ghost)"
                        r"|surface_add_vertex\s*\(\s*_?\w*points")

AUTHOR = re.compile(r"/root/TraceData|\bTraceData\."
                    r"|\badd_trace\b|\bsave_pattern\b|\bget_all_traces\b|\bget_pattern\b"
                    r"|_save_map_over_http|MAP_SAVE_URL|save-layers"
                    r"|FileAccess\.open\([^)]*WRITE|ResourceSaver\.save")

def classify(gds):
    txt = "\n".join(read(res(g)) for g in gds if os.path.exists(res(g)))
    if not txt.strip(): return None, {}
    f = dict(cfg=bool(CFG.search(txt)),
             touch=bool(TOUCH.search(txt)),
             drive=bool(DRIVE_SRC.search(txt)) and bool(DRIVE_SINK.search(txt)),
             author=bool(AUTHOR.search(txt)))
    if   f["author"] and (f["drive"] or f["touch"]): r = 4
    elif f["drive"]:                                 r = 3
    elif f["touch"]:                                 r = 2
    elif f["cfg"]:                                   r = 1
    else:                                            r = 0
    return r, f

rung, flags = {}, {}
for tok, gds in tok2scripts.items():
    r, f = classify(gds)
    if r is not None: rung[tok], flags[tok] = r, f

h = collections.Counter(rung.values()); n = len(rung)
print("=== CORPUS: %d registry tokens with a reachable script ===" % n)
for r in range(5):
    print("  rung %d : %5d  (%4.1f%%)" % (r, h[r], 100.0*h[r]/n))
print("  rung>=2 (ACTIVATED): %d  (%.1f%%)" % (h[2]+h[3]+h[4], 100.0*(h[2]+h[3]+h[4])/n))
print("  rung>=3 (DRIVEN+)  : %d  (%.1f%%)" % (h[3]+h[4], 100.0*(h[3]+h[4])/n))

spine = json.loads(read(os.path.join(ROOT, "commons/maps/curriculum_spine.json")))
order = [s["name"] for s in spine["spine"]["sequences"]]

def seq_maps(name):
    fp = os.path.join(ROOT, "commons/maps/sequences", name + ".json")
    if not os.path.exists(fp): return []
    d = json.loads(read(fp)); out = []
    for sid, s in (d.get("sequences") or {}).items():
        for m in s.get("maps", []):
            out.append(m if isinstance(m, str) else (m.get("map_id") or m.get("name")))
    return out

def map_tokens(mn):
    fp = os.path.join(ROOT, "commons/maps", mn, "map_data.json")
    if not os.path.exists(fp): return None
    try: d = json.loads(read(fp))
    except Exception: return None
    toks = []
    for row in d.get("layers", {}).get("interactables", []):
        if isinstance(row, list):
            for c in row:
                if isinstance(c, str) and c.strip() and c.strip() != "-":
                    toks.append(c.split(":")[0].split("#")[0].strip())
    return toks

print("\n=== 22 SPINE SEQUENCES (spine order) ===")
print("%-2s %-22s %4s %4s | %4s %4s %4s %4s %4s | %3s %6s %6s" % (
    "#","sequence","maps","plc","r0","r1","r2","r3","r4","top","act%","dri%"))
tally = []
for i, name in enumerate(order, 1):
    maps = seq_maps(name); toks = []
    for mn in maps:
        t = map_tokens(mn)
        if t: toks += t
    rs = [rung[t] for t in toks if t in rung]
    if not rs:
        print("%-2d %-22s %4d %4d | -- none --" % (i,name,len(maps),0)); continue
    hh = collections.Counter(rs)
    act = 100.0*(hh[2]+hh[3]+hh[4])/len(rs); dri = 100.0*(hh[3]+hh[4])/len(rs)
    print("%-2d %-22s %4d %4d | %4d %4d %4d %4d %4d | %3d %6.1f %6.1f" % (
        i,name,len(maps),len(rs),hh[0],hh[1],hh[2],hh[3],hh[4],max(rs),act,dri))
    tally.append((name, dri, act, max(rs), len(rs)))

print("\n=== spine sequences ranked by DRIVEN share (rung>=3) ===")
for name, dri, act, top, nn in sorted(tally, key=lambda x: x[1]):
    print("  %-22s %5.1f%%  (top rung %d, %d placements)" % (name, dri, top, nn))

print("\n=== rung-3 exemplars (first 40, alphabetical) ===")
r3 = sorted(k for k,v in rung.items() if v == 3)
print("  n=%d" % len(r3)); print("  " + ", ".join(r3[:40]))
print("\n=== rung-4, all ===")
for t in sorted(k for k,v in rung.items() if v==4):
    print("   %-26s %s" % (t, ",".join(tok2scripts[t])))
json.dump({"rung":rung,"flags":flags}, io.open(os.path.join(os.path.dirname(__file__),"rungs4.json"),"w",encoding="utf-8"))
