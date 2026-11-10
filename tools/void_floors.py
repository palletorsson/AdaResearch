"""The tower floor a map stands on, found by MAP NAME - never write a floor number into a tool.

Floors get inserted as the curriculum is reworked (2026-11-09: Trans_Scale at 18 moved every floor >= 18 down one),
and a tool that names its floor by number goes on working on whatever floor now has that number.

    from void_floors import floor_of
    floor_of("Logic_Event")                         # in commons/void/rooms.json
    floor_of("Random_Entropy", OUT / "draft-rooms.json")   # in a draft or snapshot file
    floor_of("WaveFunctions_Intro", rooms_doc)      # in an already-parsed rooms document

The GDScript twin is tools/probes/void_floor.gd. A map that is not in the tower raises KeyError.
"""
import json
from pathlib import Path

ROOMS = Path(__file__).resolve().parents[1] / "commons" / "void" / "rooms.json"


def floor_of(map_name, rooms=None):
    doc = rooms if isinstance(rooms, dict) else json.loads(Path(rooms or ROOMS).read_text(encoding="utf-8"))
    for i, f in enumerate(doc.get("floors", [])):
        if f.get("map") == map_name:
            return i
    raise KeyError("no floor holds map %r (%s)" % (map_name, rooms if isinstance(rooms, (str, Path)) else "rooms.json"))


if __name__ == "__main__":
    import sys
    for name in sys.argv[1:] or ["Trans_Playground"]:
        print(floor_of(name), name)
