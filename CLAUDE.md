## Skill routing

When the user's request matches an available skill, invoke it via the Skill tool. When in doubt, invoke the skill.

Key routing rules:
- Product ideas/brainstorming → invoke /office-hours
- Strategy/scope → invoke /plan-ceo-review
- Architecture → invoke /plan-eng-review
- Design system/plan review → invoke /design-consultation or /plan-design-review
- Full review pipeline → invoke /autoplan
- Bugs/errors → invoke /investigate
- QA/testing site behavior → invoke /qa or /qa-only
- Code review/diff check → invoke /review
- Visual polish → invoke /design-review
- Ship/deploy/PR → invoke /ship or /land-and-deploy
- Save progress → invoke /context-save
- Resume context → invoke /context-restore
- Author a backlog-ready spec/issue → invoke /spec
- CI health/dependency vulnerabilities/git hygiene pass → invoke /harden

## Design System
Always read DESIGN.md (repo root) before making any visual or UI decisions.
All font choices, colors, spacing, and aesthetic direction are defined there.
Do not deviate without explicit user approval.
In QA mode, flag any code that doesn't match DESIGN.md.

- DESIGN.md covers the Spekooh app (`app/`) and the Django admin. S@Learn is a
  separate product with its own DESIGN.md in its own repo; don't apply one to
  the other.
- The token values in `app/lib/theme/*.dart` are authoritative. If DESIGN.md and
  the code disagree on a value, the code wins and DESIGN.md gets fixed in the
  same PR. Any new color, radius, shadow or user-visible copy rule also gets a
  row in DESIGN.md's decision log.
- Every user-visible string goes in both `app_en.arb` and `app_fr.arb`, then
  `flutter gen-l10n`.
