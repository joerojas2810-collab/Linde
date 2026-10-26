extends "res://scripts/hud.gd"
var boton_accion:=Rect2()

func _init()->void:ui=preload("res://scripts/ui_viva.gd").new()

func _draw() -> void:
	var vs := size
	if esc == null: return
	if esc.modo == "menu": return _menu(vs)
	if esc.modo == "creador": return _creador(vs)
	if esc.modo == "unirse" or esc.modo == "conectando": return _unirse(vs)
	if esc.panel=="mapa": return _mapa(vs)
	if esc.panel=="inv":return _inventario(vs)
	if esc.panel=="ficha":return _panel(vs)
	var j = esc.j
	var h: float = j.hora_dia()
	var st: Dictionary = j.stats()
	# --- estado del jugador ---
	var p:=Rect2(16,16,284,142 if j.puntos_libres()<=0 else 168)
	ui.panel(self,p)
	ui.texto_en(self,"%s · Nivel %d"%[j.jug().nombre,j.nivel()],Rect2(36,32,244,28),19)
	ui.medidor(self,Rect2(36,70,148,20),float(j.jug().hp)/st.hp)
	ui.texto_en(self,"%d / %d"%[j.jug().hp,st.hp],Rect2(196,68,84,24),16)
	var sig:=C.umbral_xp(j.nivel()+1) if j.nivel()<C.NIVEL_MAX else C.umbral_xp(j.nivel())
	var ant:=C.umbral_xp(j.nivel())
	ui.medidor(self,Rect2(36,106,148,16),float(j.jug().xp-ant)/maxf(1,sig-ant),true)
	ui.texto_en(self,"XP %d / %d"%[j.jug().xp-ant,maxi(1,sig-ant)],Rect2(196,100,84,28),14)
	if j.puntos_libres()>0:ui.texto_en(self,"%d punto(s) disponibles · K"%j.puntos_libres(),Rect2(36,136,244,26),14)
	# --- día, red y misiones ---
	_tracker(vs, j, h)
	# --- avisos, ayuda y pista ---
	var msgs: Array = []
	for aviso in j.msgs.slice(-4):
		var linea := ""
		for palabra in str(aviso).split(" "):
			if ui.ancho_texto(linea + " " + palabra,16)>480.0:
				msgs.append(linea)
				linea=palabra
			else: linea+=(" " if linea!="" else "")+palabra
		if linea!="": msgs.append(linea)
	msgs=msgs.slice(-8)
	if not msgs.is_empty() and esc.panel=="" and not esc.ayuda_visible:
		var alto := 20.0 + msgs.size() * 22.0
		ui.panel(self, Rect2(16, 660 - alto - 8, 520, alto))
		for i in msgs.size(): _t(str(msgs[i]), Vector2(32, 660 - alto + 4 + i * 22.0), 16)
	ui.panel(self, Rect2(vs.x / 2 - 310, 668, 620, 40))
	ui.texto_en(self,"I  Mochila    M  Mapa    E  Interactuar    Espacio  Actuar    H  Ayuda",Rect2(vs.x/2-288,676,576,24),16,UiArte.TINTA,true)
	if esc.ayuda_visible and esc.panel=="":_ayuda(vs,j)
	if esc.debug: _t("anim: %s #%d" % [esc._anim.estado, esc._anim.cuadro], Vector2(vs.x - 200, 700), 16, UiArte.FOCO)
	if esc.pista != "" and esc.panel=="" and not esc.ayuda_visible:
		var w: float = ui.ancho_texto(esc.pista, 16) + 32.0
		ui.tooltip(self, Rect2(vs.x / 2 - w / 2, 610, w, 40))
		_t(esc.pista, Vector2(vs.x / 2 - w / 2 + 16, 620), 16)
	if esc.build:
		var id: String = C.ORDEN_CONSTR[esc.pieza_i]
		ui.panel(self, Rect2(380, 16, 540, 72))
		_t("CONSTRUIR: %s · coste %s" % [C.CONSTR[id].n, J_txt(C.CONSTR[id].coste)], Vector2(396, 26), 16)
		_t("[Q/E] cambiar · [Espacio] colocar · [X] retirar · [B] salir", Vector2(396, 52), 16)
	if esc.panel != "": _panel(vs)


