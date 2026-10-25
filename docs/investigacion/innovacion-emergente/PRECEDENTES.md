# Precedentes y evidencia externa

> **Vigencia**: fuentes externas consultadas el 2026-10-25 y fijadas por SHA; no se revisan con el código de Linde. Para comprobar licencias o versiones hay que repetir la consulta. Estado del juego: [ESTADO.md](../../../production/epics/mundo-vivo/ESTADO.md).

Fecha de consulta: 2026-10-25. **[C]** Versiones fijadas mediante la API pública de GitHub (`commits/master`); archivos descargados desde `raw.githubusercontent.com` con esos SHA. No se presupone que sean releases estables ni que `master` permanezca igual.

| Fuente | Versión inspeccionada | Alcance |
|---|---|---|
| [Cataclysm-DDA](https://github.com/CleverRaven/Cataclysm-DDA/tree/e205329f31b0205fc95b7b3d30b35cce1b7a62dc) | `e205329f31b0205fc95b7b3d30b35cce1b7a62dc` | Recetas, requisitos, pericias, aprendizaje durante fabricación/desmontaje; CMake y licencia. |
| [GDQuest](https://github.com/gdquest-demos/godot-4-procedural-generation/tree/19c98cee16ed18e642b3ce178f4c649d56b334b2) | `19c98cee16ed18e642b3ce178f4c649d56b334b2` | Rama `godot4`, armas modulares y generación persistente; proyecto y licencia. |
| [Dwarf Fortress: registro oficial 2015](https://www.bay12games.com/dwarves/dev_2015.html) | Entradas fechadas 20/03, 23/03, 20/08 y notas de versión de 2015 | Documentación primaria histórica; no se inspeccionó código del juego ni se verificó equivalencia con la versión actual. |

## CDDA: conocimiento de recetas y pericia

**[C]** [`src/recipe.h`](https://github.com/CleverRaven/Cataclysm-DDA/blob/e205329f31b0205fc95b7b3d30b35cce1b7a62dc/src/recipe.h) contiene `recipe_proficiency` (ID, obligatoriedad, multiplicador temporal, penalización, ritmo de aprendizaje y experiencia máxima). [`recipe.cpp`](https://github.com/CleverRaven/Cataclysm-DDA/blob/e205329f31b0205fc95b7b3d30b35cce1b7a62dc/src/recipe.cpp#L398) carga `skills_required`; alrededor de L436 carga `autolearn`, L458 `decomp_learn` y L474 `book_learn`. En `recipe::finalize`, L995, el autolearn simplificado deriva requisitos de las habilidades y dificultad. Son recetas definidas mediante datos, no descubrimiento de código nuevo.

**[C]** [`src/requirements.cpp`](https://github.com/CleverRaven/Cataclysm-DDA/blob/e205329f31b0205fc95b7b3d30b35cce1b7a62dc/src/requirements.cpp#L369), `load_obj_list`, usa listas de listas para requisitos; `can_make_with_inventory` (L945) y `check_enough_materials` (L1143) consultan disponibilidad. La estructura permite alternativas en grupos de componentes/herramientas. Es útil como antecedente para materiales sustituibles; no equivale a que cualquier sustitución sea válida.

**[C]** [`src/proficiency.cpp`](https://github.com/CleverRaven/Cataclysm-DDA/blob/e205329f31b0205fc95b7b3d30b35cce1b7a62dc/src/proficiency.cpp#L110), `proficiency::load`, carga `required_proficiencies`, `time_to_learn`, `can_learn` y `teachable`. `proficiency_set::practice` (L324) rechaza pericias ya aprendidas, no aprendibles o sin prerrequisitos; acumula tiempo y aprende al alcanzar el umbral. `has_prereqs` (L481) comprueba dependencias. `serialize`/`deserialize` (L563 en adelante) conservan conocidas y aprendizaje. La [documentación de pericias](https://github.com/CleverRaven/Cataclysm-DDA/blob/e205329f31b0205fc95b7b3d30b35cce1b7a62dc/doc/JSON/PROFICIENCY.md) distingue habilidades amplias, pericias específicas y recetas. **[P]** Reutilizar esa separación conceptual sobre la práctica existente de Linde; no añadir un segundo sistema de experiencia paralelo sin necesidad.

**[C]** [`src/crafting.cpp`](https://github.com/CleverRaven/Cataclysm-DDA/blob/e205329f31b0205fc95b7b3d30b35cce1b7a62dc/src/crafting.cpp#L3185), `Character::craft_proficiency_gain`, reparte tiempo de aprendizaje entre materias elegibles y considera ayudantes: si otro participante conoce una pericia, el bonus observado pasa a 2. El progreso verifica prerrequisitos y límites. Al completar fabricación, L3745–3780, diferencia memoria de referencia (libro, dispositivo o NPC) y puede memorizar la receta. La probabilidad usa tiempo de fabricación, dificultad elevada a cuarta potencia, habilidad e inteligencia. L5703–5708 muestra aprendizaje por desmontaje condicionado a `learn_by_disassembly` y `can_decomp_learn`.

**[I]** Esto permite modelar «puedo trabajar con ayuda aunque todavía no lo sé de memoria» y enseñanza mediante práctica compartida. No prueba investigación autónoma abierta ni difusión cultural global. **[P]** En Linde preferir progreso entero acumulado y reproducible antes que trasladar probabilidades o la fórmula de CDDA sin balance.

**[C]** [`src/recipe_dictionary.cpp`](https://github.com/CleverRaven/Cataclysm-DDA/blob/e205329f31b0205fc95b7b3d30b35cce1b7a62dc/src/recipe_dictionary.cpp#L790) enlaza recetas a libros; L850 mantiene una colección de autolearn. **[I]** Índices precalculados son un precedente útil para evitar recorrer todas las recetas ante cada observación.

### Reutilización, dependencias y licencia

**[C]** El [CMake raíz](https://github.com/CleverRaven/Cataclysm-DDA/blob/e205329f31b0205fc95b7b3d30b35cce1b7a62dc/CMakeLists.txt) exige C++17, Threads y ZLIB; contiene rutas condicionales de SDL3/Curses y otras opciones. Los archivos de crafting dependen ampliamente de `Character`, inventarios, calendario, IDs tipados, JSON y estado del mundo de CDDA. **[I]** Extraerlos como biblioteca para GDScript supondría portar una parte importante del dominio o introducir un puente nativo; no es una integración pequeña.

**[C]** [`LICENSE.txt`](https://github.com/CleverRaven/Cataclysm-DDA/blob/e205329f31b0205fc95b7b3d30b35cce1b7a62dc/LICENSE.txt) declara CC BY-SA 3.0 para Cataclysm y enumera excepciones de fuentes/bibliotecas. **[V]** Compatibilidad con la distribución y licencias de Linde, alcance de una adaptación y obligaciones concretas: no resueltos por esta investigación. La copia local `licencias/Cataclysm-DDA/` no demuestra por sí sola autorización ni identidad de versión. **[P]** Adoptar patrones y escribir implementación propia; no copiar C++, JSON de contenido o recursos hasta evaluar cada archivo y su atribución. No se incorpora CDDA como dependencia.

## GDQuest: composición de comportamientos

**[C]** [`godot4/modular_weapons/modular_weapon/src/modular_weapon.gd`](https://github.com/gdquest-demos/godot-4-procedural-generation/blob/19c98cee16ed18e642b3ce178f4c649d56b334b2/godot4/modular_weapons/modular_weapon/src/modular_weapon.gd), `ModularWeapon`, expone escenas de configuración/emisor y arrays de `ProjectileMotion` y `ProjectileEvent`. `add_motion` y `add_impact_event` rechazan duplicados por script salvo permiso explícito; los setters reconstruyen emisores desde una escena.

**[C]** [`projectile/projectile.gd`](https://github.com/gdquest-demos/godot-4-procedural-generation/blob/19c98cee16ed18e642b3ce178f4c649d56b334b2/godot4/modular_weapons/modular_weapon/src/projectile/projectile.gd), `setup`, duplica cada recurso de movimiento y enlaza el proyectil; `_update_movement` suma sus vectores. [`projectile_motion/projectile_motion.gd`](https://github.com/gdquest-demos/godot-4-procedural-generation/blob/19c98cee16ed18e642b3ce178f4c649d56b334b2/godot4/modular_weapons/modular_weapon/src/projectile_motion/projectile_motion.gd) define la interfaz `Resource`. [`projectile_events/projectile_event.gd`](https://github.com/gdquest-demos/godot-4-procedural-generation/blob/19c98cee16ed18e642b3ce178f4c649d56b334b2/godot4/modular_weapons/modular_weapon/src/projectile_events/projectile_event.gd), `trigger`, filtra fallos antes de invocar `_do_trigger`.

**[I]** El precedente muestra composición de capacidades previamente implementadas. No contiene, en estos archivos, aprendizaje, autoría, profesiones ni validación de combinaciones en servidor. Rechazar duplicados no resuelve interacciones incompatibles o explosiones de coste. **[P]** Para futuros efectos de Linde usar IDs autorizados y reglas de compatibilidad; no aceptar scripts o escenas enviados por un cliente.

**[C]** [`infinite_space/shared/world_generator.gd`](https://github.com/gdquest-demos/godot-4-procedural-generation/blob/19c98cee16ed18e642b3ce178f4c649d56b334b2/godot4/infinite_space/shared/world_generator.gd), `make_seed_for`, deriva semilla de texto, coordenadas y dato adicional. [`persistent_world_generator.gd`](https://github.com/gdquest-demos/godot-4-procedural-generation/blob/19c98cee16ed18e642b3ce178f4c649d56b334b2/godot4/infinite_space/persistent_world_generator.gd) guarda modificaciones en un diccionario que sobreescribe la generación base al reconstruir sectores. En ese archivo no hay escritura a disco: «persistente» conserva modificaciones al recorrer/regenerar el mundo durante la sesión, no demuestra guardado entre procesos.

**[P]** Aplicar el patrón «base derivable + hechos persistidos» a diseños y descubrimientos usando el guardado de Linde. No sustituir el generador de terreno. **[C]** El tercero ya incluido en `Linde/cenital/terceros/infinite-generation-demo/ORIGEN.md` apunta a `mearnest-dev/infinite-generation-demo`, no a este repositorio GDQuest.

**[C]** [`godot4/project.godot`](https://github.com/gdquest-demos/godot-4-procedural-generation/blob/19c98cee16ed18e642b3ce178f4c649d56b334b2/godot4/project.godot) declara feature 4.7. La muestra usa Node2D, CharacterBody2D, Resource, PackedScene y RandomNumberGenerator de Godot. **[V]** No se probó el conjunto de escenas en Linde 4.7.1 ni se auditó cada recurso transitivo. El README raíz conserva rutas antiguas: para esta investigación manda el árbol `godot4` fijado.

**[C]** La [licencia](https://github.com/gdquest-demos/godot-4-procedural-generation/blob/19c98cee16ed18e642b3ce178f4c649d56b334b2/LICENSE) distingue código MIT y arte CC BY 4.0. **[P]** Si se copia código, conservar el aviso MIT; si se usa arte, evaluar y registrar atribución por separado. **[V]** La compatibilidad final de cualquier incorporación sigue pendiente; aquí no se copia ni integra código/arte de GDQuest.

## Dwarf Fortress: historia y transmisión, no biblioteca

**[C/documentación histórica]** El [registro oficial de 2015](https://www.bay12games.com/dwarves/dev_2015.html) describe investigación individual con requisitos, aprendizaje por relaciones maestro/alumno y registros escritos; también relata pérdidas y redescubrimientos durante simulaciones iniciales sin libros. **[I]** Un diseño cultural necesita distinguir existencia histórica de accesibilidad presente. Estas notas sirven como precedente conceptual; no permiten trasladar sus estructuras internas.

**[V]** No se verificó el algoritmo actual, su complejidad ni cómo conecta hoy cada descubrimiento con fabricación. No se inspeccionó código fuente reutilizable ni licencia que autorice copiarlo. **[P]** Diseñar para Linde registros propios de procedencia, portadores y copias, sin asumir que la investigación académica de DF desbloquea automáticamente tecnología práctica.

## Determinismo: comprobación complementaria

**[C/documentación]** [Godot 4.2: RandomNumberGenerator](https://docs.godotengine.org/en/4.2/classes/class_randomnumbergenerator.html) advierte que el algoritmo subyacente es detalle de implementación. **[I]** Una semilla por sí sola no constituye contrato de reproducción entre versiones del motor. **[P]** Versionar reglas y registrar resultados confirmados; para repetición a largo plazo fijar también algoritmo/versión y ordenar entradas. La documentación 4.2 se usa para esa advertencia, no como prueba de la implementación concreta de 4.7.1.

## Selección

**[P]** No añadir otro motor: Linde ya cubre la gramática que faltaría en muchos precedentes. CDDA es más apropiado para conocimiento técnico; GDQuest para modularidad; DF para memoria cultural. Un cuarto proyecto no aporta una necesidad técnica demostrada que justifique otra dependencia en esta fase.

## Inventario de archivos externos consultados

**[C]** SHA-256 del contenido inspeccionado. Para reconstruir: abrir el archivo en el repositorio/commit de la tabla inicial y comparar su hash. No se conservan copias de código externo en el proyecto. Las descargas de trabajo en `/tmp` son temporales, no requisito para retomar. Intentos 404 (`doc/JSON/RECIPES.md`, `src/character_recipes.cpp`, `src/character_skill.cpp`, `src/recipe_subset.cpp`) no se usan como evidencia.

| Proyecto | Archivo | SHA-256 |
|---|---|---|
| cdda | `CMakeLists.txt` | `8604ea0dc01a2fdf27366381831c60f9c853d807495a314fd712a812bec53360` |
| cdda | `LICENSE.txt` | `6e3d17bae7a8f0dee4b0d0c6af5bdf4396a0e685455efa8c2ad4ce52acdd99e2` |
| cdda | `doc/JSON/PRACTICE_RECIPES.md` | `cfb3e8c62b12cc2a5c73a5a849a9f957e8862ecb289a837c3c9fa85b4a9714eb` |
| cdda | `doc/JSON/PROFICIENCY.md` | `715f5bdd9f4aa2f41074c31e63b8b394fa5fca932dd7e285210b9382bd55cc29` |
| cdda | `src/character.cpp` | `7824a98fdcbac7ab65f7e55621eedae5dd64b268c436df4b92ff1e44f310bfe8` |
| cdda | `src/character_proficiency.cpp` | `a7a203dc096251ca441e8f91f1d801fd05c2d9f10d2bcd7de7390eec027a5045` |
| cdda | `src/crafting.cpp` | `f4e7312c328a7a3568ffe77c3fb7bd69a1f23449620fb2441b00b75196a8f4e4` |
| cdda | `src/proficiency.cpp` | `28c319b93d23869f7c52afb0d312aa38d3b0d41d3e764b99156d8c79bd39f443` |
| cdda | `src/proficiency.h` | `87c636001998c37ee33448ece55ae7d7c09c1f93b73693339800e5f552adad4c` |
| cdda | `src/recipe.cpp` | `d5d9df3636d672776ae7a6fb18aadb93db5cfcd8864eea0a063028d40a4fdfbe` |
| cdda | `src/recipe.h` | `15415ae7ee1780fa68c4ce7f3d446f021b3b49b6038e6a6f90f924c909f6c811` |
| cdda | `src/recipe_dictionary.cpp` | `f671d6a09f2c8970e192b2e4044db4be24aaaa2089a54f6d554525a1c94f7e8d` |
| cdda | `src/requirements.cpp` | `7a4ae65aca76c5a686d874d74f7dbc9900ce9cffa9f6c01de45cd2d449d2f74f` |
| gdquest | `LICENSE` | `571ec1d87f266565d599dbeff1ba59ad24416b6c2703fe8cd70f867e4ce4dc8a` |
| gdquest | `README.md` | `94403a4b57e9011e538e2c07d0797b664355e8fcdd28780f39746c80ebc299f0` |
| gdquest | `godot4/infinite_space/persistent_world_generator.gd` | `39d1d909b7987f2b321c3d57876d806da33b76e76da06439e2b112724ace9cb2` |
| gdquest | `godot4/infinite_space/shared/world_generator.gd` | `1f0def45f2bc1b99ebfabe3c93fc40aa1e954232e5c81aa9b7e2f5b3d81b2029` |
| gdquest | `godot4/modular_weapons/modular_weapon/src/modular_weapon.gd` | `6575b5aee4645d3ad0349482dbece8cbd753edecf9a40f0639cd311dc3fe56b8` |
| gdquest | `godot4/modular_weapons/modular_weapon/src/projectile/projectile.gd` | `07f53077be491ac8f64e5b58a77a1450f1a5137a578f61fbe8a25c6a53a1c5bb` |
| gdquest | `godot4/modular_weapons/modular_weapon/src/projectile_events/projectile_event.gd` | `78e3f6bc18508b9453db38288703e8f2c949b88b925d6f4c728d33456290b768` |
| gdquest | `godot4/modular_weapons/modular_weapon/src/projectile_motion/projectile_motion.gd` | `852dec65d440b145f56b07173d4135c2f875749eb80da9542ed6e6b8ca4dad01` |
| gdquest | `godot4/project.godot` | `b0eac4c6708fb9184af436d7a3c38cae94de3f03afae70d4fff19ca835afe976` |
