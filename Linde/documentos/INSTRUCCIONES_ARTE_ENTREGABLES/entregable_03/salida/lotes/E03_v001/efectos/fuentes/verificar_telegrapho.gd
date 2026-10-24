extends SceneTree
## Verifica limites mecanicos observados; genera una lamina geometrica.
const T = preload("res://fuentes/telegrapho.gd")
var errores: Array = []
var pruebas := 0

func _initialize() -> void:
	var ce := T.centro_enemigo(Vector2(100,100),28)
	_comprobar(ce == Vector2(100,86), "centro enemigo -tam/2")
	_comprobar(T.centro_jugador(Vector2(100,100)) == Vector2(100,94), "centro jugador -6")
	for radio in [14.0,44.0,36.0]:
		var area := T.circulo(Vector2.ZERO,radio)
		_comprobar(T.contiene_centro(Vector2(radio+6.0,0),area), "incluye radio+6")
		_comprobar(not T.contiene_centro(Vector2(radio+6.01,0),area), "excluye mas de radio+6")
	var libre := func(p, d, _tam): return p+d
	var final := T.predecir_final(Vector2.ZERO,Vector2.RIGHT,70,28,libre)
	_comprobar(final == Vector2(70,0), "avance70 sin obstaculo")
	var bloqueado := func(p, d, _tam): return p if (p+d).x > 26.0 else p+d
	var final_pared := T.predecir_final(Vector2.ZERO,Vector2.RIGHT,70,28,bloqueado)
	_comprobar(final_pared == Vector2(26,0), "pared detiene pasos2")
	var capsula := T.linea(Vector2.ZERO,final,28,16)
	_comprobar(T.contiene_centro(Vector2(35,0),capsula), "ancho/2+6 incluido")
	_comprobar(not T.contiene_centro(Vector2(35,0.01),capsula), "ancho/2+6 excluido")
	_comprobar(T.contiene_centro(Vector2(84,-14),capsula), "extremo redondo")
	_comprobar(not T.contiene_centro(Vector2(84.01,-14),capsula), "fuera extremo")
	var nula := T.linea(Vector2.ZERO,Vector2.ZERO,28,16)
	_comprobar(T.contiene_centro(Vector2(14,-14),nula), "segmento nulo es circulo")
	_lamina()
	var r := {"motor": Engine.get_version_info().string, "pruebas": pruebas, "errores": errores, "resultado": "OK" if errores.is_empty() else "FALLO", "limite": "Pruebas de geometria visual. No ejecutan combate ni certifican red/prediccion en juego."}
	FileAccess.open("res://qa/VALIDACION_TELEGRAFOS.json",FileAccess.WRITE).store_string(JSON.stringify(r,"\t")+"\n")
	print(JSON.stringify(r))
	quit(0 if errores.is_empty() else 1)

func _comprobar(ok: bool, nombre: String) -> void:
	pruebas += 1
	if not ok: errores.append(nombre)

func _lamina() -> void:
	var im := Image.create(320,128,false,Image.FORMAT_RGBA8)
	im.fill(Color("42624e"))
	var areas := [T.circulo(Vector2(28,64),14),T.circulo(Vector2(102,64),44),T.circulo(Vector2(196,64),36), T.linea(Vector2(252,46),Vector2(288,86),28,16)]
	for y in 128:
		for x in 320:
			var p := Vector2(x,y)
			for area in areas:
				var d := T.distancia_eje(p,area)
				if d > area.radio_efectivo: continue
				# Borde exterior mas checkers: tolerancia de centro del PJ.
				if d >= area.radio_efectivo-1: im.set_pixel(x,y,Color("ffe0bc"))
				elif absf(d-area.radio_base)<0.8: im.set_pixel(x,y,Color("efb64d"))
				elif d > area.radio_base and (x+y)%4==0: im.set_pixel(x,y,Color("ce6453"))
				elif d <= area.radio_base and (x+y)%6==0: im.set_pixel(x,y,Color("8a574f"))
	im.resize(960,384,Image.INTERPOLATE_NEAREST)
	im.save_png("res://qa/TELEGRAFOS_GEOMETRIA_x3.png")
