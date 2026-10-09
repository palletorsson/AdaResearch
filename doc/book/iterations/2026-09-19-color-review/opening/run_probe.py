import subprocess,time,json,pathlib,sys
out=pathlib.Path('doc/book/iterations/2026-09-19-color-review/opening/runtime').resolve()
name=sys.argv[1]
phase=sys.argv[2] if len(sys.argv)>2 else 'current'
cmd=['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--path',str(pathlib.Path('.').resolve()),'--xr-mode','off','--audio-driver','Dummy','--rendering-method','mobile','--rendering-driver','vulkan','--resolution','1280x900','--log-file',str(out/(name+'-'+phase+'-engine.log')),'--script','res://doc/book/iterations/2026-09-19-color-review/opening/probes/probe_'+name+'.gd','--','--capture','--phase='+phase]
t=time.time()
with open(out/(name+'-'+phase+'-console.log'),'w',encoding='utf-8') as f:
 p=subprocess.Popen(cmd,stdout=f,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
 (out/(name+'-'+phase+'-run.json')).write_text(json.dumps({'pid':p.pid,'command':cmd,'started':t},indent=2))
 try: code=p.wait(timeout=150)
 except subprocess.TimeoutExpired:p.kill();code='timeout'
(out/(name+'-'+phase+'-run.json')).write_text(json.dumps({'pid':p.pid,'command':cmd,'elapsed':time.time()-t,'exit':code},indent=2))
print(code)
