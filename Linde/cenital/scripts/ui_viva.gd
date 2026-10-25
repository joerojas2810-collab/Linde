extends "res://scripts/ui_arte.gd"
const MADERA := Color("50301f")
const ORO := Color("d6a84e")
const SOMBRA := Color("211a16")
const TEAL := Color("12363b")

func _init()->void:
	super._init()
	fuente.variation_opentype={TextServerManager.get_primary_interface().name_to_tag("wght"):600.0}

func marco(ci:CanvasItem,r:Rect2,fondo:Color,oscuro:bool=false)->void:
	var borde:=3.0 if r.size.y<52 else 12.0
	ci.draw_rect(Rect2(r.position+Vector2(4,5),r.size),Color(0.03,0.07,0.06,0.4))
	ci.draw_rect(r,SOMBRA)
	ci.draw_rect(r.grow(-2),Color("9c6032"))
	ci.draw_rect(r.grow(-4),MADERA)
	# Vetas discretas en el marco, siempre alineadas a píxeles.
	if borde>6:
		for y in [5,8]:
			ci.draw_line(r.position+Vector2(12,y),Vector2(r.end.x-12,r.position.y+y),Color("81502e"),1)
			ci.draw_line(Vector2(r.position.x+12,r.end.y-y),r.end-Vector2(12,y),Color("81502e"),1)
		ci.draw_line(r.position+Vector2(6,12),Vector2(r.position.x+6,r.end.y-12),Color("81502e"),1)
	ci.draw_rect(r.grow(-borde),ORO)
	ci.draw_rect(r.grow(-borde-2),Color("291f18"))
	ci.draw_rect(r.grow(-borde-4),fondo)
	ci.draw_line(r.position+Vector2(borde+4,borde+4),Vector2(r.end.x-borde-4,r.position.y+borde+4),Color("edce86"),1)
	for p in [r.position+Vector2(4,4),Vector2(r.end.x-10,r.position.y+4),Vector2(r.position.x+4,r.end.y-10),r.end-Vector2(10,10)]:
		ci.draw_rect(Rect2(p,Vector2(6,6)),ORO)
		ci.draw_rect(Rect2(p+Vector2(1,1),Vector2(2,2)),Color("ffe2a0"))

func panel(ci:CanvasItem,r:Rect2)->void:
	if r.size.x<800:super.panel(ci,r)
	else:marco(ci,r,Color("f4dfad"))
func tooltip(ci:CanvasItem,r:Rect2)->void:marco(ci,r,Color("f6e8bf"))
func boton(ci:CanvasItem,r:Rect2,foco:bool)->void:
	marco(ci,r,Color("225357") if foco else TEAL,true)
func ranura(ci:CanvasItem,r:Rect2,seleccionada:bool)->void:
	ci.draw_rect(r,Color("e7b64e") if seleccionada else Color("786346"))
	ci.draw_rect(r.grow(-2),Color("1d3c3d") if seleccionada else Color("e2c993"))
	ci.draw_line(r.position+Vector2(3,3),Vector2(r.end.x-3,r.position.y+3),Color("ffe7aa"),1)
	ci.draw_line(Vector2(r.position.x+3,r.end.y-3),r.end-Vector2(3,3),Color("a58a5e"),1)
	if seleccionada:ci.draw_rect(r.grow(2),Color("ffd666"),false,2)

# El texto cabe por métricas reales de la fuente, no por un desplazamiento fijo.
func texto_en(ci:CanvasItem,txt:String,r:Rect2,tam:int=16,col:Color=TINTA,centrado:bool=false)->void:
	var t:=tam
	while t>12 and fuente.get_height(t)>r.size.y:t-=1
	var visible:=txt
	if ancho_texto(visible,t)>r.size.x:
		while visible.length()>0 and ancho_texto(visible+"…",t)>r.size.x:visible=visible.left(-1)
		visible+="…"
	var x:=r.position.x+(r.size.x-ancho_texto(visible,t))/2.0 if centrado else r.position.x
	var y:=r.position.y+(r.size.y-fuente.get_height(t))/2.0+fuente.get_ascent(t)
	texto(ci,visible,Vector2(roundf(x),roundf(y)),t,col)

func medidor(ci:CanvasItem,r:Rect2,frac:float,xp:bool=false)->void:
	ci.draw_rect(r,Color("382b20"))
	ci.draw_rect(r.grow(-1),ORO)
	ci.draw_rect(r.grow(-3),Color("182d2c"))
	var interior:=r.grow(-4)
	var ancho:=floorf(interior.size.x*clampf(frac,0,1))
	if ancho>0:
		var lleno:=Rect2(interior.position,Vector2(ancho,interior.size.y))
		ci.draw_rect(lleno,Color("519da9") if xp else Color("ce453c"))
		ci.draw_rect(Rect2(lleno.position,Vector2(ancho,2)),Color("94cfca") if xp else Color("ff9b68"))
