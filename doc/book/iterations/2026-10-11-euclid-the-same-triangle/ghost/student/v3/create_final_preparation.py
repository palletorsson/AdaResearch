from pathlib import Path

HERE = Path(__file__).resolve().parent
source = (HERE.parent / 'v2' / 'prepare_v2.py').read_text(encoding='utf-8')
source = source.replace('v2', 'v3').replace("GHOST / 'revised-input'", "GHOST / 'final-input'")
source = source.replace('    var outlines_removed = true', '    var outlines_removed = true\n    var zero_outline_count = 0')
source = source.replace('            outlines_removed = outlines_removed and child.outline_size == 0', '''            if child == host.readout:
                outlines_removed = outlines_removed and child.outline_size == 6 and child.outline_modulate == Color.WHITE
            else:
                outlines_removed = outlines_removed and child.outline_size == 0
                if child.outline_size == 0: zero_outline_count += 1''')
source = source.replace('    check("v3.all_label_outlines_zero", outlines_removed)', '''    check("v3.final_label_outline_policy", outlines_removed)
    check("v3.five_labels_without_outline", zero_outline_count == 5, zero_outline_count, 5)
    near("v3.readout_outline_size", host.readout.outline_size, 6.0)
    check("v3.readout_white_outline", host.readout.outline_modulate == Color.WHITE, str(host.readout.outline_modulate), "WHITE")''')
source = source.replace("'outline_size_for_all_direct_labels': 0,", "'outline_sizes': {'five_corner_and_button_labels': 0, 'readout': 6, 'readout_outline_color': 'WHITE'},")
source = source.replace('euclid_study.gd adds outline_size=0 for three corner labels, readout, and two button labels.', 'euclid_study.gd adds outline_size=0 for three corner and two button labels; readout has outline_size=6 and outline_modulate=Color.WHITE.')
source = source.replace('Parent supplied revised packet and stated intended presentation changes.', 'Parent supplied final visually checked packet and stated intended presentation changes; intermediate v2 was frozen but superseded before engine execution.')
source = source.replace("'new_reads':", "'previous_intermediate_packet': 'student/v2 retained, no engine execution',\n    'new_reads':")
extra = '''
intermediate_diff = ''.join(difflib.unified_diff(read(INITIAL / 'v2' / 'euclid_study.gd').splitlines(True), read(HERE / 'euclid_study.gd').splitlines(True), fromfile='v2/euclid_study.gd', tofile='v3/euclid_study.gd'))
(HERE / 'final_vs_intermediate.diff').write_text(intermediate_diff, encoding='utf-8')
print('Final versus intermediate source:')
print(intermediate_diff)
'''
source = source.replace("source_diffs =", extra + "\nsource_diffs =", 1)
(HERE / 'prepare_v3.py').write_text(source, encoding='utf-8')
(HERE / 'run_probes.py').write_text((HERE.parent / 'v2' / 'run_probes.py').read_text(encoding='utf-8').replace('/v2/', '/v3/'), encoding='utf-8')
