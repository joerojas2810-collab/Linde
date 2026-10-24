extends SceneTree
const P = preload("res://fuentes/params.gd")
func _initialize() -> void:
	var presets: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://presets.json"))
	for id in presets:
		var look: Array = presets[id].look
		var tintes := {"piel": P.PIEL[int(look[0])], "pelo": P.PELO[int(look[1])], "tunica": P.ROPA[int(look[2])], "pantalon": P.PANTALON}
		var atlas := Image.create(128,128,false,Image.FORMAT_RGBA8)
		atlas.fill(Color.TRANSPARENT)
		for capa in ["cuerpo","piel","botas","pantalon","tunica","cinturon","pelo"]:
			var source := Image.load_from_file("res://capas/"+capa+".png")
			var layer: Image = tenir(source,tintes[capa]) if tintes.has(capa) else source
			atlas.blend_rect(layer,Rect2i(0,0,128,128),Vector2i.ZERO)
		atlas.save_png("res://previews/"+id+"_compuesto.png")
		var bg := Image.create(128,128,false,Image.FORMAT_RGBA8)
		bg.fill(Color("70964f"))
		bg.blend_rect(atlas,Rect2i(0,0,128,128),Vector2i.ZERO)
		bg.resize(384,384,Image.INTERPOLATE_NEAREST)
		bg.save_png("res://previews/"+id+"_contacto_x3.png")
		print(id,": compuesto con capas compartidas y tenir original")
	quit()

static func tenir(img: Image, objetivo: Color, media: float = -1.0) -> Image:
	var out: Image = img.duplicate()
	if media <= 0.0: media = valor_medio(img)
	if media <= 0.0: return out
	for y in out.get_height():
		for x in out.get_width():
			var px := out.get_pixel(x, y)
			if px.a8 > 0: out.set_pixel(x, y, Color.from_hsv(objetivo.h, objetivo.s, clampf(objetivo.v * px.v / media, 0.0, 1.0), px.a))
	return out

static func valor_medio(img: Image) -> float:
	var suma := 0.0
	var n := 0
	for y in img.get_height():
		for x in img.get_width():
			var px := img.get_pixel(x, y)
			if px.a8 > 0:
				suma += px.v
				n += 1
	return suma / n if n > 0 else 0.0

