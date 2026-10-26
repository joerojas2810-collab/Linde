extends RefCounted
## Solo presentación: lee estados existentes; no cambia profesiones, vínculos o rutinas.
var activo:=true
var cache:Dictionary={}
func tex(id:String)->Texture2D:
	if not cache.has(id):
		var t:Texture2D=load("res://arte/pendientes_v1/"+id+".png")
		var atlas:=AtlasTexture.new();atlas.atlas=t;atlas.region=Rect2(t.get_image().get_used_rect());cache[id]=atlas
	return cache[id]
func objeto(ci:CanvasItem,id:String,r:Rect2)->void:ci.draw_texture_rect(tex(id),r,false)
func oficio(ci:CanvasItem,p:Vector2,dir:Vector2i,rol:String)->void:
	if not activo:return
	match rol:
		"agricultor":
			objeto(ci,"sombrero",Rect2(p-Vector2(13,39),Vector2(26,18)))
			ci.draw_line(p+Vector2(9,-2),p+Vector2(12,-24),Color("80522f"),1)
			ci.draw_rect(Rect2(p+Vector2(8,-24),Vector2(7,2)),Color("a8b2bb"))
		"explorador":objeto(ci,"mochila",Rect2(p+Vector2(-7,-22),Vector2(14,18)) if dir==Vector2i.UP else Rect2(p+Vector2(5,-17),Vector2(8,12)))
		"mercader":objeto(ci,"bolsa",Rect2(p+Vector2(-10,-17),Vector2(11,13)))
		"guardia":
			if dir==Vector2i.DOWN:objeto(ci,"casco_guardia",Rect2(p+Vector2(-9,-39),Vector2(18,23)))
			else:
				var vista:int={Vector2i.RIGHT:1,Vector2i.UP:2,Vector2i.LEFT:3}.get(dir,0)
				ci.draw_texture_rect(tex("pesada_casco_"+str(vista)),Rect2(p-Vector2(16,32),Vector2(32,32)),false)
func permanencia(ci:CanvasItem,p:Vector2,estado:String)->void:
	if not activo:return
	var col:Color={"visitante":Color("81c2e7"),"aspirante":Color("e9ba4d"),"residente":Color("81c77a"),"ausente":Color("a0a2aa")}.get(estado,Color("81c77a"))
	var q:=p+Vector2(11,-32)
	ci.draw_rect(Rect2(q-Vector2(1,1),Vector2(7,7)),Color("25342c"))
	if estado=="aspirante":ci.draw_colored_polygon(PackedVector2Array([q+Vector2(2,-1),q+Vector2(5,2),q+Vector2(2,5),q+Vector2(-1,2)]),col)
	elif estado=="residente":
		ci.draw_rect(Rect2(q,Vector2(5,5)),col);ci.draw_rect(Rect2(q+Vector2(2,3),Vector2(1,2)),Color("25342c"))
	else:ci.draw_circle(q+Vector2(2,2),2,col,estado!="ausente")
func ocupacion(ci:CanvasItem,p:Vector2,act:String,t:float)->void:
	if not activo or not act in ["vigilar","explorar","comerciar"]:return
	var q:=p+Vector2(-4,-56-roundf(sin(t*3)*0.5))
	ci.draw_rect(Rect2(q-Vector2(2,2),Vector2(12,12)),Color(0.05,0.15,0.12,0.9))
	if act=="vigilar":
		ci.draw_colored_polygon(PackedVector2Array([q,q+Vector2(8,0),q+Vector2(7,5),q+Vector2(4,8),q+Vector2(1,5)]),Color("97bad1"))
	elif act=="explorar":
		ci.draw_line(q+Vector2(0,7),q+Vector2(7,0),Color("eed89b"),1);ci.draw_line(q+Vector2(3,0),q+Vector2(7,0),Color("eed89b"),1)
	else:
		ci.draw_circle(q+Vector2(4,4),4,Color("e8bc55"));ci.draw_line(q+Vector2(4,1),q+Vector2(4,7),Color("916432"),1)
func petate(ci:CanvasItem,p:Vector2)->void:
	if activo:objeto(ci,"petate",Rect2(p-Vector2(17,14),Vector2(34,19)))
