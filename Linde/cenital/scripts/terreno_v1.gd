extends RefCounted
## Adaptado de Infinite Generation Demo (MIT, cool cat, revisión 63f7400).
## Aviso y código original en res://terceros/infinite-generation-demo/.
## V1 congelada: muestreo en coordenadas globales, independiente del orden de carga.
const TAM := 16
const LIMITE := 65536
var altitude := FastNoiseLite.new()
var moisture := FastNoiseLite.new()
var temperature := FastNoiseLite.new()
var semilla := 0
func _init(s: int) -> void:
 semilla=s
 altitude.seed=s
 moisture.seed=s ^ 0x42631
 temperature.seed=s ^ 0x73517
 for campo in [altitude,moisture,temperature]:
  campo.noise_type=FastNoiseLite.TYPE_SIMPLEX_SMOOTH
  campo.fractal_octaves=3
 altitude.frequency=0.009
 moisture.frequency=0.013
 temperature.frequency=0.006
static func region(c: Vector2i) -> Vector2i:
 return Vector2i(floori(float(c.x)/TAM),floori(float(c.y)/TAM))
static func hash_celda(c: Vector2i, s: int) -> int:
 var v: int=c.x*374761393+c.y*668265263+s*2147483629
 v=(v^(v>>13))*1274126177
 return (v^(v>>16))&0x7fffffff
static func distancia_valle(c: Vector2i) -> int:
 return maxi(maxi(0,maxi(-c.x,c.x-63)),maxi(0,maxi(-c.y,c.y-47)))
func valida(c: Vector2i) -> bool:
 return c.x>=-LIMITE and c.y>=-LIMITE and c.x<LIMITE and c.y<LIMITE
func datos(c: Vector2i) -> Dictionary:
 # Mismas coordenadas globales en ambos lados de cualquier borde de región.
 var alt: float=altitude.get_noise_2d(c.x,c.y)
 var moist: float=moisture.get_noise_2d(c.x,c.y)
 var calor: float=temperature.get_noise_2d(c.x,c.y)
 var transicion: float=clampf(float(distancia_valle(c))/12.0,0.0,1.0)
 alt=lerpf(0.12,alt,transicion)
 var camino: bool=posmod(c.x-32,96)==0 or posmod(c.y-23,96)==0
 var tipo:=1 if camino else 2 if alt< -0.22 else 0 # Mundo.T: PASTO, CAMINO, AGUA
 var bioma: String="ribera" if alt< -0.22 else "sierra" if alt>0.23 else "bosque" if moist>0.08 else "secano" if calor>0.2 else "pradera"
 var azar: float=float(hash_celda(c,semilla)%10000)/10000.0
 # Entrada gradual al exterior para no dibujar un corte recto en el borde del valle.
 azar=azar/lerpf(0.2,1.0,transicion)
 var objeto:=""
 if tipo==0:
  if bioma=="bosque": objeto="arbol" if azar<0.19 else "arbusto" if azar<0.29 else ""
  elif bioma=="sierra": objeto="veta" if azar<0.045 else "veta_cobre" if azar<0.07 else "veta_estano" if azar<0.085 else "roca" if azar<0.24 else "arbusto" if azar<0.27 else ""
  elif bioma=="secano": objeto="arbusto" if azar<0.05 else "arcilla" if azar<0.10 else "veta_cobre" if azar<0.12 else "veta_estano" if azar<0.13 else "roca" if azar<0.15 else ""
  else: objeto="arbusto" if azar<0.08 else "arbol" if azar<0.12 else "roca" if azar<0.15 else "veta" if azar<0.16 else "arcilla" if azar<0.175 else ""
 return {"tipo":tipo,"bioma":bioma,"objeto":objeto}
func generar_region(pos: Vector2i) -> Dictionary:
 var terreno:=PackedInt32Array()
 var biomas:=PackedStringArray()
 var recursos: Array=[]
 terreno.resize(TAM*TAM);biomas.resize(TAM*TAM)
 var chunk_offset:=pos*TAM
 for x in range(TAM):
  for y in range(TAM):
   var celda:=chunk_offset+Vector2i(x,y)
   var d:=datos(celda)
   terreno[y*TAM+x]=int(d.tipo)
   biomas[y*TAM+x]=str(d.bioma)
   if d.objeto!="": recursos.append({"t":str(d.objeto),"c":celda})
 return {"terreno":terreno,"biomas":biomas,"recursos":recursos}
