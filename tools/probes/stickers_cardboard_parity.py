"""stickers_cardboard_parity.py - the cardboard constructions in GDScript against the contract, number for number.

The game's port of the sticker rules (commons/stickers/sticker_data.gd) and the contract it ports
(ada_encyclopedia/src/lib/stickers.ts) are run on the SAME files and must give the same answers:

  OPS       StickerData.apply_ops (tools/probes/stickers_apply_ops.gd) against applyOps
            (tools/probes/stickers_cardboard_runner.ts ops) on a base copied from the truth and a fixture of 86 ops:
            ties between walls (one construction; another construction; no construction; a paper board; a primitive;
            a pair already tied either way; taken ids; cut, retie, word), back stickers (on cardboard, and on paper and a
            deep board, which have no back; the pink triangle's quarter turns read on the back; an exact 45 degree tie),
            scribbles (front; back on cardboard; back on paper refused; an unknown board; the clamp and its rounding; an id
            taken by a sticker, a thread or a stroke), erases and unerases with their skips, replays. Four times: with the
            boards and the constructions, with each alone, with neither. Every key of every sticker, thread and stroke,
            every result and its words, the applied list and the revision: 0 differences, exactly.
  GEOMETRY  stickers_cardboard_geometry.gd against the runner's geometry: wallPoint at eight points of every wall and
            at every sticker's pin, wallYaw, drawnWallThreads (pins, control point, 17 points along each), drawnStrokes
            per face and where each stroke's ends stand, strokeZ, wallsOf, and the cleaning of every board, of the
            constructions (with and without the boards) and of every stroke, plus named CASES for every refusal and
            clamp. On the truth and on the document the fixture leaves. Numbers to 1e-9, words exactly.
  OVER      a thread never passes through cardboard (stickers_cardboard_geometry.gd --mode=over against the runner's
            over): wallLines, drawnWallThreads' over, threadPieces (pieces, the tag piece, each piece's control point and
            middle, the tag's point), overBoard on every thread drawn on one board, named overWalls / overBoard /
            threadPieces cases, and the constants (THREAD_OVER, THREAD_CLEAR, PENS with join and soft, MITER_LIMIT,
            PEN_COLOUR_NAMES, STROKE_STEP, STROKE_DOT ...). Runs: over:research - every sticker on the truth's research
            construction and its mirror on the other face of its wall, every pair tied; over:odd - layouts made to be
            odd (two walls side by side in one plane, with a gap, touching, and turned 37 degrees; back to back with a
            gap and touching; a wall at 37 degrees and a table at 37 with a wall at 90; tables of different heights - a
            thread over a lower wall, through it, under a high one; three walls in a row, and a row with its middle wall
            turned; walls of different heights in a row; an L), every pair tied, and named cases each made for one
            outcome (a thread along a face, a hair inside it, through a wall's end exactly, beside it, grazing the top
            edge from above and below, a thread whose lowest point is its vertex, one between the top edge and THREAD_OVER
            above it, under the bottom edge, along the cardboard inside it, from its mid-plane, a walk that clears a wall
            the straight line would cross and one that meets a wall the straight line passes under, walls listed against
            the thread's direction, a line leaving by a wall's end, a piece up to a tall wall over a low one in its way,
            front to front over two walls back to back, and from a face pressed against the other wall's: each wall
            twice, no more); with --fuzz, over:fuzz (random constructions, stickers and threads, random cases) and
            over:fuzz-ops (the document the random ops leave). Numbers to 1e-9, every count, index and word exactly. The
            contract's answers to the named cases are also held to what each case was made for (FIXTURE INTENT), or the
            cases would not test what they say.
  PROPERTY  on every over run, the contract's answers held to its promise (the runner's `property`, as
            tests/stickers/cardboard.test.ts holds it): every drawn piece of every thread between walls, and of every
            thread on one cardboard board, sampled every 0.4 mm against every wall's cardboard. A thread FAILS when a
            sample lies 0.1 mm or more inside cardboard, unless a pin of it lies on a face pressed against another wall
            (within 0.1 mm of that wall's cardboard: it cannot be reached without passing through). The rule's known
            limit is counted apart, never passed: a sample inside a wall whose cardboard crosses another's, meets it at a
            joint (a T, a V, a corner of unequal tops) or stands back to back within 4 mm of it (the points over one can
            fall inside the other); walls meeting only end to end at tops within THREAD_OVER are held strictly.
            Any failing thread
            fails the parity; the counts are printed per construction (threads, over a wall, through, pressed, and as the
            negative how many would pass through as the one curve). The port is held to those answers number for number,
            so the property speaks for it too.
  MUTANTS   (--mutants) the same runs against scratch copies of the port with one rule taken out each; each must fail
            where its rule is used and only there, or the check above could not have seen that rule broken. A mutant
            names the runs it MUST bite and the runs it MAY bite (the truth's research layout catches a rule there only
            where its stickers happen to stand); biting any other run fails it. A mutant that may never finish (no cap
            on how often a wall is gone over) runs bounded (MUTANT_LIMITS), and a run killed as a hang is a bite.

The truth (commons/data/stickers/*.json) is only READ, copied into the run folder; nothing writes it, and nothing is
posted anywhere. Godot runs headless through tools/godot_watchdog.py with APPDATA pointed into the run folder, so user://
is never the real one.

  python tools/probes/stickers_cardboard_parity.py [--out=<dir>] [--mutants] [--sd=<sticker_data.gd>] [--godot=<exe>] [--workers=3] [--fuzz=<n> [--seed=<s>]]

  --out      the run folder's parent (default ada_run/stickers/cardboard_parity); each run gets <out>/<time>/
  --sd       a scratch copy of another sticker_data.gd as the port under test (the report then shows its differences)
  --mutants  also run every mutant and check that each one bites (--mutants=a,b: those alone)
  --workers  Godot runs at once (default 3), each with its own user:// folder
  --fuzz     also n seeded random ops (--seed, default 20261114) with the boards and walls and without, and the geometry
             of the document they leave; and n random threads over random constructions with n / 4 random cases over
             walls (over:fuzz), and the over of the document the random ops leave (over:fuzz-ops)
Exit 0 when the port shows 0 differences in every run, the fixture's cases give what they were made for, no thread fails
the property (and, with --mutants, every mutant bites where it should).
"""
import copy
import json
import os
import shutil
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
DATA = ROOT / 'commons' / 'data' / 'stickers'
PORT = ROOT / 'commons' / 'stickers' / 'sticker_data.gd'
ENC = ROOT.parent / 'ada_encyclopedia'
TSX = ENC / 'node_modules' / 'tsx' / 'dist' / 'cli.mjs'
RUNNER = ROOT / 'tools' / 'probes' / 'stickers_cardboard_runner.ts'
GODOT = r'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'
DOCS = ('designs', 'boards', 'placements', 'constructions')
TOL = 1e-9
PENS = {'fine': 0.003, 'marker': 0.008, 'chisel': 0.016, 'spray': 0.05}
T0 = '2026-11-14T20:00:00Z'

# ---------------------------------------------------------------- the fixture


def fixture_boards(truth):
    """The truth's boards and four of the fixture's own: two walls of a second construction, a cardboard board in no
    construction (its record carries a depth and hang, which cardboard does not keep), and nothing for cb_ghost, a wall
    of the fixture's research whose board the boards do not hold."""
    d = copy.deepcopy(truth)
    d['boards'] += [
        {'id': 'cb_annex_a', 'title': 'annex a', 'w': 0.7, 'h': 0.5, 'paper': '#c4a27a', 'stock': 'cardboard'},
        {'id': 'cb_annex_b', 'title': 'annex b', 'w': 0.7, 'h': 0.5, 'paper': '#C4A27A', 'stock': 'cardboard'},
        {'id': 'cb_loose', 'title': 'a loose wall', 'w': 0.9, 'h': 0.7, 'paper': '#c4a27a', 'stock': 'cardboard', 'depth': 0.5, 'hang': True},
    ]
    return d


def fixture_constructions(truth):
    d = copy.deepcopy(truth)
    research = next(c for c in d['constructions'] if c['id'] == 'research')
    research['walls'].append({'board': 'cb_ghost', 'table': 'sign', 'at': [0.3, 0.3], 'yaw': 90})
    d['constructions'].append({'id': 'annex', 'title': 'An annex', 'tables': [{'id': 'annex_t', 'w': 1.2, 'd': 0.6, 'h': 0.72, 'at': [4, -2], 'yaw': 45}],
                               'walls': [{'board': 'cb_annex_a', 'table': 'annex_t', 'at': [-0.3, 0], 'yaw': 30},
                                         {'board': 'cb_annex_b', 'table': 'annex_t', 'at': [0.3, 0.1], 'yaw': -60}]})
    return d


def board(i):
    return {'kind': 'board', 'id': i}


def add(op_id, sid, board_id, at, n=(0, 0, 1), up=(0, 1, 0), design='punctum_hand_missing', size=0.15, by='vr:fixture', host=None):
    return {'op_id': op_id, 'op': 'add', 'sticker': {'id': sid, 'design': design, 'host': host or board(board_id), 'at': list(at), 'n': list(n), 'up': list(up),
                                                     'size': size, 'z': 0, 'by': by, 't': T0, 'state': 'on', 'moves': 0}}


def move(op_id, sid, at, n, up, host=None, size=None):
    o = {'op_id': op_id, 'op': 'move', 'id': sid, 'at': list(at), 'n': list(n), 'up': list(up)}
    if host:
        o['host'] = host
    if size is not None:
        o['size'] = size
    return o


def tie(op_id, tid, a, b, word='the gap', colour='#b3121b', why=None):
    th = {'id': tid, 'a': a, 'b': b, 'word': word}
    if colour:
        th['colour'] = colour
    if why:
        th['why'] = why
    return {'op_id': op_id, 'op': 'tie', 'thread': th}


def scribble(op_id, sid, board_id, face, pen, points, width=None, colour='#16191e'):
    return {'op_id': op_id, 'op': 'scribble', 'stroke': {'id': sid, 'host': board(board_id), 'face': face, 'pen': pen,
                                                         'width': PENS[pen] if width is None else width, 'colour': colour, 'points': points}}


def one(op_id, kind, i, **kw):
    return dict({'op_id': op_id, 'op': kind, 'id': i}, **kw)


