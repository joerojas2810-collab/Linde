extends "res://scripts/mundo_arte.gd"
## Presentación mundial integrada. Mismas celdas, recursos, colisiones y reglas.
var mundo_actual
const VELADURAS:={"valle":Color(0.46,0.73,0.23,0.16),"bosque":Color(0.18,0.44,0.20,0.23),"pradera":Color(0.38,0.73,0.30,0.23),"sierra":Color(0.33,0.44,0.54,0.20),"secano":Color(0.87,0.60,0.24,0.19)}
func dentro(_p:Vector2)->bool:return true

func suelo(ci:CanvasItem,m,c:Vector2i,tiempo:float)->void:
	mundo_actual=m
	base.cargar();base.suelo(ci,m,c,tiempo)
	var p:=Vector2(c)*16
	var t:int=m.tipo(c)
	var bioma:String=m.bioma(c)
	var h:=posmod(c.x*73+c.y*127,101)
	if t==Mundo.T.PASTO:
		var mezcla:=1.0 if Mundo.es_valle(c) else clampf(float(Mundo.Terreno.distancia_valle(c))/12.0,0,1)
		var tinte:Color=VELADURAS.get(bioma,VELADURAS.valle)
		tinte.a*=mezcla
		ci.draw_rect(Rect2(p,Vector2(16,16)),tinte)
		if Mundo.CANTERA.has_point(c):ci.draw_rect(Rect2(p,Vector2(16,16)),Color(0.68,0.56,0.37,0.32))
		if m.objeto_presente(c)=="" and not Mundo.CASA.has_point(c):
			if bioma in ["valle","pradera"] and h<12 and not Mundo.CANTERA.has_point(c):
				for q in [Vector2(3,6),Vector2(10,10),Vector2(6,13)]:_flor(ci,p+q,Color("c7a4e9") if bioma=="pradera" and h%2==0 else Color("fff2ba"))
			elif bioma=="bosque" and h<16:
				ci.draw_rect(Rect2(p+Vector2(4,7),Vector2(3,1)),Color("cd9b47"))
				ci.draw_rect(Rect2(p+Vector2(9,11),Vector2(2,1)),Color("8bac50"))
			elif bioma=="secano" and h<16:
				ci.draw_line(p+Vector2(7,13),p+Vector2(6,7),Color("a37b35"),1)
				ci.draw_line(p+Vector2(8,13),p+Vector2(10,8),Color("f1ce70"),1)
			elif bioma=="sierra" and h<10:
				ci.draw_rect(Rect2(p+Vector2(5,10),Vector2(3,1)),Color("99b5ba"))
				ci.draw_rect(Rect2(p+Vector2(9,5),Vector2(2,1)),Color("5f727d"))
			# Juncos en tierra firme, no nuevos obstáculos dentro del agua.
			var orilla:=false
			for dir in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
				if m.tipo(c+dir)==Mundo.T.AGUA:orilla=true
			if orilla and h<55:
				for x in [4,7,10]:
					ci.draw_line(p+Vector2(x,14),p+Vector2(x-1,5+posmod(x,3)),Color("326a48"),1)
					ci.draw_rect(Rect2(p+Vector2(x-1,4+posmod(x,3)),Vector2(1,3)),Color("b6924e"))
	elif t==Mundo.T.AGUA:
		# Conserva animación y conexiones; sustituye el tinte lodoso del interior.
		var conexion:=mascara(m,c,t)
		var datos:Array=mapeo.water[str(conexion)]
		var cuadro:=int(tiempo/0.15)%4
		ci.draw_texture_rect_region(tex("E04_water_47_anim.png"),Rect2(p,Vector2(16,16)),Rect2(int(datos[0])*16+cuadro*128,int(datos[1])*16,16,16),Color(0.65,1.08,1.18))
		if h<15 and conexion==255:
			var fase:=int(tiempo*2.0)%3
			ci.draw_rect(Rect2(p+Vector2(4+fase,8),Vector2(3,1)),Color(0.66,0.93,0.96,0.60))
	elif t in [Mundo.T.RUINA,Mundo.T.MURO_RUINA]:
		ci.draw_rect(Rect2(p,Vector2(16,16)),Color(0.20,0.40,0.36,0.12))
		if h<30:
			ci.draw_rect(Rect2(p+Vector2(2,13),Vector2(6,1)),Color("76934f"))
			ci.draw_rect(Rect2(p+Vector2(3,11),Vector2(2,2)),Color("93ac62"))
	if c.y==Mundo.CASA.end.y and c.x>=Mundo.CASA.position.x and c.x<Mundo.CASA.end.x:
		ci.draw_rect(Rect2(p,Vector2(16,4)),Color(0.07,0.19,0.12,0.20))
	var id:String=m.por_celda.get(c,"")
	if id!="" and not m.estado.rotos.has(id):_sombra_suelo(ci,p+Vector2(8,15),24 if m.objetos[id].t=="arbol" else 14)

func _flor(ci:CanvasItem,p:Vector2,color:Color)->void:
	ci.draw_line(p,p+Vector2(0,3),Color("44773c"),1)
	ci.draw_rect(Rect2(p-Vector2(1,0),Vector2(3,1)),color)
	ci.draw_rect(Rect2(p-Vector2(0,1),Vector2(1,3)),color)
	ci.draw_rect(Rect2(p,Vector2.ONE),Color("edbd3b"))

func color_objeto(bioma:String,tipo:String)->Color:
	if bioma=="secano" and tipo in ["arbol","arbusto"]:return Color(1.12,1.01,0.70)
	if bioma=="bosque" and tipo in ["arbol","arbusto"]:return Color(0.94,1.05,0.96)
	if bioma=="sierra" and tipo=="roca":return Color(0.93,1.02,1.11)
	return Color.WHITE

