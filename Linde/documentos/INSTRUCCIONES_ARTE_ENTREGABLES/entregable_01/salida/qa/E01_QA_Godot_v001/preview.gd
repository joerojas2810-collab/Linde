extends Node2D
## Isolated QA: the production compositor is copied byte for byte, never changed.
const Arte = preload("res://scripts/arte_equipo.gd")
const Val = preload("res://scripts/validar_hoja.gd")
const ARQS = ["ligera", "media", "pesada"]
const PALS = ["pal_vigia", "pal_zarzal", "pal_albor"]
const DIRS = [Vector2i.DOWN, Vector2i.RIGHT, Vector2i.UP, Vector2i.LEFT]
const DIRECTIONS = ["frente", "derecha", "espalda", "izquierda"]
const SLOTS = ["casco", "torso", "pantalones", "botas", "guantes", "escudo", "espada"]
var before
var after
var paletas: Dictionary
var arq := "ligera"
var pal := "pal_vigia"
var failures: Array = []
var checks := 0
var show_trail := true
var trail: ImageTexture

func check(ok: bool, msg: String) -> void:
	checks += 1
	if not ok:
		failures.append(msg)
		push_error(msg)

func equipment(a: String, p: String, slots: Array = SLOTS) -> Array:
	var out: Array = []
	for slot in slots:
		var chosen: String = "pal_espada_hierro" if slot == "espada" else ("pal_escudo_madera" if slot == "escudo" else p)
		out.append({"ranura":slot,"arquetipo":a,"familia":chosen,"variante":"sin_piedra","paleta":paletas[chosen],"delta":{}})
	return out

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	paletas = JSON.parse_string(FileAccess.get_file_as_string("res://paletas.json")).paletas
	before = Arte.new("res://original")
	after = Arte.new("res://candidato")
	trail = ImageTexture.create_from_image(ImagenUtil.imagen("res://candidato/ataque/E01_estela_ataque.png"))
	check(before.disponible() and before.ataque_disponible(), "original no carga")
	check(after.disponible() and after.ataque_disponible(), "candidato no carga")
	for a in ARQS:
		for p in PALS:
			for look in [[0,0,0],[1,1,1],[2,3,2]]:
				for r in range(4):
					for c in range(4):
						var commands: Array = after.comandos(Vector2(24,48),DIRS[r],c,equipment(a,p),look,false,"ataque")
						var names: Array = commands.map(func(item): return item[0])
						check(commands.size() > 0,"comandos vacíos")
						for slot in SLOTS:
							check(slot in names,"falta %s/%s/%d/%d" % [a,slot,r,c])
						for hidden in ["b_tunica","b_pantalon","b_botas"]:
							check(not hidden in names,"base no oculta: "+hidden)
						check(names.find("espada") > names.find("torso"),"espada detrás de torso")
						for cmd in commands:
							check(cmd[2] == Rect2(c*48,r*48,48,48) and cmd[3] == Rect2(0,0,48,48),"celda o pivote incorrecto")
						var cached: int = after.recoloreados
						after.comandos(Vector2(24,48),DIRS[r],c,equipment(a,p),look,false,"ataque")
						check(after.recoloreados == cached,"caché no reutilizada")
	# Empty slots preserve the base; each single slot hides only its corresponding clothing.
	for r in range(4):
		for c in range(4):
			var bare: Array = after.comandos(Vector2(24,48),DIRS[r],c,[],[0,0,0],false,"ataque")
			var bare_names: Array = bare.map(func(item): return item[0])
			for layer in ["b_tunica","b_pantalon","b_botas"]:
				check(layer in bare_names,"base sin equipo falta: "+layer)
			for slot in SLOTS:
				var solo: Array = after.comandos(Vector2(24,48),DIRS[r],c,equipment("media","pal_vigia",[slot]),[0,0,0],false,"ataque")
				var names: Array = solo.map(func(item):return item[0])
				check(slot in names,"ranura aislada no aparece: "+slot)
				for equip_slot in Arte.OCULTA:
					check((Arte.OCULTA[equip_slot] in names) == (equip_slot != slot),"ocultación aislada incorrecta")
	# Run the unmodified original structural validator on all 17 candidate sheets.
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://candidato/ataque/manifiesto.json"))
	var validation: Array = []
	for a in manifest.hojas:
		for slot in manifest.hojas[a]:
			var fn: String = manifest.hojas[a][slot].archivo
			var result: Dictionary = Val.validar(ImagenUtil.imagen("res://candidato/ataque/"+fn),48,"indice",ImagenUtil.imagen("res://original/ataque/referencia/ataque.png"))
			check(result.errores.is_empty(),"validador: "+fn+str(result.errores))
			validation.append({"archivo":fn,"errores":result.errores,"avisos":result.avisos})
	var f := FileAccess.open("res://evidencia/E01_pruebas_godot.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"motor":Engine.get_version_info(),"comprobaciones":checks,"fallos":failures,"hojas":validation,"red_real":false,"nota":"Compositor real copiado, prueba aislada. Estela dibujada solo por el preview."},"  "))
	f.close()
	print("E01 QA: ",checks," comprobaciones; ",failures.size()," fallos")
	if not failures.is_empty():
		get_tree().quit(1)
		return
	# Retained windowed captures after 60 real rendered frames per presentation.
	for a in ARQS:
		for p in PALS:
			arq = a
			pal = p
			queue_redraw()
			for n in range(60): await get_tree().process_frame
			await RenderingServer.frame_post_draw
			var path := "res://evidencia/E01_godot_%s_%s.png" % [arq,pal]
			check(get_viewport().get_texture().get_image().save_png(path) == OK,"captura no guardada")
			print("CAPTURA ",path)
	get_tree().quit(0 if failures.is_empty() else 1)

func _draw() -> void:
	if before == null or after == null: return
	draw_string(ThemeDB.fallback_font,Vector2(26,35),"E01 · compositor real de Godot · "+arq+" / "+pal,HORIZONTAL_ALIGNMENT_LEFT,-1,23)
	draw_string(ThemeDB.fallback_font,Vector2(26,68),"ANTES  |  preparado / anticipación / impacto / recuperación",HORIZONTAL_ALIGNMENT_LEFT,-1,16)
	draw_string(ThemeDB.fallback_font,Vector2(650,68),"CANDIDATO  |  preparado / anticipación / impacto / recuperación",HORIZONTAL_ALIGNMENT_LEFT,-1,16)
	for r in range(4):
		var y := 95+r*165
		draw_string(ThemeDB.fallback_font,Vector2(26,y+14),DIRECTIONS[r],HORIZONTAL_ALIGNMENT_LEFT,-1,14)
		for c in range(4):
			for side in range(2):
				var origin := Vector2(24+side*624+c*144,y+20)
				draw_set_transform(origin,0,Vector2(3,3))
				var artist = before if side == 0 else after
				for cmd in artist.comandos(Vector2(24,48),DIRS[r],c,equipment(arq,pal),[0,0,0],false,"ataque"):
					draw_texture_rect_region(cmd[1],cmd[3],cmd[2])
				if side==1 and show_trail:
					draw_texture_rect_region(trail,Rect2(0,0,48,48),Rect2(c*48,r*48,48,48))
				draw_set_transform(Vector2.ZERO)
	draw_string(ThemeDB.fallback_font,Vector2(26,790),"Prueba aislada · zoom 3 nearest · estela recuperada, capa propuesta · no demuestra red ni integración en mapa",HORIZONTAL_ALIGNMENT_LEFT,-1,15)
