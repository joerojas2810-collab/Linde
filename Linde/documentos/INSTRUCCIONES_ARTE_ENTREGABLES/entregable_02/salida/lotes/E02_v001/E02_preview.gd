extends Node2D
## Interactive isolated E02 scene, with retained real-render evidence and tests.
const Composer = preload("res://scripts/E02_compositor.gd")
const STATES = ["herramienta","dano","caida","dormir"]
const ARQS = ["ligera","media","pesada"]
const PALS = ["pal_vigia","pal_zarzal","pal_albor"]
const ROWS = ["frente","derecha","espalda","izquierda"]
var composer
var state_i := 0
var arq_i := 0
var frame := 0
var elapsed := 0.0
var paused := false
var variant := "baseline"
var automatic := false
var failures: Array = []
var checks := 0

func check(condition: bool,label: String) -> void:
	checks+=1
	if not condition: failures.append(label)

func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	composer=Composer.new()
	check(composer.errors.is_empty(),"carga de hojas")
	for state in STATES:
		var n: int = composer.manifests[state].cuadros_runtime_a_fuente.size()
		for arq in ARQS:
			for pal in PALS:
				for r in range(4):
					for logical in range(n):
						var cmd: Array = composer.commands(state,r,logical,arq,"baseline",pal)
						var names: Array = cmd.map(func(c):return c[0])
						check(not cmd.is_empty(),"composición vacía")
						check(names.find("guantes_lejana")<names.find("torso"),"mano lejana tapa torso")
						check(names.find("guantes_cercana")>names.find("torso"),"mano cercana queda detrás")
						check(names.find("b_pelo")<names.find("casco"),"pelo sobre casco")
						check(names.has("b_cinturon"),"falta cinturón")
						check(not names.has("b_tunica") and not names.has("b_botas") and not names.has("b_pantalon"),"ropa no oculta")
						check(names.has("hacha")==(state=="herramienta"),"herramienta en estado equivocado")
						check((not names.has("escudo") and not names.has("espada")) if state in ["caida","dormir"] else true,"armas al descansar")
						for c in cmd:
							check(c[2].position==Vector2(int(composer.manifests[state].cuadros_runtime_a_fuente[logical])*48,r*48) and c[3]==Rect2(0,0,48,48),"cuadro/pivote")
						var cache: int = composer.textures.size()
						composer.commands(state,r,logical,arq,"baseline",pal)
						check(composer.textures.size()==cache,"caché crece al repetir")
	for n in range(3):check(composer.manifests.herramienta.cuadros_runtime_a_fuente[n]==[1,2,3][n],"mapping herramienta")
	var f:=FileAccess.open("res://validacion/E02_godot.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"motor":Engine.get_version_info(),"comprobaciones":checks,"fallos":failures,"red_real":false,"tipo":"Compositor prototipo E02, no integrado al juego"},"  "))
	f.close()
	print("E02 QA: ",checks," comprobaciones; ",failures.size()," fallos")
	if not failures.is_empty():get_tree().quit(1);return
	if "--capturas" in OS.get_cmdline_user_args():
		automatic=true
		for s in range(4):
			for a in range(3):
				state_i=s;arq_i=a
				queue_redraw()
				for i in range(60):await get_tree().process_frame
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png("res://validacion/E02_godot_%s_%s.png" % [STATES[s],ARQS[a]])
		get_tree().quit()

func _process(dt: float) -> void:
	if composer == null: return
	if not paused and not automatic:
		elapsed+=dt
		var seconds := .1 if state_i==0 else .3 if state_i==1 else .45
		if elapsed>=seconds:
			elapsed=0;frame=(frame+1)%composer.manifests[STATES[state_i]].cuadros_runtime_a_fuente.size()
	queue_redraw()

func _unhandled_key_input(e: InputEvent) -> void:
	if not e.is_pressed() or e.is_echo():return
	if e.keycode==KEY_SPACE:paused=not paused
	elif e.keycode in [KEY_1,KEY_2,KEY_3,KEY_4]:state_i=e.keycode-KEY_1;frame=0
	elif e.keycode==KEY_TAB:arq_i=(arq_i+1)%3
	elif e.keycode==KEY_RIGHT:paused=true;frame=(frame+1)%composer.manifests[STATES[state_i]].cuadros_runtime_a_fuente.size()
	elif e.keycode==KEY_ESCAPE:get_tree().quit()

func _draw() -> void:
	if composer==null:return
	var state: String=STATES[state_i];var arq: String=ARQS[arq_i]
	draw_string(ThemeDB.fallback_font,Vector2(24,32),"LINDE E02 · "+state+" · "+arq,HORIZONTAL_ALIGNMENT_LEFT,-1,24)
	draw_string(ThemeDB.fallback_font,Vector2(24,62),"BASE + HERRAMIENTA     /     EQUIPO COMPUESTO     ·     zoom 3 nearest",HORIZONTAL_ALIGNMENT_LEFT,-1,17)
	var n: int = composer.manifests[state].cuadros_runtime_a_fuente.size()
	for r in range(4):
		var y:=90+r*164
		draw_string(ThemeDB.fallback_font,Vector2(24,y+16),ROWS[r],HORIZONTAL_ALIGNMENT_LEFT,-1,15)
		for logical in range(n):
			if not automatic and logical != frame: continue
			for side in range(2):
				var offset:=Vector2(22+side*624+(logical if automatic else 1)*144,y+20)
				draw_set_transform(offset,0,Vector2(3,3))
				for cmd in composer.commands(state,r,logical,arq,"base" if side==0 else variant):
					draw_texture_rect_region(cmd[1],cmd[3],cmd[2])
				draw_set_transform(Vector2.ZERO)
	# Live mode animates each direction; capture mode shows all logical frames.
	draw_string(ThemeDB.fallback_font,Vector2(24,785),"1 herramienta · 2 daño · 3 caída · 4 dormir · Tab equipo · Espacio pausa · → cuadro · Esc salir | Prototipo, sin eventos nuevos",HORIZONTAL_ALIGNMENT_LEFT,-1,15)
