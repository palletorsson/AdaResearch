from pathlib import Path
r=Path.cwd();o=Path(__file__).resolve().parent
s=(r/'doc/book/iterations/2026-09-23-cloth-pilot-review/probe.gd').read_text(encoding='utf-8')
s=s.replace('\tcomplete=true','''	var rebuilt:Array=desk._bodies(cloth)
	await press("STIFFNESS")
	check("STIFFNESS after REBUILD retains the full top row",rebuilt.all(func(s):return pinned(s).size()==8 and is_equal_approx(s.linear_stiffness,0.1)))
	var falls:Node3D=desk.other
	check("falling comparison starts with narrow rails",falls!=null and falls.landing=="rail" and is_equal_approx(falls.RAIL_T,0.14))
	if falls!=null:
		await create_timer(12.5).timeout
		await snapshot("rail",falls.to_global(Vector3(3,1.7,3.5)),falls.to_global(Vector3(0,0.65,0)),58)
		await press("LANDING")
		check("LANDING callback chooses pan and starts fresh falls",falls.landing=="pan" and falls.stopped_states.all(func(x):return not x))
		await create_timer(12.5).timeout
		await snapshot("pan",falls.to_global(Vector3(3,1.7,3.5)),falls.to_global(Vector3(0,0.65,0)),58)
	complete=true''')
(o/'cloth_probe.gd').write_bytes(s.encode())