def fixture_ops():
    s50 = [-0.766, 0.6428, 0]   # up at a turn of 50 degrees on a front (toward -X)
    return [
        # back stickers: cardboard has a back, paper and a deep board do not; an edge-on normal (n.z = 0) is the front
        add('fx-a1', 'fx-back-hand', 'cb_hand', [0.1, -0.12, 0], n=[0, 0, -1]),
        add('fx-a2', 'fx-back-gap', 'cb_gap', [-0.2, 0.05, -0.2], n=[0.2, 0.1, -0.97], up=[0.1, 1, 0.3], by='someone'),
        add('fx-a3', 'fx-back-paper', 'visitors', [0.3, 0.2, -0.03], n=[0, 0, -1]),
        add('fx-a4', 'fx-back-deep', 'mindmap', [0.5, 0.4, 0.45], n=[0, 0, -1]),
        add('fx-a5', 'fx-edge-on', 'cb_hand', [0, 0.2, 0.1], n=[0, 1, 0]),
        # the pink triangle (snap90) on a back and a front: its quarter turns read against n = -Z and n = +Z
        add('fx-a6', 'fx-tri-back', 'cb_reset', [0.2, -0.15, 0], n=[0, 0, -1], up=s50, design='here_pink_triangle'),
        add('fx-a7', 'fx-tri-front', 'cb_reset', [0.2, -0.15, 0], up=s50, design='here_pink_triangle'),
        add('fx-a8', 'fx-tri-back-45', 'cb_mouth', [-0.2, -0.2, 0], n=[0, 0, -1], up=[-0.7071, 0.7071, 0], design='here_pink_triangle'),
        add('fx-a9', 'fx-annex-a', 'cb_annex_a', [0, 0, 0], n=[0, 0, -1]),
        add('fx-a10', 'fx-annex-b', 'cb_annex_b', [0.1, 0.1, 0]),
        add('fx-a11', 'fx-loose', 'cb_loose', [0, 0, 0.3]),
        add('fx-a12', 'fx-ghost', 'cb_ghost', [0, 0.1, 0]),
        add('fx-a13', 'fx-loose-back', 'cb_loose', [0.2, -0.2, 0.1], n=[0, 0, -1]),
        # moves onto a back, off it onto paper, from paper onto a back
        move('fx-m1', 'cb-saw', [0.2, 0.1, 0], [0, 0, -1], [0, 1, 0]),
        move('fx-m2', 'fx-back-hand', [0.4, -0.3, 0], [0, 0, -1], [0, 1, 0], host=board('visitors')),
        move('fx-m3', 'fx-back-hand', [-0.25, -0.1, 0.4], [0, 0, -1], [0.3, 0.95, 0.1], host=board('cb_mouth')),
        move('fx-m4', 'seed-board-question', [0.1, 0.1, 0], [0, 0, -1], [0, 1, 0], host=board('cb_counted')),
        move('fx-m5', 'cb-compass', [-0.21, 0.07, 0], [0, 0, 1], [0.2588, 0.9659, 0], size=0.18),
        one('fx-p1', 'peel', 'cb-nails'),
        move('fx-m6', 'cb-nails', [0, 0, 0], [0, 0, -1], [0, 1, 0]),
        one('fx-r1', 'restore', 'cb-nails'),
        one('fx-n1', 'note', 'fx-back-gap', note='  scribbled  '),
        one('fx-n2', 'note', 'fx-back-gap', note=''),
        one('fx-n3', 'note', 'fx-back-paper', note=' kept as sent '),   # applyOps keeps a note as given (cleanOp trimmed it)
        one('fx-f1', 'front', 'fx-back-gap'),
        # red thread between walls: one construction yes; another, none, paper, a primitive no; a pair tied either way no
        tie('fx-t1', 'fx-th-hand-gap', 'cb-in-your-hand', 'cb-compass', word='the hand'),
        tie('fx-t2', 'fx-th-gap-hand', 'cb-compass', 'cb-in-your-hand'),
        tie('fx-t3', 'fx-th-back-front', 'fx-back-gap', 'cb-saw', word='behind'),
        tie('fx-t4', 'fx-th-cantor-again', 'cb-floats-forget', 'cb-cantor'),
        tie('fx-t5', 'fx-th-annex', 'cb-hand-missing', 'fx-annex-a'),
        tie('fx-t6', 'fx-th-paper', 'cb-thumb-once', 'seed-board-triangle'),
        tie('fx-t7', 'fx-th-loose', 'cb-thumb-once', 'fx-loose'),
        tie('fx-t8', 'fx-th-loose-paper', 'fx-loose', 'seed-board-triangle'),
        tie('fx-t9', 'fx-th-annex-ab', 'fx-annex-a', 'fx-annex-b', word='annexed'),
        tie('fx-t10', 'fx-th-ghost', 'cb-nails', 'fx-ghost', word='unseen'),
        tie('fx-t11', 'fx-th-one-wall', 'cb-nails', 'cb-thumb-once', word='one wall'),
        tie('fx-t12', 'fx-th-primitive', 'cb-nails', 'seed-sphere-here'),
        tie('fx-t13', 'cb-st-hand-front-0', 'cb-nails', 'cb-compass'),
        tie('fx-t14', 'cb-nails', 'cb-mouth', 'cb-compass'),
        tie('fx-t15', 'fx-th-missing', 'cb-nails', 'fx-nobody'),
        tie('fx-t16', 'fx-th-no-colour', 'cb-mouth', 'cb-same-place', word='a mouth', colour=None, why='said twice'),
        one('fx-u1', 'untie', 'cb-th-amphora-nobody-quite-made'),
        one('fx-u2', 'untie', 'cb-th-amphora-nobody-quite-made'),
        tie('fx-t17', 'fx-th-amphora-again', 'cb-nobody-quite-made', 'cb-amphora', word='again'),
        one('fx-u3', 'retie', 'cb-th-amphora-nobody-quite-made'),
        one('fx-u4', 'untie', 'fx-th-amphora-again'),
        one('fx-u5', 'retie', 'cb-th-amphora-nobody-quite-made'),
        one('fx-u6', 'retie', 'cb-th-amphora-nobody-quite-made'),
        one('fx-w1', 'word', 'fx-th-hand-gap', word='held apart', why='across the table'),
        one('fx-w2', 'word', 'cb-th-lower-down-same-place', word='returns'),
        one('fx-p2', 'peel', 'cb-mouth'),
        one('fx-w3', 'word', 'fx-th-nope', word='x'),
        # scribbles: front; back on cardboard; back on paper and on a deep board no; an unknown board; the clamp; ids
        scribble('fx-s1', 'fx-st-front', 'cb_hand', 'front', 'marker', [[-0.3, 0.2], [0.123456789, -0.287654321], [0.7, 0.5]]),
        scribble('fx-s2', 'fx-st-back', 'cb_hand', 'back', 'fine', [[0.1, 0.1], [0.2, 0.05], [-2, -2]], colour='#b3121b'),
        scribble('fx-s3', 'fx-st-paper-back', 'visitors', 'back', 'marker', [[0, 0], [0.1, 0.1]]),
        scribble('fx-s4', 'fx-st-nowhere', 'nope_board', 'front', 'marker', [[0, 0], [5, 5]]),
        scribble('fx-s5', 'fx-st-nowhere-back', 'nope_board', 'back', 'marker', [[0, 0], [0.1, 0.1]]),
        scribble('fx-s6', 'cb-nails', 'cb_hand', 'front', 'marker', [[0, 0], [0.1, 0.1]]),
        scribble('fx-s7', 'cb-th-amphora-mouth', 'cb_hand', 'front', 'marker', [[0, 0], [0.1, 0.1]]),
        scribble('fx-s8', 'cb-st-hand-front-0', 'cb_hand', 'front', 'marker', [[0, 0], [0.1, 0.1]]),
        scribble('fx-s9', 'fx-st-front', 'cb_gap', 'front', 'marker', [[0, 0], [0.1, 0.1]]),
        scribble('fx-s10', 'fx-st-deep', 'mindmap', 'front', 'spray', [[-3, 2], [3, -2]], width=0.1, colour='#eb0d85'),
        scribble('fx-s11', 'fx-st-deep-back', 'mindmap', 'back', 'spray', [[0, 0], [0.1, 0.1]]),
        scribble('fx-s12', 'fx-st-loose-back', 'cb_loose', 'back', 'chisel', [[-0.44, 0.34], [0.46, -0.36]], width=0.02),
        scribble('fx-s13', 'fx-st-ghost', 'cb_ghost', 'front', 'fine', [[0, 0], [0.2, 0.2]]),
        scribble('fx-s14', 'fx-st-annex', 'cb_annex_b', 'back', 'spray', [[-0.3, 0], [0.3, 0.05], [0.31, -0.26]], colour='#eb0d85'),
        scribble('fx-s1', 'fx-st-replayed', 'cb_hand', 'front', 'marker', [[0, 0], [0.1, 0.1]]),
        # erase and unerase, each with its skip; ids that are not strokes
        one('fx-e1', 'erase', 'fx-st-front'),
        one('fx-e2', 'erase', 'fx-st-front'),
        one('fx-e3', 'unerase', 'fx-st-front'),
        one('fx-e4', 'unerase', 'fx-st-front'),
        one('fx-e5', 'erase', 'cb-st-hand-front-0'),
        one('fx-e6', 'unerase', 'cb-st-hand-front-1'),
        one('fx-e7', 'erase', 'fx-st-none'),
        one('fx-e8', 'erase', 'cb-nails'),
        one('fx-e9', 'unerase', 'fx-st-none'),
        one('fx-p3', 'peel', 'cb-st-hand-front-1'),
        one('fx-e10', 'erase', 'fx-st-back'),
        # one id space, replays, the rest
        add('fx-a14', 'cb-st-hand-front-2', 'cb_hand', [0, 0, 0]),
        add('fx-a15', 'fx-back-hand', 'cb_hand', [0, 0, 0]),
        scribble('seed-cb-st-edges-front-18', 'fx-st-from-the-truth', 'cb_edges', 'front', 'marker', [[0, 0], [0.1, 0.1]]),
        add('fx-a1', 'fx-back-hand-again', 'cb_hand', [0, 0, 0], n=[0, 0, -1]),
        add('fx-a16', 'fx-no-design', 'cb_hand', [0, 0, 0], design='no_such_design'),
        move('fx-m7', 'seed-sphere-here', [0, 0.3, 0], [0, 1, 0], [0, 0, -1]),
        one('fx-r2', 'restore', 'fx-back-gap'),
        one('fx-p4', 'peel', 'cb-mouth'),
    ]

# ---------------------------------------------------------------- the cases (cleaning)


