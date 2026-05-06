from pathlib import Path
for i,line in enumerate(Path(r"commons/grid/GridUtilitiesComponent.gd").read_text(encoding="utf-8").splitlines(), start=1):
    if '"Sr"' in line or '\"Sr\"' in line:
        print(i, line)
