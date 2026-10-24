---
spec_version: "1.0"
type: shaped-work
id: P1-fixture-program
title: "Fixture P1-fixture-program"
status: designed
created: 2026-10-24
appetite: small
kind: program
slices:
  - tests/fixtures/program/valid/slice-a.md
  - tests/fixtures/program/valid/slice-b.md  # builds on slice-a
verify: make test
acceptance_criteria:
  - id: AC-1
    description: Fixture criterion
    status: pending
---

# Fixture P1-fixture-program