def fixture_cases():
    tab = {'id': 't1', 'w': 1.6, 'd': 0.8, 'h': 0.74, 'at': [0, 0], 'yaw': 0}
    wall = {'board': 'cb_hand', 'table': 't1', 'at': [0, 0], 'yaw': 0}

    def con(**kw):
        c = {'id': 'case', 'title': 'A case', 'tables': [dict(tab)], 'walls': [dict(wall)]}
        c.update(kw)
        return c

    def doc(*cs, **kw):
        d = {'version': 1, 'revision': 4, 'constructions': list(cs)}
        d.update(kw)
        return d

    def t(**kw):
        return dict(tab, **kw)

    def w(**kw):
        return dict(wall, **kw)

    yaws = con(tables=[t(id='ta', yaw=-90), t(id='tb', yaw=450.00004), t(id='tc', yaw='90'), t(id='td', yaw=None)],
               walls=[w(board='cb_hand', table='ta', yaw=360), w(board='cb_gap', table='tb', yaw=-0.00001), w(board='cb_mouth', table='tc', yaw='abc'),
                      w(board='cb_reset', table='td', yaw=7200), w(board='cb_worked', table='ta', yaw=-3600.5)])
    cons = [
        ('ok', doc(con())),
        ('wall-no-table', doc(con(walls=[w(table='nope')]))),
        ('wall-table-number', doc(con(walls=[w(table=1)]))),
        ('stands-twice', doc(con(walls=[w(), w(at=[0.1, 0])]))),
        ('table-id-twice', doc(con(tables=[t(), t()]))),
        ('table-id-bad', doc(con(tables=[t(id='T1')]))),
        ('table-at-far', doc(con(tables=[t(at=[31, 0])]))),
        ('table-at-limit', doc(con(tables=[t(at=[30, -30])]))),
        ('table-w-missing', doc(con(tables=[{k: v for k, v in tab.items() if k != 'w'}]))),
        ('table-w-text', doc(con(tables=[t(w='1.2')]))),
        ('table-clamps', doc(con(tables=[t(w=99, d=0.01, h=3)]))),
        ('table-not-object', doc(con(tables=[5]))),
        ('tables-not-list', doc(con(tables='x'))),
        ('wall-at-missing', doc(con(walls=[{k: v for k, v in wall.items() if k != 'at'}]))),
        ('wall-at-far', doc(con(walls=[w(at=[6.5, 0])]))),
        ('wall-at-off-table', doc(con(walls=[w(at=[2, -1])]))),
        ('wall-at-text', doc(con(walls=[w(at=['0.1', 0])]))),
        ('wall-at-three', doc(con(walls=[w(at=[0, 0, 0])]))),
        ('wall-board-bad', doc(con(walls=[w(board='CB')]))),
        ('wall-not-object', doc(con(walls=[7]))),
        ('yaws', doc(yaws)),
        ('title-long', doc(con(title='t' * 100, note='n' * 500))),
        ('title-blank', doc(con(title='   ', note=' \n '))),
        ('title-astral', doc(con(title='\U0001F3A8' * 50))),
        ('id-bad', doc(con(id='Bad'))),
        ('id-missing', doc({k: v for k, v in con().items() if k != 'id'})),
        ('id-newline', doc(con(id='case\n'))),
        ('twice', doc(con(), con(walls=[w(board='cb_gap')]))),
        ('board-in-two', doc(con(), con(id='other'))),
        ('paper-wall', doc(con(walls=[w(board='visitors')]))),
        ('ghost-wall', doc(con(walls=[w(board='cb_nowhere')]))),
        ('tables-25', doc(con(tables=[t(id=f't{i}') for i in range(25)], walls=[]))),
        ('walls-65', doc(con(walls=[w(board=f'cbw_{i}') for i in range(65)]))),
        ('doc-string', 'x'),
        ('doc-null', None),
        ('doc-list', []),
        ('doc-no-list', {'constructions': 'x'}),
        ('revision-text', doc(con(), revision='7')),
        ('revision-negative', doc(con(), revision=-3)),
        ('revision-big', doc(con(), revision=1e12)),
        ('revision-fraction', doc(con(), revision=2.7)),
        ('construction-number', doc(5)),
        ('construction-list', doc([])),
    ]
    boards = [
        ('cardboard-deep', {'id': 'cbx', 'title': 'x', 'w': 0.8, 'h': 0.6, 'stock': 'cardboard', 'depth': 0.5, 'hang': True}),
        ('plywood', {'id': 'cbx', 'title': 'x', 'w': 0.8, 'h': 0.6, 'stock': 'plywood', 'depth': 0.5, 'hang': True}),
        ('cardboard-capital', {'id': 'cbx', 'title': 'x', 'w': 0.8, 'h': 0.6, 'stock': 'Cardboard'}),
        ('cardboard-title-long', {'id': 'cbx', 'title': 'w' * 70, 'w': 0.8, 'h': 0.6, 'stock': 'cardboard', 'note': '  '}),
        ('id-bad', {'id': 'X', 'w': 0.8, 'h': 0.6}),
        ('id-newline', {'id': 'cbx\n', 'w': 0.8, 'h': 0.6, 'stock': 'cardboard'}),
        ('paper-capital', {'id': 'cbx', 'w': 0.8, 'h': 0.6, 'paper': '#C4A27A', 'stock': 'cardboard'}),
        ('no-size', {'id': 'cbx', 'h': 0.6, 'stock': 'cardboard'}),
        ('size-text', {'id': 'cbx', 'w': '0.8', 'h': 0.6, 'stock': 'cardboard'}),
    ]
    st = {'id': 'st-case', 'host': board('cb_hand'), 'face': 'front', 'pen': 'marker', 'width': 0.008, 'colour': '#16191e', 'points': [[0, 0], [0.1, 0.1]]}

    def s(**kw):
        return dict(st, **kw)

    strokes = [
        ('ok', s()),
        ('pen-bad', s(pen='crayon')),
        ('pen-proto', s(pen='toString')),
        ('face-side', s(face='side')),
        ('one-point', s(points=[[0, 0]])),
        ('too-many', s(points=[[0, i / 4000] for i in range(2001)])),
        ('most', s(points=[[i / 4000, 0] for i in range(2000)])),
        ('colour-word', s(colour='red')),
        ('colour-short', s(colour='#fff')),
        ('colour-capital', s(colour='#B3121B')),
        ('point-far', s(points=[[0, 0], [10.0001, 0]])),
        ('point-limit', s(points=[[10, -10], [-10, 10]])),
        ('point-text', s(points=[['0.1', 0], [0, 0]])),
        ('point-three', s(points=[[0, 0, 0], [0, 0]])),
        ('point-rounding', s(points=[[0.123456789, -0.00005], [-0.00015, 9.99996]])),
        ('points-not-list', s(points='x')),
        ('width-wide', s(pen='fine', width=0.5)),
        ('width-text', s(width='0.01')),
        ('width-missing', {k: v for k, v in s(pen='spray').items() if k != 'width'}),
        ('width-thin', s(pen='chisel', width=0.001)),
        ('width-rounding', s(width=0.0123456)),
        ('host-primitive', s(host={'kind': 'primitive', 'id': 'box'})),
        ('host-bad-id', s(host=board('Bad'))),
        ('host-missing', {k: v for k, v in st.items() if k != 'host'}),
        ('host-list', s(host=[])),
        ('id-bad', s(id='x')),
        ('id-newline', s(id='st-case\n')),
        ('by-long', s(by='v' * 70)),
        ('by-blank', s(by='   ')),
        ('by-number', s(by=5)),
        ('by-astral', s(by='\U0001F3A8' * 35)),
        ('t-bad', s(t='yesterday')),
        ('t-fraction', s(t='2026-11-14T12:00:00.123Z')),
        ('t-minutes', s(t='2026-11-14T12:00Z')),
        ('t-newline', s(t='2026-11-14T12:00:00Z\n')),
        ('erased', s(state='erased', erased={'by': 'pen', 't': '2026-11-14T12:00:00Z'})),
        ('erased-blank', s(state='erased', erased={'by': '  ', 't': 'bad'})),
        ('erased-list', s(state='erased', erased=[])),
        ('erased-missing', s(state='erased')),
        ('on-with-erased', s(state='on', erased={'by': 'pen', 't': '2026-11-14T12:00:00Z'})),
        ('state-other', s(state='gone')),
        ('back-on-paper', s(host=board('visitors'), face='back')),
        ('raw-string', 'x'),
        ('raw-null', None),
        ('raw-list', []),
    ]
    return {'constructions': [{'name': n, 'raw': r} for n, r in cons], 'boards': [{'name': n, 'raw': r} for n, r in boards],
            'strokes': [{'name': n, 'raw': r} for n, r in strokes]}

# ---------------------------------------------------------------- the over fixture: a thread never passes through cardboard

CARDBOARD = 0.005   # stickers.ts CARDBOARD (and THREAD_OVER 0.004, THREAD_CLEAR 0.003): the named cases are laid out by them


def tied(tid, a, b):
    return {'id': tid, 'a': a, 'b': b, 'word': 'w', 'colour': '#b3121b', 'by': 'parity', 't': T0, 'state': 'tied'}


def all_pairs(prefix, stickers):
    return [tied(f'{prefix}-{i}-{j}', a['id'], b['id']) for i, a in enumerate(stickers) for j, b in enumerate(stickers) if j > i]


def mirror(s):
    """The same sticker on the other face of its wall: x, y and up kept, n and at.z of that face (as settle stores them)."""
    m = copy.deepcopy(s)
    back = s['n'][2] < 0
    m['id'] = s['id'] + '-mirror'
    m['n'] = [0, 0, 1] if back else [0, 0, -1]
    m['at'] = [s['at'][0], s['at'][1], 0 if back else -CARDBOARD]
    return m


def sticker(sid, board_id, at, back=False, up=(0, 1, 0), design='punctum_hand_missing', size=0.1):
    return {'id': sid, 'design': design, 'host': board(board_id), 'at': [at[0], at[1], -CARDBOARD if back else 0], 'n': [0, 0, -1 if back else 1],
            'up': list(up), 'size': size, 'z': 1, 'by': 'parity', 't': T0, 'state': 'on', 'moves': 0}


def over_research(placements, constructions):
    """Every sticker on the walls of the truth's research construction that is on, and its mirror on the other face of its
    wall; every pair tied (the threads between walls go over the walls in between, those within one wall over its top
    edge when they join its two faces)."""
    research = next(c for c in constructions['constructions'] if c['id'] == 'research')
    walls = {w['board'] for w in research['walls']}
    stickers = []
    for s in placements['stickers']:
        h = s.get('host') or {}
        if h.get('kind') == 'board' and h.get('id') in walls and s.get('state') == 'on':
            stickers += [copy.deepcopy(s), mirror(s)]
    return {'version': 1, 'revision': 1, 'stickers': stickers, 'threads': all_pairs('pr', stickers), 'strokes': [], 'applied': []}


def wall_stickers(bid, w, h):
    """Three on a wall's front, their mirrors on its back and one more there, turned 15 degrees."""
    r = lambda v: round(v, 6) + 0.0
    front = [sticker(f'{bid}-f{i}', bid, (r(fx * w), r(fy * h)), design=('punctum_hand_missing', 'here_pink_triangle')[i % 2])
             for i, (fx, fy) in enumerate([(-0.35, -0.3), (0.0, 0.2), (0.35, -0.05)])]
    return front + [mirror(s) for s in front] + [sticker(f'{bid}-b3', bid, (r(0.15 * w), r(0.25 * h)), back=True, up=(-0.2588, 0.9659, 0))]


def over_odd():
    """Layouts made to be odd, every pair of their stickers tied, and the named cases (over_cases)."""
    boards, cons, stickers, threads = [], [], [], []

    def cb(bid, w=0.8, h=0.6):
        boards.append({'id': bid, 'title': bid, 'w': w, 'h': h, 'paper': '#c4a27a', 'stock': 'cardboard'})
        return bid

    def table(tid, at, h=0.74, yaw=0, w=2.0, d=1.0):
        return {'id': tid, 'w': w, 'd': d, 'h': h, 'at': list(at), 'yaw': yaw}

    def wall(bid, tid, at, yaw=0):
        return {'board': bid, 'table': tid, 'at': list(at), 'yaw': yaw}

    def construction(cid, title, tables, walls):
        cons.append({'id': cid, 'title': title, 'tables': tables, 'walls': walls})
        mine = []
        for w in walls:
            b = next(x for x in boards if x['id'] == w['board'])
            mine += wall_stickers(w['board'], b['w'], b['h'])
        stickers.extend(mine)
        threads.extend(all_pairs(cid, mine))

    # two walls side by side in one plane: with a gap, with their ends touching, and turned 37 degrees
    construction('odd_plane', 'side by side, a gap', [table('pl_t', (0, 0), w=2.0, d=0.8)],
                 [wall(cb('ob_pa'), 'pl_t', (-0.45, 0)), wall(cb('ob_pb'), 'pl_t', (0.45, 0))])
    construction('odd_touch', 'side by side, touching', [table('to_t', (0, -2), w=1.6, d=0.8)],
                 [wall(cb('ob_ta'), 'to_t', (-0.4, 0)), wall(cb('ob_tb'), 'to_t', (0.4, 0))])
    construction('odd_plane37', 'side by side, turned 37', [table('p37_t', (0, 2), w=2.0, d=0.8, yaw=37)],
                 [wall(cb('ob_ra'), 'p37_t', (-0.45, 0)), wall(cb('ob_rb'), 'p37_t', (0.45, 0))])
    # back to back: a centimetre apart, and touching
    construction('odd_back', 'back to back, a gap', [table('bk_t', (3, 0), w=1.0, d=0.8)],
                 [wall(cb('ob_bc'), 'bk_t', (0, 0.01)), wall(cb('ob_bd'), 'bk_t', (0, -0.01), 180)])
    construction('odd_back_touch', 'back to back, touching', [table('bt_t', (3, -2), w=1.0, d=0.8)],
                 [wall(cb('ob_be'), 'bt_t', (0, 0.005)), wall(cb('ob_bf'), 'bt_t', (0, -0.005), 180)])
    # a wall at 37 degrees between two square ones, and a table at 37 degrees with a wall at 90 on it
    construction('odd_angle', 'a wall at 37 degrees', [table('an_t', (0, 4), w=2.4, d=1.2), table('an_t2', (2.0, 4.0), h=0.9, yaw=37, w=1.0, d=1.0)],
                 [wall(cb('ob_ae'), 'an_t', (-0.7, 0.35)), wall(cb('ob_af'), 'an_t', (0, 0), 37), wall(cb('ob_ag'), 'an_t', (0.7, -0.35)),
                  wall(cb('ob_ah'), 'an_t2', (0, 0), 90)])
    # tables of different heights, the walls facing +X: a low wall between two taller ones (a thread over it, or through
    # it), and a high wall on a high table between two low ones (a thread under it)
    construction('odd_heights', 'tables of different heights',
                 [table('ht_1', (-1.2, 7), h=0.45, w=0.8), table('ht_2', (0, 7), w=0.8), table('ht_3', (1.2, 7), h=1.1, w=0.8),
                  table('ht_1b', (-1.2, 8.2), h=0.45, w=0.8), table('ht_4', (0, 8.2), h=1.4, w=0.8), table('ht_3b', (1.2, 8.2), w=0.8)],
                 [wall(cb('ob_h1', h=1.2), 'ht_1', (0, 0), 90), wall(cb('ob_l2', h=0.3), 'ht_2', (0, 0), 90), wall(cb('ob_h3'), 'ht_3', (0, 0), 90),
                  wall(cb('ob_h1b'), 'ht_1b', (0, 0), 90), wall(cb('ob_u4', h=0.4), 'ht_4', (0, 0), 90), wall(cb('ob_h3b'), 'ht_3b', (0, 0), 90)])
    # three walls in a row, all facing +Z; and a row whose middle wall faces the other way
    construction('odd_row', 'three walls in a row', [table('rw_t', (-3, 4), w=0.8, d=2.6)],
                 [wall(cb('ob_r1', 0.6, 0.5), 'rw_t', (0, -1.1)), wall(cb('ob_r2', 0.6, 0.5), 'rw_t', (0, 0)), wall(cb('ob_r3', 0.6, 0.5), 'rw_t', (0, 1.1))])
    construction('odd_row_turned', 'a row, its middle wall turned', [table('rt_t', (-5, 4), w=0.8, d=2.6)],
                 [wall(cb('ob_s1', 0.6, 0.5), 'rt_t', (0, -1.1)), wall(cb('ob_s2', 0.6, 0.5), 'rt_t', (0, 0), 180), wall(cb('ob_s3', 0.6, 0.5), 'rt_t', (0, 1.1))])
    # walls of different heights in a row, all facing +X (0.8, 0.45, 0.5 and 0.9 m, the review's F2): the piece up to a
    # taller wall goes over a low one in its way; and an L, one wall's end against the other's face at a right angle
    construction('odd_steps', 'walls of different heights in a row',
                 [table('st_1', (6, 0), w=0.6, d=0.6), table('st_2', (6.3, 0), w=0.6, d=0.6), table('st_3', (6.6, 0), w=0.6, d=0.6),
                  table('st_4', (7.2, 0), w=0.6, d=0.6)],
                 [wall(cb('ob_ka', 0.6, 0.8), 'st_1', (0, 0), 90), wall(cb('ob_kb', 0.6, 0.45), 'st_2', (0, 0), 90),
                  wall(cb('ob_kc', 0.6, 0.5), 'st_3', (0, 0), 90), wall(cb('ob_kd', 0.6, 0.9), 'st_4', (0, 0), 90)])
    construction('odd_corner', 'two walls at a corner', [table('co_t', (6, 3), w=1.6, d=0.8)],
                 [wall(cb('ob_ca'), 'co_t', (0, 0.2)), wall(cb('ob_cb', 0.4, 0.6), 'co_t', (0.4, 0.2), 90)])
    # boards in no construction: a loose cardboard wall (front to back over its top edge) and a paper board (no back:
    # never over), each with stickers on its back as a record could hold them
    for bid, w, h, stock in [('ob_loose', 0.9, 0.7, True), ('op_paper', 1.0, 0.7, False)]:
        boards.append(dict({'id': bid, 'title': bid, 'w': w, 'h': h, 'paper': '#c4a27a'}, **({'stock': 'cardboard'} if stock else {})))
        mine = wall_stickers(bid, w, h)
        stickers.extend(mine)
        threads.extend(all_pairs(bid, mine))
    cb('ob_case')
    doc = {'version': 1, 'revision': 1, 'stickers': stickers, 'threads': threads, 'strokes': [], 'applied': []}
    cases, expect = over_cases()
    return {'version': 1, 'revision': 1, 'boards': boards}, {'version': 1, 'revision': 1, 'constructions': cons}, doc, cases, expect


