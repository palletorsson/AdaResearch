#!/usr/bin/env python3
"""Tests for tools/grammar_kernel.py: in-memory grammar and terms, no repo files. The negative cases prove the kernel
bites: a wrong argument type and a body the build never makes are both refused; a `sorry` is accepted and counted."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import grammar_kernel as gk  # noqa: E402

G = {"operations": {
    "genesis": {"kind": "form", "sig": "() -> point"},
    "extension": {"kind": "body", "sig": "form -> body", "aliases": ["extension"]},
    "hand": {"kind": "body", "sig": "body -> held body", "aliases": ["grabbable", "hand"]},
    "times": {"kind": "number", "sig": "(form, n, placement) -> copies"},
    "config": {"kind": "name", "sig": "(form, values) -> one of its kind"},
}}
POINT = {"build": {"p": "point"}, "card": {"formula": "point", "op": "genesis"}}
LINE = {"build": {"op": "compose", "parts": [{"t": "point"}, {"t": "point"}, {"p": "mesh"}]}}
PLANK = {"build": {"op": "compose", "parts": [{"t": "line", "scaffold": True}, {"p": "mesh"}, {"p": "collider"}]},
         "card": {"formula": "extension(line) = plank", "op": "extension"}}


def one(terms, name):
    return gk.run(G, terms, card=name)[0]


def test_good_derivation_is_proved():
    r = one({"point": POINT, "line": LINE, "plank": PLANK}, "plank")
    assert r["errors"] == [] and "boundary" in r["built"], r


def test_wrong_argument_type_is_refused():
    held = {"build": {"op": "compose", "parts": [{"t": "line"}, {"p": "grabbable"}]},
            "card": {"formula": "hand(line) = held line", "op": "hand"}}
    r = one({"point": POINT, "line": LINE, "held": held}, "held")
    assert any("must be a body" in e for e in r["errors"]), r


def test_claimed_body_without_collider_is_refused():
    fake = {"build": {"op": "compose", "parts": [{"t": "line"}, {"p": "mesh"}]},
            "card": {"formula": "extension(line) = fake plank", "op": "extension"}}
    r = one({"point": POINT, "line": LINE, "fake": fake}, "fake")
    assert any("has no boundary" in e for e in r["errors"]), r


def test_scaffold_does_not_count():
    # the line is a scaffold: the finished plank has no position of its own, only its mesh and collider
    r = one({"point": POINT, "line": LINE, "plank": PLANK}, "plank")
    assert "position" not in r["built"], r


def test_card_and_formula_must_name_the_same_op():
    odd = dict(PLANK, card={"formula": "hand(line) = plank", "op": "extension"})
    r = one({"point": POINT, "line": LINE, "plank": odd}, "plank")
    assert any("formula calls hand" in e for e in r["errors"]), r


def test_sorry_is_accepted_and_counted():
    fake = {"build": {"p": "mesh"}, "card": {"formula": "extension(line) = x", "op": "extension",
                                             "sorry": "the body is made by the hall, not the term"}}
    r = one({"point": POINT, "line": LINE, "x": fake}, "x")
    assert r["errors"] == [] and r["errors_held"] and r["sorry"], r


def test_unwitnessed_is_not_an_error():
    c = {"build": {"p": "mesh"}, "card": {"formula": "config(line, hue) = coloured line", "op": "config"}}
    r = one({"point": POINT, "line": LINE, "c": c}, "c")
    assert r["errors"] == [] and r["unwitnessed"], r


if __name__ == "__main__":
    fails = 0
    for name, fn in list(globals().items()):
        if name.startswith("test_"):
            try:
                fn()
                print("ok  ", name)
            except AssertionError as e:
                fails += 1
                print("FAIL", name, e)
    sys.exit(fails)
