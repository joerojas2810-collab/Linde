extends RefCounted
# Contrato visual compartido PJ/NPC. Array aditivo: los tres índices heredados no cambian.
# [piel, color_pelo, ropa, identidad, peinado, pantalon, botas, cinturon].
# Identidad no cambia estadísticas ni restringe colores/ropa; selecciona su catálogo de diez peinados. El cuerpo base es compartido.
const P = preload("res://scripts/params.gd")
const IDENTIDAD := ["Hombre", "Mujer"]
const PEINADOS_HOMBRE := ["Corto", "Corto uniforme", "Media melena", "Recogido", "Despeinado", "Raya izquierda", "Raya derecha", "Rizado", "Largo", "Coleta"]
const PEINADOS_MUJER := ["Pixie", "Corto uniforme", "Melena", "Moño", "Coleta", "Trenza", "Flequillo", "Rizado", "Largo", "Media melena"]
# IDs de tratamiento gráfico estables; cada identidad tiene su propia lista de diez opciones.
const ESTILOS_HOMBRE := [0, 1, 13, 3, 4, 5, 6, 7, 8, 9]
const ESTILOS_MUJER := [10, 1, 2, 3, 9, 11, 12, 7, 8, 13]
const PANTALONES := [P.PANTALON, Color("65513c"), Color("263c55"), Color("52604c"), Color("95836b"), Color("733e42"), Color("2d3037"), Color("b1a18c")]
const BOTAS := [Color("5d402f"), Color("292b32"), Color("8b6844"), Color("aa8d62"), Color("4a535b"), Color("723d31")]
const CINTURONES := [Color("67462e"), Color("28262b"), Color("9b7442"), Color("545867"), Color("7c3f39"), Color("b29b70")]
const CAMPOS := ["piel", "pelo", "ropa", "identidad", "peinado", "pantalon", "botas", "cinturon"]
const ETIQUETAS := ["Piel", "Color de pelo", "Ropa", "Personaje", "Peinado", "Pantalón", "Botas", "Cinturón"]
const NPC := {
	"maren": [1, 5, 2, 1, 3, 1, 0, 2],
	"ordal": [6, 4, 8, 0, 1, 6, 1, 0],
	"nerea": [4, 6, 5, 1, 2, 3, 2, 1],
}

static func limites() -> Array:
	return [P.PIEL.size(), P.PELO.size(), P.ROPA.size(), IDENTIDAD.size(), PEINADOS_HOMBRE.size(), PANTALONES.size(), BOTAS.size(), CINTURONES.size()]

# Estricto para red. Partidas viejas mantienen su array de tres elementos y su render original.
static func valido(v) -> bool:
	if not v is Array or v.size() not in [3, 8]: return false
	var lim := limites()
	for i in v.size():
		if not v[i] is int or v[i] < 0 or v[i] >= lim[i]: return false
	return true

static func indice(v: Array, i: int) -> int:
	if i >= v.size() or not (v[i] is int or v[i] is float): return 0
	return clampi(int(v[i]), 0, int(limites()[i]) - 1)

static func de_creador(cr: Dictionary) -> Array:
	var out: Array = []
	for campo in CAMPOS: out.append(int(cr.get(campo, 0)))
	return out

static func npc(id: String) -> Array:
	# Fallback estable, sin volver a dibujar a todos como Maren.
	if NPC.has(id): return NPC[id].duplicate()
	var n := absi(id.hash())
	return [n % P.PIEL.size(), int(n / 8) % P.PELO.size(), int(n / 80) % P.ROPA.size(), n % 2, n % PEINADOS_HOMBRE.size(), n % PANTALONES.size(), n % BOTAS.size(), n % CINTURONES.size()]

static func peinados(identidad: int) -> Array:
	return PEINADOS_MUJER if identidad == 1 else PEINADOS_HOMBRE

static func estilo_visual(look: Array) -> int:
	var estilos: Array = ESTILOS_MUJER if indice(look, 3) == 1 else ESTILOS_HOMBRE
	return estilos[indice(look, 4)]

static func etiqueta(i: int, v: int, identidad: int = 0) -> String:
	if i == 3: return IDENTIDAD[v]
	if i == 4: return peinados(identidad)[v]
	return "%d / %d" % [v + 1, limites()[i]]
