extends SceneTree
const J = preload("res://scripts/juego.gd")
const M = preload("res://scripts/mundo.gd")
const Srv = preload("res://scripts/red_servidor.gd")
const Cli = preload("res://scripts/red_cliente.gd")
var total := 0
var fallos := 0
func ok(v: bool, texto: String) -> void:
 total += 1
 print(("PASS " if v else "FAIL ") + texto)
 if not v: fallos += 1
func preparar(j) -> void:
 var a = j.autonomia
 a.reglas.expediciones = false
 a.tareas.datos().activos.clear()
 for nid in j.habitantes.ids:
  if a.perfil(nid).is_empty(): continue
  # Escenario de contabilidad aislado; no modifica datos de balance del producto.
  var p: Dictionary = a.reglas.perfiles[nid]
  p.grupo = "talleres"
  p.receta = "lingote"
  p.reserva_producto = 3
  p.recetas = ["lingote"]
  p.herramientas_necesarias = []
  p.caracter = {"codicia":0,"honestidad":100,"rencor":0}
  p.identidad = {}
  var n: Dictionary = a.estado(nid)
  n.inv = {"baya":a.sociedad.reserva_comida(nid),"lingote":3}
  n.recetas_nuevas = []
  n.comprometido = {}
  n.compromiso_hasta = 0
  n.plan = {}
  n.bloqueos = {}
 a.sociedad.grupo("talleres").inv = {}
 a.sociedad.datos().acuerdos.clear()
