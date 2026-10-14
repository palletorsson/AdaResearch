"""Reconcile preserved ZIP inputs against the committed proposal and local evidence."""
from pathlib import Path
import hashlib
import json
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
INPUT = HERE / "imports/2026-10-14"
BASE_COMMIT = "e5414cb18"

# Imported IDs are provenance, not additional live tracker tickets.
MAPPING = {
    "ada_random_noise_route": [[1], [2], [1, 6], [2, 5], [6, 15, 18], [2, 7], [3], [20], [20]],
    "ada_particles_tutorial": [[1, 8], [8], [9], [11], [10], [13], [12, 18], [3, 8, 9], [13, 20]],
    "ada_random_noise_artifacts": [[1, 4], [4], [14], [6], [5], [6, 7], [7, 12], [7], [12], [18]],
    "ada_dissipated_author_book": [["w1"], ["w1"], ["w2"], ["w2"], ["w3"], ["w4"]],
}


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def git_bytes(path):
    return subprocess.check_output(["git", "show", f"{BASE_COMMIT}:{path}"], cwd=ROOT)


def main():
    manifest = read_json(INPUT / "manifest.json")
    for name, digest in manifest["files"].items():
        assert hashlib.sha256((INPUT / name).read_bytes()).hexdigest() == digest, name
    source_paths = [f"commons/maps/sequences/{s}.json" for s in ("randomness", "noise", "particles")]
    source_paths += ["commons/maps/curriculum_spine.json", "commons/data/map_authored.json", "commons/data/museum/em_plan.json"]
    source_paths += [f"commons/maps/{m}/map_data.json" for m in ("Random_Definition", "Randomness_10_PRINT_Algorithm")]
    source_paths += ["commons/maps/Noise_Perlin_Simplex/final.md", "commons/maps/Noise_Perlin_Simplex/tutorial.md"]
    source_paths += [f"doc/tasks/{g}.json" for g in ("book_randomness", "book_noise")]
    evidence = {p: {"working_sha256": hashlib.sha256((ROOT / p).read_bytes()).hexdigest(),
                    "committed_sha256": hashlib.sha256(git_bytes(p)).hexdigest()} for p in source_paths}
    orders = {}
    for name in ("randomness", "noise", "particles"):
        p = f"commons/maps/sequences/{name}.json"
        orders[name] = {"committed": json.loads(git_bytes(p))["sequences"][name]["maps"],
                        "working": read_json(ROOT / p)["sequences"][name]["maps"]}
    textile = {}
    for m in ("Random_Definition", "Randomness_10_PRINT_Algorithm"):
        p = f"commons/maps/{m}/map_data.json"
        textile[m] = {}
        for label, d in (("committed", json.loads(git_bytes(p))), ("working", read_json(ROOT / p))):
            textile[m][label] = [v for row in d["layers"]["interactables"] for v in row if "textile_comparison" in str(v)]
    existing_tasks = []
    for g, nums in (("book_randomness", [1,17,18,19,20,21,26,28,29,30,44]), ("book_noise", [14,17,19,20])):
        for t in read_json(ROOT / f"doc/tasks/{g}.json")["tasks"]:
            if int(t["id"].split(".")[-1]) in nums:
                existing_tasks.append({k: t[k] for k in ("id", "title", "status")})
    tasks = []
    for g, targets in MAPPING.items():
        imported = read_json(INPUT / f"doc/tasks/{g}.json")["tasks"]
        assert len(imported) == len(targets), g
        for t, mapped in zip(imported, targets):
            ids = [f"randomness_research_writing.{int(x[1:]):03}" if isinstance(x, str)
                   else f"randomness_research.{x:03}" for x in mapped]
            tasks.append({"imported_id": t["id"], "title": t["title"], "incorporated_into": ids})
    result = {"date": "2026-10-14", "baseline_commit": BASE_COMMIT,
              "source_zip_sha256": manifest["sha256"], "evidence": evidence,
              "orders": orders, "textile_locations": textile, "existing_task_statuses": existing_tasks,
              "imported_task_mapping": tasks, "runtime_verified": False,
              "historical_library_snapshots": "Described by ZIP, not supplied or independently verified in this comparison"}
    (HERE / "comparison.json").write_text(json.dumps(result, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
    print(f"Compared {len(evidence)} current/committed sources; mapped {len(tasks)} imported tasks.")


if __name__ == "__main__":
    main()