## Controles reales (teclas de escena.gd); [clave, descripción] y los títulos de grupo llevan clave vacía.
func _ayuda(vs:Vector2,j)->void:
	var valle:String="Sociedad del Valle: habitantes, grupos y acuerdos" if j.autonomia.activa() else "Misiones"
	var filas:Array=[
		["","MOVERSE Y ACTUAR"],
		["WASD / flechas","Moverse"],
		["E","Interactuar: hablar, cofre, cama, cultivo, mesa u horno"],
		["Espacio","Atacar o golpear árbol, roca o veta (mantener pulsado)"],
		["V","Ficha del habitante cercano"],
		["Esc","Menú de pausa · F5 guardar · H cerrar esta ayuda"],
		["","PANELES Y MODOS"],
		["I","Mochila y equipo"],
		["C","Fabricar (necesita mesa u horno a 2 celdas o menos)"],
		["F","Forja: mejorar piezas de set"],
		["G","Taller: materiales, planos y saberes"],
		["K","Habilidades"],
		["M","Mapa personal: flechas desplazan, +/− zoom, Inicio centra"],
		["J",valle],
		["B","Construir: Q/E cambia pieza · Espacio coloca · X retira · B sale"],
		["","DENTRO DE UN PANEL"],
		["↑ ↓  ·  rueda","Elegir o desplazar  (Av Pág / Re Pág: página)"],
		["Enter / E  ·  clic","Activar el botón elegido. Lo que no es botón es solo información"],
		["Esc  ·  ×","Cerrar"]]
	var r:=Rect2(vs.x/2-380,56,760,28+filas.size()*28+40)
	ui.panel(self,r)
	ui.texto_en(self,"CONTROLES",Rect2(r.position+Vector2(28,14),Vector2(300,28)),22)
	var y:=r.position.y+54
	for f in filas:
		if f[0]=="":
			ui.texto_en(self,str(f[1]),Rect2(r.position.x+28,y,r.size.x-56,24),15,Color("12363b"))
		else:
			ui.texto_en(self,str(f[0]),Rect2(r.position.x+40,y,170,24),16,UiArte.TINTA)
			ui.texto_en(self,str(f[1]),Rect2(r.position.x+216,y,r.size.x-244,24),16,UiArte.TINTA)
		y+=28

func _icono_item(clave:String,ranura:String="")->String:
	var info:Dictionary=Eq.info(clave) if clave!="" else {}
	var slot:String=ranura if ranura!="" else str(info.get("equipo",""))
	if slot in ["arma","escudo"]:
		var indice:=0
		if clave!="":
			for e in Eq.visible({slot:clave}):indice=maxi(0,["ligera","media","pesada"].find(e.get("arquetipo","ligera")))
		return "../pendientes_v1/"+("espada" if slot=="arma" else "escudo")+"_"+str(indice)+".png"
	return ui.ruta_icono(clave,slot)

func _celda(r:Rect2,i:int,clave:String,ranura:String="",cantidad:int=0)->void:
	ui.ranura(self,r,i==esc.sel)
	var ic:=_icono_item(clave,ranura)
	if ic!="":
		var tex:Texture2D=ui.tex(ic)
		if tex!=null:draw_texture_rect(tex,r.grow(-8),false,Color(1,1,1,0.22 if clave=="" else 1.0))
	elif clave!="":
		var info:Dictionary=Eq.info(clave)
		draw_rect(Rect2(r.position+Vector2(17,17),r.size-Vector2(34,34)),Color(info.get("c","#7a8d63")))
		ui.texto_centrado(self,str(info.n).left(2).to_upper(),r.get_center().x,r.get_center().y+5,14)
	if cantidad>1:
		var txt:=str(cantidad)
		draw_string_outline(ui.fuente,r.end-Vector2(8+ui.ancho_texto(txt,16),8),txt,HORIZONTAL_ALIGNMENT_LEFT,-1,16,4,Color("132b2a"))
		ui.texto(self,txt,r.end-Vector2(8+ui.ancho_texto(txt,16),8),16,Color("fff3cf"))
	if i>=0:objetivos.append({"r":r,"i":i})

