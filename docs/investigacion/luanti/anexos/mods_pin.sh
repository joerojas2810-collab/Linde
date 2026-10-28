#!/usr/bin/env bash
# ============================================================================
# Linde RPG — descarga reproducible de Luanti, Mineclonia y mods
# Verificado por documentación el 2026-10-28. NO ejecutado en este proyecto.
#
# Uso:
#   ./mods_pin.sh --destino ~/linde/luanti          # descarga todo
#   ./mods_pin.sh --destino ~/linde/luanti --solo-base
#   ./mods_pin.sh --manifiesto                        # solo imprime el manifiesto
#
# Regla del proyecto: NINGÚN mod entra al modpack sin (a) licencia explícita y
# (b) una prueba registrada en Mineclonia. Este script descarga; no valida.
# ============================================================================
set -euo pipefail

DESTINO="${HOME}/linde/luanti"
SOLO_BASE=0
MANIFIESTO=0

while [ $# -gt 0 ]; do
  case "$1" in
    --destino)   DESTINO="$2"; shift 2 ;;
    --solo-base) SOLO_BASE=1; shift ;;
    --manifiesto) MANIFIESTO=1; shift ;;
    -h|--help)   sed -n '2,14p' "$0"; exit 0 ;;
    *) echo "Opción desconocida: $1" >&2; exit 2 ;;
  esac
done

# ---------------------------------------------------------------------------
# Manifiesto: repositorio | referencia | licencia | papel
# 'HEAD' significa: al ejecutar, registrar el SHA resultante en versiones.txt.
# ---------------------------------------------------------------------------
JUEGO_REPO="https://codeberg.org/mineclonia/mineclonia.git"
JUEGO_REF="0.124.1"                                   # commit 7410cf18a231b4dd094bd90dc534951ef17b4275
JUEGO_LIC="GPL-3.0"

# Mods aprobados para el modpack objetivo (Arquitectura B).
# Formato: "nombre|repo|ref|licencia|papel"
MODS=(
  "moreores|https://github.com/minetest-mods/moreores.git|HEAD|Zlib|materiales extra (por probar duplicaciones)"
  # "inventory_pouches|https://github.com/JamesClarke7283/inventory_pouches.git|HEAD|SIN-LICENCIA|BLOQUEADO hasta aclarar licencia"
)

# Mods de la arquitectura de contingencia (Minetest Game). NO aprobados para Linde:
# se listan para poder probarlos, no para distribuirlos.
MODS_MTG=(
  "mobs_redo|https://github.com/minetest-mirrors/mobs_redo.git|HEAD|MIT|API de mobs"
  "mobs_monster|https://github.com/minetest-mirrors/mobs_monster.git|HEAD|MIT|monstruos"
  "mobs_animal|https://github.com/minetest-mirrors/mobs_animal.git|HEAD|MIT (modelos K Pavel)|animales"
  "mobs_npc|https://github.com/minetest-mirrors/mobs_npc.git|HEAD|MIT|NPC"
  "ethereal|https://github.com/minetest-mirrors/ethereal.git|HEAD|MIT|biomas"
  "moreores|https://github.com/minetest-mods/moreores.git|HEAD|Zlib|minerales"
  "3d_armor|https://github.com/minetest-mods/3d_armor.git|HEAD|LGPL-2.1|armadura visible"
  "toolranks|https://github.com/lisacvuk/minetest-toolranks.git|HEAD|LGPL-2.1|progresion de herramientas"
  "areas|https://github.com/minetest-mods/areas.git|HEAD|LGPL-2.1|proteccion"
  "unified_inventory|https://github.com/minetest-mods/unified_inventory.git|HEAD|LGPL-2.1+|inventario"
  "caverealms_lite|https://github.com/minetest-mirrors/caverealms_lite.git|HEAD|BSD|cavernas"
  "cottages|https://github.com/Sokomine/cottages.git|HEAD|GPL-3.0|casas"
  "travelnet|https://github.com/Sokomine/travelnet.git|HEAD|GPL-3.0|viaje rapido"
  "easyvend|https://github.com/minetest-mirrors/easyvend.git|HEAD|LGPL-2.1|tiendas"
)

