extends SceneTree
const J=preload("res://scripts/juego.gd")
const M=preload("res://scripts/mundo.gd")
func _init() -> void:
 var args:=OS.get_cmdline_user_args()
 var semilla:=int(args[0]) if not args.is_empty() else 123
 var dias:=int(args[1]) if args.size()>1 else 10
 var j=J.nueva(semilla,"Observador",[0,0,0])
 j.combate.enemigos.clear()
 for i in dias*2880:
  j.tick(0.5)
  if i%2880==2879:
   print("PROGRESO semilla=",semilla," dia=",i/2880+1," habitantes=",j.habitantes.ids.size())
   j.guardar("/tmp/linde-simulacion-checkpoint-%d.json"%semilla)
 var s=j.autonomia.sociedad
 var camas:=0;var completas:=0;var negativas:=false
 for k in j.d.mundo.constr:
  if j.d.mundo.constr[k].t=="cama_huesped":
   camas+=1
   var c:=Vector2i(int(k.get_slice(",",0)),int(k.get_slice(",",1)))
   if s.casa_completa(c):completas+=1
 for nid in j.habitantes.ids:
  for q in j.autonomia.estado(nid).inv.values():
   if int(q)<0:negativas=true
 var trabajadores: Array=[]
 for nid in j.habitantes.ids:
  var n:Dictionary=j.autonomia.estado(nid)
  trabajadores.append({"id":nid,"oficio":j.autonomia.perfil(nid).get("oficio",""),"objetivo":n.get("objetivo",""),"inv":n.inv,"plan":n.plan})
 var resultado: Dictionary={"trabajadores":trabajadores,"semilla":semilla,"dias":dias,"habitantes":j.habitantes.ids.size(),"camas":camas,"casas_completas":completas,"solares":s.habitat.datos().parcelas.size(),"obras":s.habitat.datos().obras,"inventarios_negativos":negativas,"estadisticas":s.datos().estadisticas,"regiones":j.mundo.regiones.size()}
 var ruta:="/tmp/linde-crecimiento-simulacion-%d.json"%semilla
 FileAccess.open(ruta,FileAccess.WRITE).store_string(JSON.stringify(resultado,"  "))
 print("SIMULACION_CRECIMIENTO ",JSON.stringify(resultado))
 quit(1 if negativas else 0)
