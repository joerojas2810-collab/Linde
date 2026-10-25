extends SceneTree
# Recorre la UI real: menú -> creador -> partida -> paneles -> guardar -> continuar. Falla ante cualquier error de script.
var fallos := 0
func ok(c: bool, n: String) -> void:
	print(("PASS " if c else "FAIL ") + n)
	if not c: fallos += 1
func tecla(esc, k: int, u: int = 0) -> void:
	var e := InputEventKey.new()
	e.pressed = true
	e.keycode = k
	e.unicode = u
	esc._unhandled_key_input(e)
func _init() -> void:
	var ruta := ProjectSettings.globalize_path("user://") + "pruebas_linde/ui.json"
	DirAccess.make_dir_recursive_absolute(ruta.get_base_dir())
	for f in [ruta, ruta + ".bak"]: if FileAccess.file_exists(f): DirAccess.remove_absolute(f)
	var esc = load("res://main.tscn").instantiate()
	esc.ruta = ruta
	root.add_child(esc)
	await process_frame
	ok(esc.modo == "menu" and esc.menu_sel == 1, "menú sin partida: preselecciona Nueva")
	tecla(esc, KEY_ENTER)
	ok(esc.modo == "creador", "abre el creador")
	for i in 7: tecla(esc, KEY_BACKSPACE)
	for ch in "Ana": tecla(esc, KEY_A, ch.unicode_at(0))
	tecla(esc, KEY_DOWN)
	tecla(esc, KEY_RIGHT)
	for i in 5: tecla(esc, KEY_DOWN)
	tecla(esc, KEY_ENTER)
	ok(esc.modo == "juego" and esc.j.d.pj.nombre == "Ana" and esc.j.d.pj.look[0] == 1, "crea el personaje con nombre y apariencia elegidos")
	for i in 10: await process_frame
	for k in [KEY_I, KEY_C, KEY_K, KEY_J]:
		tecla(esc, k)
		await process_frame
		ok(esc.panel != "", "panel %d abre" % k)
		tecla(esc, KEY_ESCAPE)
	tecla(esc, KEY_B)
	ok(esc.build, "modo construcción")
	await process_frame
	tecla(esc, KEY_B)
	esc.j.d.inv = {"madera": 10}
	tecla(esc, KEY_ESCAPE)
	ok(esc.panel == "pausa", "Esc abre pausa")
	tecla(esc, KEY_DOWN)
	tecla(esc, KEY_ENTER)
	ok(FileAccess.file_exists(ruta), "Guardar desde pausa escribe el archivo")
	tecla(esc, KEY_ESCAPE)
	tecla(esc, KEY_DOWN)
	tecla(esc, KEY_DOWN)
	tecla(esc, KEY_ENTER)
	ok(esc.modo == "menu" and esc.j == null, "Guardar y salir vuelve al menú")
	esc.menu_sel = 0
	tecla(esc, KEY_ENTER)
	ok(esc.modo == "juego" and esc.j.d.inv.get("madera", 0) == 10 and esc.j.d.pj.nombre == "Ana", "Continuar restaura la partida")
	for i in 5: await process_frame
	print("FALLOS_UI: %d" % fallos)
	quit(1 if fallos else 0)
