class_name ImagenUtil
# Carga de PNG que funciona en el editor y en el build exportado (donde res://*.png solo existe como textura importada).

static func existe(ruta: String) -> bool:
	return ResourceLoader.exists(ruta) or FileAccess.file_exists(ruta)

## Imagen sin pérdida de la ruta, o null si no existe / no es imagen.
static func imagen(ruta: String) -> Image:
	if ResourceLoader.exists(ruta):
		var t := load(ruta) as Texture2D
		if t != null:
			var im: Image = t.get_image()
			if im != null: return im
	if FileAccess.file_exists(ruta): return Image.load_from_file(ruta)
	return null
