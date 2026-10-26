extends "res://tests/prueba_vivienda.gd"
func _init() -> void:
 var j=J.nueva(123,"Artesana",[0,0,0],"poblado")
 j.combate.enemigos.clear()
 var c:=solar_preparado(j)
 var e:=E.plano("taller",c,J.LOCAL)
 var coste:=E.coste(e)
 ok(coste=={"madera":115,"fibra":41,"piedra":10},"taller: precio exacto de estructura, mesa, horno y cofre existentes")
 j.jug().inv=coste.duplicate()
 ok(j.construir("taller",c).ok and j.jug().inv.is_empty() and E.accesible(j,e),"taller terminado, pagado y accesible desde el exterior")
 var mesa:=c+Vector2i(-2,-4)
 var horno:=c+Vector2i(2,-4)
 var cofre:=c+Vector2i(2,-2)
 j.pies=M.pies_de_celda(mesa+Vector2i.DOWN);j.mira=Vector2i.UP
 j.jug().inv={"madera":6,"fibra":2}
 ok(j.interactuar().get("panel","")=="craft" and j.fabricar("escudo_madera").ok and j.jug().inv=={"escudo_madera":1},"mesa interior: interacción y receta real sin descuentos ni habilidades nuevas")
 j.pies=M.pies_de_celda(horno+Vector2i.DOWN);j.mira=Vector2i.UP
 j.jug().inv={"piedra":2,"fibra":1}
 ok(j.interactuar().get("panel","")=="craft" and j.fabricar("ladrillo").ok and j.jug().inv=={"ladrillo":2},"horno interior: fabricación existente y consumo exacto")
 j.pies=M.pies_de_celda(cofre+Vector2i.DOWN);j.mira=Vector2i.UP
 var cid:="c@"+M.clave(cofre)
 ok(j.interactuar().get("panel","")=="cofre" and j.mover_cofre(cid,"ladrillo",true).ok and j.d.cofres[cid].inv=={"ladrillo":2},"anexo de almacenamiento usa el mismo cofre, sin reservas paralelas")
 j.pies=M.pies_de_celda(c+Vector2i(0,3));j.jug().inv={"piedra":2,"fibra":1}
 ok(not j.fabricar("ladrillo").ok,"tener un taller no concede estación a distancia")
 j.mundo.quitar(horno);j.mundo.destechar(mesa)
 j.guardar("/tmp/linde-taller.json")
 var carga=J.cargar("/tmp/linde-taller.json")
 ok(carga!=null and carga.mundo.edificio_en(c)==j.mundo.edificio_en(c) and carga.mundo.constr_en(horno).is_empty() and carga.d.cofres[cid].inv=={"ladrillo":2},"persistencia conserva plano, daños y contenido sin regenerar estaciones")
 carga.pies=M.pies_de_celda(c+Vector2i.DOWN);carga.actualizar_regiones()
 carga.jug().inv={"piedra":8,"madera":1,"fibra":1}
 ok(carga.reparar_edificio(e.id,int(carga.mundo.edificio_en(c).revision)).ok and carga.jug().inv.is_empty() and carga.d.cofres[cid].inv=={"ladrillo":2},"reparación paga solo horno y cubierta, sin tocar el depósito")
 # NPC detallado: misma decisión, navegación, estación y receta que fuera del edificio.
 carga.autonomia.reglas.sociedad.activa=false
 carga.d.min=10*60
 var n: Dictionary=carga.autonomia.estado("ordal")
 n.inv={"baya":8,"mena":2,"madera":1};n.hambre=0.0
 carga.d.mundo_vivo.autonomia.ultimo_min=int(carga.d.min)
 var p0:=M.pies_de_celda(c+Vector2i.DOWN)
 carga.d.npcs.ordal.pos=[p0.x,p0.y];carga.d.npcs.ordal.energia=100.0
 ok(carga.autonomia._estacion("ordal","horno")==M.clave(horno),"NPC identifica el horno real y una ruta desde fuera del taller")
 for i in 600:carga.tick(0.1)
 ok(int(n.inv.get("lingote",0))==1 and not n.inv.has("mena") and not n.inv.has("madera") and n.recuerdos.any(func(r):return r.hecho=="fabrico"),"NPC entra y fabrica con consumo y memoria existentes")
 ok(E.abierto(e,M.pies_de_celda(c+Vector2i(0,-2))) and not E.abierto(e,M.pies_de_celda(c+Vector2i(0,3))),"cubierta local independiente de estaciones, inventarios y física")
 quit(1 if fallos else 0)
