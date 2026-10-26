extends SceneTree
## Muestra acotada y reproducible; no avanza combate ni crea población distante.
const J=preload("res://scripts/juego.gd")
const M=preload("res://scripts/mundo.gd")
const H=preload("res://scripts/huella.gd")

static func caso(seed:int,version:int,inverso:bool=false) -> Dictionary:
 # Línea base congelada: crear explícitamente una política de generación v1.
 var j=J.nueva(seed,"Muestra",[0,0,0],M.MODO_POBLADO,1)
 j.d.mundo.generacion.version=version;j.mundo.configurar(seed);j.combate.fauna.planes.clear()
 var estado=H.hash_de(j.d);var cargadas=j.mundo.regiones.size()
 var coords:Array=[];var por_region:Dictionary={};var especies:Dictionary={};var terreno:Array=[]
 var compatibles=true
 for y in range(-14,15):
  for x in range(-14,15):coords.append(Vector2i(x,y))
 if inverso:coords.reverse()
 var inicio=Time.get_ticks_usec()
 for r in coords:
  var p:Dictionary=j.combate.fauna.plan_region(r)
  por_region[M.clave(r)]={}
  if p.is_empty():continue
  especies[p.tipo]=int(especies.get(p.tipo,0))+1
  var h:Dictionary=j.combate.fauna.habitat_en(p.celda)
  compatibles=compatibles and h.get("tipo","")==p.tipo and M.Terreno.distancia_valle(p.celda)>=8
  compatibles=compatibles and (p.bioma!="ribera" or h.get("agua_vecina",false))
  por_region[M.clave(r)]={"id":p.id,"celda":[p.celda.x,p.celda.y],"tipo":p.tipo,"bioma":p.bioma}
 var planes:Array=[]
 for y in range(-14,15):
  for x in range(-14,15):
   var r=Vector2i(x,y);planes.append(por_region[M.clave(r)])
   terreno.append(j.mundo.generador.datos(r*16))
 return {"semilla":seed,"generador":version,"regiones":841,"ocupadas":especies.values().reduce(func(a,b):return a+b,0),"especies":especies,"planes_sha256":H.hash_de(planes),"terreno_sha256":H.hash_de(terreno),"estado_sha256":estado,"consulta_pura":estado==H.hash_de(j.d) and cargadas==j.mundo.regiones.size(),"compatibles":compatibles,"perfiles":j.combate.fauna.habitats,"tiempo_ms":(Time.get_ticks_usec()-inicio)/1000.0}

func _init() -> void:
 var salida=""
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--salida="):salida=arg.trim_prefix("--salida=")
 var casos:Array=[]
 for seed in [123,456,789]:
  for version in [1,2]:casos.append(caso(seed,version))
 var result={"huella":H.huella(),"casos":casos}
 if salida!="":
  var f=FileAccess.open(salida,FileAccess.WRITE);f.store_string(JSON.stringify(result,"  "));f.close()
 else:print(JSON.stringify(result,"  "))
 quit()