func natural(ci: CanvasItem,tipo:String,c:Vector2i,agotado:bool,jugador:Vector2,accion:Rect2=Rect2()) -> void:
	if agotado:
		super.natural(ci,tipo,c,agotado,jugador);return
	var nombre: String = "tree_"+ARBOLES[posmod(c.x*7+c.y*3,3)] if tipo=="arbol" else "bush_berries" if tipo=="arbusto" else "rock" if tipo in ["roca","arcilla"] else "ore_copper"
	var clave := "E04_"+nombre+("_64" if tipo=="arbol" else "")
	var d: Dictionary=objetos.get(clave,{})
	if d.is_empty():super.natural(ci,tipo,c,agotado,jugador);return
	var pies:=Vector2(c)*16+Vector2(8,16)
	var bbox: Array=d.bbox
	var r:=Rect2((pies-Vector2(d.pivote[0],d.pivote[1])+Vector2(bbox[0],bbox[1])).round(),Vector2(bbox[2]-bbox[0],bbox[3]-bbox[1]))
	var tint: Color=TINTE_MENA.get(tipo,Color.WHITE)*color_objeto(mundo_actual.bioma(c) if mundo_actual!=null else "valle",tipo)
	# Si la copa tapa al viajero, se conserva el tronco y se atenúa solo el follaje.
	if tipo=="arbol" and ((r.has_point(jugador-Vector2(0,14)) and pies.y>=jugador.y) or (accion.has_area() and r.intersects(accion) and pies.y>=jugador.y)):
		var region: Rect2=regiones[nombre]
		var corte:=0.78
		ci.draw_texture_rect_region(atlas,Rect2(r.position,Vector2(r.size.x,r.size.y*corte)),Rect2(region.position,Vector2(region.size.x,region.size.y*corte)),Color(1,1,1,0.40))
		ci.draw_texture_rect_region(atlas,Rect2(r.position+Vector2(0,r.size.y*corte),Vector2(r.size.x,r.size.y*(1-corte))),Rect2(region.position+Vector2(0,region.size.y*corte),Vector2(region.size.x,region.size.y*(1-corte))))
	elif tipo=="arbusto" and accion.has_area() and r.intersects(accion) and pies.y>=jugador.y:
		# Misma política de follaje: solo durante un golpe real y cerca del útil.
		_original(ci,nombre,r,tint*Color(1,1,1,0.40))
	else:_original(ci,nombre,r,tint)

var base=preload("res://scripts/mundo_arte.gd").new()
var atlas: Texture2D
var regiones: Dictionary = {}

func _init() -> void:
	var im := ImagenUtil.imagen("res://arte/mundo/vivo/objetos_originales.png")
	atlas = ImageTexture.create_from_image(im)
	var cfg: Array = JSON.parse_string(FileAccess.get_file_as_string("res://arte/mundo/vivo/atlas.json"))
	for i in cfg[0].ids.size():
		var v: Array = cfg[0].rects[i]
		var rr := Rect2i(v[0], v[1], v[2], v[3])
		var minimo := rr.end
		var maximo := rr.position
		for y in range(rr.position.y,rr.end.y):
			for x in range(rr.position.x,rr.end.x):
				if im.get_pixel(x,y).a < 0.35: continue
				minimo = minimo.min(Vector2i(x,y));maximo = maximo.max(Vector2i(x+1,y+1))
		var usado := Rect2i(minimo-rr.position,maximo-minimo)
		regiones[cfg[0].ids[i]] = Rect2(usado.position + rr.position, usado.size)

func _sombra_suelo(ci: CanvasItem, p: Vector2, ancho: float) -> void:
	ci.draw_rect(Rect2((p+Vector2(-ancho*0.45,0)).round(),Vector2(ancho,3)),Color(0.12,0.20,0.12,0.13))
	ci.draw_rect(Rect2((p+Vector2(-ancho*0.32,-2)).round(),Vector2(ancho*0.72,5)),Color(0.12,0.20,0.12,0.14))

func _original(ci: CanvasItem, nombre: String, r: Rect2, tinte: Color=Color.WHITE) -> void:
	ci.draw_texture_rect_region(atlas,r,regiones[nombre],tinte)

func prop(ci:CanvasItem,nombre:String,pies:Vector2,tinte:Color=Color.WHITE)->void:
	if not dentro(pies) or not regiones.has(nombre):super.prop(ci,nombre,pies,tinte);return
	var d:Dictionary=objetos.get(nombre,{})
	if d.is_empty():super.prop(ci,nombre,pies,tinte);return
	var b:Array=d.bbox
	_original(ci,nombre,Rect2((pies-Vector2(d.pivote[0],d.pivote[1])+Vector2(b[0],b[1])).round(),Vector2(b[2]-b[0],b[3]-b[1])),tinte)

## Recorte del mismo atlas: cobija y piecero delante del durmiente; sin cama nueva.
func cobija_cama(ci:CanvasItem,pies:Vector2,huesped:bool=false)->void:
	var region:Rect2=regiones.bed
	var fraccion:=11.0/31.0
	var destino:=Rect2((pies+Vector2(-12,-20)).round(),Vector2(25,20))
	var fuente:=Rect2(region.position+Vector2(0,region.size.y*fraccion),Vector2(region.size.x,region.size.y*(1.0-fraccion)))
	ci.draw_texture_rect_region(atlas,destino,fuente,Color(0.6,0.85,1.3) if huesped else Color.WHITE)