def over_cases():
    """The named cases, each made for one outcome: (cases for the probe, what each was made for)."""
    W0 = {'a': [-0.4, 0.0], 'b': [0.4, 0.0], 'n': [0.0, 1.0], 'bottom': 0.74, 'top': 1.34}   # mid-plane z = 0, faces z = +-0.0025

    def wl(**kw):
        return dict(W0, **kw)

    def at_z(z, **kw):
        return wl(a=[-0.4, z], b=[0.4, z], **kw)

    r = lambda v: round(v, 12) + 0.0
    h = CARDBOARD / 2
    C = CARDBOARD

    def facing_x(x, top):   # a wall line 0.6 m long whose front faces +X at x (its cardboard behind it), on a 0.74 m table
        return {'a': [r(x - h), 0.3], 'b': [r(x - h), -0.3], 'n': [1.0, 0.0], 'bottom': 0.74, 'top': top}
    STEPS = [facing_x(0.0, 1.54), facing_x(0.3, 1.19), facing_x(0.6, 1.24), facing_x(1.2, 1.64)]   # 0.8, 0.45, 0.5, 0.9 m high
    # (name, p, q, walls, points made for); the sagging curve between two pins 1 m apart at one height y dips to y - 0.06,
    # and over W0's cardboard (s 0.4975 .. 0.5025) its ends to y - 0.0599985. It passes over a wall when its lowest point
    # over the cardboard is at or above the top edge (1.34). A pin inside the cardboard, past the skin, cannot be got out
    # of without passing through it: its thread goes over from the far side, the piece from the pin runs into the wall
    # again and goes over it again, and the wall is gone over twice at most.
    walls = [
        ('through', [0, 1.0, -0.5], [0, 1.0, 0.5], [W0], 2),
        ('along-front-face', [-0.3, 1.0, h], [0.3, 1.0, h], [W0], 0),
        ('hair-inside', [-0.3, 1.0, r(h - 1e-11)], [0.3, 1.0, r(h - 1e-11)], [W0], 0),          # inside by less than the skin
        ('hair-inside-deeper', [-0.3, 1.0, r(h - 1e-8)], [0.3, 1.0, r(h - 1e-8)], [W0], 4),     # inside past it: over, and again
        ('end-exact', [0.4, 1.0, -0.5], [0.4, 1.0, 0.5], [W0], 0),
        ('end-inside', [r(0.4 - 1e-6), 1.0, -0.5], [r(0.4 - 1e-6), 1.0, 0.5], [W0], 2),
        ('end-skin', [r(0.4 - 1e-10), 1.0, -0.5], [r(0.4 - 1e-10), 1.0, 0.5], [W0], 0),
        ('beside-end', [0.5, 1.0, -0.5], [0.5, 1.0, 0.5], [W0], 0),
        ('over-top', [0, 1.6, -0.5], [0, 1.6, 0.5], [W0], 0),
        ('graze-top-above', [0, 1.400001, -0.5], [0, 1.400001, 0.5], [W0], 0),                  # lowest 1e-6 above the top edge
        ('graze-top-below', [0, 1.399998, -0.5], [0, 1.399998, 0.5], [W0], 2),                  # 2e-6 below it, the slab's ends too
        ('vertex', [0, 1.39999925, -0.5], [0, 1.39999925, 0.5], [W0], 2),                        # only its vertex is below
        ('over-the-clearance', [0, 1.403998, -0.5], [0, 1.403998, 0.5], [W0], 0),               # 3.998 mm over the edge: under top + OVER
        ('under-bottom', [0, 0.5, -0.5], [0, 0.5, 0.5], [W0], 0),
        ('parallel-inside', [-0.3, 1.0, 0.001], [0.3, 1.0, 0.001], [W0], 4),                    # along the cardboard, in it
        ('mid-plane-start', [0, 1.0, 0.0], [0, 1.0, 0.5], [W0], 4),                              # in it: first from q's other side
        ('walk-needed', [0, 1.0, -0.5], [0, 1.0, 0.5], [wl(top=2.0), at_z(0.05, top=1.5)], 2),     # over the first, the second is cleared
        ('walk-finds-more', [0, 1.0, -0.5], [0, 1.0, 0.5], [wl(top=1.6), at_z(0.1, bottom=1.3, top=1.7)], 4),   # the line passes under it
        ('reversed-list', [0, 1.0, -0.5], [0, 1.0, 0.5], [at_z(0.2, top=1.5), at_z(0.0, top=1.3), at_z(-0.2, top=1.1)], 6),
        ('two-same-lo', [0, 1.0, -0.5], [0, 1.0, 0.5], [W0, W0], 2),
        ('zero-wall', [0, 1.0, -0.5], [0, 1.0, 0.5], [wl(b=[-0.4, 0.0])], 0),
        ('graze-end', [0.3, 1.0, -h], [0.8, 1.0, h], [W0], 2),                                    # leaves by the end before the mid-plane
        ('graze-end-reversed', [0.8, 1.0, h], [0.3, 1.0, -h], [W0], 2),
        # the one curve clears the 0.45 m wall and runs into the 0.5 m one; the piece up to that goes over the low one too
        ('steps-low-in-the-way', [0, 1.2, 0], [r(1.2 - C), 1.4, 0], STEPS, 4),
    ]
    # (name, construction, (board, at) of p, (board, at) of q, points made for[, walls by board id])
    walls_on = [
        ('plane-back-front', 'odd_plane', ('ob_pa', [0, 0, -C]), ('ob_pb', [0, 0, 0]), 2),
        ('plane-front-front', 'odd_plane', ('ob_pa', [0, 0, 0]), ('ob_pb', [0, 0, 0]), 0),
        ('plane-back-back', 'odd_plane', ('ob_pa', [0, 0, -C]), ('ob_pb', [0, 0, -C]), 0),
        ('plane37-front-front', 'odd_plane37', ('ob_ra', [0.1, 0, 0]), ('ob_rb', [-0.1, 0.05, 0]), 0),
        ('plane37-back-front', 'odd_plane37', ('ob_ra', [0, 0, -C]), ('ob_rb', [0, 0, 0]), 2),
        ('touch-back-front', 'odd_touch', ('ob_ta', [0, 0, -C]), ('ob_tb', [0, 0, 0]), 2),
        ('back-gap-front-front', 'odd_back', ('ob_bc', [0, 0, 0]), ('ob_bd', [0, 0, 0]), 4),
        ('back-touch-backs', 'odd_back_touch', ('ob_be', [0.2, 0, -C]), ('ob_bf', [0.2, 0, -C]), 0),
        # front to front over both (the review's F1): ob_bf's near point on ob_be's side, where the line comes in from
        ('back-touch-front-front', 'odd_back_touch', ('ob_be', [0, 0, 0]), ('ob_bf', [0, 0, 0]), 4),
        # from a back pressed against the other wall's back: no way out but through cardboard; each wall twice, then no more
        ('back-touch-pressed', 'odd_back_touch', ('ob_be', [0.2, 0.05, -C]), ('ob_bf', [-0.1, 0, 0]), 8),
        ('angle-shallow', 'odd_angle', ('ob_ae', [0, 0, 0]), ('ob_ag', [0, 0, 0]), 4),
        ('heights-above', 'odd_heights', ('ob_h1', [0, 0.24, 0]), ('ob_h3', [0, 0.12, -C]), 0),
        ('heights-through', 'odd_heights', ('ob_h1', [0, -0.36, 0]), ('ob_h3', [0, -0.18, -C]), 2),
        ('heights-under', 'odd_heights', ('ob_h1b', [0, 0, 0]), ('ob_h3b', [0, 0, -C]), 0),
        ('row-front-front', 'odd_row', ('ob_r1', [0, 0, 0]), ('ob_r3', [0, 0, 0]), 4),
        ('row-back-back', 'odd_row', ('ob_r1', [0, 0, -C]), ('ob_r3', [0, 0, -C]), 4),
        ('row-reversed-list', 'odd_row', ('ob_r1', [0, 0, 0]), ('ob_r3', [0, 0, 0]), 4, ['ob_r3', 'ob_r2', 'ob_r1']),
        ('rowturned-front-front', 'odd_row_turned', ('ob_s1', [0, 0, 0]), ('ob_s3', [0, 0, 0]), 4),
        ('steps-front-back', 'odd_steps', ('ob_ka', [0, 0.06, 0]), ('ob_kd', [0, 0.21, -C]), 4),   # steps-low-in-the-way, stood on tables
    ]
    boards = [
        ('ob-front-back', [-0.2, 0, 0], [0.1, -0.1, -C], 'ob_case', 2),
        ('ob-back-front', [0.1, -0.1, -C], [-0.2, 0, 0], 'ob_case', 2),
        ('ob-one-face', [-0.2, 0, 0], [0.3, 0.1, 0], 'ob_case', 0),
        ('ob-paper', [-0.2, 0, 0], [0.1, -0.1, -C], 'op_paper', 0),
        ('ob-pick', [-0.2, 0, 0], [0.1, -0.1, -C], {'w': 0.8, 'h': 0.6, 'stock': 'cardboard'}, 2),
        ('ob-mirror', [0.1, 0.05, 0], [0.1, 0.05, -C], 'ob_case', 2),
        ('ob-beside', [0.5, 0, 0], [0.5, 0, -C], 'ob_case', 0),
        ('ob-above', [0, 0.35, 0], [0, 0.35, -C], 'ob_case', 0),
        ('ob-missing', [-0.2, 0, 0], [0.1, -0.1, -C], 'no_board', 0),
    ]
    # (name, p, q, over, tag made for): the longest piece, the first of equals within 1e-12
    pieces = [
        ('pc-none', [0, 0, 0], [1, 0, 0], [], 0),
        ('pc-equal', [0, 0, 0], [2, 0, 0], [[1, 0, 0]], 0),
        ('pc-within', [0, 0, 0], [1, 1.0000000000005, 0], [[1, 0, 0]], 0),
        ('pc-beyond', [0, 0, 0], [1, 1.000000000002, 0], [[1, 0, 0]], 1),
        ('pc-middle', [0, 0, 0], [1, 0, 0], [[0, 0.1, 0], [1, 0.1, 0]], 1),
        ('pc-four-equal', [0, 0, 0], [4, 0, 0], [[1, 0, 0], [2, 0, 0], [3, 0, 0]], 0),
        ('pc-last-longest', [0, 0, 0], [2, 0, 2], [[1, 0, 0], [2, 0, 0]], 2),
    ]
    cases = {'walls': [{'name': n, 'p': p, 'q': q, 'walls': ws} for n, p, q, ws, _ in walls] +
                      [dict({'name': e[0], 'construction': e[1], 'p': {'board': e[2][0], 'at': e[2][1]}, 'q': {'board': e[3][0], 'at': e[3][1]}},
                            **({'walls': e[5]} if len(e) > 5 else {})) for e in walls_on],
             'boards': [{'name': n, 'p': p, 'q': q, 'board': b} for n, p, q, b, _ in boards],
             'pieces': [{'name': n, 'p': p, 'q': q, 'over': o} for n, p, q, o, _ in pieces]}
    off = CARDBOARD / 2 + 0.003
    expect = {'walls': {e[0]: e[-1] for e in walls} | {e[0]: e[4] for e in walls_on}, 'boards': {e[0]: e[-1] for e in boards}, 'pieces': {e[0]: e[-1] for e in pieces},
              # and where some of them go over, in order from p: THREAD_CLEAR off each face, THREAD_OVER above the edge, the
              # near one on the side the line comes in through (from within the cardboard: the side q is not on). From a pin
              # inside it the wall is gone over a second time, nearer p (inserted after it), from the far side of the first.
              'points': {'walls': {'through': [[0, 1.344, -off], [0, 1.344, off]],
                                   'mid-plane-start': [[0, 1.344, off], [0, 1.344, -off], [0, 1.344, -off], [0, 1.344, off]],
                                   'graze-end': [[0.4, 1.344, -off], [0.4, 1.344, off]],
                                   'parallel-inside': [[-0.3, 1.344, -off], [-0.3, 1.344, off], [0, 1.344, off], [0, 1.344, -off]],
                                   # over the 0.45 m wall, then the 0.5 m one: each 4 mm over its own top edge
                                   'steps-low-in-the-way': [[0.3 - h - off, 1.194, 0], [0.3 - h + off, 1.194, 0], [0.6 - h - off, 1.244, 0], [0.6 - h + off, 1.244, 0]],
                                   # ob_be's front at z -1.995, the backs at -2.0, ob_bf's front at -2.005: 3 mm off each face
                                   'back-touch-front-front': [[3, 1.344, -1.992], [3, 1.344, -2.003], [3, 1.344, -1.997], [3, 1.344, -2.008]]},
                         'boards': {'ob-front-back': [[-0.05, 0.304, 0.003], [-0.05, 0.304, -0.008]]}}}
    return {'over': cases}, expect


