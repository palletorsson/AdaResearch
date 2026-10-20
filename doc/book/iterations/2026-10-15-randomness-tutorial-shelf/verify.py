from pathlib import Path
import json, os, re, subprocess
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
chapter=(ROOT/'commons/maps/Random_Definition/tutorial.md').read_text(encoding='utf-8')
blocks=re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)```',chapter,re.S)
assert len(blocks)==1 and blocks[0][0]=='direct_randomness.gd'
assert blocks[0][1].strip()==(ROOT/'doc/book/studies/randomness-shelf/direct_randomness.gd').read_text(encoding='utf-8').strip()
(HERE/'printed').mkdir(exist_ok=True)
(HERE/'printed/direct_randomness.gd').write_text(blocks[0][1],encoding='utf-8')
engine=os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe')
with (HERE/'verification.log').open('w',encoding='utf-8') as log:
    result=subprocess.run([engine,'--headless','--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--script','res://'+(HERE/'verify.gd').relative_to(ROOT).as_posix(),'--','--no-bridges'],cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,timeout=60,creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
output=(HERE/'verification.log').read_text(encoding='utf-8')
assert result.returncode==0 and 'RANDOMNESS TUTORIAL SHELF: PASS' in output and 'ERROR:' not in output,output
summary=[line for line in output.splitlines() if 'RANDOMNESS TUTORIAL SHELF:' in line][0]
(HERE/'verification.json').write_text(json.dumps({'result':summary,'engine':'Godot 4.6','printedCodeMatches':True,'headsetTrial':'not observed','independentHumanReconstruction':'not observed'},indent=2)+'\n',encoding='utf-8')
print(summary)
