"""Create supplied E adapters from the unchanged F harness structure."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
study=root/'doc/book/studies/qfep-lineage'
text=(study/'f_term_museum.gd').read_text(encoding='utf8')
text=text.replace('f_term','e_term').replace('QFEP_F_Term','QFEP_E_Term').replace('StudentQFEPFTerm','StudentQFEPETerm')
text=text.replace('Vector3(4, 0, 12)','Vector3(10, 0, 12)')
(study/'e_term_museum.gd').write_text(text,encoding='utf8')
text=(study/'f_term.tscn').read_text(encoding='utf8').replace('f_term','e_term').replace('QFEPFTermLesson','QFEPETermLesson')
(study/'e_term.tscn').write_text(text,encoding='utf8')
text=(root/'tools/test_qfep_f_term.py').read_text(encoding='utf8').replace('F Term','E Term').replace('qfep_f_term','qfep_e_term').replace('qfep_f_student','qfep_e_student').replace('prediction_checks','possibility_checks')
(root/'tools/test_qfep_e_term.py').write_text(text,encoding='utf8')
