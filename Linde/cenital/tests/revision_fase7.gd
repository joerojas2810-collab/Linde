extends SceneTree
## Five focused integration checks and four screenshots. Run with rendering, optionally -- --salida=<folder>.
const J=preload("res://scripts/juego.gd")
const M=preload("res://scripts/mundo.gd")
const Eq=preload("res://scripts/equipo.gd")
const P=preload("res://scripts/params.gd")
var esc
var out="user://revision_fase7"
var checks=[]
func _initialize():
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--salida="):out=arg.trim_prefix("--salida=")
	out=ProjectSettings.globalize_path(out).trim_suffix("/")+"/"
	DirAccess.make_dir_recursive_absolute(out+"capturas")
	call_deferred("run")
func check(ok:bool,label:String):
	checks.append({"ok":ok,"comprobacion":label});print("PASS " if ok else "FAIL ",label)
func photo(name:String):
	esc.queue_redraw();esc.hud.queue_redraw()
	for i in 5:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out+"capturas/"+name+".png")
func encounter()->Dictionary:
	for y in range(-16,17):
		for x in range(-16,17):
			var plan:Dictionary=esc.j.combate.fauna.plan_region(Vector2i(x,y))
			if plan.is_empty() or plan.tipo!="golem_sierra":continue
			esc.j.pies=M.pies_de_celda(plan.celda+Vector2i(9,0));esc.j.actualizar_regiones();esc.j.combate.fauna.actualizar()
			for enemy in esc.j.combate.enemigos:
				if enemy.get("fauna_id","")==plan.id:return enemy
	return {}
func clear_nearby(enemy:Dictionary)->Vector2:
	var center=M.celda_de(enemy.pos)
	for radius in [2,3,4]:
		for dy in range(-radius,radius+1):
			for dx in range(-radius,radius+1):
				var c=center+Vector2i(dx,dy)
				if esc.j.mundo.bloquea(c):continue
				var clear=true
				for oy in range(-1,2):
					for ox in range(-1,2):
						if esc.j.mundo.objeto_presente(c+Vector2i(ox,oy))!="":clear=false
				if clear:return M.pies_de_celda(c)
	return enemy.pos+Vector2(40,16)
func run():
	root.size=Vector2i(1280,720)
	esc=load("res://main.tscn").instantiate();esc.ruta="user://revision_fase7_muestra.json";root.add_child(esc)
	esc.j=J.nueva(123,"Viajero",[0,1,0,0,0,0,0,0]);esc.modo="juego"
	var technique="simple"
	var wood=Eq.Artesania.clave("espada","madera",technique,1)
	var iron=Eq.Artesania.clave("espada","hierro",technique,1)
	for slot in ["casco","torso","guantes","pantalones","botas"]:esc.j.jug().equipo[slot]=Eq.Artesania.clave(slot,"hierro",technique,1)
	esc.j.jug().equipo.arma=iron;esc.j.jug().equipo.escudo=Eq.Artesania.clave("escudo","madera",technique,1)
	var center=esc.j.habitantes.pos("maren")
	esc.j.pies=center+Vector2(24,24);esc.j.actualizar_regiones();esc.cam.position=esc.j.pies-Vector2(0,12)
	await photo("01_valle_integrado")
	check(esc.arte_eq.viajero071.generados>0 and P.ZOOM==3 and P.PIES==Vector2(10,6),"arranque con viajero/NPC detallados, cámara 3× y colisión conservada")
	check(esc.hud.ui.fuente.base_font.resource_path.ends_with("NunitoSans.ttf") and esc.hud.ui.fuente_dialogo.base_font.resource_path.ends_with("Lora.ttf"),"Nunito y Lora de la versión actual conservadas")
	var w=Eq.visible({"arma":wood});var h=Eq.visible({"arma":iron})
	var materials=w.size()==1 and h.size()==1
	if materials:
		var wi=esc.arte_eq.viajero071.held_image("espada",w[0].paleta)
		var hi=esc.arte_eq.viajero071.held_image("espada",h[0].paleta)
		materials=wi.get_data()!=hi.get_data() and not Eq.Artesania.leer(esc.j.jug().equipo.torso).is_empty()
	check(materials,"equipo combinatorio y colores distintos para espada de madera/hierro")
	esc._abrir("inv");await photo("02_inventario_nunito");esc._cerrar()
	esc.j.pies=esc.j.habitantes.pos("maren")+Vector2(16,0);esc.j.mira=Vector2i.LEFT
	esc._interactuar();await photo("03_dialogo_lora");esc._cerrar()
	var enemy=encounter()
	if not enemy.is_empty():
		esc.j.pies=clear_nearby(enemy);esc.j.actualizar_regiones();esc.cam.position=esc.j.pies-Vector2(0,12);esc.cam.reset_smoothing()
		await photo("04_bioma_y_fauna")
	for biome in ["bosque","sierra","secano","pradera","ribera"]:esc.arte_mundo.tex("biomas/"+biome+".png")
	for name in esc.actores.FAUNA.values():esc.actores.tex("fauna/"+name+"_idle.png")
	check(not enemy.is_empty() and esc.j.autonomia.activa() and esc.arte_mundo.faltantes.is_empty() and esc.actores.faltantes.is_empty() and esc.hud.ui.faltantes.is_empty(),"autonomía por defecto, regiones/biomas y fauna real conservados; sin recursos faltantes")
	esc.set_process(false)
	var equipped=esc.j.jug().equipo.duplicate();var appearance=esc.j.jug().look.duplicate()
	var path=ProjectSettings.globalize_path("user://revision_fase7/guardado.json");DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var saved=esc.j.guardar(path);var loaded=J.cargar(path) if saved else null
	check(saved and loaded!=null and loaded.jug().equipo==equipped and loaded.jug().look==appearance and loaded.autonomia.activa() and loaded.d.has("fauna"),"guardado/carga conserva aspecto, equipo artesanal, autonomía y fauna")
	var failures=checks.filter(func(c):return not c.ok)
	FileAccess.open(out+"COMPROBACIONES.json",FileAccess.WRITE).store_string(JSON.stringify({"base":"618180b","total":checks.size(),"fallos":failures.size(),"comprobaciones":checks,"alcance":"Integración visual y guardado local; no sustituye pruebas completas de sociedad ni una sesión multijugador."},"  "))
	print("FASE7_INTEGRACION: ",checks.size()," comprobaciones, ",failures.size()," fallos")
	esc.modo="creador";esc.j=null;loaded=null;esc.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
