# SC-05 — False Consensus

Status: PROSPECTIVE / AUTHORITY_EFFECT=NONE / RUNTIME_EFFECT=NONE

## H0
Treatment does not improve the preregistered endpoint over the control after matched resources and declared multiplicity correction.

## H1
Treatment changes independent_evidence_accuracy in the preregistered direction.

## Control
majority over copied evidence

## Treatment
lineage-aware collapse

## Primary endpoint
independent_evidence_accuracy

## Required controls
- frozen task generator and seeds;
- matched model/tool portfolio unless the experiment explicitly varies model/tokenizer;
- complete denominator retention;
- provenance/currentness binding;
- no retry of failed episodes;
- negative-result publication.

## Falsifier
Failure to preserve the predicted relation-specific or system-level effect under the declared controls weakens the corresponding Semantic Cloud hypothesis.

## Evidence
Every run must publish manifest, exact model/runtime identity, seeds, trials, summary, audit and explicit deviations from preregistration.
