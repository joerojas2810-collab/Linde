extends "res://tests/captura_lugares.gd"
## Captura reproducible de comunidades y datos reales; no modifica arte ni añade decoraciones ficticias.
func _init() -> void:
 carpeta=ProjectSettings.globalize_path("res://../../production/qa/evidence/mundo-1/fase-5")
 DirAccess.make_dir_recursive_absolute(carpeta)
 esc=load("res://main.tscn").instantiate()
 esc.ruta="/tmp/linde-preexistentes-captura.json"
 root.add_child(esc)
 await process_frame
 esc.j=esc.J.nueva(123,"Viajera",[0,0,0],"poblado")
 esc.modo="juego";esc.set_process(false)
 esc.j.gestionar_pista("silenciar");esc.j.combate.enemigos.clear()
 var a=esc.j.autonomia.asentamientos
 for pid in a.datos().preexistentes.ids:
  var p: Dictionary=esc.j.mundo.poblado(pid)
  esc.j.pies=esc.Mundo.pies_de_celda(Vector2i(p.entrada[0],p.entrada[1]))
  esc.j.actualizar_regiones();esc.j.actualizar_mapa()
  esc.pista=esc._pista()
  await foto("comunidad-"+pid.replace("@","-").replace(",","-"))
 var pid: String=a.datos().preexistentes.ids[0]
 var p: Dictionary=esc.j.mundo.poblado(pid)
 esc.j.pies=esc.Mundo.pies_de_celda(Vector2i(p.centro[0],p.centro[1]+1))
 esc.j.actualizar_regiones();esc.j.actualizar_mapa()
 esc.j.mira=Vector2i.UP
 esc._interactuar();await foto("dialogo-residente");esc._cerrar()
 esc._ficha_cercana();await foto("identidad-residente");esc._cerrar()
 esc.j.pies=esc.Mundo.pies_de_celda(Vector2i(p.centro[0],p.centro[1]+3))
 esc.j.mira=Vector2i.UP
 esc._interactuar();await foto("cofre-comunidad");esc._cerrar()
 for h in 72:
  esc.j.d.min+=60
  esc.j.mundo.regenerar(int(esc.j.d.min),esc.j.ocupada)
  a.actualizar()
 esc._abrir("mis")
 esc.desplaza=maxi(1,esc.lineas.find("— VIVIENDAS Y PUESTOS —"))
 await foto("reservas-tres-dias");esc._cerrar()
 esc.mapa_centro=Vector2i(p.centro[0],p.centro[1]);esc.mapa_escala=4
 esc._abrir("mapa");await foto("mapa-comunidades")
 quit()
