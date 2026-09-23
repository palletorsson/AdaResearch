"""Offline regressions for paragraph coverage, cache identity and receipts.

No test reads credentials or calls the classification service.
Run with: python -m unittest tools.test_book_registers
"""
from copy import deepcopy
from contextlib import ExitStack, redirect_stdout
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from tools import book_registers as registers


TAXONOMY = {'version': 'test-1', 'labels': [
    {'id': 'technical', 'label': 'Technical', 'definition': 'Explains a mechanism.'},
    {'id': 'poetic', 'label': 'Poetic', 'definition': 'Uses evocative imagery.'},
]}
MODEL = 'jev-1.13.0'


def source_for(text, name='TestHall'):
    return {'map': name, 'blocks': registers.parse_blocks(text)}


def make_payload(text='A mechanism.\n\nA metaphor.'):
    rows = registers.paragraph_rows([source_for(text)])
    return registers.payload_for(rows, TAXONOMY, MODEL)


def response_for(payload):
    return {'model': payload['model'], 'answers': {
        key: {'type': 'noul', 'noul': 0.75} for key in payload['questions']
    }, 'usage': {'input_tokens': 321, 'output_tokens': 0}}


def payload_hash(payload):
    return registers.digest(json.dumps(payload, sort_keys=True, ensure_ascii=False))


