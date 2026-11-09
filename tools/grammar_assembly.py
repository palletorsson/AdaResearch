#!/usr/bin/env python3
"""ASSEMBLY INDEX of the artifact grammar (Palle, 2026-11-09: "What can artifact grammar learn from assembly theory" -
"yes" to a tool). After Cronin & Walker's Assembly Theory: an object's ASSEMBLY INDEX is the fewest joining steps that
build it from basic blocks, where anything already built on the way can be REUSED at no extra cost; its COPY NUMBER is
how many identical copies exist. A high index in many copies is what chance does not make: selection kept that form.

Read from each term's structured `build` tree in commons/modular/terms.json (all 251 terms have one), never from the
prose expressions. The counting rules:
  block                 a primitive ({"p": mesh|point|body|collider...}) or a parameter leaf: 0 joins
  transform             moves, turns, scales (the grammar: "a new place, the form unchanged"): 0 joins, same object
  compose / assemblage  k DIFFERENT parts: k-1 joins; m IDENTICAL parts first become one m-copy object by doubling
                        (ceil(log2 m) joins: a, 2a, 4a, ...) - reuse, the core of the theory
  times / array         n copies: ceil(log2 n) joins - so `quad * 6` and six identical quads count the same
  associate, engine, connect, sort, exhibit, field
                        1 join each (a field is one construction; its resolution is not counted)
  recurse / rewrite     2 joins per depth level (each level is the rule applied to its own result: a few copies of the
                        level before, reused) - an approximation, flagged `rule`
  {"t": term}           that term's whole pathway; every intermediate counts ONCE per term however often it is reused
A term's index = the number of distinct joined objects in its expanded pathway.

Against the tower (commons/void/rooms.json, artifacts + copies), a placed work's term is: the timeline row's form term
(commons/data/artifact_timeline.json), else the token itself when it is a term, else `mod_<term>`.
  copy number   placements of works whose term it is, across the tower
  selected      e^a * (n - 1): the term's share of the tower's ASSEMBLY  A = sum_i e^a_i (n_i - 1) / N_T
  used before shown
                a part (a term in the pathway) that stands in the tower on its own, but first on a LATER floor than a
                work that already uses it - Palle 2026-11-08: "each floor only what it has earned"
  pool          descending the floors: the distinct joined objects the tower has made so far (does making accumulate?)

    python tools/grammar.py assembly [--markdown] [--json]        # writes ada_run/grammar_assembly.json
"""
from __future__ import annotations

import json
import math
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TERMS = ROOT / "commons/modular/terms.json"
ROOMS = ROOT / "commons/void/rooms.json"
TIMELINE = ROOT / "commons/data/artifact_timeline.json"
OUT = ROOT / "ada_run/grammar_assembly.json"

UNARY = {"associate", "engine", "connect", "sort", "exhibit", "field"}
RULES = {"recurse", "rewrite"}
JOINS = {"compose", "assemblage"}
COPIES = {"times", "array"}


def doubling(m: int) -> int:
    """Joins that make m identical copies from one, reusing what is built: a, 2a, 4a ... (ceil log2)."""
    return 0 if m <= 1 else math.ceil(math.log2(m))


def _key(node) -> str:
    return json.dumps(node, sort_keys=True, ensure_ascii=False)


def _count(n) -> int:
    if isinstance(n, (int, float)):
        return max(1, int(n))
    if isinstance(n, list):
        out = 1
        for v in n:
            out *= _count(v)
        return out
    return 1


