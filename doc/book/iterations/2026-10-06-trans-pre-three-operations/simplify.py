from pathlib import Path
from write_lesson import HERE, ROOT, put

# Preserve the earlier revision in before-boxmesh; the active lesson is one file.
writer = '''from pathlib import Path
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
def put(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(value, encoding="utf-8", newline="\\n")
def main():
    code = "<!-- student-code:lesson.gd -->\\n```gdscript\\n" + (HERE/"lesson.gd").read_text(encoding="utf-8") + "```"
    text = (HERE/"lesson-text.md").read_text(encoding="utf-8").replace("{{CODE}}", code)
    put(ROOT/"commons/maps/Trans_Pre/tutorial.md", text)
    put(HERE/"tutorial.md", text)
if __name__ == "__main__": main()
'''
put(HERE/'write_lesson.py', writer)
p = HERE/'run_checks.py'
s = p.read_text(encoding='utf-8')
s = s.replace("for name in ['lesson.gd', 'cube_body.gd', 'face_body.gd', 'line_skin.gd']:", "for name in ['lesson.gd']:")
start = s.index('    predecessor = ')
end = s.index('    work = ', start)
s = s[:start]+s[end:]
needle = "    shutil.copyfile(HERE/'verify.gd', work/'verify.gd')"
s = s.replace(needle, "    shutil.copyfile(work/'project.godot', HERE/'native-project.godot')\n"+needle)
s = s.replace("ROOT/'commons/maps/Point_Animatedcube/tutorial.md', ", "HERE/'native-project.godot', ")
put(p, s)