class ParsingTests(unittest.TestCase):
    def assert_source_spans(self, text, blocks):
        lines = text.replace('\r\n', '\n').replace('\r', '\n').split('\n')
        for block in blocks:
            raw = '\n'.join(lines[block['start_line'] - 1:block['end_line']])
            self.assertEqual(block['source_text'], raw)
            self.assertEqual(block['sha256'], registers.digest(raw))

    def test_paragraphs_inside_lists_quotes_and_soft_line_breaks(self):
        text = '# Heading\n\nFirst\ncontinued.\n\n- Item one.\n- Item two.\n\n> Quoted.\n\nAfter.'
        blocks = registers.parse_blocks(text)
        self.assertEqual([b['text'] for b in blocks],
                         ['Heading', 'First\ncontinued.', 'Item one.', 'Item two.', 'Quoted.', 'After.'])
        self.assertEqual([(b['start_line'], b['end_line']) for b in blocks],
                         [(1, 1), (3, 4), (6, 6), (7, 7), (9, 9), (11, 11)])
        self.assert_source_spans(text, blocks)

    def test_code_headings_and_comments_are_not_classification_targets(self):
        text = '# Heading\n\n<!-- internal marker -->\n\n```python\n[^fake]: code\n```\n\n    indented code\n\nProse.'
        blocks = registers.parse_blocks(text)
        self.assertEqual([b['kind'] for b in blocks], ['heading', 'code', 'code', 'paragraph'])
        rows = registers.paragraph_rows([source_for(text)])
        self.assertEqual([r['block']['text'] for r in rows], ['Prose.'])
        self.assert_source_spans(text, blocks)

    def test_adjacent_single_word_footnotes_are_not_consumed_as_links(self):
        text = '[^one]: First\n[^two]: Second\n'
        blocks = registers.parse_blocks(text)
        self.assertEqual([b['kind'] for b in blocks], ['footnote', 'footnote'])
        self.assertEqual([b['text'] for b in blocks], ['First', 'Second'])
        self.assertEqual([b['start_line'] for b in blocks], [1, 2])
        self.assert_source_spans(text, blocks)

    def test_footnote_continuation_paragraphs_are_prose_and_have_offsets(self):
        text = 'Body.[^one]\n\n[^one]: First line\n    continued.\n\n    Second paragraph.\n\nAfter.'
        blocks = registers.parse_blocks(text)
        self.assertEqual([b['kind'] for b in blocks], ['paragraph', 'footnote', 'footnote', 'paragraph'])
        self.assertEqual([b['text'] for b in blocks], ['Body.[^one]', 'First line\ncontinued.', 'Second paragraph.', 'After.'])
        self.assertEqual([(b['start_line'], b['end_line']) for b in blocks], [(1, 1), (3, 4), (6, 6), (8, 8)])
        self.assert_source_spans(text, blocks)

    def test_code_within_a_footnote_stays_structural(self):
        text = '[^a]: Source explanation.\n\n        print(1)\n\n    Further explanation.'
        blocks = registers.parse_blocks(text)
        self.assertEqual([b['kind'] for b in blocks], ['footnote', 'code', 'footnote'])
        self.assertEqual(blocks[1]['text'], 'print(1)')
        self.assert_source_spans(text, blocks)

    def test_unicode_separators_do_not_shift_commonmark_source_offsets(self):
        text = 'First\r\nline\u2028still prose.\r\n\r\nSecond.\r\n'
        blocks = registers.parse_blocks(text)
        self.assertEqual(blocks[0]['source_text'], 'First\nline\u2028still prose.')
        self.assertEqual(blocks[1]['start_line'], 4)
        self.assert_source_spans(text, blocks)

    def test_repeated_paragraphs_have_unique_stable_ids(self):
        blocks = registers.parse_blocks('Repeat.\n\nRepeat.')
        self.assertNotEqual(blocks[0]['id'], blocks[1]['id'])
        self.assertEqual(blocks[0]['sha256'], blocks[1]['sha256'])
        self.assertEqual(blocks, registers.parse_blocks('Repeat.\n\nRepeat.'))
        rows = registers.paragraph_rows([source_for('Repeat.', 'A'), source_for('Repeat.', 'B')])
        self.assertNotEqual(rows[0]['target_id'], rows[1]['target_id'])

    def test_malformed_two_tick_closer_recovers_prose_without_rewriting_source(self):
        text = '```gdscript\nx = 1\n``\n\nRecovered prose.\n\n[^a]: Source.'
        blocks = registers.parse_blocks(text)
        self.assertEqual([b['kind'] for b in blocks], ['code', 'paragraph', 'footnote'])
        self.assertEqual(blocks[0]['source_text'], '```gdscript\nx = 1\n``')
        self.assertTrue(all('parse_warning' in b for b in blocks))
        self.assert_source_spans(text, blocks)

    def test_valid_fence_can_contain_two_ticks_without_recovery(self):
        text = '```text\n``\n\nStill code.\n```\n\nActual prose.'
        blocks = registers.parse_blocks(text)
        self.assertEqual([b['kind'] for b in blocks], ['code', 'paragraph'])
        self.assertIn('Still code.', blocks[0]['text'])
        self.assertFalse(any('parse_warning' in b for b in blocks))
        self.assert_source_spans(text, blocks)

    def test_ambiguous_malformed_fence_is_not_guessed(self):
        text = '```text\n``\n\nMaybe code.\n``\n\nMore.'
        blocks = registers.parse_blocks(text)
        self.assertEqual([b['kind'] for b in blocks], ['code'])
        self.assertIn('Unclosed code fence', blocks[0]['parse_warning'])
        self.assert_source_spans(text, blocks)