imprimir_manifiesto() {
  echo "# Manifiesto Linde — $(date -u +%F)"
  echo "# Motor: Luanti 5.17.0 — https://github.com/luanti-org/luanti/releases/tag/5.17.0"
  echo "# Juego: Mineclonia ${JUEGO_REF} (${JUEGO_LIC}) — ${JUEGO_REPO}"
  printf '# %-22s %-10s %s\n' "MOD" "REF" "LICENCIA"
  for fila in "${MODS[@]}"; do
    IFS='|' read -r n r ref lic papel <<<"$fila"
    printf '# %-22s %-10s %s\n' "$n" "$ref" "$lic"
  done
}

if [ "$MANIFIESTO" -eq 1 ]; then imprimir_manifiesto; exit 0; fi

mkdir -p "$DESTINO"/{games,downloads}
echo "Destino: $DESTINO"

# ---------------------------------------------------------------------------
# 1) Juego base
# ---------------------------------------------------------------------------
if [ ! -d "$DESTINO/games/mineclonia/.git" ]; then
  echo "==> Clonando Mineclonia (${JUEGO_REF})"
  git clone --branch "$JUEGO_REF" --depth 1 "$JUEGO_REPO" "$DESTINO/games/mineclonia"
else
  echo "==> Mineclonia ya existe; se respeta (no se actualiza sola)"
fi

# ---------------------------------------------------------------------------
# 2) Mods
# ---------------------------------------------------------------------------
descargar_mods() {
  local arreglo=("$@")
  for fila in "${arreglo[@]}"; do
    IFS='|' read -r nombre repo ref lic papel <<<"$fila"
    local modalidad="worlds/linde/worldmods"
    local destino_mod="$DESTINO/$modalidad/$nombre"

    if [ "$lic" = "SIN-LICENCIA" ]; then
      echo "!! $nombre: sin licencia declarada -> NO se descarga al modpack"
      continue
    fi
    if [ -d "$destino_mod" ]; then
      echo "==> $nombre ya presente"
      continue
    fi
    mkdir -p "$(dirname "$destino_mod")"
    echo "==> $nombre ($lic) — $papel"
    if [ "$ref" = "HEAD" ]; then
      git clone --depth 1 "$repo" "$destino_mod"
    else
      git clone --branch "$ref" --depth 1 "$repo" "$destino_mod"
    fi
  done
}

if [ "$SOLO_BASE" -eq 0 ]; then
  descargar_mods "${MODS[@]}"
fi

# ---------------------------------------------------------------------------
# 3) Registro de versiones (lo que hace reproducible la instalación)
# ---------------------------------------------------------------------------
REGISTRO="$DESTINO/versiones.txt"
{
  echo "# Linde — versiones fijadas el $(date -u +%FT%TZ)"
  echo "luanti:=5.17.0"
  echo "mineclonia=$(git -C "$DESTINO/games/mineclonia" rev-parse HEAD 2>/dev/null || echo '?')"
  for d in "$DESTINO"/worlds/linde/worldmods/*/; do
    [ -d "$d/.git" ] || continue
    n=$(basename "$d")
    echo "$n=$(git -C "$d" rev-parse HEAD)"
  done
} > "$REGISTRO"
echo "==> Registro de versiones: $REGISTRO"

cat <<'FIN'

Siguiente paso:
  1. Descargar Luanti 5.17.0 (binario) y ponerlo en $DESTINO/bin.
  2. Arrancar:   bin/luanti --server --worldname linde --gameid mineclonia
  3. Ejecutar la prueba técnica de 07_plan_prueba_riesgos.md §14.

Recordatorio legal: los mods con licencia sin declarar NO se pueden distribuir
en un ZIP de Linde. Ver 03_mods_catalogo.md §5.J.
FIN
