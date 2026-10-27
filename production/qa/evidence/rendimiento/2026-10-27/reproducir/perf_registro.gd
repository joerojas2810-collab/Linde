extends RefCounted
static var activo:=false
static var cuadro:Dictionary={}
static func anotar(nombre:String,us:int)->void:
 if not activo:return
 cuadro[nombre]=int(cuadro.get(nombre,0))+us
