"""Fresh ghost-student runner. Runs GPU jobs serially with a hidden, bounded process."""
from pathlib import Path
import argparse, hashlib, json, os, re, subprocess, sys, time
sys.stdout.reconfigure(encoding='utf-8', errors='replace')

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
PACKET = HERE.parent / 'packet'
GODOT = Path('C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe')
NAMES = ['shaping','patterns','materials','water','pink','field']
HEADINGS = ['Shaping —','Patterns —','Materials —','Water —','Pink Extravaganza —','A field kept']

def extract():
    text = (PACKET/'tutorial.md').read_text(encoding='utf-8')
    starts = [text.index('\n# '+h) for h in HEADINGS]
    ends = starts[1:] + [text.index('\n# Optional returns')]
    manifest = {}
    for name, start, end in zip(NAMES, starts, ends):
        folder = HERE/name/'original'
        folder.mkdir(parents=True, exist_ok=True)
        manifest[name] = {}
        for filename, lang, code in re.findall(r'<!-- student-code:([^>]+) -->\s*```([^\n]+)\n(.*?)\n```',text[start:end], re.S):
            filename = filename.strip()
            data = (code+'\n').encode()
            (folder/filename).write_bytes(data)
            manifest[name][filename] = hashlib.sha256(data).hexdigest()
    (HERE/'extraction.json').write_text(json.dumps(manifest,indent=2), encoding='utf-8')

def run(name, mode):
    folder = HERE/name
    cmd = [str(GODOT),'--path',str(ROOT),'--no-window','--rendering-method','gl_compatibility','--xr-mode','off','--audio-driver','Dummy','--script',str(folder/'probe.gd'),'--','--no-bridges',mode]
    started = time.time()
    env = os.environ.copy()
    startup = subprocess.STARTUPINFO(); startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    try:
        result = subprocess.run(cmd, cwd=ROOT, stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=100, startupinfo=startup, creationflags=subprocess.CREATE_NO_WINDOW, env=env)
        output = result.stdout.decode('utf-8',errors='replace'); rc = result.returncode
    except subprocess.TimeoutExpired as exc:
        output = (exc.stdout or b'').decode('utf-8',errors='replace')+'\nRUNNER TIMEOUT 100s\n'; rc=-999
    history = folder/'logs'; history.mkdir(exist_ok=True)
    index = len(list(history.glob(mode+'-*.log'))) + 1
    log = history/f'{mode}-{index:02d}.log'; log.write_text(output,encoding='utf-8')
    rows = [json.loads(line.split('GHOST_JSON:',1)[1]) for line in output.splitlines() if line.startswith('GHOST_JSON:')]
    error_lines = [line for line in output.splitlines() if re.search(r'SCRIPT ERROR|SHADER ERROR|Parse Error|shader compilation failed',line,re.I)]
    passed = rc == 0 and bool(rows) and not error_lines and all(row.get('errors',1)==0 for row in rows)
    record = {'lesson':name,'mode':mode,'exit_code':rc,'passed':passed,'script_shader_errors':error_lines,'seconds':round(time.time()-started,2),'log':str(log.relative_to(HERE)),'observations':rows}
    results = HERE/'runs.json'
    prior = json.loads(results.read_text()) if results.exists() else []
    prior.append(record); results.write_text(json.dumps(prior,indent=2),encoding='utf-8')
    print(json.dumps(record,indent=2))
    if not passed: print(output[-16000:])
    return passed

if __name__ == '__main__':
    parser=argparse.ArgumentParser(); parser.add_argument('lesson',choices=NAMES+['extract','all']); parser.add_argument('mode',nargs='?',default='original',choices=['original','variation'])
    args=parser.parse_args()
    if args.lesson=='extract': extract()
    elif args.lesson=='all':
        passed = True
        for name in NAMES:
            for mode in ['original','variation']: passed = run(name,mode) and passed
        sys.exit(0 if passed else 1)
    else: sys.exit(0 if run(args.lesson,args.mode) else 1)
