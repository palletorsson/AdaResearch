"""Create supplied Lambda launch/test adapters from the preceding hall."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
study=root/'doc/book/studies/qfep-lineage'
text=(study/'e_term_museum.gd').read_text(encoding='utf8')
text=text.replace('e_term','lambda').replace('QFEP_E_Term','QFEP_Lambda_Spectrum').replace('StudentQFEPETerm','StudentQFEPLambda')
text=text.replace('Vector3(10, 0, 12)','Vector3(4, 0, 9)').replace('= PI / 2.0','= -PI / 2.0')
(study/'lambda_museum.gd').write_text(text,encoding='utf8')
text=(study/'e_term.tscn').read_text(encoding='utf8').replace('e_term','lambda').replace('QFEPETermLesson','QFEPLambdaLesson')
(study/'lambda.tscn').write_text(text,encoding='utf8')
text=(root/'tools/test_qfep_e_term.py').read_text(encoding='utf8').replace('E Term','Lambda').replace('qfep_e_term','qfep_lambda').replace('qfep_e_student','qfep_lambda_student').replace('possibility_checks','recommendation_checks')
(root/'tools/test_qfep_lambda.py').write_text(text,encoding='utf8')
