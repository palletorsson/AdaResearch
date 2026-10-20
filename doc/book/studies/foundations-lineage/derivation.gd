extends RefCounted
# Toy syntax only: 0, S0, SS0, ... . Axiom 0; rule w -> Sw.
func well_formed(word: String) -> bool:
    if not word.ends_with("0"): return false
    return word.left(word.length()-1).replace("S", "").is_empty()

func verify(proof: Array, target: String) -> bool:
    if not well_formed(target) or proof.is_empty() or proof[0] != "0": return false
    for i in range(1, proof.size()):
        if not proof[i] is String or proof[i] != "S"+str(proof[i-1]): return false
    return proof[-1] == target

func search(target: String, budget: int) -> Dictionary:
    if not well_formed(target) or budget < 0 or budget > 32:
        return {"status":"INVALID INPUT", "proof":[], "examined":0}
    var proof: Array[String] = ["0"]
    for step in range(budget+1):
        if proof[-1] == target:
            return {"status":"CHECKED DERIVATION", "proof":proof, "examined":step+1}
        if step < budget: proof.append("S"+proof[-1])
    return {"status":"NOT FOUND WITHIN BUDGET", "proof":proof, "examined":budget+1}
