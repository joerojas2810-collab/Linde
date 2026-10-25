# Claude Code Game Studios -- Game Studio Agent Architecture

Indie game development managed through 49 coordinated Claude Code subagents.
Each agent owns a specific domain, enforcing separation of concerns and quality.

## Technology Stack

- **Engine**: Godot 4.7.1
- **Language**: GDScript
- **Version Control**: Git with trunk-based development
- **Build System**: SCons (engine), Godot Export Templates
- **Asset Pipeline**: Godot Import System + custom resource pipeline

> **Note**: Engine-specialist agents exist for Godot, Unity, and Unreal with
> dedicated sub-specialists. Use the set matching your engine.

## Project Structure

@.claude/docs/directory-structure.md

## Engine Version Reference

<!-- ENGINE-REFERENCE-IMPORT: the line below is engine-specific. /setup-engine
     rewrites it to @docs/engine-reference/<engine>/VERSION.md for the chosen
     engine, so a Unity or Unreal project stops loading the Godot reference every
     session. It defaults to Godot (the template's example engine); skills that
     need the pinned version read docs/engine-reference/<engine>/VERSION.md on
     demand regardless of this import. -->
@docs/engine-reference/godot/VERSION.md


## Technical Preferences

`project.yaml` at the repo root is the primary config store — engine, specialists,
naming, platform, performance, modes. Skills resolve it via `resolve_config`
(see `.claude/docs/config-resolution.md`).

`.claude/docs/technical-preferences.md` is the **legacy fallback**, read on demand
when a key is absent from `project.yaml`. It is not imported here: before
`/setup-engine` runs it is almost entirely `[TO BE CONFIGURED]` placeholders, and
after it runs `project.yaml` holds the real values.

## Coordination Rules

@.claude/docs/coordination-rules.md

## Collaboration Protocol

**User-driven collaboration, not autonomous execution.**
Every task follows: **Question -> Options -> Decision -> Draft -> Approval**

- Agents MUST ask "May I write this to [filepath]?" before using Write/Edit tools
  (exempt: `active.md` appends, agent memory, a subagent's new file at the path
  its orchestrating skill named; see `.claude/rules/agent-memory.md`)
- Agents MUST show drafts or summaries before requesting approval
- Multi-file changes require explicit approval for the full changeset
- No commits without user instruction
- A skipped or dismissed question is not an answer: act on nothing, re-ask in
  plain text and wait
- Started outside this file's folder? Warn first: hooks, deny rules and the
  ask-first mode load only when Claude Code starts here

See `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md` for full protocol and examples.

> **First session?** If the project has no engine configured and no game concept,
> run `/start` to begin the guided onboarding flow.

## Documentación: qué leer y cómo mantenerla

**Entrada rápida (toda sesión de Linde, en este orden, sin cargar más):**
1. Qué es → [`design/game-brief.md`](design/game-brief.md).
2. Qué existe y qué está verificado → [`production/epics/mundo-vivo/ESTADO.md`](production/epics/mundo-vivo/ESTADO.md) (fuente de verdad; cada cifra lleva fecha y alcance).
3. Qué decisiones respetar → [`Linde/cenital/docs/DECISIONES.md`](Linde/cenital/docs/DECISIONES.md) (índice único, solo la tabla).
4. Sesión anterior → `production/session-state/active.md`.

**Lectura contextual (solo si la tarea toca el tema):** el contrato del sistema en `Linde/cenital/docs/` y su GDD en `design/gdd/` (el GDD dice qué se quiere; el contrato, cómo funciona hoy); el plan activo de la iniciativa; `docs/investigacion/` solo para conocimiento/invención de técnicas; arte pendiente en `Linde/cenital/docs/ARTE_PENDIENTE.md`. **Visión original** (para contrastar decisiones con los objetivos de Linde, no es lectura técnica diaria): [`Linde/documentos/LINDE_Punto_de_Inicio/`](Linde/documentos/LINDE_Punto_de_Inicio/00_LEEME.md).

**Mantenimiento:**
- Antes de crear un documento, buscar si corresponde actualizar uno existente. Cada iniciativa tiene **un solo plan activo**; las investigaciones son referencia y no duplican el plan.
- Al implementar y probar una fase: actualizar su estado en el plan **y** registrar en `ESTADO.md` el resultado verificado (qué se ejecutó, cuándo, resultado). No convertir resultados históricos en actuales sin repetir la prueba.
- Decisiones: una fila en el índice de `DECISIONES.md` (ID, fecha, estado, enlace); fundamentos y alternativas junto al sistema o la iniciativa.
- Si una investigación o doc contradice el código verificado, prevalece el código: corregirlo o marcarlo obsoleto con fecha.
- Al terminar una iniciativa: mover su plan a `docs/archivo/` y dejar enlazadas sus decisiones en el índice. Lo histórico no se borra sin aprobación expresa.
- **No mover** `Linde/arte-entregado/`, `Linde/documentos/{contrato-equipo,sistema-de-equipo}.md` ni `Linde/documentos/FASE_07/`: los citan código, pruebas y manifiestos.

## Coding Standards

@.claude/docs/coding-standards.md

## Context Management

Read `.claude/docs/context-management.md` on demand — it is a reference, not
session context. Two of its conventions are load-bearing and cited by name
elsewhere in the repo, so they are restated here rather than lost:

- **`production/session-state/active.md` is the session checkpoint.** The file is
  the memory, not the conversation. Read it first after any compaction, crash, or
  `/clear`.
- **Helpers in `.claude/scripts/` emit observations, never verdicts.** A script
  that scores or judges will eventually contradict a mode or override it cannot
  see. (Cited by `artifact-check.sh` and `adr-dep-graph.sh`.)
