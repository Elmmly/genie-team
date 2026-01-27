---
spec_version: "1.0"
type: design
id: TEST-5
title: Missing Spec Ref
status: designed
created: 2026-01-27
appetite: small
complexity: simple
ac_mapping:
  - ac_id: AC-1
    approach: Test approach
    components: [src/test.ts]
components:
  - name: TestComponent
    action: create
    files: [src/test.ts]
---

# Missing spec_ref — should fail design validation
