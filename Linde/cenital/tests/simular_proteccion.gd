extends SceneTree
const J=preload("res://scripts/juego.gd")
func _init() -> void:
 var args:=OS.get_cmdline_user_args()
 var semilla:=int(args[0]) if not args.is_empty() else 123
 var j=J.nueva(semilla,"Observador",[0,0,0])
 j.autonomia.activar()
 for i in 144000:j.tick(0.1)
 var s=j.autonomia.sociedad
 var fibra:=0
 var negativos:=false
 for nid in j.habitantes.ids:
  var inv: Dictionary=j.autonomia.estado(nid).inv
  fibra+=int(inv.get("fibra",0))
  for q in inv.values():if int(q)<0:negativos=true
 for c in j.d.cofres.values():fibra+=int(c.inv.get("fibra",0))
 for gid in s.cfg.grupos:fibra+=int(s.grupo(gid).inv.get("fibra",0))
 var r:={"dias":10,"semilla":semilla,"habitantes":j.habitantes.ids.size(),"cofres":j.d.cofres.size(),"fibra_total":fibra,"inventarios_negativos":negativos,"hechos":s.datos().estadisticas}
 var base:=ProjectSettings.globalize_path("res://../../production/qa/evidence/proteccion")
 var f:=FileAccess.open(base+"/simulacion-%d.json"%semilla,FileAccess.WRITE)
 f.store_string(JSON.stringify(r,"  "));f.close()
 print("SIMULACION ",JSON.stringify(r))
 quit(1 if negativos else 0)
