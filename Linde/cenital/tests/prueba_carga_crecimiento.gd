extends SceneTree
const J=preload("res://scripts/juego.gd")
const M=preload("res://scripts/mundo.gd")
const S=preload("res://scripts/red_servidor.gd")
func _init() -> void:
 var j=J.nueva(987,"Carga",[0,0,0])
 j.combate.enemigos.clear()
 var so=j.autonomia.sociedad
 j.autonomia.estado("maren").inv={"madera":200,"piedra":200,"fibra":200,"baya":30}
 var puestos:=0
 for y in range(6,42,3):
  for x in range(5,58,3):
   if puestos>=10:break
   var c:=Vector2i(x,y)
   if j.mundo.puede_poner(c)!="" or M.ESENCIALES.has(c):continue
   j.mundo.poner(c,"cama_huesped",false)
   j.d.min+=1440
   so._inmigrar()
   puestos+=1
 for i in 3:j.unir("carga_%d"%i,"Prueba %d"%i,[0,0,0])
 j.d.mundo_vivo.autonomia.ultimo_min=int(j.d.min)
 var srv=S.new();srv.j=j
 var tiempos: Array=[]
 for i in 1200:
  var inicio:=Time.get_ticks_usec()
  j.tick(0.05)
  srv.instantanea_actual()
  tiempos.append(float(Time.get_ticks_usec()-inicio)/1000.0)
 tiempos.sort()
 var r:Dictionary={"habitantes":j.habitantes.ids.size(),"sesiones":j.rt.size(),"ticks":tiempos.size(),"p95_ms":tiempos[floori(tiempos.size()*0.95)],"max_ms":tiempos[-1],"regiones":j.mundo.regiones.size(),"bytes_instantanea":var_to_bytes(srv.instantanea_actual()).size()}
 FileAccess.open("/tmp/linde-carga-crecimiento.json",FileAccess.WRITE).store_string(JSON.stringify(r,"  "))
 var bien:bool=r.habitantes==12 and r.sesiones==4 and r.regiones<=200
 print(("PASS " if bien else "FAIL ")+"CARGA_CRECIMIENTO "+JSON.stringify(r))
 srv.free()
 quit(0 if bien else 1)
