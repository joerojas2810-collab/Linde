extends SceneTree
func _initialize():
 var target=ProjectSettings.globalize_path("res://../mapa_muestra/arte")
 DirAccess.make_dir_recursive_absolute(target)
 var body=Image.load_from_file("res://capas/cuerpo.png")
 for name in ["piel","botas"]:
  var layer=Image.load_from_file("res://capas/"+name+".png")
  body.blend_rect(layer,Rect2i(0,0,128,128),Vector2i.ZERO)
 body.save_png(target+"/personaje_cuerpo.png")
 for name in ["pelo","tunica","pantalon","cinturon"]:
  var layer=Image.load_from_file("res://capas/"+name+".png")
  layer.save_png(target+"/personaje_"+name+".png")
 var f=FileAccess.open(target+"/personaje.json",FileAccess.WRITE)
 f.store_string(JSON.stringify({"celda":32,"capas":["cuerpo","pantalon","tunica","cinturon","pelo"]},"  "));f.close()
 print("Integracion personaje walk capas lista")
 quit()