func _inventario(vs:Vector2)->void:
	objetivos.clear()
	var r:=Rect2(vs.x/2-496,112,992,536)
	ui.panel(self,r)
	var cab:=Rect2(vs.x/2-220,92,440,52)
	ui.marco(self,cab,Color("12363b"))
	var titulo_fuente:Font=ui.fuente_dialogo
	var ancho_titulo:float=titulo_fuente.get_string_size("MOCHILA Y EQUIPO",HORIZONTAL_ALIGNMENT_LEFT,-1,24).x
	draw_string(titulo_fuente,Vector2(vs.x/2-ancho_titulo/2,128),"MOCHILA Y EQUIPO",HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("fff0c7"))
	boton_cerrar=Rect2(r.end.x-44,r.position.y+12,30,30)
	draw_rect(boton_cerrar,Color("9a3e27"))
	draw_rect(boton_cerrar,Color("e2b75a"),false,2)
	ui.texto_centrado(self,"×",boton_cerrar.get_center().x,boton_cerrar.position.y+22,22,Color("fff0c7"))
	var izq:=Rect2(r.position+Vector2(24,50),Vector2(388,332))
	ui.marco(self,izq,Color("12363b"))
	# Fondo geométrico discreto; el personaje es el dibujante real del juego.
	draw_circle(izq.get_center(),96,Color("1c4445"),false,2)
	draw_circle(izq.get_center(),82,Color("1c4445"),false,1)
	ui.texto_en(self,esc.j.jug().nombre,Rect2(izq.position+Vector2(26,20),Vector2(336,28)),18,Color("f7e2aa"),true)
	var equipo:Dictionary=esc.j.jug().equipo
	var ys:=[58,126,194,262]
	for k in C.RANURAS.size():
		var lado:=0 if k<4 else 1
		var fila:=k if k<4 else k-4
		var pos:=izq.position+Vector2(16 if lado==0 else 312,ys[fila])
		_celda(Rect2(pos,Vector2(60,60)),3+k,str(equipo.get(C.RANURAS[k],"")),C.RANURAS[k])
	var centro:=izq.position+Vector2(194,276)
	draw_set_transform(centro,0,Vector2(6,6))
	esc.arte_eq.dibujar(self,Vector2.ZERO,Vector2i.DOWN,0,Eq.visible(equipo),esc.j.jug().look,"reposo")
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
	var st:Dictionary=esc.j.stats()
	var stats:=["Vida  %d / %d"%[esc.j.jug().hp,st.hp],"Daño  %d"%st.dmg,"Defensa  %d"%st.def,"Nivel  %d"%esc.j.nivel()]
	for k in 4:
		var box:=Rect2(izq.position+Vector2((k%2)*198,348+(k/2)*40),Vector2(190,34))
		ui.ranura(self,box,false)
		ui.texto_centrado(self,stats[k],box.get_center().x,box.position.y+23,17)
	var ks:Array=esc.j.jug().inv.keys();ks.sort()
	var primero:=4+C.RANURAS.size()
	var pagina:=maxi(0,(esc.sel-primero)/20)
	var zona:=r.position+Vector2(472,72)
	_t("MOCHILA   %d / %d espacios"%[preload("res://scripts/inventario.gd").slots(esc.j.jug().inv),st.slots],zona-Vector2(0,25),19)
	var inicio:=pagina*20
	for k in 20:
		var pos:=zona+Vector2((k%5)*88,(k/5)*72)
		var indice:=inicio+k
		var existe:=indice<ks.size()
		_celda(Rect2(pos,Vector2(64,64)),primero+indice if existe else -1,str(ks[indice]) if existe else "","",int(esc.j.jug().inv[ks[indice]]) if existe else 0)
	if ks.size()>20:_t("Página %d / %d · ↑↓ para recorrer"%[pagina+1,ceili(ks.size()/20.0)],zona+Vector2(0,288),14)
	var ficha:=Rect2(zona+Vector2(-8,310),Vector2(456,112))
	ui.ranura(self,ficha,false)
	var clave:=""
	var accion:=""
	if esc.sel>=3 and esc.sel<primero-1:
		clave=str(equipo.get(C.RANURAS[esc.sel-3],""));accion="Quitar" if clave!="" else ""
	elif esc.sel>=primero and esc.sel-primero<ks.size():
		clave=str(ks[esc.sel-primero])
		var info:Dictionary=Eq.info(clave)
		accion="Equipar" if info.has("equipo") else "Usar" if info.has("cura") else ""
	var info:Dictionary=Eq.info(clave) if clave!="" else {}
	var ic:=_icono_item(clave) if clave!="" else ""
	ui.icono(self,ic,Rect2(ficha.position+Vector2(10,18),Vector2(56,56)))
	var titulo:String=str(info.get("n","Ranura vacía"))
	ui.texto_en(self,titulo,Rect2(ficha.position+Vector2(78,8),Vector2(362,28)),18)
	var datos:Array=[]
	for dato in [["dmg","Daño"],["def","Defensa"],["hp","Vida"],["cura","Cura"]]:
		if info.has(dato[0]) and float(info[dato[0]])!=0:datos.append("%s %s"%[dato[1],str(info[dato[0]])])
	var detalle:String=" · ".join(datos) if not datos.is_empty() else ("Material de fabricación" if clave!="" else "Selecciona un objeto de la mochila.")
	ui.texto_en(self,detalle,Rect2(ficha.position+Vector2(78,36),Vector2(360,24)),15)
	boton_accion=Rect2()
	if accion!="":
		boton_accion=Rect2(ficha.position+Vector2(306,64),Vector2(138,40))
		ui.boton(self,boton_accion,true)
		ui.texto_en(self,accion,boton_accion.grow(-8),16,Color("fff0c7"),true)
	var bono:String="Bono: "+esc._txt_bono(esc.j.bono_set())
	draw_string(ui.fuente,izq.position+Vector2(2,444),bono,HORIZONTAL_ALIGNMENT_LEFT,390,14,UiArte.TINTA)
	var pie:=Rect2(vs.x/2-310,618,620,40)
	ui.marco(self,pie,Color("12363b"))
	ui.texto_en(self,"↑↓ / ←→ Seleccionar    Enter Usar / Equipar    Esc Cerrar",pie.grow(-9),15,Color("fff0c7"),true)