func _init() -> void:
 var j = J.nueva(123, "Colectivas", [0,0,0])
 var a = j.autonomia
 var s = a.sociedad
 var t = a.tareas
 preparar(j)
 ok(s.balance_grupo("canteros").is_empty(), "grupo sin miembros no genera pedidos por configuración")
 var inv: Dictionary = s.grupo("talleres").inv
 inv.madera = 2
 var b: Dictionary = s.balance_grupo("talleres").madera
 ok(b.reserva == 3 and b.stock == 2 and b.pendiente == 1, "reserva menos stock: un saldo único por grupo e ítem")
 var estado := JSON.stringify(j.d)
 var ids := JSON.stringify(s.balance_grupo("talleres"))
 ok(ids == JSON.stringify(s.balance_grupo("talleres")) and estado == JSON.stringify(j.d), "consulta idempotente sin efectos materiales ni nuevas órdenes")
 inv.clear()
 a.estado("maren").inv.madera = 4
 b = s.balance_grupo("talleres").madera
 ok(b.aportable == 3 and b.pendiente == 0, "stock privado conserva insumo personal y solo aporta excedente")
 a.estado("maren").comprometido = {"madera":4}
 a.estado("maren").compromiso_hasta = int(j.d.min)+5
 b = s.balance_grupo("talleres").madera
 ok(b.comprometido == 4 and b.aportable == 0 and b.pendiente == 3, "insumos comprometidos no cubren otra demanda")
 a.estado("maren").compromiso_hasta = int(j.d.min)
 ok(s.balance_grupo("talleres").madera.pendiente == 0, "compromiso vencido deja el excedente disponible una sola vez")
 # Dos metas personales del mismo producto no suman dos veces el mismo objetivo.
 a.estado("maren").inv.erase("lingote")
 a.estado("maren").inv.mena = 2
 a.estado("maren").recetas_nuevas = ["lingote"]
 ok(s.balance_grupo("talleres").lingote.individuales == 3, "metas equivalentes de un actor consolidan el máximo objetivo actual")
 a.estado("maren").recetas_nuevas = []
 a.estado("maren").inv.erase("mena")
 # Una salida de oficio también respeta compromisos, incluso al depositar físicamente.
 a.estado("maren").inv.lingote = 6
 a.estado("maren").comprometido = {"lingote":6}
 a.estado("maren").compromiso_hasta = int(j.d.min)+5
 ok(s.aportable("maren","lingote") == 0, "producto de oficio no evade un compromiso vigente")
 preparar(j)
 var n: Dictionary = a.estado("maren")
 n.inv.erase("baya")
 var falta: int = s.reserva_comida("maren")
 s.grupo("talleres").inv.baya = falta
 b = s.balance_grupo("talleres").baya
 ok(b.individuales == falta and b.pendiente == 0, "depósito cubre necesidad individual sin duplicarla")
 # El retiro pendiente usa las mismas unidades del depósito; no es producción futura.
 t.iniciar("maren", {"item":"baya","cantidad":falta,"motivo":"alimentarme"})
 n.plan = {"act":"compartir","celda":[28,20]}
 t.resultado("maren", n.inv.duplicate(), true)
 b = s.balance_grupo("talleres").baya
 ok(b.atendidas == 0 and b.pendiente == 0, "retiro y stock no se cuentan dos veces")
 s.grupo("talleres").inv.clear()
 s.datos().acuerdos.uno = {"estado":"activo","vence":int(j.d.min)+5,"solicitante":"maren","proveedor":"ordal","bien":{"baya":falta},"pago":{}}
 b = s.balance_grupo("talleres").baya
 ok(b.acuerdos == falta and b.pendiente == 0, "garantía entrante cubre su necesidad sin restarla otra vez del stock")
 s.datos().acuerdos.uno.estado = "cumplido"
 ok(s.balance_grupo("talleres").baya.pendiente == falta, "acuerdo cerrado sin bienes actuales no promete suministro")
 # Un acuerdo del grupo cubre una sola vez, primero al individuo y luego al depósito.
 s.datos().acuerdos.uno.estado = "activo"
 s.datos().acuerdos.uno.grupo_destino = "talleres"
 s.datos().acuerdos.uno.bien.baya = falta + 1
 b = s.balance_grupo("talleres").baya
 ok(b.acuerdos == falta and b.acuerdos_colectivos == 1, "una misma garantía reparte cobertura personal y colectiva sin duplicarse")
 s.datos().acuerdos.uno.vence = int(j.d.min)
 b = s.balance_grupo("talleres").baya
 ok(b.acuerdos == 0 and b.acuerdos_colectivos == 0, "garantía vencida deja de cubrir ambos destinos")
 # Recolección individual real en marcha: cubre a su actor, no genera stock.
 preparar(j)
 n = a.estado("maren")
 n.inv.erase("baya")
 ok(s._obtener("maren","baya",falta,[],"alimentarme"), "ejecutor existente acepta atender una necesidad individual")
 b = s.balance_grupo("talleres").baya
 ok(b.atendidas == falta and b.stock == 0 and b.pendiente == 0, "necesidad atendida se descuenta sin inventar comida")
 t.cancelar("maren","prueba")
 ok(s.balance_grupo("talleres").baya.pendiente == falta, "cancelar trabajo reabre el saldo")
 # Demanda colectiva asignada una vez; otro actor solo recibe el remanente.
 preparar(j)
 ok(s._obtener("maren","madera",3,[],"abastecer Talleres","talleres"), "reclamo colectivo usa la cadena de aprovisionamiento actual")
 b = s.balance_grupo("talleres").madera
 ok(b.en_curso == 3 and b.pendiente == 0 and b.stock == 0, "orden en curso cubre demanda sin convertirse en inventario")
 var repetida := false
 for meta in s.objetivos("ordal"):
  if meta.get("grupo", "") == "talleres" and meta.item == "madera": repetida = true
 ok(not repetida, "segundo actor no recibe otra orden cubierta")
 ok(s.balance_grupo("talleres","maren").madera.pendiente == 3, "actor asignado sigue viendo su propia demanda para continuarla")
 # Invalidar el recurso vuelve visible el déficit sin esperar el siguiente intento.
 var oid: String = t.datos().activos.maren.recurso
 j.mundo.romper(oid, j.d.min)
 ok(s.balance_grupo("talleres").madera.en_curso == 0, "recurso agotado deja de respaldar la orden")
 # Las garantías colectivas descuentan solo lo que el receptor podrá aportar realmente.
 preparar(j)
 a.estado("ordal").inv.madera = 4
 var lejos_acuerdo := M.pies_de_celda(Vector2i(32,46))
 j.d.npcs.maren.pos = [lejos_acuerdo.x,lejos_acuerdo.y]
 ok(s._obtener("maren","madera",3,[],"abastecer Talleres","talleres"), "acuerdo local existente sirve a una demanda colectiva")
 var cid: String = s._ocupado("maren")
 ok(cid != "" and s.datos().acuerdos[cid].get("grupo_destino", "") == "talleres", "garantía conserva destino colectivo sin otro inventario")
 b = s.balance_grupo("talleres").madera
 ok(b.acuerdos_colectivos == 2 and b.pendiente == 1, "envío descuenta la reserva que retendrá el receptor")
 var saldo_prometido: int = b.pendiente
 j.d.npcs.ordal.pos = j.d.npcs.maren.pos.duplicate()
 ok(s.entregar(cid), "entrega real de la garantía colectiva")
 b = s.balance_grupo("talleres").madera
 ok(b.pendiente == saldo_prometido and b.acuerdos_colectivos == 0 and b.aportable == 2, "recepción reemplaza promesa por stock aportable sin saltos ni duplicación")
 # Una garantía de insumo no se confunde con la salida colectiva de la receta.
 preparar(j)
 a.estado("ordal").inv.mena = 3
 var lejos_insumo := M.pies_de_celda(Vector2i(10,9))
 j.d.npcs.ordal.pos = [lejos_insumo.x,lejos_insumo.y]
 ok(s._obtener("maren","lingote",1,[],"abastecer Talleres","talleres"), "cadena productiva obtiene un insumo mediante acuerdo existente")
 cid = s._ocupado("maren")
 ok(cid != "" and s.datos().acuerdos[cid].get("grupo_destino", "") == "" and s.atencion("maren","lingote") == 1, "insumo respalda la tarea original sin prometer una segunda salida colectiva")
 a._decidir("maren")
 ok(t.datos().activos.has("maren") and s.atencion("maren","lingote") == 1, "espera del insumo conserva el encargo productivo")
 j.d.npcs.ordal.pos = j.d.npcs.maren.pos.duplicate()
 a._decidir("maren")
 ok(t.datos().activos.has("maren") and s.atencion("maren","lingote") == 1 and a.estado("maren").inv.get("mena",0) > 0, "insumo recibido mantiene el encargo con bienes reales hasta reevaluar")
 # Fabricación comprometida y ruta: cantidad pendiente, no receta multiplicada por actor.
 preparar(j)
 n = a.estado("maren")
 n.inv.mena = 2
 n.inv.madera = 1
 a.estado("ordal").inv.lingote = 1
 var lejos := M.pies_de_celda(Vector2i(32,46))
 j.d.npcs.maren.pos = [lejos.x, lejos.y]
 var horno := Vector2i(28,20)
 j.d.mundo.constr[M.clave(horno)] = {"t":"horno","dueno":"local"}
 ok(s._obtener("maren","lingote",2,[],"abastecer Talleres","talleres"), "producción en curso reutiliza estación y receta")
 ok(s.atencion("maren","lingote") == 2, "orden productiva válida conserva cantidad encargada")
 n.inv.erase("mena")
 ok(s.atencion("maren","lingote") == 0, "perder insumos deja de ocultar escasez")
 n.inv.mena = 2
 j.d.mundo.constr.erase(M.clave(horno))
 ok(s.atencion("maren","lingote") == 0, "estación retirada invalida cobertura")
 # Perder la ruta también invalida la cobertura, sin consumir ni cancelar otra orden.
 n.inv.mena = 2
 j.d.mundo.constr[M.clave(horno)] = {"t":"horno","dueno":"local"}
 n.plan.celda = [-9999,-9999]
 ok(s.atencion("maren","lingote") == 0, "destino inalcanzable no respalda producción pendiente")
 # El excedente contabilizado llega al depósito mediante el ejecutor físico actual.
 preparar(j)
 n = a.estado("maren")
 n.inv.madera = 4
 var cerca := M.pies_de_celda(Vector2i(28,21))
 j.d.npcs.maren.pos = [cerca.x,cerca.y]
 var madera_antes: int = int(n.inv.madera) + int(s.grupo("talleres").inv.get("madera",0))
 ok(s._depositar("maren"), "ejecutor entrega el excedente contabilizado")
 ok(n.inv.get("madera",0) == 1 and s.grupo("talleres").inv.get("madera",0) == 3 and int(n.inv.madera) + int(s.grupo("talleres").inv.madera) == madera_antes, "traslado conserva cantidades y reserva personal")
 ok(s.balance_grupo("talleres").madera.pendiente == 0, "material entregado reemplaza al aporte previsto sin descontar dos veces")
 # Un efecto parcial no sigue figurando a la vez como stock y tarea pendiente.
 t.iniciar("maren", {"item":"madera","cantidad":3,"motivo":"parcial","grupo":"talleres"})
 var antes: Dictionary = n.inv.duplicate()
 a.dar("maren","madera",1)
 t.resultado("maren", antes, true)
 ok(t.datos().activos.maren.demanda.cantidad == 2, "salida parcial reduce exactamente lo pendiente de la tarea")
 # Adaptador regional: obligaciones reales, no tasas futuras ni recursos de génesis nuevos.
 var p := {"id":"prueba","cofre":"sin_cofre","residentes":[{"oficio":"recolector","usos":0}],"comida_min":int(j.d.min),"deuda_comida":2}
 var regional: Dictionary = a.asentamientos.balance_resumido(p)
 ok(regional.baya.pendiente == 3 and regional.hacha_piedra.pendiente == 1, "resumen informa deuda, comida de trabajo y herramienta real sin simular producción")
 # Integración con perfiles originales, sin ajustes del escenario contable.
 j = J.nueva(456, "Persistencia", [0,0,0], "poblado")
 a = j.autonomia
 # Integración: snapshot durable bajo Asentamientos, guardado y réplica existentes.
 j.d.min += 1
 a.paso()
 ok(a.asentamientos.datos().has("demandas"), "paso autoritativo publica el balance al terminar las decisiones")
 a.estado("maren").inv.hacha_piedra = 1
 ok(a.sociedad._obtener("maren","madera",3,[],"abastecer Talleres","talleres"), "tarea activa con perfil original para verificar continuidad")
 a.asentamientos.actualizar_demandas()
 ok(a.asentamientos.datos().demandas.poblados.size() > 1, "vista integra poblado detallado y comunidades resumidas existentes")
 var snapshot := JSON.stringify(a.asentamientos.datos().demandas)
 a.asentamientos.actualizar_demandas()
 ok(JSON.stringify(a.asentamientos.datos().demandas) == snapshot, "consolidación repetida del mismo estado no duplica demandas")
 var ruta := "/tmp/linde-colectivas-%d.json" % OS.get_process_id()
 ok(j.guardar(ruta), "guarda demandas colectivas")
 var carga = J.cargar(ruta)
 ok(carga != null and JSON.stringify(carga.autonomia.asentamientos.datos().demandas) == snapshot, "carga conserva el último balance y su identidad")
 if carga != null:
  carga.autonomia.asentamientos.actualizar_demandas()
  ok(JSON.stringify(carga.autonomia.asentamientos.datos().demandas) == snapshot, "recalcular tras carga produce el mismo saldo")
 var srv = Srv.new()
 srv.j = j
 var cli = Cli.new()
 cli._bienvenida(srv.estado_para(J.LOCAL))
 ok(JSON.stringify(cli.j.autonomia.asentamientos.datos().demandas) == snapshot, "bienvenida replica las demandas sin otro canal")
 var copia := JSON.stringify(cli.j.d)
 cli.j.autonomia.asentamientos.actualizar_demandas()
 ok(JSON.stringify(cli.j.d) == copia, "cliente no publica ni simula balances")
 cli.free()
 srv.free()
 print("COLECTIVAS: %d comprobaciones, %d fallos" % [total,fallos])
 quit(1 if fallos else 0)
