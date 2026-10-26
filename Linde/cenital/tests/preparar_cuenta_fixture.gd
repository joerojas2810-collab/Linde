extends SceneTree
func _initialize():
	var path=""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--config="):path=a.trim_prefix("--config=")
	var cfg=JSON.parse_string(FileAccess.get_file_as_string(path))
	var J=preload("res://scripts/juego.gd")
	var j=J.cargar(str(cfg.mundo));assert(j!=null)
	var id:String=cfg.id;assert(j.d.jugadores.has(id))
	var pj:Dictionary=j.jug(id)
	pj.inv={"madera":7,"piedra":3,"espada_hierro":1};pj.xp=43
	pj.equipo.arma="espada_hierro"
	pj.mapa={"bloques":{"99,99":"npc:maren"}}
	pj.look=[1,2,3,0,0,1,2,1]
	assert(j.guardar(str(cfg.mundo)))
	print("PASS fixture personaje persistente; mundo compartido reutilizado")
	quit()
