# Desarrollo generativo acotado

Prototipo solicitado e implementado el 24/10/2026. Extiende Sociedad del valle; todos los ajustes son propios provisionales.

## Experiencia

El jugador descubre materiales, practica oficios, organiza talleres y fabrica nuevas combinaciones de equipo. Los habitantes siguen las mismas reglas de práctica, recetas y coste. Las situaciones no requieren fichas de cada espada o armadura, pero sí acciones y efectos implementados.

## Reglas y dependencias

- Gramática versionada de forma, material, técnica y calidad. Compatible con las ranuras, estadísticas, inventarios y capas visuales existentes.
- Materiales elaborados por una regla de núcleo + refuerzo, con entradas y salida explícitas. Sin mezclas recursivas ni minerales nuevos en el mapa.
- Práctica adquirida solo por acciones confirmadas; conocimiento por obtención real de materiales. Rangos acotados por disciplina y material; no se agregan a la lista manual de habilidades.
- Calidad y técnicas se validan en servidor; las propiedades de piezas anteriores no dependen del nivel actual de su creador.
- Talleres que amplían superficie según práctica e inventario. Cada suelo cuesta madera y respeta rutas/ocupación. Técnicas avanzadas necesitan superficie, reducida por pericia de construcción.
- Compras de obras de NPC conservan stock, coste, capacidad y proximidad. No hay objetos creados por la interfaz.
- Estado persistente dentro de `mundo_vivo.autonomia.desarrollo`; claves `art1:` y `mat1:` autocontenidas. La versión 1 se conserva para partidas guardadas.

## Parámetros y límites

`datos/desarrollo/reglas_v1.json`: compatibilidades, materiales, coeficientes, costes, técnicas, rangos y máximos. Dependencias: Equipo/Inventario, Construcción/Mundo, Combate, Sociedad, guardado y red. Rango máximo 3, 3 acciones por rango, hasta 8 suelos de taller y 2 obras de NPC. Reutiliza arte existente recoloreado; sin nuevos movimientos, siluetas o efectos de combate.

## Aceptación

1. Una combinación válida genera receta, propiedades y representación; una incompatible, no canónica o fuera de límites se rechaza.
2. Fabricar/refinar exige conocimiento, estación, materiales y capacidad; fallar no consume ni entrena.
3. Recolectar/fabricar/construir/impactar realmente produce práctica; cargar no acumula efectos.
4. Equipo generado afecta las estadísticas solo al estar equipado; material elaborado se consume en una pieza posterior.
5. Guardar, cargar y replicar conserva piezas, materiales y aprendizaje. El servidor no admite una calidad que el cliente no conoce.
6. Simular varios días desde cero produce superficie de taller y obras sin tarjetas ni intervenciones.
7. El atlas explica fuentes y usos de los recursos actuales; planos y costes son visibles antes de confirmar.

## Fuera de alcance

Generación ilimitada de mecánicas, código creado por NPC, mapas o ciudades nuevas, siluetas nuevas, balance final y simulación metalúrgica. Las combinaciones tienen límites y no sustituyen el trabajo futuro de diseñar capacidades nuevas.
