extends SceneTree
## Verifica que la fuente distribuida contiene glifos españoles sin recurrir al fallback.
func _initialize() -> void:
    var font: FontFile = load("res://fuentes/tipografia/PixelifySans[wght].ttf")
    var missing: Array = []
    for c in "ÁÉÍÓÚÜÑáéíóúüñ¿¡0123456789":
        if not font.has_char(c.unicode_at(0)): missing.append(c)
    print(JSON.stringify({"font":"Pixelify Sans","license":"OFL-1.1","missing":missing}))
    quit(0 if missing.is_empty() else 1)