## Ratón: el mismo camino que el teclado. Cada pantalla publica sus zonas en `objetivos` al dibujarse.
func _input(event:InputEvent)->void:
	if esc==null or not (event is InputEventMouseButton or event is InputEventMouseMotion):return
	var p:Vector2=event.position
	var zona:=-1
	for objetivo in objetivos:
		if objetivo.r.has_point(p):zona=objetivo.i;break
	if event is InputEventMouseMotion:
		if zona>=0 and esc.panel!="inv":
			if esc.panel!="" and esc.panel!="dialogo":esc.sel=zona
			elif esc.modo=="menu":esc.menu_sel=zona
		return
	if not event.pressed:return
	var boton:int=event.button_index
	if esc.modo!="juego":
		if boton==MOUSE_BUTTON_LEFT or boton==MOUSE_BUTTON_RIGHT:_clic_pantalla(zona,p,boton)
		return
	if esc.panel=="":return
	if esc.panel=="dialogo" or esc.panel=="ficha":
		if boton==MOUSE_BUTTON_LEFT:esc._cerrar()
	elif boton==MOUSE_BUTTON_WHEEL_UP or boton==MOUSE_BUTTON_WHEEL_DOWN:
		if esc.panel!="inv":esc._desplazar(-3 if boton==MOUSE_BUTTON_WHEEL_UP else 3)
	elif boton==MOUSE_BUTTON_LEFT:
		if boton_cerrar.has_point(p):esc._cerrar()
		elif esc.panel=="inv" and boton_accion.has_point(p):_activar()
		elif zona>=0:
			esc.sel=zona
			if esc.panel!="inv" or event.double_click:_activar()
	get_viewport().set_input_as_handled()

## Menú inicial, creador y «Unirse»: clic = elegir; en el creador, un segundo clic en el valor del campo activo cambia la opción (derecho, la anterior).
func _clic_pantalla(zona:int,p:Vector2,boton:int)->void:
	if zona<0:return
	if esc.modo=="menu":
		esc.menu_sel=zona
		_tecla(KEY_ENTER)
	elif esc.modo=="creador":
		var ya_activo:bool=esc.cr.campo==zona
		esc.cr.campo=zona
		var total:int=Aspecto.CAMPOS.size()+2
		if zona==total-1:_tecla(KEY_ENTER)
		elif ya_activo and zona>0 and p.x>objetivos[zona].r.position.x+objetivos[zona].r.size.x*0.45:_tecla(KEY_LEFT if boton==MOUSE_BUTTON_RIGHT else KEY_RIGHT)
	elif esc.modo=="unirse":
		esc.un.campo=zona
		if zona==3 and boton==MOUSE_BUTTON_LEFT:_tecla(KEY_ENTER)
	else:return
	get_viewport().set_input_as_handled()

