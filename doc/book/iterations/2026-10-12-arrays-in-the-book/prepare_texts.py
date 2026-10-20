from pathlib import Path
import re

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
HALLS = ['Array', 'Tutorial_3D', 'Tutorial_Tiling_Floor', 'Tutorial_Tiling_Walls', 'Tutorial_Disco']

def main():
    for hall in HALLS[1:]:
        folder = HERE / hall
        text = (folder / 'manuscript.md').read_text(encoding='utf-8')
        def include(match):
            name = match.group(1)
            code = (folder / name).read_text(encoding='utf-8')
            return f'<!-- student-code:{name} -->\n```gdscript\n{code}```'
        text = re.sub(r'<!-- include:([^>]+) -->', include, text)
        (folder / 'tutorial.md').write_text(text, encoding='utf-8')
    for hall in HALLS:
        text = (HERE / hall / 'tutorial.md').read_text(encoding='utf-8')
        blocks = re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)^```', text, re.M | re.S)
        assert blocks
        for name, code in blocks:
            assert code == (HERE / hall / name).read_text(encoding='utf-8')
            assert '$' not in code
    print('Five manuscripts assembled; all seven printed files match their sources.')

if __name__ == '__main__': main()
