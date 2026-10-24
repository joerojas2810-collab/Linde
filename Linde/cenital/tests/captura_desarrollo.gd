extends SceneTree
## Escena real con actividad de NPC y acciones reales del jugador para inspeccionar los paneles.
const J = preload("res://scripts/juego.gd")
const M = preload("res://scripts/mundo.gd")
const A = preload("res://scripts/artesania.gd")
var carpeta := ""
func foto(nombre: String) -> void:
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(carpeta+"/"+nombre+".png")
func recoger(j,tipo: String,veces: int) -> void:
	var pendientes := veces
	for oid in j.mundo.objetos:
		if pendientes<=0:return
		var o: Dictionary=j.mundo.objetos[oid]
		if o.t!=tipo or j.mundo.objeto_presente(o.c)!=oid:continue
		var ruta: Array=j.mundo.camino(M.celda_de(j.pies),func(c):return j.mundo.es_adyacente(c,o.c))
		if ruta.is_empty():continue
		j.pies=M.pies_de_celda(ruta.back()) # Posicionamiento QA; se recoge mediante la acción real.
		for i in 12:
			if j.mundo.objeto_presente(o.c)!=oid:break
			j.golpear_objeto(o.c)
		pendientes-=1
func _init() -> void:
	carpeta=ProjectSettings.globalize_path("res://../../production/qa/evidence/desarrollo")
	var esc=load("res://main.tscn").instantiate()
	esc.ruta="/tmp/linde-desarrollo-captura.json"
	root.add_child(esc)
	await process_frame
	esc.j=J.nueva(123,"Exploradora",[0,0,0])
	esc.j.autonomia.activar()
	esc.j.combate.enemigos.clear()
	for i in 43200:esc.j.tick(0.1)
	esc.modo="juego"
	# Descubrir madera y practicar con tres piezas comunes usando ingredientes recolectados.
	recoger(esc.j,"arbol",4)
	esc.j.pies=M.pies_de_celda(Vector2i(28,21))
	if not esc.j.estacion_cerca("mesa"):
		recoger(esc.j,"roca",1)
		esc.j.pies=M.pies_de_celda(Vector2i(28,21))
		esc.j.construir("mesa",Vector2i(29,20))
	var espada:=A.clave("espada","madera","simple",0)
	for i in 3:
		if not esc.j.fabricar_artefacto(espada).ok:
			push_error("No se pudo preparar la práctica con acciones reales")
			quit(1);return
	esc.j.equipar(espada)
	var e:=InputEventKey.new();e.pressed=true;e.keycode=KEY_G
	esc._unhandled_key_input(e)
	if esc.panel!="desarrollo":push_error("G no abrió el taller");quit(1);return
	print("PASS UI: G abre el taller")
	await foto("taller")
	esc._abrir("materiales")
	if esc.sel!=1:push_error("El atlas no empieza por el primer material");quit(1);return
	await foto("materiales")
	for i in esc.lineas.size():
		if esc.lineas[i].begins_with("Lingote"):
			esc.sel=i
			await foto("hierro")
			break
	esc._abrir("planos")
	await foto("planos")
	esc._abrir("practica")
	await foto("practica")
	esc._abrir("laminados")
	await foto("laminados")
	esc._abrir("inv")
	await foto("equipo")
	var f=FileAccess.open(carpeta+"/estado.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(esc.j.d,"  "));f.close()
	# La prueba lógica conserva una pieza compuesta fabricada con costes reales.
	if FileAccess.file_exists("/tmp/linde-materiales-prueba.json"):
		var compuesta=J.cargar("/tmp/linde-materiales-prueba.json")
		if compuesta!=null:
			esc._cerrar()
			esc.j=compuesta
			esc.j.combate.enemigos.clear()
			await foto("armadura_compuesta")
			esc._abrir("inv")
			await foto("inventario_compuesto")
	print("CAPTURAS_DESARROLLO: "+carpeta)
	quit()