func _tecla(codigo:Key)->void:
	var e:=InputEventKey.new();e.pressed=true;e.keycode=codigo
	esc._unhandled_key_input(e)

func _activar()->void:
	esc._ejecutar_sel()

func _tracker(vs: Vector2, j, h: float) -> void:
	var lineas: Array = []   # [texto, tamaño]
	for id in C.MISIONES:
		var e: String = j.estado_mision(id)
		if e != "activa" and e != "cumplida": continue
		lineas.append([C.MISIONES[id].n + (" (¡cumplida!)" if e == "cumplida" else ""), 16])
		if C.MISIONES[id].da != "" and e == "cumplida": lineas.append(["→ vuelve con " + C.MISIONES[id].da.capitalize(), 16])
		for o in C.MISIONES[id].obj: lineas.append([("[x] " if j.objetivo_ok(o) else "[ ] ") + j.objetivo_txt(o), 16])
	if j.vivo != null:   # misiones de plantilla activas (story-004)
		for mi: Dictionary in j.vivo.instancias_visibles(j.LOCAL):
			if mi.estado != "activa": continue
			lineas.append([str(mi.nombre) + (" (¡cumplida!)" if mi.cumplida else ""), 16])
			lineas.append([str(mi.texto), 16])
	var extra := 1 if esc.red != null else 0
	var celda: Vector2i=esc.j.mundo.celda_de(esc.j.pies)
	var bioma: String=esc.j.mundo.bioma(celda)
	var hito: String=esc.j.mundo.hito_en(celda)
	lineas.append(["%s%s · %d, %d" % [hito + " · " if hito != "" else "",bioma.capitalize(),celda.x,celda.y],16])
	var alto := 72.0 + (extra + lineas.size()) * 26.0 + (8.0 if not lineas.is_empty() else 0.0)
	var r := Rect2(vs.x - 16 - 328, 16, 328, alto)
	ui.panel(self, r)
	ui.texto_en(self,"Día %d · %02d:%02d"%[j.dia(),int(h),int(fmod(h,1.0)*60)],Rect2(r.position+Vector2(22,20),Vector2(284,32)),23)
	var y := 64.0
	if esc.red != null:
		_t(esc.red.estado_txt(), r.position + Vector2(16, y), 16)
		y += 26.0
	for l in lineas:
		ui.texto_en(self,str(l[0]),Rect2(r.position+Vector2(22,y),Vector2(284,24)),int(l[1]))
		y += 26.0

func _panel(vs:Vector2)->void:
	if esc.panel!="ficha":super._panel(vs);return
	var nid:String=esc.ficha_npc
	var perfil:Dictionary=esc.j.autonomia.perfil(nid)
	var estado:Dictionary=esc.j.d.get("mundo_vivo",{}).get("autonomia",{}).get("npcs",{}).get(nid,{})
	var r:=Rect2(vs.x/2-420,118,840,490)
	ui.panel(self,r)
	var nombre:String=esc.j.habitantes.fichas.get(nid,{}).get("n",nid)
	ui.texto_en(self,nombre,Rect2(r.position+Vector2(30,24),Vector2(780,40)),28)
	var tarjeta:=Rect2(r.position+Vector2(28,88),Vector2(224,288))
	ui.marco(self,tarjeta,Color("12363b"))
	var look:Array=esc.j.habitantes.aspecto(nid) if esc.j.habitantes.fichas.has(nid) else [0,1,0,0,0,0,0,0]
	draw_set_transform(tarjeta.position+Vector2(112,238),0,Vector2(6,6))
	esc.arte_eq.dibujar(self,Vector2.ZERO,Vector2i.DOWN,0,[],look,"reposo")
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
	var permanencia:String=esc.j.autonomia.sociedad.arraigo.estado(nid)
	draw_set_transform(tarjeta.position+Vector2(184,24),0,Vector2(3,3))
	esc.arte_vida.permanencia(self,Vector2(-11,32),permanencia)
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
	ui.texto_en(self,permanencia.capitalize(),Rect2(tarjeta.position+Vector2(20,245),Vector2(184,26)),17,Color("f8e4af"),true)
	var x:=r.position.x+280;var y:=r.position.y+94
	ui.texto_en(self,"Oficio: "+str(perfil.get("oficio","habitante")).capitalize(),Rect2(x,y,524,30),20)
	ui.texto_en(self,"Ahora: "+str(estado.get("ocupacion","sin ocupación registrada")).capitalize(),Rect2(x,y+38,524,28),17)
	var bio:Dictionary=perfil.get("biografia",{})
	var cfg:Dictionary=esc.j.autonomia.sociedad.cfg.biografia
	var lineas:Array=[]
	if bio.is_empty():lineas.append("Biografía sin registrar.")
	else:
		lineas.append("Origen: "+str(cfg.origenes.get(bio.get("origen",""),"Sin registrar")))
		var antecedente:String=cfg.antecedentes.get(bio.get("antecedente",""),{}).get("texto","Sin registrar")
		if "%s" in antecedente:antecedente=antecedente%esc.j.habitantes.fichas.get(bio.get("con",""),{}).get("n","alguien")
		lineas.append("Historia: "+antecedente)
		lineas.append("Aspiración: "+str(cfg.aspiraciones.get(bio.get("aspiracion",""),{}).get("texto","Sin registrar")))
	var texto:String="\n\n".join(lineas)
	draw_multiline_string(ui.fuente,Vector2(x,y+110),texto,HORIZONTAL_ALIGNMENT_LEFT,510,17,8,UiArte.TINTA)
	ui.texto_en(self,"V cerca de un habitante · E / Enter / Esc cerrar",Rect2(r.position+Vector2(28,432),Vector2(784,30)),16)

