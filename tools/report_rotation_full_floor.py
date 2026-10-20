from pathlib import Path
import html, json
ROOT=Path(__file__).resolve().parents[1]
REPORT=ROOT/"doc/book/iterations/2026-10-20-rotation-full-floor"
old=json.loads((ROOT/"commons/maps/Trans_Rotation/map_data.json").read_text(encoding="utf8"))
rooms=json.loads((ROOT/"commons/void/rooms.json").read_text(encoding="utf8"))
mapping={
 "rotation_wall_crossings":(["rotating_platform-9","axis-x","axis-z"],"Y: marked quarter-turn platform. X: upright wheel platform descends one storey. Z: original upright rider, with a 2 m rise and 4 m run to fit the ceiling."),
 "rotation_array_compare":(["angle-bands"],"All four bands, two columns and six rows. Cube geometry is half-sized; the 0.44 m and 1.2 m test bodies retain their actual dimensions."),
 "film_transformation_order":(["turn-order-film"],"Original film with pause, step, route and replay."),
 "axial_sweep":(["axial-sweep"],"Original cube/triangle, play and boundary controls."),
 "transform_composition_workbench":(["composition"],"Original four pairs, starting at X/Y, with intermediate traces."),
 "boolean_tunnel":(["twisting-tunnel"],"All five hollow cubes, 18 degrees per segment. The passage points down, with a clear bore, entrance plank and a landing on floor 17."),
 "hinge_release":(["hinge"],"Original joint, turn, KEEP/RETURN, RELEASE, TRACE and RESET. Uses the tower floor instead of its large receiving plane."),
}
coverage=[]
for z,row in enumerate(old["layers"]["interactables"]):
 for x,value in enumerate(row):
  if not value:continue
  kind=value.split(":")[0]
  if kind=="carousel_cake":
   profile=value.split("#profile:")[1].split("#")[0]
   ids,note=["carousel-"+profile],"Original eight layers and exponential speed rule. Compact perimeter placement; profile: "+profile+"."
  else:
   assert kind in mapping,(x,z,value)
   ids,note=mapping[kind]
  coverage.append(dict(source_cell=[x,z],source=value,placements=ids,adaptation=note))
assert len(coverage)==12
ids={p["id"] for group in ["artifacts","construction"] for p in rooms["floors"][16][group]}
assert all(set(row["placements"])<=ids for row in coverage)
(REPORT/"museum-coverage.json").write_text(json.dumps(coverage,indent=2)+"\n",encoding="utf8")
native=json.loads((REPORT/"tests/checks.json").read_text())
editor=json.loads((REPORT/"editor-checks.json").read_text())
assert native["passed"] and editor["passed"]
figures=[
 ("cube-banks","Compare four rotation rules","The same cubes sit between banks made from cubes and wedges. The original two body widths can replay the route."),
 ("wheel-from-above","Shaft A: ride the wheel down","A half-turn carries an upright platform from Rotation to the floor below. The same support and tracking behavior are exercised by desktop and XR tests."),
 ("boolean-from-above","Shaft B: turn the corridor downward","The five hollow cubes keep their accumulated turns. Enter from the west plank and drop through the opening."),
 ("descent-arrival","A landing beneath the passage","The outlet leaves standing clearance above the receiving platform. Walk west onto floor 17; this is an arrival, not a completed Scale map."),
 ("rotation-gallery","Five profiles, one speed rule","Cake, column, ziggurat, spindle and flare retain their original eight-layer motion."),
 ("workbench-and-hinge","Order, boundary and return","The workbench, axial sweep, hinge and film retain their original controls."),
 ("editor","Keep arranging it","All thirteen artifacts and each construction cell remain selectable, movable and copyable in the shared editor layout."),
]
photos="".join(f'<figure><img src="images/{name}.png" alt="{title}"><figcaption><strong>{title}</strong><p>{text}</p></figcaption></figure>' for name,title,text in figures)
rows="".join(f'<tr><td>{html.escape(r["source"].split("#")[0])}</td><td>{html.escape(", ".join(r["placements"]))}</td><td>{html.escape(r["adaptation"])}</td></tr>' for r in coverage)
page=f"""<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Rotation / build, compare, descend</title><style>
body{{margin:0;background:#171922;color:#eee8e0;font:17px/1.6 system-ui,sans-serif}}main{{max-width:1300px;margin:auto;padding:44px 24px}}h1{{font-size:clamp(32px,5vw,64px);line-height:1.1;max-width:900px}}a{{color:#e6b8ed}}p{{max-width:940px}}.lead{{font-size:22px}}nav{{display:flex;gap:24px;flex-wrap:wrap}}figure{{margin:40px 0;background:#232530}}img{{width:100%;display:block}}figcaption{{padding:20px 28px}}figcaption strong{{font-size:23px}}figcaption p{{margin:4px 0}}table{{border-collapse:collapse;width:100%;font-size:14px}}td,th{{padding:14px;border-bottom:1px solid #464852;text-align:left;vertical-align:top}}.checks{{padding:20px;border-left:4px solid #9cbd9c;background:#222c28}}
</style><main><nav><a href="http://localhost:3003/voxel-editor?mode=void&floor=16">Edit Rotation / floor 16</a><a href="http://localhost:3003/lab-editor?mode=void&floor=16">Lab editor</a><a href="http://localhost:3003/voxel-editor?mode=void&floor=17">Edit the lower landing</a></nav>
<h1>Rotation: build, compare, descend.</h1><p class="lead">All twelve original museum placements are accounted for on one Rotation floor. Cube and wedge banks frame the comparisons; the shafts turn rotation into a way down.</p>
<p>The Y platform, the X descent wheel and the Z rider demonstrate three axes. A downward Boolean passage provides a second route to the next storey. Five carousel profiles, the composition workbench, axial sweep, hinge and film remain separate editable objects.</p>
<div class="checks">{len(native["checks"])} native assertions passed with the desktop body and synthetic XR head/controller poses; {len(editor["checks"])} editor/model/API checks passed. A physical headset has not been tested. Captures below are from the native tower; wheel poses are staged for visibility, with traversal verified separately. Tutorial and final texts are unchanged.</div>
{photos}<h2>Original museum coverage</h2><p>Dimensions are adapted where needed for a six-metre storey. Floor 17 currently provides receiving geometry only; its Scale lesson is still to be built.</p>
<table><thead><tr><th>Original placement</th><th>Editable placement(s)</th><th>What carries forward</th></tr></thead><tbody>{rows}</tbody></table>
<p><a href="tests/checks.json">Native assertions</a> · <a href="editor-checks.json">Editor checks</a> · <a href="museum-coverage.json">Placement inventory</a></p></main></html>"""
(REPORT/"index.html").write_text(page,encoding="utf8")
print(f"Report: {len(coverage)} original placements covered.")