class Assembly:
    def __init__(self, terms: dict):
        self.terms = terms
        self.memo: dict = {}       # term -> (joined objects frozenset, flags set, term refs set)

    def term(self, name: str, stack: tuple = ()) -> tuple:
        if name in self.memo:
            return self.memo[name]
        if name in stack or name not in self.terms:
            return frozenset(), {"cycle" if name in stack else "unknown term"}, set()
        joins, flags, refs = self.node(self.terms[name].get("build"), stack + (name,))
        out = (frozenset(joins), flags, refs)
        self.memo[name] = out
        return out

    def node(self, n, stack: tuple) -> tuple:
        """-> (set of joined-object keys, flags, term refs). The object's identity is returned through `ident`."""
        joins, flags, refs = set(), set(), set()
        self._walk(n, stack, joins, flags, refs)
        return joins, flags, refs

    def ident(self, n) -> str:
        """The identity of the object a node makes (transforms do not change it)."""
        if isinstance(n, dict):
            if "t" in n and "op" not in n:
                return "term:" + str(n["t"])
            if n.get("op") == "transform" or ("of" in n and "op" not in n):
                return self.ident(n.get("of"))
        return "obj:" + _key(n)

    def _walk(self, n, stack, joins, flags, refs) -> None:
        if isinstance(n, list):
            for x in n:
                self._walk(x, stack, joins, flags, refs)
            return
        if not isinstance(n, dict):
            return
        if "t" in n and "op" not in n:
            name = str(n["t"])
            refs.add(name)
            j, f, r = self.term(name, stack)
            joins |= j
            flags |= {x for x in f if x != "rule"} | ({"rule"} if "rule" in f else set())
            refs |= r
            return
        op = n.get("op")
        if op is None:
            if "p" in n:
                return                                        # a block
            for k in ("of", "union", "intersect", "subtract"):
                if k in n:
                    self._walk(n[k], stack, joins, flags, refs)
            parts = [n[k] for k in ("union", "intersect", "subtract") if k in n]
            if parts and isinstance(parts[0], list) and len(parts[0]) > 1:
                for i in range(len(parts[0]) - 1):
                    joins.add(f"boolean:{i}:" + _key(n))
            return
        if op == "transform":
            self._walk(n.get("of"), stack, joins, flags, refs)
            return
        if op in JOINS:
            parts = n.get("parts") or []
            for p in parts:
                self._walk(p, stack, joins, flags, refs)
            groups = defaultdict(int)
            for p in parts:
                groups[self.ident(p)] += 1
            for ident, m in groups.items():                      # identical parts: one m-copy object by doubling
                for i in range(1, doubling(m) + 1):
                    joins.add(f"copies:{2 ** i if 2 ** i < m else m}:{ident}")
            keys = sorted(f"{m}x{ident}" for ident, m in groups.items())
            for i in range(1, len(keys)):                        # then the distinct groups, pairwise
                joins.add(f"{op}:" + "|".join(keys[: i + 1]))
            return
        child = n.get("of")
        self._walk(child, stack, joins, flags, refs)
        if op in COPIES:
            m = _count(n.get("n", n.get("dims", 1)))
            ident = self.ident(child)
            for i in range(1, doubling(m) + 1):
                joins.add(f"copies:{2 ** i if 2 ** i < m else m}:{ident}")
            return
        if op in RULES:
            flags.add("rule")
            for d in range(int(n.get("depth", 1) or 1)):
                joins.add(f"{op}:{d}:a:" + _key(n))
                joins.add(f"{op}:{d}:b:" + _key(n))
            return
        joins.add(f"{op}:" + _key(n))                            # unary and anything new: one join


def term_of_token(token: str, terms: dict, forms: dict) -> str | None:
    if token in forms:
        return forms[token]
    if token in terms:
        return token
    if token.startswith("mod_") and token[4:] in terms:
        return token[4:]
    return None