## Cartografía por bloques; jamás revela terreno, enemigos ni objetos no observados.
func _mapa(vs: Vector2) -> void:
	objetivos.clear()
	boton_cerrar = Rect2()
	var j = esc.j
	ui.panel(self, Rect2(70, 30, vs.x - 140, 620))
	_t("MAPA PERSONAL · N ↑", Vector2(96, 56), 24)
	_t("M / Esc cerrar · Flechas mover · +/− zoom · Inicio volver a ti", Vector2(96, 92), 16)
	var zona := Rect2(96, 134, 740, 450)
	draw_rect(zona, Color("202e33"))
	var b := int(j.autonomia.reglas.conocimiento.bloque)
	var centro: Vector2i = esc.mapa_centro
	var escala: float = esc.mapa_escala
	var bloques: Dictionary = j.jug().get("mapa", {}).get("bloques", {})
	for k in bloques:
		var c := Vector2i(int(k.get_slice(",", 0)), int(k.get_slice(",", 1))) * b
		var pos := zona.get_center() + Vector2(c - centro) * escala
		var r := Rect2(pos, Vector2.ONE * b * escala).intersection(zona)
		if r.has_area(): draw_rect(r, Color("6c9673") if bloques[k] == "visto" else Color("a38b58"))
	var numero := 0
	for h in j.Exploracion.hitos(j, esc.J.LOCAL):
		numero += 1
		var k: String = h.bloque
		var c := Vector2(int(k.get_slice(",", 0)), int(k.get_slice(",", 1))) * b + Vector2.ONE * b / 2.0
		var pos := zona.get_center() + (c - Vector2(centro)) * escala
		if zona.grow(-16).has_point(pos):
			draw_circle(pos, 10, Color("f3de99"))
			_t(str(numero), pos + Vector2(-4, -9), 14)
	var yo := zona.get_center() + Vector2(esc.J.Mundo.celda_de(j.pies) - centro) * escala
	if zona.has_point(yo):
		draw_circle(yo, 6, Color.WHITE)
		_t("Tú", yo + Vector2(9, -9), 16, Color.WHITE)
	_t("Verde: recorrido · Ocre: contado · Oscuro: desconocido", Vector2(96, 612), 16)
	_t("REFERENCIAS APROXIMADAS", Vector2(858, 142), 16)
	var y := 182.0
	numero = 0
	for h in j.Exploracion.hitos(j, esc.J.LOCAL):
		numero += 1
		_t("%d. %s" % [numero, h.nombre], Vector2(858, y), 16)
		var fuente: String = h.fuente
		var n := "Explorado por ti"
		if fuente != "visto": n = "Según " + str(j.habitantes.fichas.get(fuente.trim_prefix("npc:"), {}).get("n", "un habitante"))
		_t(n, Vector2(858, y + 21), 14)
		y += 52
