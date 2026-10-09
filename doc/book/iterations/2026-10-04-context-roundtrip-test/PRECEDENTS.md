# Systems to learn from

Primary sources consulted 4 October 2026. The applications to Ada below are our proposals, not capabilities demonstrated by this pilot.

## GraphRAG: ask at the right scale

Microsoft's GraphRAG separates global synthesis over generated community reports from local retrieval combining graph relationships and original text chunks. [Global search](https://microsoft.github.io/graphrag/query/global_search/), [local search](https://microsoft.github.io/graphrag/query/local_search/).

**Borrow:** whole-project questions read all relevant sequence summaries; an artifact question opens its source and dependencies. Start with Ada's existing authored sequence/map structure. A generated summary does not verify its source or judge the curriculum.

## RAPTOR: several levels, with links across them

RAPTOR builds a hierarchy by recursively clustering and summarizing documents. Its soft clustering permits overlapping groups, and its collapsed-tree retrieval can select material from different levels directly. [Research paper](https://arxiv.org/html/2401.18059v1#S3).

**Borrow:** keep summaries at project, sequence and map levels, but allow direct entry anywhere and thematic links across sequences. Trace can concern memory, drawing and later arrays. The hierarchy should help navigation without forcing one exclusive taxonomy. Generated summaries still need checking.

## Letta / MemGPT: explicit working memory

Letta exposes persistent memory blocks with labels, descriptions, size limits and editable contents. Attached blocks stay in context and may be shared or made read-only. Concurrent whole-value edits can overwrite one another. [Memory blocks documentation](https://docs.letta.com/v1-sdk/memory/memory-blocks).

**Borrow:** a small shared author brief, an active sequence summary and one local question. Give parallel readers separate reports; let one synthesis pass reconcile proposed changes. Preserve reasons and unresolved choices, not just compressed assertions. Persistence alone does not make a memory correct.

## Bazel Skyframe: know what a change affects

Skyframe records dependencies, evaluates independent work in parallel and invalidates dependent results when inputs change. Its correctness depends on declaring the inputs used. [Skyframe reference](https://bazel.build/reference/skyframe).

**Borrow:** attach source fingerprints to claims and link those claims to the summaries that use them. A changed Grid script flags the affected Grid/Array teaching relation for review. It does not require reopening every chapter, and a fingerprint change does not itself refute the claim. This borrows a build-system principle; installing Bazel is unnecessary. Editorial reasoning is less deterministic than a build.

## W3C PROV: retain where a claim came from

PROV describes entities, activities and agents, including derivation and attribution. It provides a structure for provenance rather than a certificate of truth. [PROV overview](https://www.w3.org/TR/prov-overview/), [PROV ontology](https://www.w3.org/TR/prov-o/).

**Borrow:** record source, version, inspection method, finding, reader, date and limits. Keep “author decision,” “source-supported,” “runtime-observed,” “proposed” and “unknown” separate. Agreement among several AI readers is not a substitute for independent evidence.

## What Ada needs next

Combine these ideas inside the files we already use before adding a platform:

1. **Orientation:** a small author brief plus project and sequence arcs.
2. **Selective detail:** a hall summary linked to its material and neighbours.
3. **Evidence:** scoped claims tied to versions and inspection methods.
4. **Return:** each local report names its consequence for the sequence and project.
5. **Freshness:** changed dependencies trigger a review of affected claims.

Keep two kinds of finding visible. An absent source, contradictory promise or undeclared prerequisite can be checked. Whether an encounter is moving, critically sharp or well placed needs reading, experience and artistic judgment. No retrieval or build system decides that for us.

The pilot tests one handoff and a simulated changed input. It does not implement a complete graph, automatic dependency discovery, continuous monitoring or a new memory service.