class PayloadTests(unittest.TestCase):
    def test_every_question_explicitly_names_only_its_target(self):
        payload = make_payload()
        self.assertEqual(len(payload['questions']), 4)
        ids = [p['id'] for p in payload['state']['paragraphs']]
        for i, target in enumerate(ids):
            for label in TAXONOMY['labels']:
                q = payload['questions'][f'p{i}_{label["id"]}']
                self.assertEqual(q['type'], 'noul')
                self.assertIn(repr(target), q['instructions'])
                self.assertNotIn(repr(ids[1-i]), q['instructions'])
                self.assertIn('annotation_rules', q['instructions'])
        self.assertIn('must not supply its labels', payload['state']['annotation_rules'])

    def test_context_and_targets_retain_authored_text(self):
        text = '# One\n\nFirst **paragraph**.\n\nSecond paragraph.\n\n# Two\n\nThird.'
        rows = registers.paragraph_rows([source_for(text)])
        self.assertEqual(rows[0]['context']['heading'], 'One')
        self.assertEqual(rows[0]['context']['next'], 'Second paragraph.')
        self.assertEqual(rows[2]['context']['heading'], 'Two')
        self.assertEqual(rows[0]['block']['text'], 'First **paragraph**.')

    def test_cache_identity_changes_for_each_inference_input(self):
        payload = make_payload()
        baseline = payload_hash(payload)
        variants = []
        changed = deepcopy(payload); changed['model'] = 'jev-other'; variants.append(changed)
        changed = deepcopy(payload); changed['state']['paragraphs'][0]['text'] += ' Revised.'; variants.append(changed)
        changed = deepcopy(payload); changed['state']['paragraphs'][0]['context']['heading'] = 'New heading'; variants.append(changed)
        changed = deepcopy(payload); changed['questions']['p0_technical']['instructions'] += ' New rubric.'; variants.append(changed)
        changed = deepcopy(payload); changed['state']['paragraphs'].reverse(); variants.append(changed)
        for changed in variants:
            with self.subTest(changed=changed):
                self.assertNotEqual(payload_hash(changed), baseline)


class ReceiptTests(unittest.TestCase):
    def setUp(self):
        self.payload = make_payload()
        self.response = response_for(self.payload)

    def validate(self, response):
        return registers.validate_response(response, self.payload, TAXONOMY['labels'], 2)

    def test_independent_probabilities_need_not_sum_to_one(self):
        self.assertEqual(self.validate(self.response), [
            {'technical': 0.75, 'poetic': 0.75}, {'technical': 0.75, 'poetic': 0.75}])

    def test_zero_and_one_are_valid_probabilities(self):
        self.response['answers']['p0_technical']['noul'] = 0
        self.response['answers']['p0_poetic']['noul'] = 1
        self.assertEqual(self.validate(self.response)[0], {'technical': 0, 'poetic': 1})

    def test_boolean_nonfinite_out_of_range_and_nonnumeric_scores_rejected(self):
        for value in [True, False, None, '0.5', [], {}, -0.001, 1.001, float('nan'), float('inf'), -float('inf')]:
            with self.subTest(value=value):
                response = deepcopy(self.response)
                response['answers']['p0_technical']['noul'] = value
                with self.assertRaises(ValueError): self.validate(response)

    def test_wrong_answer_type_and_malformed_answer_rejected(self):
        for answer in [None, [], 0.5, {'type': 'bool', 'noul': 0.5}, {'type': 'noul'}]:
            with self.subTest(answer=answer):
                response = deepcopy(self.response)
                response['answers']['p0_technical'] = answer
                with self.assertRaises(ValueError): self.validate(response)

    def test_missing_extra_or_cross_batch_answers_rejected(self):
        for change in ['missing', 'extra', 'wrong_batch']:
            response = deepcopy(self.response)
            if change == 'missing': del response['answers']['p0_technical']
            elif change == 'extra': response['answers']['p3_technical'] = {'type': 'noul', 'noul': 0.5}
            else: response['answers']['p2_technical'] = response['answers'].pop('p0_technical')
            with self.subTest(change=change), self.assertRaises(ValueError): self.validate(response)

    def test_wrong_or_missing_pinned_model_rejected(self):
        for model in [None, '', True, MODEL + '-other']:
            with self.subTest(model=model):
                response = deepcopy(self.response); response['model'] = model
                with self.assertRaises(ValueError): self.validate(response)

    def test_invalid_token_receipts_raise_controlled_validation_error(self):
        for usage in [None, [], 'bad', {}, {'input_tokens': True, 'output_tokens': 0},
                      {'input_tokens': 1, 'output_tokens': -1}, {'input_tokens': 1.0, 'output_tokens': 0}]:
            with self.subTest(usage=usage):
                response = deepcopy(self.response); response['usage'] = usage
                with self.assertRaises(ValueError): self.validate(response)


class OfflineRunTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.maps = self.root / 'commons/maps'
        (self.maps / 'sequences').mkdir(parents=True)
        (self.maps / 'curriculum_spine.json').write_text(json.dumps({'spine': {'sequences': [
            {'name': 'first', 'order': 1}]}}), encoding='utf-8')
        (self.maps / 'sequences/first.json').write_text(json.dumps({'sequences': {'first': {'maps': ['Main']}}}), encoding='utf-8')
        for name, content in [('Main', b'\xef\xbb\xbf# Title\r\n\r\nFirst.\r\n\r\nSecond.\r\n'), ('Outside', b'Outside paragraph.\n')]:
            folder = self.maps / name; folder.mkdir()
            (folder / 'final.md').write_bytes(content)
        self.taxonomy_path = self.root / 'taxonomy.json'
        self.taxonomy_path.write_text(json.dumps(TAXONOMY), encoding='utf-8')
        self.out = self.root / 'out'
        self.original_inventory = registers.inventory

    def run_prepare(self, *args):
        argv = ['book_registers.py', '--mode', 'prepare', '--out', str(self.out), *args]
        with ExitStack() as stack:
            stack.enter_context(patch.object(registers, 'ROOT', self.root))
            stack.enter_context(patch.object(registers, 'TAXONOMY_PATH', self.taxonomy_path))
            stack.enter_context(patch.object(registers, 'inventory', lambda: self.original_inventory(self.root)))
            stack.enter_context(patch.object(registers, 'get_key', side_effect=AssertionError('Credentials must not be read')))
            stack.enter_context(patch.object(registers, 'api_call', side_effect=AssertionError('Network must not be called')))
            stack.enter_context(patch('sys.argv', argv))
            stack.enter_context(redirect_stdout(io.StringIO()))
            result = registers.main()
        return result, json.loads((self.out / 'annotations.json').read_text(encoding='utf-8'))

    def seed_cache(self, model=MODEL):
        rows = registers.paragraph_rows(self.original_inventory(self.root))
        payload = registers.payload_for(rows, TAXONOMY, MODEL)
        response = response_for(payload); response['model'] = model
        cache = self.out / 'cache'; cache.mkdir(parents=True)
        (cache / (payload_hash(payload) + '.json')).write_text(json.dumps(response), encoding='utf-8')

    def test_inventory_and_prepare_preserve_all_original_file_bytes(self):
        before = {p: p.read_bytes() for p in self.maps.glob('*/final.md')}
        sources = self.original_inventory(self.root)
        self.assertEqual([s['map'] for s in sources], ['Main', 'Outside'])
        self.assertEqual([s['in_spine'] for s in sources], [True, False])
        result, data = self.run_prepare()
        self.assertEqual(result, 0)
        self.assertEqual(data['summary']['paragraphs'], 3)
        self.assertEqual(data['summary']['tagged'], 0)
        self.assertEqual(data['summary']['api_requests'], 0)
        self.assertTrue(data['sources_unchanged'])
        self.assertEqual(before, {p: p.read_bytes() for p in before})

    def test_exact_cache_is_reused_but_changed_context_is_pending(self):
        self.seed_cache()
        result, data = self.run_prepare()
        self.assertEqual(result, 0)
        self.assertEqual(data['summary']['tagged'], 3)
        self.assertEqual(data['summary']['cache_hits'], 1)
        path = self.maps / 'Main/final.md'
        path.write_bytes(path.read_bytes().replace(b'# Title', b'# Changed heading'))
        result, data = self.run_prepare()
        self.assertEqual(result, 0)
        self.assertEqual(data['summary']['tagged'], 0)
        self.assertEqual(data['summary']['cache_hits'], 0)

    def test_wrong_model_cached_receipt_is_reported_as_error(self):
        self.seed_cache(model='jev-other')
        result, data = self.run_prepare()
        self.assertEqual(result, 1)
        self.assertEqual(data['summary']['errors'], 1)
        self.assertEqual(data['summary']['tagged'], 0)
        self.assertEqual(data['summary']['api_requests'], 0)


if __name__ == '__main__':
    unittest.main()
