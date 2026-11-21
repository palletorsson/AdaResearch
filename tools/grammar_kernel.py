#!/usr/bin/env python3
"""A small kernel for the grammar of the spine, in the spirit of Lean (prototype, 2026-11-21).

tools/grammar.py checks the VOCABULARY and the ORDER (the earned rule). This checks the TYPES: each transition card's
formula is a claim, a derivation such as `extension(point) = black point`, and the kernel holds it against two things.

  1. the signature  grammar.json gives each operation a `sig` ("form -> body"). Each argument the formula names must
                    have the input type: `hand(line)` is refused, because a line has no body to take.
  2. the build      terms.json gives each term a `build`, the tree the Godot kernel (composite.gd) actually constructs.
                    The kernel infers what that tree HAS (a position, a form, a boundary, mass, a hand, a joint ...) and
                    the card's output type must be among them: a card that says extension(...) over a build with no
                    collider is claiming a body the engine never builds.

Types are capability sets, read structurally from the build, not declared: a term is what its build gives it.
Where the build cannot witness a type (chance, a decision, a rule about rules) the claim is UNWITNESSED: accepted and
counted, never an error. A card may also carry `"sorry": "<reason>"`, Lean's declared hole: the kernel accepts it,
counts it and names it. The dark spot stays visible instead of being either forbidden or hidden.

    python tools/grammar_kernel.py                 # every card; exit code = errors
    python tools/grammar_kernel.py --chapter=point # one chapter (the pilot floor)
    python tools/grammar_kernel.py --card=pendulum --why
    python tools/grammar_kernel.py --json
Read-only: it writes nothing.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GRAMMAR = ROOT / "commons/modular/grammar.json"
TERMS = ROOT / "commons/modular/terms.json"

# ---------------------------------------------------------------- what a build HAS (capabilities)
PRIM_CAPS = {
    "point": {"position"},
    "mesh": {"form"},
    "sweep": {"form"},
    "collider": {"boundary"},
    "grabbable": {"hand"},
    "label": {"name"},
    "light": {"light"},
    "boolean_passage": {"form", "combined"},
}
OP_CAPS = {   # what a build operator adds to what its parts already have
    "compose": set(),          # parts side by side: the union of what they have (and `parts` when they are kinds, below)
    "transform": {"place"},
    "times": {"copies"},
    "array": {"copies", "address"},
    "associate": {"name"},
    "assemblage": {"parts"},
    "connect": {"ties"},
    "field": {"field"},
    "recurse": {"recursion"},
    "rewrite": {"rewriting"},
    "sort": {"reading"},
}
ENGINE_CAPS = {   # {"op": "engine", "kind": ...}: what the running engine adds (composite.gd's engines)
    "physics": {"mass", "time"},
    "random": {"chance"},
    "noise": {"field", "chance"},
    "sine_field": {"field", "time"},
    "cells": {"states", "time"},
    "logic": {"decision"},
    "hand": {"hand"},
    "trail": {"time", "form"},
    "trace": {"time", "form"},
}
OPAQUE_PRIMS ={"prefab", "portal_piece", "electric_floor"}   # a registry artifact stands in as itself: trusted, unread

# ---------------------------------------------------------------- the signature's type names
# input type -> the capabilities that satisfy it (ANY one). A name not listed is a VALUE argument (time, n, a measure):
# the kernel does not type it.
INPUT = {
    "point": {"position"},
    "points": {"position"},
    "form": {"position", "form"},
    "solid": {"form"},
    "edges or faces": {"position", "form"},
    "body": {"boundary", "mass"},
    "part kinds ...": {"position", "form", "boundary", "mass"},
    "parts": {"copies", "parts"},
    "nodes": {"position", "copies"},
}
# output type -> the capability the BUILD must have for the claim to hold. None = the build cannot witness it.
OUTPUT = {
    "point": "position",
    "line": "form",
    "body": "boundary",
    "named object": "name",
    "path": "form",
    "inside": "form",
    "copies": "copies",
    "moving body": "time",
    "held body": "hand",
    "moved body": "place",
    "motion": "time",
    "joint": "ties",
    "one thing": "parts",
    "addressed copies": "address",
    "reading": "reading",
    "field": "field",
    "self-similar form": "recursion",
    "sentence -> form": "rewriting",
    "graph": "ties",
    "drawn value": "chance",
    "states": "states",
    "output": "decision",
}
UNWITNESSED = {"one of its kind", "union | difference | intersection", "a rule about its rules"}


def read(p: Path):
    return json.loads(p.read_text(encoding="utf-8"))


def parse_sig(sig: str) -> tuple[list[str], str]:
    """'(form, n, placement) -> copies' -> (['form', 'n', 'placement'], 'copies'); the FIRST top-level arrow splits"""
    depth = 0
    for i in range(len(sig) - 1):
        c = sig[i]
        depth += c == "("
        depth -= c == ")"
        if depth == 0 and sig[i:i + 2] == "->":
            left, right = sig[:i].strip(), sig[i + 2:].strip()
            break
    else:
        return [], sig.strip()
    if left.startswith("(") and left.endswith(")"):
        left = left[1:-1]
    args = [a.strip() for a in split_top(left)] if left else []
    return [a for a in args if a], right


def split_top(s: str) -> list[str]:
    out, depth, cur = [], 0, ""
    for c in s:
        if c in "([":
            depth += 1
        elif c in ")]":
            depth -= 1
        if c == "," and depth == 0:
            out.append(cur)
            cur = ""
        else:
            cur += c
    out.append(cur)
    return out


class Kernel:
    def __init__(self, grammar: dict, terms: dict):
        self.g = grammar
        self.terms = terms
        self.ops = grammar["operations"]
        self.memo: dict[str, frozenset] = {}
        self.opaque: dict[str, set] = {}
        self.names = {}
        for k, t in terms.items():
            for n in (k, t.get("label") or ""):
                if n:
                    self.names.setdefault(norm(n), k)
        self.alias = {}
        for op, o in self.ops.items():
            self.alias[op] = op
            for a in o.get("aliases", []):
                if re.fullmatch(r"[A-Za-z_]+", a):
                    self.alias.setdefault(a, op)

    # ---- inference: what a build has
    def caps(self, term: str, stack: tuple = ()) -> frozenset:
        if term in self.memo:
            return self.memo[term]
        if term in stack or term not in self.terms:
            return frozenset()
        b = self.terms[term].get("build")
        found: set = set()
        c = self._caps(b, stack + (term,), found)
        lg = self.terms[term].get("logic")
        if isinstance(lg, dict) and lg.get("inputs") and lg.get("outputs") and lg.get("cases"):
            c.add("decision")   # a truth table the gate tests run: inputs become an output, witnessed
        self.memo[term] = frozenset(c)
        self.opaque[term] = found
        return self.memo[term]

    def _caps(self, b, stack, opaque: set) -> set:
        if isinstance(b, list):
            out: set = set()
            for x in b:
                out |= self._caps(x, stack, opaque)
            return out
        if not isinstance(b, dict):
            return set()
        if b.get("scaffold"):
            return set()   # shown while building, removed when done: the finished thing does not have it
        if "t" in b:
            out = set(self.caps(b["t"], stack))
            opaque |= self.opaque.get(b["t"], set())
            return out
        if "p" in b:
            p = b["p"]
            if p == "body":
                return {"mass"} if b.get("kind") in ("rigid", "dynamic") else {"boundary"}
            if p in OPAQUE_PRIMS:
                opaque.add(p)
                return {"position", "form", "boundary"}
            return set(PRIM_CAPS.get(p, set()))
        op = b.get("op")
        out = set()
        for key in ("of", "parts"):
            if key in b:
                out |= self._caps(b[key], stack, opaque)
        if op == "engine":
            out |= ENGINE_CAPS.get(b.get("kind"), {"time"})
        elif op == "compose" and len(self._kinds(b.get("parts") or [])) >= 2:
            out |= {"parts"}   # grammar: assemblage = several KINDS of part become one thing
        elif op in OP_CAPS:
            out |= OP_CAPS[op]
        elif op:
            opaque.add(op)
        return out

    def _kinds(self, parts: list) -> set:
        """the distinct TERMS a compose stands side by side (through transforms); bare primitives are one thing's
        surface, collider and body, not kinds of part"""
        out = set()
        for p in parts:
            while isinstance(p, dict) and p.get("op") == "transform":
                p = p.get("of")
            if isinstance(p, dict) and "t" in p and not p.get("scaffold"):
                out.add(p["t"])
        return out

    # ---- the claim: parse a card's formula into (op, [args])
    def claim(self, formula: str):
        for m in re.finditer(r"([A-Za-z_]+)\(", formula):
            op = self.alias.get(m.group(1))
            if not op:
                continue
            depth, j = 0, m.end() - 1
            for j in range(m.end() - 1, len(formula)):
                depth += formula[j] == "("
                depth -= formula[j] == ")"
                if depth == 0:
                    break
            inner = formula[m.end():j]
            return op, [a.strip() for a in split_top(inner) if a.strip()]
        return None, []

    def resolve(self, arg: str):
        """an argument -> (term or None, copies?) ; 'truck × 2' -> ('truck', True)"""
        copies = bool(re.search(r"[×*]\s*\d+|×", arg))
        base = re.split(r"\s*[×*]\s*", arg)[0]
        inner = self.claim(base)
        if inner[0]:
            return ("<" + base + ">", copies)   # a nested derivation, checked on its own card
        return (self.names.get(norm(base)), copies)

    # ---- the judgment
    def check_card(self, term: str) -> dict:
        t = self.terms[term]
        card = t["card"]
        r = {"card": term, "formula": card.get("formula", ""), "op": card.get("op"), "errors": [], "unwitnessed": [],
             "unread": [], "sorry": card.get("sorry")}
        built = self.caps(term)
        r["built"] = sorted(built)
        if self.opaque.get(term):
            r["unread"].append("build uses " + ", ".join(sorted(self.opaque[term])) + " (trusted, not read)")
        fop, args = self.claim(r["formula"])
        op = card.get("op")
        if op == "genesis":
            fop = fop or "genesis"
        if op not in self.ops:
            r["errors"].append(f"card op {op!r} is not an operation")
            return r
        sig_in, sig_out = parse_sig(self.ops[op]["sig"])
        r["sig"] = self.ops[op]["sig"]
        if fop and fop != op and fop not in (card.get("with") or []):
            r["errors"].append(f"the card says {op}, its formula calls {fop}")
        if fop == op:
            for i, a in enumerate(args):
                want = sig_in[i] if i < len(sig_in) else None
                tname, copies = self.resolve(a)
                if want not in INPUT:
                    continue
                if tname is None:
                    r["unread"].append(f"argument {a!r} names no term")
                    continue
                if tname.startswith("<"):
                    continue
                have = set(self.caps(tname)) | ({"copies"} if copies else set())
                if not have & INPUT[want]:
                    r["errors"].append(f"argument {i + 1} {a!r} must be a {want} (one of {sorted(INPUT[want])}); "
                                       f"{tname} has {sorted(have) or 'nothing'}")
        # the output: does the build have what the card claims?
        if sig_out in UNWITNESSED or sig_out not in OUTPUT:
            r["unwitnessed"].append(f"{op} -> {sig_out}: the build cannot show this")
        else:
            need = OUTPUT[sig_out]
            if need not in built:
                r["errors"].append(f"{op} claims a {sig_out}, the build has no {need} (it has {sorted(built) or 'nothing'})")
        if r["sorry"]:
            r["errors_held"] = r["errors"]
            r["errors"] = []
        return r


def norm(s: str) -> str:
    return re.sub(r"[\s_\-]+", " ", s.strip().lower())


def run(grammar: dict, terms: dict, chapter: str | None = None, card: str | None = None) -> list[dict]:
    k = Kernel(grammar, terms)
    out = []
    for name, t in terms.items():
        if not isinstance(t.get("card"), dict):
            continue
        if chapter and t.get("chapter") != chapter:
            continue
        if card and name != card:
            continue
        out.append(k.check_card(name))
    return out


def main(argv: list) -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    opt = {a.split("=", 1)[0]: (a.split("=", 1)[1] if "=" in a else True) for a in argv[1:]}
    g, terms = read(GRAMMAR), read(TERMS)["terms"]
    res = run(g, terms, opt.get("--chapter"), opt.get("--card"))
    if "--json" in opt:
        print(json.dumps(res, ensure_ascii=False, indent=1))
        return sum(len(r["errors"]) for r in res)
    err = sum(1 for r in res if r["errors"])
    unw = sum(1 for r in res if r["unwitnessed"])
    sor = sum(1 for r in res if r["sorry"])
    print(f"grammar kernel: {len(res)} cards, {len(res) - err - unw - sor} proved, {unw} unwitnessed, "
          f"{sor} sorry, {err} refused")
    for r in res:
        state = "REFUSED" if r["errors"] else "sorry" if r["sorry"] else "unwitnessed" if r["unwitnessed"] else "ok"
        print(f"  {state:11} {r['card']:20} {r['formula'][:60]}")
        for e in r["errors"]:
            print(f"      ✗ {e}")
        if "--why" in opt:
            print(f"      sig {r.get('sig')}   build has {r['built']}")
            for u in r["unwitnessed"] + r["unread"]:
                print(f"      · {u}")
            if r["sorry"]:
                print(f"      sorry: {r['sorry']}")
    return sum(len(r["errors"]) for r in res)


if __name__ == "__main__":
    sys.exit(main(sys.argv))
