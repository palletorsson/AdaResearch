"""Apply the review pacing pass without changing any printed GDScript."""
from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'doc/book/iterations/2026-10-09-randomness-review-ready'


def replace_once(text, old, new):
    assert text.count(old) == 1, old[:150]
    return text.replace(old,new,1)


def main():
    maps = json.loads((ROOT/'commons/maps/sequences/randomness.json').read_text(encoding='utf-8-sig'))['sequences']['randomness']['maps']
    edits = {}
    starts = {
        'Random_Remove':'Read `eligible()` and `remove_one()` first: one builds the available set; the other selects and removes a member.',
        'Randomness_10_PRINT_Algorithm':'Read `choose_backslash()` and `build_pattern()` first. They turn one threshold test into a record of marks. `draw_pattern()` gives that record its lines.',
        'Random_Cubes':'Read `draw_face()` and `accept_face()` first. One requests an outcome; the other records it and decides whether another draw is allowed.',
        'Random_Mushrooms':'Read `regrow()` and `apply_sizes()` first. One samples the records; the other changes how a retained size is used. `make_mushroom()` supplies the two familiar primitive constructions.',
        'Random_Space_Geometry':'Read `replay()`, `sample_field()` and `neighbour_gap()` first: draw independent values, sample related values, then compare neighbouring addresses.'
    }
    for m in maps:
        path = ROOT/'commons/maps'/m/'tutorial.md'
        original = (OUT/'before'/m/'tutorial.md').read_text(encoding='utf-8-sig')
        text = original
        if m in starts:
            pos=text.index('<!-- student-code:')
            text=text[:pos]+starts[m]+'\n\n'+text[pos:]
        # Known code stays complete but need not interrupt each new operation.
        marker='<!-- student-code:point_body.gd -->'
        pos=text.index(marker)
        if text[:pos].count('<details>') == text[:pos].count('</details>'):
            block=re.search(r'<!-- student-code:point_body.gd -->\s*```gdscript\n.*?\n```',text,re.S)
            assert block
            text=text[:block.start()]+'<details>\n<summary>Complete inherited PointBody — keep this file beside the lesson</summary>\n\n'+block[0]+'\n\n</details>'+text[block.end():]
        if m == 'Random_Entropy':
            text=replace_once(text,'Read `new_sample`, `counts_of` and the first three lines of `draw_state` first. They create the record, count it and protect it with a copy. Then read `neighbour_changes` and `entropy_of`. `box_at`, `text_at` and `_ready` reuse familiar construction to make those operations visible.',
                'Read `new_sample`, `counts_of` and the first three lines of `draw_state` first: make a record, count it, protect its order with a copy. Then compare neighbours. The complete `entropy_of` function is included; follow its calculation after the sorting experiment. Construction and pickup reuse the earlier lessons.')
            a=text.index('## What the entropy function reads');b=text.index('## Predict, then change the copy',a)
            text=text[:a]+'''## What the entropy function reads

`entropy_of()` receives **counts**, with no positions or neighbouring pairs. Equal counts give the same reading even when their arrangements differ. That is the limit to investigate first.

Use two checks: `[4, 4, 4, 4]` gives H = 2 bits per symbol; `[16, 0, 0, 0]` gives H = 0. Neither result tells us where the symbols stood. Sorting keeps both readings. Run the comparisons below before following the calculation term by term.

<details>
<summary>Second reading: how the entropy calculation works</summary>

Add the counts to obtain the nonzero sample size. For each positive count, `p` is its share. `-log(p) / log(2.0)` gives the information value associated with that share; multiplying by `p` weights it. Summing those terms gives empirical marginal Shannon entropy in bits per symbol.

With four equal shares, each quarter contributes half a bit: H = 2. A single share of one contributes zero: H = 0. Skip zero counts before taking a logarithm; their contribution is zero, but `log(0)` cannot supply it. The program assumes a nonempty sample.

This calculation does not multiply by record length, predict from a previous entry or measure physical heat. Its input determines what it can notice.

</details>

'''+text[b:]
        if m == 'Random_Pheromone':
            old='Each step takes this order: **fade → deposit at the current address → count the visit → choose → move**. The starting position enters `path` immediately. A completed step adds one departure visit and one destination to the path, so after twenty steps there are twenty visits and twenty-one recorded positions. The latest position has not necessarily received a deposit yet.'
            new='''## Follow one update

Press STEP once and read `advance()` in this order:

1. **Fade:** reduce old scent, stopping at zero.
2. **Deposit:** add scent at the point's current address.
3. **Count:** add one visit there. This record does not fade.
4. **Choose:** either consult neighbouring scent or select a random direction.
5. **Move:** keep the destination in `path`, then redraw both views.

The starting position is already in the path. After one step there is one counted visit and two recorded positions; after twenty, twenty visits and twenty-one positions. The destination has not necessarily received a deposit yet. Follow this single update before using +20 or changing ATTRACT to AVOID.'''
            text=replace_once(text,old,new)
        bridges={
            'Random_Space_Geometry':('In Random Mushrooms you kept each body\'s record and changed how one property was displayed. Keep that separation here. Build two small grids at matching addresses: independent heights on the left, samples of a Perlin field on the right. Change the field\'s frequency while keeping every independent height.',
                'In Mushrooms a sampled value changed one body. Here the subject is **the relation between neighbours**. Build two grids at matching addresses: independent heights on the left, samples of one Perlin field on the right. Change its frequency while keeping every independent height.'),
            'Randomness_Examples_of_Randomness':('In Space Geometry you compared independent heights with values from a spatial field. Here the sampling rule has a different responsibility: it supplies evidence for an estimate. Keep the point, arrays and counters. Draw two coordinates, record the position, and ask whether it falls inside a circle.',
                'Space Geometry asked how neighbouring values relate. Here **draws supply evidence for an estimate**. Keep the point, arrays and counters. Draw two coordinates, record their position, and count whether it falls inside a circle. The sampling rule must suit the area we claim to measure.'),
            'Random_Pheromone':('The Random Walk point kept a trail, but never read it. The Monte Carlo board counted samples without letting a previous hit choose the next position. Here a visit changes a field that later movement reads. The record becomes part of the mechanism.',
                'The Walk point never read its trail; the Monte Carlo board never let a hit guide another sample. Here **a visit can change the next choice**. The point deposits a signal in its grid, then later movement reads that signal. The record enters the mechanism.'),
            'Random_Space':('In Synthesis, several weighted waves made one result. In Space Geometry, neighbouring addresses sampled one field. Here those operations meet: sample several fields at the same address and add their contributions. Unlike Pheromone, a visit changes nothing. The same address and settings give the same value regardless of the route you took through the room.',
                'Synthesis added weighted waves; Space Geometry sampled a field at neighbouring addresses. Here **fields combine at each address**. Sample several contributions and add them. Pheromone changed its field through visits; this construction returns the same value whenever the address and settings return.')
        }
        if m in bridges:text=replace_once(text,*bridges[m])
        # Preserve every complete listing and every small suggested code edit.
        assert re.findall(r'```gdscript\s*\n(.*?)```',original,re.S) == re.findall(r'```gdscript\s*\n(.*?)```',text,re.S),m
        edits[path]=text
    for revision in sorted((OUT/'revisions').glob('*.final.md')):
        m=revision.name.removesuffix('.final.md')
        text=revision.read_text(encoding='utf-8')
        before=(OUT/'before'/m/'final.md').read_text(encoding='utf-8-sig')
        assert re.findall(r'<!-- @.*?-->',before)==re.findall(r'<!-- @.*?-->',text),m
        assert re.findall(r'!\[.*?\]\((.*?)\)',before)==re.findall(r'!\[.*?\]\((.*?)\)',text),m
        edits[ROOT/'commons/maps'/m/'final.md']=text
    for path,text in edits.items():
        before=(OUT/'before'/path.parent.name/path.name).read_text(encoding='utf-8-sig')
        assert path.read_text(encoding='utf-8-sig') in (before,text),f'Concurrent edit: {path}'
    for path,text in edits.items():path.write_text(text.rstrip()+'\n',encoding='utf-8')
    print('Applied prose/presentation edits; every GDScript block and reflective artifact marker preserved.')


if __name__ == '__main__':main()