def fuzz_over(n, seed):
    """n random threads over random constructions (1-4 tables and 2-6 walls each, any size, turned anyhow - some by
    quarter turns, some by 37 - a few feet past their table's edge), stickers on fronts and backs (half of the fronts
    mirrored), a few peeled stickers and cut threads, three in ten threads within one wall; and n / 4 random cases over
    1-6 random wall lines (some of no length; a quarter of the pins on or about a face or a mid-plane, along a wall or
    past its end), n / 20 over a random board, n / 50 random pieces (some of equal lengths). Numbers to 6 places."""
    import math
    import random
    rng = random.Random(seed * 7 + 1)
    r6 = lambda v: round(v, 6) + 0.0
    boards, cons, stickers, threads = [], [], [], []
    designs = ['punctum_hand_missing', 'punctum_nails', 'here_pink_triangle', 'no_such_design']

    def yaw():
        x = rng.random()
        if x < 0.3:
            return rng.choice([0, 90, 180, 270, -90, 360, 450])
        if x < 0.45:
            return rng.choice([37, 143, 217, 323, -37, 45, 30])
        return r6(rng.uniform(-400, 400))

    def up():
        if rng.random() < 0.6:
            return [0, 1, 0]
        a = rng.uniform(-math.pi, math.pi)
        return [r6(-math.sin(a)), r6(math.cos(a)), 0]

    def on(bid, w, h, back, sid):
        return sticker(sid, bid, (r6(rng.uniform(-0.45, 0.45) * w), r6(rng.uniform(-0.45, 0.3) * h)), back=back, up=up(),
                       design=rng.choice(designs), size=r6(rng.uniform(0.04, 0.2)))

    k = max(3, n // 400)
    sid = 0
    for ci in range(k):
        tabs = [{'id': f'fz_t{ci}_{ti}', 'w': r6(rng.uniform(0.3, 2.4)), 'd': r6(rng.uniform(0.3, 1.6)), 'h': rng.choice([0.74, 0.74, r6(rng.uniform(0.3, 1.5))]),
                 'at': [r6(rng.uniform(-2.5, 2.5)), r6(rng.uniform(-2.5, 2.5))], 'yaw': yaw()} for ti in range(rng.randint(1, 4))]
        walls, mine = [], []
        for wi in range(rng.randint(2, 6)):
            bid = f'fz_b{ci}_{wi}'
            w, h = (0.8, 0.6) if rng.random() < 0.4 else (r6(rng.uniform(0.2, 1.6)), r6(rng.uniform(0.2, 1.2)))
            boards.append({'id': bid, 'title': bid, 'w': w, 'h': h, 'paper': '#c4a27a', 'stock': 'cardboard'})
            t = rng.choice(tabs)
            walls.append({'board': bid, 'table': t['id'], 'at': [r6(rng.uniform(-t['w'] / 2 - 0.2, t['w'] / 2 + 0.2)), r6(rng.uniform(-t['d'] / 2 - 0.2, t['d'] / 2 + 0.2))],
                          'yaw': yaw()})
            front = []
            for _ in range(rng.randint(1, 4)):
                sid += 1
                front.append(on(bid, w, h, False, f'fz-s{sid}'))
            back = [mirror(s) for s in front if rng.random() < 0.5]
            for _ in range(rng.randint(0, 3)):
                sid += 1
                back.append(on(bid, w, h, True, f'fz-s{sid}'))
            for s in front + back:
                if rng.random() < 0.04:
                    s['state'] = 'peeled'
            mine += front + back
        cons.append({'id': f'fz_c{ci}', 'title': f'fuzz {ci}', 'tables': tabs, 'walls': walls})
        stickers += mine
        by_board = {}
        for s in mine:
            by_board.setdefault(s['host']['id'], []).append(s)
        for ti in range(max(8, n // k)):
            pool = rng.choice(list(by_board.values())) if rng.random() < 0.3 else mine
            if len(pool) < 2:
                continue
            a, b = rng.sample(pool, 2)
            t = tied(f'fz-th{ci}-{ti}', a['id'], b['id'])
            if rng.random() < 0.03:
                t['state'] = 'cut'
            threads.append(t)

    def line():
        ax, az = rng.uniform(-1.5, 1.5), rng.uniform(-1.5, 1.5)
        ang, length = rng.uniform(0, 2 * math.pi), (0.0 if rng.random() < 0.03 else rng.uniform(0.2, 1.6))
        sgn = rng.choice([1, -1])
        bottom = rng.uniform(0.3, 1.2)
        return {'a': [r6(ax), r6(az)], 'b': [r6(ax + length * math.cos(ang)), r6(az + length * math.sin(ang))],
                'n': [r6(-math.sin(ang) * sgn), r6(math.cos(ang) * sgn)], 'bottom': r6(bottom), 'top': r6(bottom + rng.uniform(0.2, 1.2))}

    def pin(ws):
        if ws and rng.random() < 0.25:   # about the first wall: on (about) a face or its mid-plane, along it or past its end
            w = ws[0]
            (ax, az), (bx, bz), (nx, nz) = w['a'], w['b'], w['n']
            t, off = rng.uniform(-0.15, 1.15), rng.choice([CARDBOARD / 2, -CARDBOARD / 2, 0.0, rng.uniform(-0.05, 0.05)])
            return [r6(ax + (bx - ax) * t + nx * off), r6(rng.uniform(0.2, 2.2)), r6(az + (bz - az) * t + nz * off)]
        return [r6(rng.uniform(-2, 2)), r6(rng.uniform(0.2, 2.2)), r6(rng.uniform(-2, 2))]

    cw = []
    for i in range(max(10, n // 4)):
        ws = [line() for _ in range(rng.randint(1, 6))]
        cw.append({'name': f'fz-w{i}', 'p': pin(ws), 'q': pin(ws), 'walls': ws})
    cb = []
    for i in range(max(5, n // 20)):
        b = rng.choice(boards)
        rb = b['id'] if rng.random() < 0.6 else {'w': r6(rng.uniform(0.2, 1.6)), 'h': r6(rng.uniform(0.2, 1.2)), 'stock': 'cardboard'}
        w, h = (b['w'], b['h']) if isinstance(rb, str) else (rb['w'], rb['h'])
        side = lambda: rng.choice([0, -CARDBOARD])
        cb.append({'name': f'fz-b{i}', 'p': [r6(rng.uniform(-0.7, 0.7) * w), r6(rng.uniform(-0.7, 0.7) * h), side()],
                   'q': [r6(rng.uniform(-0.7, 0.7) * w), r6(rng.uniform(-0.7, 0.7) * h), side()], 'board': rb})
    cp = []
    for i in range(max(5, n // 50)):
        if rng.random() < 0.5:   # equal steps along the axes
            L, at, pts = rng.choice([0.25, 0.5, 1.0]), [0.0, 0.0, 0.0], [[0.0, 0.0, 0.0]]
            for _ in range(rng.randint(1, 6)):
                at = list(at)
                at[rng.randrange(3)] += L * rng.choice([1, -1])
                pts.append(at)
        else:
            pts = [[r6(rng.uniform(-1, 1)) for _ in range(3)] for _ in range(rng.randint(2, 8))]
        cp.append({'name': f'fz-p{i}', 'p': pts[0], 'q': pts[-1], 'over': pts[1:-1]})
    doc = {'version': 1, 'revision': 1, 'stickers': stickers, 'threads': threads, 'strokes': [], 'applied': []}
    return ({'version': 1, 'revision': 1, 'boards': boards}, {'version': 1, 'revision': 1, 'constructions': cons}, doc,
            {'over': {'walls': cw, 'boards': cb, 'pieces': cp}})

# ---------------------------------------------------------------- mutants: one rule out each, and where each must bite
# (old text of the port, new text, the runs that must then differ[, the runs that may]). A mutant that bites nowhere
# else proves its rule is read only where it should be; one whose text is gone from the port is reported stale. MAY: the
# truth's research layout breaks a rule there only where its stickers happen to stand (a pair of pins that a rounding
# puts a hair inside a face, a thread whose lowest point over a wall is its vertex), so a bite there is allowed, not
# required; over:odd is made to break each rule wherever it is laid.

OVER_RUNS = {'over:research', 'over:odd'}

# over_walls' walk as the port has it (every piece held to every wall, each wall twice at most), and the old one in its
# place for the over-old-walk mutant: the rest of the curve from the last far point only, each wall once
OVER_WALK_NOW = (
    '\tvar met := PackedInt32Array()\n'
    '\tmet.resize(all.size())   # zero-filled: how often the thread has gone over each wall\n'
    '\tvar pts: Array = [a3(p), a3(q)]\n'
    '\tvar from := 0   # the pieces before the last insertion did not change and the walls only drop out: they stay clear\n'
    '\twhile true:\n'
    '\t\tvar at := -1\n'
    '\t\tvar wall := -1\n'
    '\t\tvar hit := {}\n'
    '\t\tvar k := from\n'
    '\t\twhile k + 1 < pts.size() and at < 0:   # the pieces from p: the first that runs into any wall\n'
    '\t\t\tfor i in all.size():\n'
    '\t\t\t\tif met[i] >= 2:\n'
    '\t\t\t\t\tcontinue   # over a wall twice at most (there and back)\n'
    '\t\t\t\tvar h := _into_wall(pts[k], pts[k + 1], all[i])\n'
    '\t\t\t\tif not h.is_empty() and (hit.is_empty() or float(h.lo) < float(hit.lo)):\n'
    '\t\t\t\t\thit = h\n'
    '\t\t\t\t\twall = i\n'
    '\t\t\tif not hit.is_empty():\n'
    '\t\t\t\tat = k\n'
    '\t\t\tk += 1\n'
    '\t\tif hit.is_empty():\n'
    '\t\t\tbreak\n'
    '\t\tmet[wall] += 1\n'
    '\t\tpts.insert(at + 1, hit.far)\n'
    '\t\tpts.insert(at + 1, hit.near)\n'
    '\t\tfrom = at\n'
    '\treturn pts.slice(1, pts.size() - 1)\n')
OVER_WALK_OLD = (
    '\tvar left: Array = range(all.size())\n'
    '\tvar over: Array = []\n'
    '\tvar cur := a3(p)\n'
    '\tvar end := a3(q)\n'
    '\twhile not left.is_empty():\n'
    '\t\tvar best := -1\n'
    '\t\tvar hit := {}\n'
    '\t\tfor i in left:\n'
    '\t\t\tvar h := _into_wall(cur, end, all[i])\n'
    '\t\t\tif not h.is_empty() and (hit.is_empty() or float(h.lo) < float(hit.lo)):\n'
    '\t\t\t\thit = h\n'
    '\t\t\t\tbest = i\n'
    '\t\tif hit.is_empty():\n'
    '\t\t\tbreak\n'
    '\t\tleft.erase(best)\n'
    '\t\tover.append(hit.near)\n'
    '\t\tover.append(hit.far)\n'
    '\t\tcur = hit.far\n'
    '\treturn over\n')

# a mutant that may never finish: its Godot runs get this many seconds (the watchdog's grace) instead of 120, and a run
# killed for it counts as a bite
MUTANT_LIMITS = {'over-no-cap': 45}

MUTANTS = {
    # settle ignores a cardboard wall's back
    'no-back': ('var back: bool = sided and float(a3(s.get("n"))[2]) < 0.0', 'var back: bool = false', {'ops:full', 'ops:boards'}),
    # cleanBoard forgets the stock: no board is a wall, and none has a back (nor goes over its top edge front to back)
    'no-stock': ('\t\tb["stock"] = "cardboard"\n\t\treturn b\n', '\t\tpass\n', {'ops:full', 'ops:boards', 'geometry:truth', 'geometry:after'} | OVER_RUNS),
    # a tie may not join two walls of one construction
    'no-walls': ('var one_construction: bool = on_boards and wall_map_in is Dictionary', 'var one_construction: bool = false and wall_map_in is Dictionary',
                 {'ops:full', 'ops:walls'}),
    # the old refusal of a tie across boards
    'old-words': ('a thread ties two stickers on one board, or on two walls of one construction', 'a thread ties two stickers on the same board',
                  {'ops:full', 'ops:boards', 'ops:walls', 'ops:bare'}),
    # a scribble's points are not put back on the board
    'no-clamp': ('var x := minf(hw, maxf(-hw, float(q[0]))) * 10000.0\n\t\t\t\tvar y := minf(hh, maxf(-hh, float(q[1]))) * 10000.0',
                 'var x := float(q[0]) * 10000.0\n\t\t\t\tvar y := float(q[1]) * 10000.0', {'ops:full', 'ops:boards'}),
    # the clamp's rounding taken out (points past the board still put back on it)
    'no-round': ('points.append([(cx if cx - 0.5 <= x else cx - 1.0) / 10000.0 + 0.0, (cy if cy - 0.5 <= y else cy - 1.0) / 10000.0 + 0.0])',
                 'points.append([x / 10000.0, y / 10000.0])', {'ops:full', 'ops:boards'}),
    # paper takes a scribble on its back
    'paper-back': ('if str(stk.get("face", "")) == "back" and not two_sided(board):', 'if false:', {'ops:full', 'ops:boards', 'ops:walls', 'ops:bare'}),
    # strokes are not in the one id space
    'two-spaces': ('return st.index.has(id) or st.tindex.has(id) or st.sindex.has(id)', 'return st.index.has(id) or st.tindex.has(id)',
                   {'ops:full', 'ops:boards', 'ops:walls', 'ops:bare'}),
    # an erase that does not keep who erased it
    'erase-forgets': ('s["erased"] = {"by": who, "t": now}', 'pass', {'ops:full', 'ops:boards', 'ops:walls', 'ops:bare'}),
    # a note trimmed in applyOps (it is cleanOp that trims; applyOps keeps what it is given)
    'note-trim': ('s["note"] = op.note', 's["note"] = str(op.note).strip_edges()', {'ops:full', 'ops:boards', 'ops:walls', 'ops:bare'}),
    # a wall turns the other way
    'yaw-sign': ('return [x * c + z * s, -x * s + z * c]', 'return [x * c - z * s, x * s + z * c]', {'geometry:truth', 'geometry:after'} | OVER_RUNS),
    # a wall's foot taken as the board's centre (no half height)
    'no-half-height': ('float(table.get("h", 0.0)) + float(board_rec.get("h", 0.0)) / 2.0 + q[1]', 'float(table.get("h", 0.0)) + q[1]',
                       {'geometry:truth', 'geometry:after'} | OVER_RUNS),
    # drawn strokes ignore their face
    'any-face': ('h.id == board_id \\\n\t\t\t\tand (face == "" or str(s.get("face", "")) == face):',
                 'h.id == board_id \\\n\t\t\t\tand (true or str(s.get("face", "")) == face):', {'geometry:truth', 'geometry:after'}),
    # a back stroke drawn on the front's plane
    'back-plane': ('return -CARDBOARD - STROKE_LIFT if face == "back" else STROKE_LIFT', 'return STROKE_LIFT', {'geometry:truth', 'geometry:after'}),
    # a stroke's id read with PCRE's $ (a final newline passes it)
    'dollar': ('const STICKER_ID := "^[a-z0-9][a-z0-9_-]{2,63}\\\\z"', 'const STICKER_ID := "^[a-z0-9][a-z0-9_-]{2,63}$"', {'geometry:truth', 'geometry:after'}),
    # ---- a thread never passes through cardboard ----
    # held once: the one curve goes over the first wall it meets, and the pieces are not held again
    'over-held-once': ('\t\tpts.insert(at + 1, hit.near)\n', '\t\tpts.insert(at + 1, hit.near)\n\t\tbreak\n', OVER_RUNS),
    # THE OLD WALK (2026-11-15): only the rest of the curve, from the last far point, each wall once; the pieces before it
    # are never held again (a piece up to a tall wall passes through a low one in its way)
    'over-old-walk': (OVER_WALK_NOW, OVER_WALK_OLD, {'over:odd'}, {'over:research'}),
    # THE OLD NEAR SIDE: the side p is on (Math.sign(z0) || 1), not the side the line comes in through (back to back, the
    # far point past the second wall's mid-plane turns it the wrong way)
    'over-old-near': ('var side := signf(z_in) if absf(z_in) >= band - 1e-12 else (-signf(z1) if absf(z1) >= band else (1.0 if z0 > 0.0 else (-1.0 if z0 < 0.0 else 1.0)))',
                      'var side := (1.0 if z0 > 0.0 else (-1.0 if z0 < 0.0 else 1.0))', {'over:odd'}, {'over:research'}),
    # THE OLD THRESHOLD: a curve passes over a wall only when its lowest point clears the top edge by THREAD_OVER (the
    # piece over the edge itself, sagging under top + THREAD_OVER, then runs into the wall again)
    'over-old-threshold': ('if _js_min(ys) >= _f(w.get("top")) or', 'if _js_min(ys) >= _f(w.get("top")) + THREAD_OVER or', OVER_RUNS),
    # a cap of 1: each wall gone over once at most (never there and back)
    'over-cap-1': ('if met[i] >= 2:', 'if met[i] >= 1:', {'over:odd'}, {'over:research'}),
    # no cap: a thread from a pin pressed against another wall, or inside cardboard, is chased round them for ever; its
    # run is bounded (MUTANT_LIMITS) and a hang is a bite
    'over-no-cap': ('if met[i] >= 2:', 'if false and met[i] >= 2:', {'over:odd'}, {'over:research'}),
    # the mid-plane crossing instead of the slab: a thread that grazes a wall and leaves by its end is not caught
    'over-mid-plane': ('[z0, z1, CARDBOARD / 2.0 - SKIN]', '[z0, z1, SKIN]', OVER_RUNS),
    # the crossing not kept within the stretch inside the cardboard (past the wall's end for a grazing thread)
    'over-unclamped': ('minf(hi, maxf(lo, z0 / (z0 - z1)))', 'z0 / (z0 - z1)', OVER_RUNS),
    # the near point put on the far side
    'over-near-flipped': ('var k := side * off', 'var k := -side * off', OVER_RUNS),
    # the tag on the last of equal pieces, not the first
    'over-tag-last': ('if l > best + 1e-12:', 'if l >= best - 1e-12:', OVER_RUNS),
    # no skin: a pin a hair inside a face (a rounding) counts as inside the cardboard
    'over-skin-0': ('const SKIN := 1e-9', 'const SKIN := 0.0', {'over:odd'}, {'over:research'}),
    # the curve's vertex forgotten: only the ends of the stretch say how low it runs
    'over-no-vertex': ('if sv > lo and sv < hi:', 'if false:', {'over:odd'}, {'over:research'}),
    # no bottom edge: a thread under a high wall goes over it
    'over-no-bottom': (' or _js_max(ys) < _f(w.get("bottom"))', '', {'over:odd'}, {'over:research'}),
    # the first wall in the list it runs into, not the first along it
    'over-list-order': ('(hit.is_empty() or float(h.lo) < float(hit.lo))', 'hit.is_empty()', OVER_RUNS),
    # a wall's line along its front face, not its cardboard's middle
    'over-line-front': ('var mid := -CARDBOARD / 2.0', 'var mid := 0.0', OVER_RUNS),
}

# ---------------------------------------------------------------- running


def write(p, obj):
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(obj, ensure_ascii=False), encoding='utf-8')


def godot(script, args, out, log, appdata, godot_exe, sd=None, limit=None):
    """One headless Godot run of a probe, through the watchdog, with its own user:// (APPDATA) folder; `limit`: the
    seconds it has to write its result (the watchdog's grace, 120 when not given) before it is killed as a hang."""
    if out.exists():
        out.unlink()
    appdata.mkdir(parents=True, exist_ok=True)
    grace = limit or 120
    cmd = [sys.executable, str(ROOT / 'tools' / 'godot_watchdog.py'), f'--expect={out}', f'--grace={grace}', '--stall=30', '--',
           godot_exe, '--headless', '--path', str(ROOT), '--xr-mode', 'off', '--log-file', str(log), '--script', f'res://tools/probes/{script}', '--']
    cmd += [str(a) for a in args] + ([f'--sd={sd}'] if sd else [])
    t = time.time()
    r = subprocess.run(cmd, env=dict(os.environ, APPDATA=str(appdata)), capture_output=True, text=True)
    if r.returncode != 0 or not out.exists():
        if r.returncode in (124, 125):   # the watchdog killed it (125: and it would not die): no result within the grace
            raise RuntimeError(f'godot {script} HUNG: killed by the watchdog after {time.time() - t:.0f} s with no result (grace {grace} s)'
                               + ('; THE PROCESS SURVIVED THE KILL' if r.returncode == 125 else ''))
        text = log.read_text(encoding='utf-8', errors='replace') if log.exists() else ''
        errors = [ln.strip() for ln in text.splitlines() if 'ERROR' in ln and 'NatureRenderer' not in ln]
        raise RuntimeError(f'godot {script} failed (exit {r.returncode}): ' + (' | '.join(errors[:3]) or text[-600:]))
    return json.loads(out.read_text(encoding='utf-8')), time.time() - t


def ts(mode, args, out):
    if out.exists():
        out.unlink()
    r = subprocess.run(['node', str(TSX), str(RUNNER), mode] + [str(a) for a in args], capture_output=True, text=True, cwd=str(ENC))
    if r.returncode != 0 or not out.exists():
        raise RuntimeError(f'the runner ({mode}) failed (exit {r.returncode}):\n{r.stdout[-800:]}\n{r.stderr[-1500:]}')
    return json.loads(out.read_text(encoding='utf-8'))


def compare(a, b, tol, path='$', st=None):
    """Every difference between the two trees: keys, lengths, words and booleans exactly; numbers within tol."""
    st = st if st is not None else {'values': 0, 'numbers': 0, 'max': 0.0, 'diffs': []}
    num = (int, float)
    if isinstance(a, bool) or isinstance(b, bool):
        st['values'] += 1
        if not (isinstance(a, bool) and isinstance(b, bool) and a == b):
            st['diffs'].append((path, a, b))
    elif isinstance(a, num) and isinstance(b, num):
        st['values'] += 1
        st['numbers'] += 1
        d = abs(float(a) - float(b))
        st['max'] = max(st['max'], d)
        if d > tol:
            st['diffs'].append((path, a, b))
    elif isinstance(a, str) and isinstance(b, str):
        st['values'] += 1
        if a != b:
            st['diffs'].append((path, a, b))
    elif a is None and b is None:
        st['values'] += 1
    elif isinstance(a, dict) and isinstance(b, dict):
        for k in sorted(set(a) | set(b)):
            if k not in a or k not in b:
                st['diffs'].append((f'{path}.{k}', a.get(k, '<missing>'), b.get(k, '<missing>')))
            else:
                compare(a[k], b[k], tol, f'{path}.{k}', st)
    elif isinstance(a, list) and isinstance(b, list):
        if len(a) != len(b):
            st['diffs'].append((f'{path}.length', len(a), len(b)))
        for i, (x, y) in enumerate(zip(a, b)):
            compare(x, y, tol, f'{path}[{i}]', st)
    else:
        st['diffs'].append((path, a, b))
    return st


VARIANTS = [('full', True, True), ('boards', True, False), ('walls', False, True), ('bare', False, False)]


def fuzz_ops(n, seed, base, boards, cons):
    """n random ops, seeded: poses with back normals and free ups (the pink triangle's snap read on either face), depths
    in and out of a deep board's range, every host kind, ties across walls, constructions and boards, scribbles with
    points past their board, erases and unerases, ids that collide across the three spaces, replays. Numbers as cleanOp
    leaves them (four places), so the server would take each op as it stands."""
    import random
    rng = random.Random(seed)
    r4 = lambda v: round(v, 4) + 0.0
    stickers = [s['id'] for s in base['stickers']]
    threads = [t['id'] for t in base['threads']]
    strokes = [s['id'] for s in base.get('strokes', [])]
    walls = [w['board'] for c in cons['constructions'] for w in c['walls']]
    board_ids = [b['id'] for b in boards['boards']] + ['nope_board']
    designs = ['punctum_hand_missing', 'punctum_nails', 'here_pink_triangle', 'here_pink_triangle']
    words = ['the gap', 'a hand', 'counted', 'returns', 'leaves out', '?']
    ops, done = [], []

    def vec(lo, hi):
        return [r4(rng.uniform(lo, hi)) for _ in range(3)]

    def host():
        r = rng.random()
        if r < 0.6:
            return board(rng.choice(walls))
        if r < 0.85:
            return board(rng.choice(board_ids))
        if r < 0.95:
            return {'kind': 'primitive', 'id': rng.choice(['box', 'sphere', 'cylinder', 'slab'])}
        return {'kind': 'void_floor', 'floor': 'QFEP_Phi_Term'}

    def pose():
        nrm = vec(-1, 1)
        nrm[2] = r4(-abs(nrm[2]) if rng.random() < 0.5 else abs(nrm[2]))
        return [r4(rng.uniform(-0.6, 0.6)), r4(rng.uniform(-0.4, 0.4)), r4(rng.uniform(-0.3, 1.0))], nrm, vec(-1, 1)

    def any_id():
        pool = [p for p in (stickers, threads, strokes) if p]
        return rng.choice(rng.choice(pool))

    for i in range(n):
        k = rng.choices(['add', 'move', 'peel', 'restore', 'note', 'front', 'tie', 'untie', 'retie', 'word', 'scribble', 'erase', 'unerase', 'replay'],
                        [14, 14, 5, 5, 3, 3, 16, 5, 5, 4, 16, 5, 5, 2])[0]
        oid = f'fz-{seed}-{i}'
        if k == 'replay' and done:
            ops.append(dict(rng.choice(done)))
            continue
        if k == 'add':
            sid = any_id() if rng.random() < 0.05 else f'fz-s-{i}'
            at, nrm, up = pose()
            o = add(oid, sid, None, at, n=nrm, up=up, design=rng.choice(designs + ['no_such_design'] * (rng.random() < 0.03)), size=r4(rng.uniform(0.05, 0.3)),
                    by=rng.choice(['vr:fuzz', 'someone', '']), host=host())
            stickers.append(sid)
        elif k == 'move':
            at, nrm, up = pose()
            o = move(oid, rng.choice(stickers), at, nrm, up, host=host() if rng.random() < 0.4 else None, size=r4(rng.uniform(0.05, 0.3)) if rng.random() < 0.3 else None)
        elif k in ('peel', 'restore', 'front'):
            o = one(oid, k, rng.choice(stickers) if rng.random() < 0.95 else any_id())
        elif k == 'note':
            o = one(oid, 'note', rng.choice(stickers), note=rng.choice(['', 'a note', ' padded ', 'x' * 20]))
        elif k == 'tie':
            tid = any_id() if rng.random() < 0.05 else f'fz-th-{i}'
            o = tie(oid, tid, rng.choice(stickers), rng.choice(stickers), word=rng.choice(words), colour=rng.choice(['#b3121b', '#8e0c16', None]),
                    why=rng.choice([None, 'because', 'they face each other']))
            threads.append(tid)
        elif k in ('untie', 'retie'):
            o = one(oid, k, rng.choice(threads))
        elif k == 'word':
            o = one(oid, 'word', rng.choice(threads), word=rng.choice(words))
            if rng.random() < 0.5:
                o['why'] = rng.choice(['', 'said again'])
        elif k == 'scribble':
            sid = any_id() if rng.random() < 0.05 else f'fz-st-{i}'
            pen = rng.choice(list(PENS))
            pts = [[r4(rng.uniform(-0.8, 0.8)), r4(rng.uniform(-0.6, 0.6))] for _ in range(rng.randint(2, 12))]
            o = scribble(oid, sid, rng.choice(walls + board_ids), rng.choice(['front', 'back']), pen, pts, width=r4(PENS[pen] * rng.uniform(0.5, 1.5)),
                         colour=rng.choice(['#16191e', '#b3121b', '#eb0d85', '#f2d318']))
            strokes.append(sid)
        else:
            o = one(oid, k, rng.choice(strokes) if rng.random() < 0.9 else any_id())
        ops.append(o)
        done.append(o)
    return ops


def ops_runs(fuzz):
    runs = [(name, 'ops.json', b, w) for name, b, w in VARIANTS]
    if fuzz:
        runs += [('fuzz', 'fuzz_ops.json', True, True), ('fuzz-bare', 'fuzz_ops.json', False, False)]
    return runs


def geometry_docs(run, fuzz):
    docs = [('truth', run / 'fixture' / 'placements.json'), ('after', run / 'after_placements.json')]
    return docs + ([('fuzz', run / 'after_fuzz_placements.json')] if fuzz else [])


def over_docs(run, fuzz):
    """The over runs: (name, placements, boards, constructions, cases)."""
    fx = run / 'fixture'
    docs = [('research', fx / 'over_research_placements.json', fx / 'boards.json', fx / 'truth_constructions.json', '-'),
            ('odd', fx / 'over_odd_placements.json', fx / 'over_odd_boards.json', fx / 'over_odd_constructions.json', fx / 'over_odd_cases.json')]
    if fuzz:
        docs += [('fuzz', fx / 'over_fuzz_placements.json', fx / 'over_fuzz_boards.json', fx / 'over_fuzz_constructions.json', fx / 'over_fuzz_cases.json'),
                 ('fuzz-ops', run / 'after_fuzz_placements.json', fx / 'boards.json', fx / 'constructions.json', '-')]
    return docs


def contract_side(run, fuzz):
    """The contract's answers (stickers.ts through the runner), computed once: they do not depend on the port. And THE
    PROPERTY of each over run (the runner's `property`, taken out of the answers the port is compared with)."""
    fx = run / 'fixture'
    want, props = {}, {}
    for name, ops_file, with_boards, with_walls in ops_runs(fuzz):
        out = run / f'ts_ops_{name}.json'
        tail = [fx / 'boards.json' if with_boards else '-'] + ([fx / 'constructions.json'] if with_walls else [])
        want[f'ops:{name}'] = ts('ops', [fx / 'placements.json', fx / ops_file, fx / 'designs.json', out] + tail, out)
    write(run / 'after_placements.json', want['ops:full']['doc'])   # the document the fixture leaves, as the server stores it
    if fuzz:
        write(run / 'after_fuzz_placements.json', want['ops:fuzz']['doc'])
    for name, doc in geometry_docs(run, fuzz):
        out = run / f'ts_geometry_{name}.json'
        want[f'geometry:{name}'] = ts('geometry', [doc, fx / 'designs.json', fx / 'boards.json', fx / 'constructions.json', fx / 'cases.json', out], out)
    for name, doc, boards, cons, cases in over_docs(run, fuzz):
        out = run / f'ts_over_{name}.json'
        want[f'over:{name}'] = ts('over', [doc, fx / 'designs.json', boards, cons, cases, out], out)
        props[f'over:{name}'] = want[f'over:{name}'].pop('property')
    return want, props


def port_jobs(run, label, sd, fuzz, limit=None):
    """The port's runs (the ops variants, the geometry on each document, the over runs) as godot() arguments; `limit`:
    the seconds each run has before it is killed as a hang (godot())."""
    fx = run / 'fixture'
    jobs = []
    for name, ops_file, with_boards, with_walls in ops_runs(fuzz):
        out = run / label / f'ops_{name}.json'
        tail = [fx / 'boards.json' if with_boards else '-'] + ([fx / 'constructions.json'] if with_walls else [])
        jobs.append((label, f'ops:{name}', 'stickers_apply_ops.gd', [fx / 'placements.json', fx / ops_file, fx / 'designs.json', out] + tail, out, sd, limit))
    for name, doc in geometry_docs(run, fuzz):
        out = run / label / f'geometry_{name}.json'
        jobs.append((label, f'geometry:{name}', 'stickers_cardboard_geometry.gd',
                     [doc, fx / 'designs.json', fx / 'boards.json', fx / 'constructions.json', fx / 'cases.json', out], out, sd, limit))
    for name, doc, boards, cons, cases in over_docs(run, fuzz):
        out = run / label / f'over_{name}.json'
        jobs.append((label, f'over:{name}', 'stickers_cardboard_geometry.gd', [doc, fx / 'designs.json', boards, cons, cases, out, '--mode=over'], out, sd, limit))
    return jobs


def over_stats(w):
    """What an over run holds, from the contract's answers: lines, threads between walls and how many walls each goes
    over, threads on one board and how many go over its top edge, cases."""
    rows = [r for c in w['constructions'].values() for r in c['threads']]
    brows = [r for rs in w['boards'].values() for r in rs]
    hist = {}
    for r in rows:
        hist[len(r['over']) // 2] = hist.get(len(r['over']) // 2, 0) + 1
    return {'lines': sum(len(c['lines']) for c in w['constructions'].values()), 'threads': len(rows), 'over_a_wall': sum(1 for r in rows if r['over']),
            'walls_gone_over': dict(sorted(hist.items())), 'board_threads': len(brows), 'over_a_top_edge': sum(1 for r in brows if r['over']),
            'tag_not_first': sum(1 for r in rows + brows if r['tag'] != 0), 'cases': {k: len(v) for k, v in w['cases'].items()}}


def property_totals(prop):
    """One over run's property, summed: over its constructions (threads between walls) and over its boards (threads on
    one cardboard board)."""
    keys = ('threads', 'over_a_wall', 'plain_through', 'through', 'pressed', 'pressed_through', 'close_through')
    tot = {part: {k: sum(h[k] for h in prop[part].values()) for k in keys} for part in ('constructions', 'boards')}
    for part in tot:
        deep = [h['deepest_mm'] for h in prop[part].values() if h['deepest_mm'] is not None]
        tot[part]['deepest_mm'] = max(deep) if deep else None
    return tot


def property_failures(props):
    """THE PROPERTY, run by run: every thread that passes through cardboard (no pin of it pressed against another wall),
    as '<run> <construction or board>: <n> threads through ... e.g. <thread> <depth> mm into <wall>'. [] when none does."""
    bad = []
    for key, prop in props.items():
        for part in ('constructions', 'boards'):
            for name, h in prop[part].items():
                if h['through']:
                    eg = '; '.join(f"{f['thread']} {f['depth_mm']} mm into {f['wall']} (piece {f['piece'] + 1} of {f['of']})" for f in h['failing'][:3])
                    bad.append(f'{key} {name}: {h["through"]} of {h["threads"]} threads through cardboard, e.g. {eg}')
    return bad


def show_property(key, prop):
    tot = property_totals(prop)
    c, b = tot['constructions'], tot['boards']
    print(f"  property {key:13s} between walls: {c['threads']} threads, {c['over_a_wall']} over a wall, {c['through']} THROUGH CARDBOARD, "
          f"{c['pressed']} with a pin pressed against another wall ({c['pressed_through']} of them through, allowed), {c['close_through']} through walls "
          f"too close to another (crossing, at a joint, or back to back under 4 mm: the known limit, counted apart); without the rule "
          f"{c['plain_through']} would pass through; deepest {c['deepest_mm']} mm.  On one wall: {b['threads']} threads, {b['over_a_wall']} over its top "
          f"edge, {b['through']} through, {b['plain_through']} as one curve; deepest {b['deepest_mm']} mm")
    for name, h in prop['constructions'].items():
        close = f"  too close {','.join(h['close'])}: {h['close_through']} through" if h.get('close') else ''
        print(f"      {name:16s} threads {h['threads']:5d}  over a wall {h['over_a_wall']:5d}  through {h['through']:3d}  pressed {h['pressed']:4d}"
              f" ({h['pressed_through']} through)  plain curve through {h['plain_through']:5d}  deepest {h['deepest_mm']} mm{close}")


def fixture_intent(want, expect, props=None):
    """The named cases as the contract answers them, against what each was made for: [] when every one gives it. With
    the over runs' property: it must bite (the one curve between the same pins passes through cardboard for > 40 threads
    of the research and of the odd layouts), and the odd layouts must hold pins pressed against another wall whose
    threads do pass through (or the exception would be untested)."""
    bad = []
    got = want['over:odd']['cases']
    for kind in ('walls', 'boards'):
        for name, n in expect[kind].items():
            v = got[kind].get(name)
            if v is None or len(v) != n:
                bad.append(f'{kind} {name}: {"missing" if v is None else len(v)} points, made for {n}')
    for name, tag in expect['pieces'].items():
        v = got['pieces'].get(name)
        if v is None or v['tag'] != tag:
            bad.append(f'pieces {name}: tag {None if v is None else v["tag"]}, made for {tag}')
    for kind, cases in expect['points'].items():
        for name, pts in cases.items():
            v = got[kind].get(name) or []
            if len(v) != len(pts) or any(abs(a - b) > 1e-8 for x, y in zip(v, pts) for a, b in zip(x, y)):
                bad.append(f'{kind} {name}: points {v}, made for {pts}')
    research = over_stats(want['over:research'])
    if research['over_a_wall'] < 40 or research['over_a_top_edge'] < 1:
        bad.append(f'research: {research["over_a_wall"]} threads over a wall, {research["over_a_top_edge"]} over a top edge (made for > 40 and > 0)')
    if props:
        for key in ('over:research', 'over:odd'):
            c = property_totals(props[key])['constructions']
            if c['plain_through'] <= 40:
                bad.append(f'{key}: the one curve passes through cardboard for {c["plain_through"]} threads (made for > 40: the property must bite)')
        c = property_totals(props['over:odd'])['constructions']
        if c['pressed'] < 1 or c['pressed_through'] < 1:
            bad.append(f'over:odd: {c["pressed"]} threads from a pressed pin, {c["pressed_through"]} of them through (made for > 0 each)')
    return bad


def run_jobs(run, jobs, want, godot_exe, workers):
    """Every Godot run, `workers` at once (each its own user:// and log), compared with the contract: {label: {run: stats}}."""
    def one_job(i, job):
        label, key, script, args, out, sd, limit = job
        out.parent.mkdir(parents=True, exist_ok=True)
        try:
            mine, secs = godot(script, args, out, out.with_suffix('.log'), run / 'appdata' / str(i), godot_exe, sd, limit)   # a user:// of its own
        except RuntimeError as e:   # a port that cannot run the probe at all (an older one lacks the functions) differs whole
            st = {'values': 0, 'numbers': 0, 'max': 0.0, 'diffs': [('$', 'the run failed: ' + str(e).strip()[:300], 'a document')], 'seconds': 0}
            return label, key, st
        st = compare(mine, want[key], 0.0 if key.startswith('ops:') else TOL)
        st['seconds'] = round(secs, 1)
        if key.startswith('ops:'):
            st['results'] = len(want[key]['results'])
            st['refused'] = sum(1 for r in want[key]['results'] if not r['ok'])
            st['skipped'] = sum(1 for r in want[key]['results'] if r['ok'] and r.get('skipped'))
        if key.startswith('over:'):   # where it differs: the constants, the walls' lines, the threads between walls, on one board, the cases
            sections = {'constants': lambda d: d.get('constants'), 'lines': lambda d: {c: v.get('lines') for c, v in (d.get('constructions') or {}).items()},
                        'wall_threads': lambda d: {c: v.get('threads') for c, v in (d.get('constructions') or {}).items()}, 'board_threads': lambda d: d.get('boards'),
                        'cases': lambda d: d.get('cases')}
            st['sections'] = {s: len(compare(f(mine) if isinstance(mine, dict) else None, f(want[key]), TOL)['diffs']) for s, f in sections.items()}
        return label, key, st
    res = {}
    with ThreadPoolExecutor(max_workers=workers) as pool:
        for label, key, st in pool.map(lambda ij: one_job(*ij), enumerate(jobs)):
            res.setdefault(label, {})[key] = st
    return res


def show(res, head):
    print(head)
    for k, st in res.items():
        extra = f", {st['results']} ops ({st['refused']} refused, {st['skipped']} skipped)" if 'results' in st else ''
        print(f"  {k:16s} {len(st['diffs']):4d} differences in {st['values']} values ({st['numbers']} numbers, largest difference {st['max']:.3g}){extra}  [{st['seconds']} s]")
        if 'sections' in st:
            print('      by section: ' + ', '.join(f'{s} {n}' for s, n in st['sections'].items()))
        for path, a, b in st['diffs'][:6]:
            print(f'      {path}: port {json.dumps(a)[:110]}  contract {json.dumps(b)[:110]}')


def main():
    opts = dict(a[2:].split('=', 1) if '=' in a else (a[2:], '1') for a in sys.argv[1:] if a.startswith('--'))
    out_root = Path(opts.get('out', ROOT / 'ada_run' / 'stickers' / 'cardboard_parity'))
    godot_exe = opts.get('godot', GODOT)
    workers = max(1, int(opts.get('workers', '3')))
    fuzz = max(0, int(opts.get('fuzz', '0')))
    seed = int(opts.get('seed', '20261114'))
    run = out_root / time.strftime('%Y%m%d-%H%M%S')
    fx = run / 'fixture'
    fx.mkdir(parents=True, exist_ok=True)
    truth = {d: json.loads((DATA / f'{d}.json').read_text(encoding='utf-8')) for d in DOCS}
    for d in ('designs', 'placements'):
        shutil.copyfile(DATA / f'{d}.json', fx / f'{d}.json')   # read from the truth, never written back
    boards = fixture_boards(truth['boards'])
    cons = fixture_constructions(truth['constructions'])
    write(fx / 'boards.json', boards)
    write(fx / 'constructions.json', cons)
    ops = fixture_ops()
    cases = fixture_cases()
    write(fx / 'ops.json', ops)
    write(fx / 'cases.json', cases)
    if fuzz:
        write(fx / 'fuzz_ops.json', fuzz_ops(fuzz, seed, truth['placements'], boards, cons))
    # the over runs: the truth's research construction as it stands (its own constructions document), the odd layouts,
    # the random ones
    write(fx / 'truth_constructions.json', truth['constructions'])
    write(fx / 'over_research_placements.json', over_research(truth['placements'], truth['constructions']))
    ob, oc, od, ocases, expect = over_odd()
    for part, doc in (('boards', ob), ('constructions', oc), ('placements', od), ('cases', ocases)):
        write(fx / f'over_odd_{part}.json', doc)
    if fuzz:
        for part, doc in zip(('boards', 'constructions', 'placements', 'cases'), fuzz_over(fuzz, seed)):
            write(fx / f'over_fuzz_{part}.json', doc)
    p = truth['placements']
    print(f'run folder {run}\nfixture: {len(ops)} ops, {sum(len(v) for v in cases.values())} cleaning cases' + (f', {fuzz} random ops (seed {seed})' if fuzz else '') +
          f'; base revision {p["revision"]}: {len(p["stickers"])} stickers, {len(p["threads"])} threads, {len(p.get("strokes", []))} strokes')
    t = time.time()
    want, props = contract_side(run, fuzz)
    print(f'the contract (stickers.ts): {time.time() - t:.1f} s')
    for name, *_ in over_docs(run, fuzz):
        print(f'  over:{name:10s} {json.dumps(over_stats(want[f"over:{name}"]))}')
    # THE PROPERTY, on the contract's answers (the port is held to those number for number below)
    for key, prop in props.items():
        show_property(key, prop)
    through = property_failures(props)
    print('the property: no drawn piece of any thread lies 0.1 mm or more inside cardboard, but from a pin pressed against another wall'
          if not through else 'THE PROPERTY FAILS: ' + ' | '.join(through))
    intent = fixture_intent(want, expect, props)
    print(f"fixture intent: {len(expect['walls']) + len(expect['boards']) + len(expect['pieces'])} named cases, the research layout and the property's negatives give what they were made for"
          if not intent else 'FIXTURE INTENT: ' + '; '.join(intent))
    jobs = port_jobs(run, 'port', opts.get('sd'), fuzz)
    src = PORT.read_text(encoding='utf-8')
    mutants = {}
    if 'mutants' in opts:
        only = set(opts['mutants'].split(',')) if opts['mutants'] != '1' else set(MUTANTS)   # --mutants=a,b: those alone
        unknown = only - set(MUTANTS)
        if unknown:
            print(f'no such mutants: {sorted(unknown)}')
            return 2
        for name, (old, new, must, *may) in MUTANTS.items():
            if name not in only:
                continue
            if src.count(old) != 1:
                mutants[name] = {'stale': src.count(old)}
                continue
            path = run / 'mutants' / f'sticker_data_{name}.gd'
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(src.replace(old, new), encoding='utf-8', newline='\n')
            mutants[name] = {'must': set(must), 'may': set(may[0]) if may else set()}
            # a mutant's bite is read on the fixture alone; one that may never finish runs bounded (MUTANT_LIMITS)
            jobs += port_jobs(run, f'mutant_{name}', str(path), 0, MUTANT_LIMITS.get(name))
    t = time.time()
    res = run_jobs(run, jobs, want, godot_exe, workers)
    print(f'{len(jobs)} Godot runs, {workers} at once: {time.time() - t:.1f} s')
    show(res['port'], f"the port under test: {opts.get('sd', 'commons/stickers/sticker_data.gd')}")
    ok = all(not st['diffs'] for st in res['port'].values()) and not intent and not through
    summary = {'run': str(run), 'ops': len(ops), 'fuzz': fuzz, 'seed': seed, 'cases': sum(len(v) for v in cases.values()), 'fixture_intent': intent,
               'over_fixture': {name: over_stats(want[f'over:{name}']) for name, *_ in over_docs(run, fuzz)},
               'property': {k: {'totals': property_totals(v), 'constructions': v['constructions'], 'boards': v['boards']} for k, v in props.items()},
               'property_failures': through,
               'port': {k: dict({'differences': len(v['diffs']), 'values': v['values'], 'numbers': v['numbers'], 'max': v['max']},
                                **({'sections': v['sections']} if 'sections' in v else {})) for k, v in res['port'].items()}}
    if mutants:
        summary['mutants'] = {}
        for name, m in mutants.items():
            if 'stale' in m:
                print(f'mutant {name}: STALE, its text is in the port {m["stale"]} times, not once')
                ok = False
                continue
            mres = res[f'mutant_{name}']
            bit = {k for k, st in mres.items() if st['diffs']}
            good = m['must'] <= bit <= m['must'] | m['may']
            verdict = 'bites where it should' if good else f'MUST {sorted(m["must"])} (MAY {sorted(m["may"])}), BIT {sorted(bit)}'
            print(f'mutant {name}: {verdict}; ' + ', '.join(f"{k} {len(st['diffs'])}" for k, st in mres.items()))
            for k, st in mres.items():
                if 'sections' in st and st['diffs']:
                    print(f'      {k} by section: ' + ', '.join(f'{s} {n}' for s, n in st['sections'].items() if n))
                for path, a, b in st['diffs'][:1]:
                    cut = 300 if path == '$' else 90   # a run that failed or hung says why in full
                    print(f'      {k} {path}: port {json.dumps(a)[:cut]}  contract {json.dumps(b)[:90]}')
            summary['mutants'][name] = {'must': sorted(m['must']), 'may': sorted(m['may']), 'bit': sorted(bit), 'ok': good,
                                        'differences': {k: len(st['diffs']) for k, st in mres.items()},
                                        'first': {k: [str(x)[:300] for x in st['diffs'][0]] for k, st in mres.items() if st['diffs']},
                                        'sections': {k: st['sections'] for k, st in mres.items() if 'sections' in st}}
            ok = ok and good
    write(run / 'summary.json', summary)
    print('PASS' if ok else 'FAIL')
    return 0 if ok else 1


if __name__ == '__main__':
    sys.exit(main())
