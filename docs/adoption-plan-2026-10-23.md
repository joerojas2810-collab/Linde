# Adoption Plan

> **Generated**: 2026-10-23
> **Project phase**: Concept (default — no `project.stage` set)
> **Engine**: Not configured in `project.yaml` (the code uses Godot 4.7.1)
> **Template version**: framework 1.2.0 · `modes.rigor: minimal` (workflow minimal, review mode solo)

Work through these steps in order. Check off each item as you complete it.
Re-run `/adopt` anytime to check remaining gaps.

**Decision recorded:** no existing file is moved or edited. The template locations
below are *references to* existing material, not copies of it.

---

## Where the existing material sits

| Existing material | Role in the template | Action |
|---|---|---|
| `Linde/documentos/LINDE_Punto_de_Inicio/01–06_*.md`, `PROMPT_PARA_CLAUDE.md`, `Linde/documentos/LINDE_Documento_de_Inicio.md` | Source for `design/game-brief.md` (and, if rigor is raised, `game-concept.md` and GDDs). Labels Acordado / Propuesta / Pendiente must carry over unchanged | Stay in place |
| `Linde/documentos/LINDE_Punto_de_Inicio/referencias/visual_objetivo.png` | Input for `/art-bible` | Stay in place |
| `Linde/cenital/` (Godot project, 14 scripts, 130 logic + 12 UI tests) | Existing code. The template's code root is `src/` (empty); path rules in `.claude/rules/` apply to `src/**` only | Stay in place |
| `Linde/cenital/docs/DECISIONES.md` | Seed for future ADRs (A01 combat model, P03–P06) | Stay in place |
| `documentacion/`, `beta/lateral/`, `inventario/`, `licencias/` | Historical record of the lateral prototype and source research | Stay in place |

None of these use the template's internal formats (no GDD, ADR, story or brief
headings were found), so nothing is flagged as "malformed" — it is simply not
yet in template shape. At `minimal`, GDDs, ADRs and UX specs are not expected.

---

## Step 1: Fix Blocking Gaps

None found.

---

## Step 2: Fix High-Priority Gaps

### 2a. Configure the engine
Nothing in `project.yaml` or `.claude/docs/technical-preferences.md` names the engine, so
ADR, story and `/dev-story` routing cannot pick Godot specialists.
**Fix**: `/setup-engine godot 4.7.1` (the project's installed editor is 4.7.1; the
reference docs in `docs/engine-reference/godot/` are pinned to 4.7 and record
"Installed at pin time: NOT DETERMINED").
**Time**: 5–10 min
- [x] `engine.name`, `version`, `language`, `rendering`, `physics` set in `project.yaml` (done 2026-10-23: Godot 4.7.1, GDScript, Compatibility, Godot Physics 2D)
- [x] `docs/engine-reference/godot/VERSION.md` "Installed at pin time" filled (4.7.1 stable, `a13da4feb`)

**Known divergence left open:** `bash .claude/scripts/project-coherence.sh` reports `[DIFFERS]` on
`commands.test` (it looks for `tests/prueba.gd` at the repo root) and `[NOT CHECKED]` on the
`project.godot` checks. Both come from the Godot project living in `Linde/cenital/` instead of the
repo root. The command itself runs (130/130 PASS). Resolves only if the project moves to the code
root (Step 5a); not edited to silence the script.

---

## Step 3: Bootstrap Infrastructure

Not on the minimal path — the brief's build order is the plan. Next: `/create-stories`
(or `/dev-story` once stories exist).

---

## Step 4: Medium-Priority Gaps

### 4a. Write the one-page game brief
`design/game-brief.md` does not exist; `/create-stories` builds from its MVP list and build order.
**Fix**: `/brainstorm` (Path C — clear concept). Seed it with `Linde/documentos/LINDE_Punto_de_Inicio/` so
nothing is re-decided: keep Acordado items as agreed, Propuestas as proposals, Pendientes
(combat model, canon, economy, world size, multiplayer) as open.
**Time**: 1 session
- [ ] `design/game-brief.md` written

### 4b. Naming conventions and performance budgets
Unset in both config sources (written by `/setup-engine`).
**Time**: included in 2a
- [ ] `naming.*` and `performance.*` populated

### 4c. Test root location
The existing tests live in `Linde/cenital/tests/` (headless Godot scripts), not in the
engine test root `/test-setup` and `/smoke-check` expect.
**Fix**: decide when running `/test-setup` whether to point it at the existing tests or
scaffold a new root; do not move the current ones without confirming.
**Time**: 30 min
- [ ] Test root decision recorded

---

## Step 5: Optional Improvements

### 5a. Code root
Path-based rules (`src/gameplay/**`, `src/ui/**`, …) do not govern code under `juego/`.
Options when you are ready: keep `Linde/cenital/` and accept that, or migrate to `src/`
(requires updating `Iniciar-Cenital.command` and the README references). Not urgent.
- [ ] Code-root decision recorded

### 5b. Forbidden patterns and allowed libraries
Empty by design; fill in `.claude/docs/technical-preferences.md` as decisions arise.
- [ ] Reviewed

---

## What to Expect from Existing Stories

There are no stories yet. New stories created by `/create-stories` will embed TR-IDs and
manifest versions only if you raise rigor above `minimal`.

---

## Review mode

Review mode resolves to `solo` — from `modes.rigor: minimal`, unless something pins it.
To change depth, change `modes.rigor` (or pin it on purpose with
`/settings --local modes.review_mode=<full|lean|solo>`).

---

## Re-run

Run `/adopt` again after completing Step 2 to verify the HIGH gap is resolved.
