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
			objeto(ci,"azada",Rect2(p+Vector2(8,-24),Vector2(8,24)))
		"explorador":objeto(ci,"mochila",Rect2(p+Vector2(-7,-22),Vector2(14,18)) if dir==Vector2i.UP else Rect2(p+Vector2(5,-17),Vector2(8,12)))
		"mercader":objeto(ci,"bolsa",Rect2(p+Vector2(-10,-17),Vector2(11,13)))
		"guardia":
			if dir==Vector2i.DOWN:objeto(ci,"casco_guardia",Rect2(p+Vector2(-9,-39),Vector2(18,23)))
			else:
				var vista:int={Vector2i.RIGHT:1,Vector2i.UP:2,Vector2i.LEFT:3}.get(dir,0)
				ci.draw_texture_rect(tex("pesada_casco_"+str(vista)),Rect2(p-Vector2(16,32),Vector2(32,32)),false)
func permanencia(ci:CanvasItem,p:Vector2,estado:String)->void:
	if not activo:return
	objeto(ci,"icono_"+estado,Rect2(p+Vector2(10,-33),Vector2(7,7)))

func ocupacion(ci:CanvasItem,p:Vector2,act:String,t:float)->void:
	if not activo or not act in ["vigilar","explorar","comerciar"]:return
	var q:=p+Vector2(-4,-56-roundf(sin(t*3)*0.5))
	objeto(ci,"icono_"+act,Rect2(q-Vector2(2,2),Vector2(12,12)))

func petate(ci:CanvasItem,p:Vector2)->void:
	if activo:objeto(ci,"petate",Rect2(p-Vector2(17,14),Vector2(34,19)))
