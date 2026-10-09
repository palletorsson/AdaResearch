"""Negative controls: a green check must not survive a broken lesson dependency."""
from pathlib import Path
from hashlib import sha256
import json
import tempfile
import unittest
from reconstruction import compose, digest, validate


class ReconstructionChecks(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        (self.root/'point.gd').write_text('extends Node3D\n')
        (self.root/'lesson.md').write_text('```gdscript\nextends Node3D\n```\n')
        (self.root/'support.gd').write_text('extends Node\n')
        self.contract = dict(brief={k:'Declared' for k in ('make','bring','given','build','check','later')},
                             lesson='lesson.md',example='point.gd',host='Prepared test mount',
                             sources=[dict(path='support.gd',sha256=sha256((self.root/'support.gd').read_bytes()).hexdigest())],
                             checks=[dict(id='release',action='Release body',expect='Body remains',kind='native')])

    def test_complete_declared_example(self):
        self.assertEqual(validate(self.contract,self.root)['structure'],'pass')

    def test_excerpt_is_not_a_complete_build(self):
        (self.root/'lesson.md').write_text('```gdscript\nvar sphere = SphereMesh.new()\n```\n')
        self.assertIn('printed-code', ' '.join(validate(self.contract,self.root)['errors']))

    def test_missing_scaffold_is_not_a_pass(self):
        (self.root/'support.gd').unlink()
        self.assertIn('source: missing', ' '.join(validate(self.contract,self.root)['errors']))

    def test_changed_scaffold_demands_review(self):
        (self.root/'support.gd').write_text('extends Node3D\n')
        self.assertIn('source: changed', ' '.join(validate(self.contract,self.root)['errors']))

    def test_stale_native_evidence_is_not_a_pass(self):
        self.contract['native_report']='native.json'
        (self.root/'native.json').write_text(json.dumps(dict(passed=True,learner_source_sha256='obsolete')))
        self.assertEqual(validate(self.contract,self.root)['native']['status'],'stale')

    def test_no_claim_of_learning_from_code(self):
        self.assertEqual(validate(self.contract,self.root)['learner_understanding'],'not tested')


class ContinuationChecks(unittest.TestCase):
    """The outgoing artifact must come from the saved state and printed edits."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.incoming = 'extends Node3D\nvar point := StaticBody3D.new()\n'
        self.operations = [
            dict(id='pickable', kind='replace',
                 before='var point := StaticBody3D.new()',
                 after='var point := XRToolsPickable.new()'),
            dict(id='freeze', kind='insert_after',
                 anchor='var point := XRToolsPickable.new()\n',
                 text='point.freeze = true\n'),
        ]
        self.write('incoming.gd', self.incoming)
        self.write('outgoing.gd', compose(self.incoming, self.operations))
        self.write('support.gd', 'extends RigidBody3D\n')
        self.write('verify.gd', '# Native verifier fixture\n')
        self.write('lesson.md', '\n'.join(
            '```gdscript\n' + fragment.rstrip() + '\n```\n'
            for fragment in (
                self.operations[0]['before'], self.operations[0]['after'],
                self.operations[1]['anchor'] + self.operations[1]['text'])))
        self.contract = dict(
            mode='continuation',
            brief={k: 'Declared' for k in ('make', 'bring', 'given', 'build', 'check', 'later')},
            lesson='lesson.md', example='outgoing.gd', host='Prepared test mount',
            incoming=dict(path='incoming.gd', sha256=digest(self.root/'incoming.gd'),
                          provenance='Assumed prior lesson state; not a certified learner build.'),
            operations=self.operations,
            sources=[dict(path='support.gd', sha256=digest(self.root/'support.gd'))],
            native_report='native.json',
            evidence_inputs=['incoming.gd', 'lesson.md', 'contract.json', 'verify.gd'],
            checks=[dict(id='release', action='Release body', expect='Body remains', kind='native')],
        )
        self.write_contract()
        self.report = dict(
            passed=True, learner_source_sha256=digest(self.root/'outgoing.gd'),
            dependencies={'support.gd': digest(self.root/'support.gd')},
            inputs={p: digest(self.root/p) for p in self.contract['evidence_inputs']},
            checks=[dict(id='release', passed=True)], scope='Fixture evidence only',
        )
        self.write_report()

    def write(self, path, content):
        (self.root/path).write_text(content, encoding='utf-8')

    def write_contract(self):
        self.write('contract.json', json.dumps(self.contract))

    def write_report(self):
        self.write('native.json', json.dumps(self.report))

    def result(self):
        self.write_contract()
        return validate(self.contract, self.root)

    def assert_failure(self, error_fragment):
        result = self.result()
        self.assertEqual(result['structure'], 'fail', result)
        self.assertIn(error_fragment, ' '.join(result['errors']))
        return result

    def test_printed_edits_compose_in_order_without_printing_full_program(self):
        self.assertEqual(compose(self.incoming, self.operations),
                         'extends Node3D\nvar point := XRToolsPickable.new()\npoint.freeze = true\n')
        result = self.result()
        self.assertEqual(result['structure'], 'pass', result)
        self.assertEqual(result['native']['status'], 'pass')
        self.assertEqual(result['learner_understanding'], 'not tested')

    def test_missing_anchor_is_not_guessed(self):
        self.operations[0]['before'] = 'var point := MissingBody.new()'
        self.assert_failure('anchor occurs 0 times')

    def test_ambiguous_anchor_is_not_guessed(self):
        self.write('incoming.gd', self.incoming + self.operations[0]['before'] + '\n')
        self.contract['incoming']['sha256'] = digest(self.root/'incoming.gd')
        self.assert_failure('anchor occurs 2 times')

    def test_unprinted_edit_is_not_supplied_by_contract(self):
        self.write('lesson.md', '```gdscript\n' + self.operations[0]['before'] + '\n```\n')
        self.assert_failure('printed-edit: missing pickable')

    def test_stale_incoming_is_not_a_valid_starting_state(self):
        self.write('incoming.gd', '# Changed upstream\n' + self.incoming)
        self.assert_failure('incoming: missing or changed state')

    def test_handmade_outgoing_cannot_pass_even_with_fresh_native_hash(self):
        self.write('outgoing.gd', compose(self.incoming, self.operations) + 'point.name = "Hidden edit"\n')
        self.report['learner_source_sha256'] = digest(self.root/'outgoing.gd')
        self.write_report()
        self.assert_failure('assembly: example is not incoming plus declared edits')

    def test_missing_declared_native_report_is_not_a_pass(self):
        (self.root/'native.json').unlink()
        result = self.result()
        self.assertEqual(result['structure'], 'fail', result)
        self.assertNotEqual(result['native']['status'], 'pass')

    def test_native_report_may_be_omitted_without_claiming_execution(self):
        del self.contract['native_report']
        result = self.result()
        self.assertEqual(result['structure'], 'pass', result)
        self.assertEqual(result['native']['status'], 'not tested')

    def test_empty_native_checks_do_not_validate_by_vacuity(self):
        self.report['checks'] = []
        self.write_report()
        result = self.assert_failure('native-evidence: empty dependencies or checks')
        self.assertNotEqual(result['native']['status'], 'pass')

    def test_empty_runtime_dependencies_do_not_validate_by_vacuity(self):
        self.report['dependencies'] = {}
        self.write_report()
        result = self.assert_failure('native-evidence: empty dependencies or checks')
        self.assertNotEqual(result['native']['status'], 'pass')

    def test_missing_declared_native_check_is_not_a_pass(self):
        self.report['checks'] = [dict(id='unrelated', passed=True)]
        self.write_report()
        result = self.assert_failure('native-evidence: missing passing check release')
        self.assertNotEqual(result['native']['status'], 'pass')

    def test_failed_native_check_overrides_report_summary(self):
        self.report['checks'][0]['passed'] = False
        self.write_report()
        result = self.assert_failure('native-evidence: missing passing check release')
        self.assertNotEqual(result['native']['status'], 'pass')

    def test_missing_evidence_binding_is_stale(self):
        del self.report['inputs']['incoming.gd']
        self.write_report()
        result = self.assert_failure('native-evidence: stale')
        self.assertEqual(result['native']['status'], 'stale')

    def test_changed_lesson_makes_native_evidence_stale(self):
        lesson = (self.root/'lesson.md').read_text(encoding='utf-8')
        self.write('lesson.md', lesson + '\nA changed instruction.\n')
        self.assert_failure('native-evidence: stale')

    def test_changed_edit_contract_makes_native_evidence_stale(self):
        self.operations[0]['id'] = 'revised-pickable-edit'
        self.assert_failure('native-evidence: stale')

    def test_changed_verifier_makes_native_evidence_stale(self):
        self.write('verify.gd', '# Different native assertions\n')
        self.assert_failure('native-evidence: stale')


if __name__ == '__main__':
    unittest.main()
