from pathlib import Path
import subprocess, json, sys, datetime, hashlib

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[5]
attempt = sys.argv[1] if len(sys.argv)>1 else 'attempt_01'
probe = sys.argv[2] if len(sys.argv)>2 else 'probe.gd'
paths = {kind: HERE / f'{attempt}_{kind}{suffix}' for kind,suffix in [('stdout','.log'),('stderr','.log'),('run','.json')]}
if any(path.exists() for path in paths.values()):
    raise RuntimeError('Refusing to overwrite evidence for '+attempt)
cmd = [r'C:\Users\palle\Desktop\Godot_v4.6-stable_win64.exe','--headless','--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--script',str(HERE/probe),'--','--no-bridges']
started = datetime.datetime.now(datetime.timezone.utc).isoformat()
timed_out = False
try:
    proc = subprocess.run(cmd,cwd=ROOT,capture_output=True,timeout=60,creationflags=subprocess.CREATE_NO_WINDOW)
    stdout,stderr,exit_code = proc.stdout,proc.stderr,proc.returncode
except subprocess.TimeoutExpired as exc:
    stdout,stderr,exit_code = exc.stdout or b'',exc.stderr or b'',None
    timed_out = True
paths['stdout'].write_text(stdout.decode('utf-8',errors='replace'),encoding='utf-8')
paths['stderr'].write_text(stderr.decode('utf-8',errors='replace'),encoding='utf-8')
metadata = dict(command=cmd,windows_command_line=subprocess.list2cmdline(cmd),cwd=str(ROOT),started_utc=started,ended_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),exit_code=exit_code,timed_out=timed_out,timeout_seconds=60,creationflags='CREATE_NO_WINDOW',script_sha256=hashlib.sha256((HERE/probe).read_bytes()).hexdigest(),stdout_path=str(paths['stdout']),stderr_path=str(paths['stderr']))
paths['run'].write_text(json.dumps(metadata,indent=2)+'\n',encoding='utf-8')
print(json.dumps(metadata,indent=2))
print(stdout.decode('utf-8',errors='replace'))
print(stderr.decode('utf-8',errors='replace'))
