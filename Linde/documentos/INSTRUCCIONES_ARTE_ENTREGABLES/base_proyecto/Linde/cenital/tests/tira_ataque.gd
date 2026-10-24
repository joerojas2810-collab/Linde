extends SceneTree
## Monta la tira de UN ciclo de ataque completo a partir de los cuadros consecutivos de movie mode.
## Captura: Godot --path Linde/cenital --always-on-top --write-movie <dir>/f.png --fixed-fps 30 --quit-after 45 -- --nueva=1
##   --ir=29,26 --arte --equipo=<familia>:<variante> --auto-ataque --mira=<dir> > <log.txt>
## (--always-on-top: con la ventana tapada macOS deja de dibujar y movie mode repite el último cuadro.)
## Uso: Godot --headless --script Linde/cenital/tests/tira_ataque.gd -- <dir_cuadros> <log.txt> <salida.png>
## <dir_cuadros>: f00000000.png... de `--write-movie <dir>/f.png --fixed-fps 30` con `--auto-ataque`; <log.txt>: su
## salida estándar. Cada línea «AUTOATQ cuadro_proceso=N ...» describe el PNG número N. La tira empieza
## un cuadro antes del primer cuadro de ataque y acaba en el primer cuadro libre de después; cada cuadro lleva
## encima (dibujado por el juego) la fase de combate, el cuadro de animación y la pose.
const PIES := Vector2i(640, 396)          # pies del PJ en pantalla: cámara en pies-(0,12), zoom 3, ventana 1280x720
const RECORTE := Rect2i(-84, -172, 176, 186)
const POR_FILA := 6
const ESCALA := 2                         # ampliación nearest de la tira para revisarla

func _init() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() < 3: print("uso: -- <dir_cuadros> <log.txt> <salida.png>"); quit(2); return
	var est: Array = []   # índice = cuadro de proceso = número del PNG de movie mode
	for l in FileAccess.get_file_as_string(a[1]).split("\n"):
		if not l.begins_with("AUTOATQ "): continue
		var n := l.get_slice("cuadro_proceso=", 1).get_slice(" ", 0).to_int()
		if est.size() <= n: est.resize(n + 1)
		est[n] = l.get_slice("estado=", 1).get_slice(" ", 0)
	var ini := est.find("ataque")
	if ini < 0: print("sin ataque en el registro"); quit(1); return
	var fin := ini
	while fin < est.size() and est[fin] == "ataque": fin += 1
	var idx: Array = range(maxi(0, ini - 1), mini(est.size(), fin + 1))
	var filas := ceili(idx.size() / float(POR_FILA))
	var out := Image.create(POR_FILA * (RECORTE.size.x + 4), filas * (RECORTE.size.y + 4), false, Image.FORMAT_RGBA8)
	out.fill(Color(0.1, 0.1, 0.1))
	for k in idx.size():
		var f := "%s/f%08d.png" % [a[0], idx[k]]
		var im := Image.load_from_file(f)
		if im == null: print("falta ", f); quit(1); return
		im.convert(Image.FORMAT_RGBA8)
		out.blit_rect(im, Rect2i(PIES + RECORTE.position, RECORTE.size), Vector2i((k % POR_FILA) * (RECORTE.size.x + 4), (k / POR_FILA) * (RECORTE.size.y + 4)))
	out.resize(out.get_width() * ESCALA, out.get_height() * ESCALA, Image.INTERPOLATE_NEAREST)
	out.save_png(a[2])
	print("tira %s: cuadros %d..%d (%d), ataque en %d..%d" % [a[2], idx[0], idx[-1], idx.size(), ini, fin - 1])
	quit(0)
