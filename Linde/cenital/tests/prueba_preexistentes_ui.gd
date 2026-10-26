extends "res://tests/prueba_lugares_ui.gd"
## La misma escena y entradas del jugador: descubrimiento, diálogo, ficha y referencias personales.
func _init() -> void:
 var e = load("res://main.tscn").instantiate()
 e.ruta="/tmp/linde-preexistentes-ui.json"
 root.add_child(e)
 await process_frame
 e.set_process(false)
 e.j=J.nueva(123,"Viajera",[0,0,0],"poblado")
 e.modo="juego"
 var j=e.j
 var a=j.autonomia.asentamientos
 var pid: String=a.datos().preexistentes.ids[0]
 var p: Dictionary=j.mundo.poblado(pid)
 var r: Dictionary=a.datos().puestos[p.puesto].residentes[0]
 var lugar: Dictionary=j.d.mundo.registro.lugares[pid]
 ok(not j.Exploracion.hitos(j,J.LOCAL).any(func(h):return h.get("id","")==pid),"el pueblo desconocido no se revela en el mapa")
 e._abrir("mis")
 ok(not e.lineas.any(func(l):return l.contains(p.nombre)),"J no revela las reservas de una comunidad sin visitar")
 e._cerrar()
 ok(not j.preguntar_lugares(r.id).ok,"la autoridad rechaza preguntar al residente lejano")
 j.pies=M.pies_de_celda(Vector2i(lugar.entrada[0],lugar.entrada[1]))
 j.actualizar_regiones();j.actualizar_mapa()
 ok(j.Exploracion.hitos(j,J.LOCAL).any(func(h):return h.get("id","")==pid and h.fuente=="visto"),"la visita confirma la comunidad en el mapa personal")
 j.pies=M.pies_de_celda(Vector2i(p.centro[0],p.centro[1]+3))
 j.mira=Vector2i.UP
 tecla(e,KEY_E)
 ok(e.panel=="cofre" and e.cofre_id==a.datos().puestos[p.puesto].cofre,"E abre el depósito apuntado aunque haya un residente cerca")
 tecla(e,KEY_ESCAPE)
 j.pies=a.posicion(r.id)
 j.mira=Vector2i.DOWN
 tecla(e,KEY_E)
 ok(e.panel=="dialogo" and e.dialogo_npc==r.id and e.dialogo_nombre==r.nombre and e.dialogo_txt.contains(p.nombre),"E habla con la persona regional por su identidad y hogar")
 var rumor := "800,800"
 r.bloques[rumor]=true
 tecla(e,KEY_L)
 ok(j.jug().mapa.bloques.get(rumor,"")=="npc:"+r.id and j.nombre_habitante(r.id)==r.nombre,"L intercambia información y conserva el nombre de la fuente")
 tecla(e,KEY_V)
 ok(e.panel=="habitante_regional" and e.lineas.any(func(l):return l.contains(r.historia)),"V muestra oficio e historia sin crear un segundo actor")
 tecla(e,KEY_ESCAPE)
 e._abrir("mis")
 ok(e.lineas.any(func(l):return l.contains(p.nombre)) and e.lineas.any(func(l):return l.contains(r.nombre)),"J muestra la comunidad visitada y sus habitantes")
 e._cerrar()
 # Un viajero debe encontrarse físicamente con la comunidad para difundir sus referencias.
 var npc: String=j.habitantes.ids[0]
 var antes: Vector2=j.habitantes.pos(npc)
 j.d.npcs[npc].pos=[j.pies.x,j.pies.y]
 j.autonomia._explorar(npc)
 ok(j.autonomia.estado(npc).bloques.has(rumor),"el encuentro transmite referencias entre residentes regionales y NPC viajeros")
 j.d.npcs[npc].pos=[antes.x,antes.y]
 j.unir("otra","Otra",[0,0,0])
 j.rt.otra.pies=antes
 ok(not j.jug("otra").mapa.bloques.has(rumor),"la información no se publica en todos los mapas personales")
 j.preguntar_lugares(npc,"otra")
 ok(j.jug("otra").mapa.bloques.get(rumor,"")=="npc:"+npc,"otro jugador recibe la referencia a través del viajero que encontró la comunidad")
 j.guardar("/tmp/linde-preexistentes-ui-guardado.json")
 var cargado=J.cargar("/tmp/linde-preexistentes-ui-guardado.json")
 ok(cargado.jug().mapa.bloques.get(rumor,"")=="npc:"+r.id and cargado.autonomia.asentamientos.residente(r.id).bloques.has(rumor),"guardar conserva procedencia personal y memoria regional")
 quit(1 if fallos else 0)
