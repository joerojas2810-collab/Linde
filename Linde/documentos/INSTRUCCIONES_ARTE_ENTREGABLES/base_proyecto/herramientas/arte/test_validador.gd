extends SceneTree
## Prueba del validador con hojas sinteticas. Uso: Godot --headless --script herramientas/arte/test_validador.gd
const V := preload("validar_hoja.gd")
const DIR := "/private/tmp/claude-501/-Users-josephrojas-Desktop-RPG-Mundo-Vivo-2026-10-23/fd56a52e-fd6f-4928-9f82-fb240eb81499/scratchpad/"
const C := 32
var fallos := 0

## Hoja valida: en cada celda un rectangulo rojo con borde gris; el desplazamiento por columna evita la pose repetida.
func hoja(col_desplaza := true) -> Image:
	var img := Image.create(4 * C, 4 * C, false, Image.FORMAT_RGBA8)
	for f in 4:
		for c in 4:
			var dx: int = c if col_desplaza else 0
			for y in range(10, 31):
				for x in range(10 + dx, 22 + dx):
					var borde: bool = x == 10 + dx or y == 10
					img.set_pixel(c * C + x, f * C + y, Color8(128, 128, 128) if borde else Color8(255, 0, 0))
	return img

func espera(nombre: String, r: Dictionary, ok: bool, aviso_sub := "", error_sub := "") -> void:
	var bien: bool = r.errores.is_empty() == ok
	if aviso_sub != "": bien = bien and " ".join(r.avisos).contains(aviso_sub)
	if error_sub != "": bien = bien and " ".join(r.errores).contains(error_sub)
	if aviso_sub == "" and ok: bien = bien and r.avisos.is_empty()
	print("%s %s" % ["PASA " if bien else "FALLA", nombre])
	if not bien:
		fallos += 1; print(V.informe_texto(r, nombre))

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	var base := hoja()
	espera("valida", V.validar(hoja(), C, "indice", base), true)
	espera("valida modo libre sin base", V.validar(hoja(), C, "libre"), true)
	var chica := Image.create(4 * C - 1, 4 * C, false, Image.FORMAT_RGBA8)
	espera("tamano incorrecto", V.validar(chica, C, "indice"), false, "", "tamano exacto")
	var h := hoja(); h.set_pixel(12, 12, Color(1, 0, 0, 0.5))
	espera("alfa parcial", V.validar(h, C, "indice"), false, "", "alfa")
	h = hoja(); h.set_pixel(12, 12, Color8(200, 10, 10))
	espera("color fuera de indice", V.validar(h, C, "indice"), false, "", "indice")
	espera("color fuera de indice tolerado en libre", V.validar(h, C, "libre"), true)
	h = hoja()
	for y in C: for x in C: h.set_pixel(32 + x, 32 + y, Color(0, 0, 0, 0))   # fila 1, columna 1
	espera("celda vacia", V.validar(h, C, "indice"), false, "", "celdas con contenido")
	h = hoja(); h.set_pixel(0, 0, Color8(255, 0, 0))
	espera("contenido en el borde", V.validar(h, C, "indice"), false, "", "borde")
	espera("pose repetida (aviso, no falla)", V.validar(hoja(false), C, "indice", hoja(false)), true, "pose repetida")
	# desplazada 5 px respecto a la base: debe detectarse; 2 px no
	var desp := Image.create(4 * C, 4 * C, false, Image.FORMAT_RGBA8)
	for f in 4:
		for c in 4:
			for y in range(5, 20):
				for x in range(10, 22): desp.set_pixel(c * C + x, f * C + y, Color8(255, 0, 0))   # contenido mucho mas arriba que la base (10..30)
	espera("desplazada respecto a la base", V.validar(desp, C, "indice", base), false, "", "silueta")
	var casi := Image.create(4 * C, 4 * C, false, Image.FORMAT_RGBA8)
	for f in 4:
		for c in 4:
			for y in range(8, 29):
				for x in range(10, 22): casi.set_pixel(c * C + x, f * C + y, Color8(255, 0, 0))   # 2 px arriba: dentro de la tolerancia de 3
	espera("desplazada 2 px (tolerada)", V.validar(casi, C, "indice", base), true, "pose repetida")
	# no modifica la entrada: la hoja se guarda y se comprueba que los bytes siguen igual
	var ruta := DIR + "hoja_valida.png"
	hoja().save_png(ruta)
	var antes := FileAccess.get_file_as_bytes(ruta)
	var salida: Array = []
	var cod := OS.execute(OS.get_executable_path(), ["--headless", "--script", ProjectSettings.globalize_path(get_script_path()), "--", ruta, "--celda=32"], salida)
	var igual := FileAccess.get_file_as_bytes(ruta) == antes
	print("%s CLI: salida 0 y entrada intacta" % ["PASA " if cod == 0 and igual else "FALLA"])
	if not (cod == 0 and igual): fallos += 1
	cod = OS.execute(OS.get_executable_path(), ["--headless", "--script", get_script_path(), "--", ruta], salida)
	print("%s CLI: argumentos invalidos -> 2 (codigo %d)" % ["PASA " if cod == 2 else "FALLA", cod])
	if cod != 2: fallos += 1
	print("Resultado: ", "TODO CORRECTO" if fallos == 0 else "%d fallos" % fallos)
	quit(0 if fallos == 0 else 1)

func get_script_path() -> String:
	var sc: Script = V
	return sc.resource_path.get_base_dir() + "/validar_hoja.gd"