def analyse(terms: dict | None = None, floors: list | None = None, doc: dict | None = None) -> dict:
    """The files by default; a test passes its own terms, floors and timeline."""
    terms = terms if terms is not None else json.loads(TERMS.read_text(encoding="utf-8"))["terms"]
    floors = floors if floors is not None else json.loads(ROOMS.read_text(encoding="utf-8"))["floors"]
    doc = doc if doc is not None else json.loads(TIMELINE.read_text(encoding="utf-8"))
    forms = {}
    for track in ("main", "environment"):
        for row in doc.get(track, []):
            t = (row.get("form") or {}).get("term")
            if t in terms:
                forms[row["key"]] = t
    asm = Assembly(terms)
    index = {}
    for name in terms:
        joins, flags, refs = asm.term(name)
        index[name] = {"a": len(joins), "parts": sorted(refs), "flags": sorted(flags)}

    copies = defaultdict(int)
    first = {}
    by_floor = defaultdict(list)
    for fi, fl in enumerate(floors):
        for a in list(fl.get("artifacts", [])) + list(fl.get("copies", []) or []):
            t = term_of_token(str(a.get("artifact", "")), terms, forms)
            if not t:
                continue
            copies[t] += 1
            first.setdefault(t, fi)
            by_floor[fi].append(t)

    # used before shown: a part placed on its own in the tower, but first on a later floor than a work using it
    early = []
    for t, f in sorted(first.items(), key=lambda x: x[1]):
        for p in index[t]["parts"]:
            if p in first and first[p] > f:
                early.append({"work": t, "floor": f, "part": p, "part_first_floor": first[p]})

    # the pool descending the floors
    pool, curve = set(), []
    for fi in range(len(floors)):
        before = len(pool)
        for t in set(by_floor.get(fi, [])):
            pool |= asm.term(t)[0]
        if len(pool) != before:
            curve.append({"floor": fi, "pool": len(pool), "new": len(pool) - before,
                          "max_a": max(index[t]["a"] for t in set(by_floor[fi]))})

    placed = {t: {"a": index[t]["a"], "n": copies[t], "first_floor": first[t],
                  "selected": round(math.exp(index[t]["a"]) * (copies[t] - 1), 1)} for t in copies}
    n_total = sum(copies.values())
    A = sum(math.exp(index[t]["a"]) * (copies[t] - 1) for t in copies) / max(1, n_total)
    return {"_doc": "derived by tools/grammar_assembly.py - never edit", "terms": index, "placed": placed,
            "assembly_A": round(A, 2), "placements_with_term": n_total, "terms_placed": len(copies),
            "used_before_shown": early, "pool_curve": curve}


def main(argv: list) -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    r = analyse()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    tmp = OUT.with_name(OUT.name + ".tmp")
    tmp.write_text(json.dumps(r, ensure_ascii=False, indent=1), encoding="utf-8")
    tmp.replace(OUT)
    if "--json" in argv:
        print(json.dumps(r, ensure_ascii=False, indent=1))
        return len(r["used_before_shown"])
    md = "--markdown" in argv
    h = (lambda s: "\n### " + s) if md else (lambda s: "\n" + s.upper())
    terms = r["terms"]
    hist = defaultdict(int)
    for v in terms.values():
        hist[v["a"]] += 1
    print(("## " if md else "") + f"Assembly of the grammar: {len(terms)} terms, {r['terms_placed']} placed in the tower "
          f"({r['placements_with_term']} placements), tower assembly A = {r['assembly_A']}")
    print(h("assembly index, all terms (index: how many terms)"))
    print(", ".join(f"{a}: {hist[a]}" for a in sorted(hist)))
    print(h("the most assembled terms"))
    for name, v in sorted(terms.items(), key=lambda x: -x[1]["a"])[:12]:
        print(f"- {name}: a = {v['a']}" + (" (rule: approximate)" if "rule" in v["flags"] else ""))
    print(h("selected forms: high index in many copies (e^a x (n - 1))"))
    for name, v in sorted(r["placed"].items(), key=lambda x: -x[1]["selected"])[:12]:
        print(f"- {name}: a = {v['a']}, {v['n']} copies, first on floor {v['first_floor']}, selected {v['selected']}")
    print(h(f"used before shown: {len(r['used_before_shown'])}"))
    for e in r["used_before_shown"][:25]:
        print(f"- {e['work']} (floor {e['floor']}) uses {e['part']}, which first stands on floor {e['part_first_floor']}")
    print(h("the pool, descending (distinct joined objects made so far)"))
    for c in r["pool_curve"]:
        print(f"- floor {c['floor']}: {c['pool']} (+{c['new']}, most assembled work here a = {c['max_a']})")
    return len(r["used_before_shown"])


if __name__ == "__main__":
    sys.exit(main(sys.argv))
