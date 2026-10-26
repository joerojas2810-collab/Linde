extends SceneTree
const J = preload("res://scripts/juego.gd")
const C = preload("res://scripts/catalogos.gd")
const M = preload("res://scripts/mundo.gd")
const Srv = preload("res://scripts/red_servidor.gd")
const Cli = preload("res://scripts/red_cliente.gd")
var total := 0
var fallos := 0
func ok(v: bool, texto: String) -> void:
 total += 1
 print(("PASS " if v else "FAIL ") + texto)
 if not v: fallos += 1
func suma_delta(resultados: Array) -> Dictionary:
 var suma := {}
 for r in resultados:
  for item in r.delta: suma[item] = int(suma.get(item,0)) + int(r.delta[item])
 return suma
# JSON distingue int/float en metadatos heredados; se compara el mismo valor serializable.
func iguales(x: Dictionary, y: Dictionary) -> bool:
 return JSON.stringify(JSON.parse_string(JSON.stringify(x))) == JSON.stringify(JSON.parse_string(JSON.stringify(y)))
func guardar(j, ruta: String):
 ok(j.guardar(ruta), "guarda economía regional")
 return J.cargar(ruta)
func _init() -> void:
 var j = J.nueva(123, "Regional", [0,0,0], "poblado")
 var a = j.autonomia
 var asen = a.asentamientos
 var puestos: Array = asen.datos().puestos.values()
 ok(puestos.size() >= 2, "escenario usa comunidades reales de génesis")
 var p: Dictionary = puestos[0]
 var inv: Dictionary = asen.inventario(p)
 var inicio := inv.duplicate(true)
 # Cosecha, consumo y producción ya maduros en un único paso, sin regalar insumos.
 j.d.min += maxi(int(asen.cfg.comida_min),C.CAMPO_CRECE_MIN)
 asen.actualizar()
 var e: Dictionary = asen.economia_regional(p)
 var causas := {}
 var extracciones := 0
 var fuentes_validas := true
 for r in e.resultados:
  causas[r.causa] = true
  if r.causa == "extraccion":
   extracciones += 1
   fuentes_validas = fuentes_validas and j.d.mundo.rotos.has(r.detalle.objeto) and r.detalle.usos_antes-r.detalle.usos_despues == 1
 ok(extracciones > 0 and fuentes_validas, "cada extracción deja objeto roto real y un uso gastado")
 ok(causas.has("cosecha") and causas.has("consumo") and causas.has("asignar_herramienta") and extracciones > 0, "ejecutor regional conecta saldos con cosecha, comida, herramientas y extracción")
 var delta := suma_delta(e.resultados)
 var items := inicio.keys()
 for item in inv:
  if not item in items: items.append(item)
 var conserva := true
 for item in items:
  conserva = conserva and int(inv.get(item,0)) == int(inicio.get(item,0)) + int(delta.get(item,0))
 ok(conserva, "stock final = stock inicial + suma exacta de resultados, sin inventario paralelo")
 var secuencia: int = e.secuencia
 var anterior := JSON.stringify(j.d)
 asen.actualizar()
 ok(int(e.secuencia) == secuencia and JSON.stringify(j.d) == anterior, "repetir el paso del mismo minuto no repite trabajo ni resultados")
 # El límite material es el mismo del ejecutor previo; no nace un objeto 'materiales'.
 inv.madera = int(asen.cfg.tope_stock)
 var antes_producciones: int = p.producciones
 j.d.min += int(asen.cfg.produccion_min)
 asen.actualizar()
 ok(p.producciones == antes_producciones and asen.balance_resumido(p).materiales.pendiente == 0 and not inv.has("materiales"), "saldo completo detiene extracción con el límite existente, sin crear ítems de control")
 # Sin cosecha ni comida: la obligación se transforma en deuda, nunca stock negativo.
 for q in p.campos: j.mundo.constr_en(Vector2i(q[0],q[1])).listo = int(j.d.min)+10000
 inv.erase("baya")
 p.comida_min = int(j.d.min)-int(asen.cfg.comida_min)
 secuencia = e.secuencia
 asen.actualizar()
 var deuda: int = p.deuda_comida
 ok(deuda == p.residentes.size() and not inv.has("baya") and int(e.secuencia) == secuencia and e.bloqueo.causa == "sin_comida", "saldo alimentario insuficiente conserva deuda y causa sin consumo ficticio")
 var bloqueo := JSON.stringify(e.bloqueo)
 asen.actualizar()
 ok(JSON.stringify(e.bloqueo) == bloqueo and int(e.secuencia) == secuencia, "bloqueo repetido no llena el historial")
 # Reinicio durante la deuda y comparación de continuación con la misma entrada real de stock.
 asen.actualizar_demandas()
 var ruta := "/tmp/linde-economia-regional-%d.json" % OS.get_process_id()
 var carga = guardar(j, ruta)
 ok(carga != null and iguales(carga.autonomia.asentamientos.datos(),asen.datos()), "carga conserva deuda, cursores, saldos, secuencias y resultados exactos")
 if carga != null:
  var ac = carga.autonomia.asentamientos
  var pc: Dictionary = ac.datos().puestos[p.id]
  # Entrada externa explícita en el escenario (no generada por la economía).
  inv.baya = deuda
  ac.inventario(pc).baya = deuda
  asen.actualizar()
  ac.actualizar()
  ok(int(p.deuda_comida) == 0 and int(inv.get("baya",0)) == 0 and e.resultados.back().causa == "pago_deuda", "pagar deuda descuenta exactamente los bienes presentes")
  ok(iguales(ac.datos(),asen.datos()), "continuación tras reinicio reproduce resultados sin doble cargo")
  secuencia = e.secuencia
  asen.actualizar()
  ok(int(e.secuencia) == secuencia, "deuda pagada no se vuelve a consumir")
 # Carencia de herramienta no fabrica una nueva ni degrada usos por un trabajo fallido.
 inv.madera = 0
 inv.baya = 1
 inv.erase("hacha_piedra")
 inv.erase("pico_piedra")
 for r in p.residentes: r.usos = 0
 j.d.min += int(asen.cfg.produccion_min)
 antes_producciones = p.producciones
 asen.actualizar()
 ok(p.producciones == antes_producciones and e.bloqueo.causa == "sin_herramienta" and asen.balance_resumido(p).hacha_piedra.pendiente > 0, "herramienta ausente mantiene demanda sin producir bienes ni usos")
 # Stock de comida positivo para trabajar: requisito previo ya existente, no consumo nuevo.
 inv.erase("baya")
 var saldo: Dictionary = asen.balance_resumido(p).baya
 ok(saldo.trabajo == 1 and saldo.pendiente > 0, "saldo expresa el requisito existente de comida para trabajar")
 # Agotar las fuentes cercanas no produce un resultado positivo ni gasta usos.
 inv.baya = 1
 for r in p.residentes: r.usos = 5
 var centro := Vector2i(p.celda[0],p.celda[1])
 var radio: int = int(asen.cfg.radio_recursos)
 for dx in range(-radio,radio+1):
  for dy in range(-radio,radio+1):
   var c := centro+Vector2i(dx,dy)
   var objeto: String = j.mundo.generador.datos(c).objeto
   if objeto in ["arbol","roca"]: j.mundo.romper(objeto+"@"+M.clave(c),j.d.min)
 secuencia = e.secuencia
 antes_producciones = p.producciones
 j.d.min += int(asen.cfg.produccion_min)
 asen.actualizar()
 var sin_desgaste := true
 for r in p.residentes: sin_desgaste = sin_desgaste and int(r.usos) == 5
 ok(p.producciones == antes_producciones and int(e.secuencia) == secuencia and sin_desgaste and e.bloqueo.causa == "sin_recurso_accesible", "fuentes agotadas no generan productos, resultados ni desgaste ficticios")
 # Réplica por bienvenida y actualización fiable; cliente no ejecuta operaciones.
 asen.actualizar_demandas()
 var srv = Srv.new()
 srv.j = j
 var cli = Cli.new()
 cli._bienvenida(srv.estado_para(J.LOCAL))
 ok(JSON.stringify(cli.j.autonomia.asentamientos.datos()) == JSON.stringify(asen.datos()), "bienvenida replica historial regional y saldos existentes")
 var replica := JSON.stringify(cli.j.d)
 cli.j.autonomia.asentamientos.actualizar()
 ok(JSON.stringify(cli.j.d) == replica, "cliente no ejecuta consumo o producción")
 cli._mundo({"mundo_vivo":j.d.mundo_vivo.duplicate(true)})
 ok(JSON.stringify(cli.j.autonomia.asentamientos.datos()) == JSON.stringify(asen.datos()), "actualización fiable conserva resultados sin volver a aplicarlos")
 cli.free()
 srv.free()
 print("REGIONAL: %d comprobaciones, %d fallos" % [total,fallos])
 quit(1 if fallos else 0)
