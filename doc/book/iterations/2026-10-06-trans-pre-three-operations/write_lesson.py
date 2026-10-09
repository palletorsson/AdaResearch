from pathlib import Path
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
def put(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(value, encoding="utf-8", newline="\n")
def main():
    code = "<!-- student-code:lesson.gd -->\n```gdscript\n" + (HERE/"lesson.gd").read_text(encoding="utf-8") + "```"
    text = (HERE/"lesson-text.md").read_text(encoding="utf-8").replace("{{CODE}}", code)
    put(ROOT/"commons/maps/Trans_Pre/tutorial.md", text)
    put(HERE/"tutorial.md", text)
if __name__ == "__main__": main()
