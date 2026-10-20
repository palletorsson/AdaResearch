from pathlib import Path
import subprocess
import imageio_ffmpeg
ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
movie = ROOT / 'ada_run/ghost-student-pilot.avi'
command = ['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe', '--path', str(ROOT), '--xr-mode', 'off', '--audio-driver', 'Dummy', '--no-window', '--resolution', '1280x840', '--rendering-method', 'gl_compatibility', '--fixed-fps', '24', '--write-movie', str(movie), '--script', 'res://' + (HERE / 'film.gd').relative_to(ROOT).as_posix(), '--', '--no-bridges']
with (HERE / 'film.log').open('w', encoding='utf8') as log:
    result = subprocess.run(command, stdout=log, stderr=subprocess.STDOUT, timeout=150, creationflags=subprocess.CREATE_NO_WINDOW)
if result.returncode:
    raise SystemExit(result.returncode)
subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(), '-y', '-i', str(movie), '-c:v', 'libx264', '-crf', '22', '-pix_fmt', 'yuv420p', '-movflags', '+faststart', '-an', str(HERE / 'rehearsal.mp4')], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True, creationflags=subprocess.CREATE_NO_WINDOW)
print('Saved', HERE / 'rehearsal.mp4')
