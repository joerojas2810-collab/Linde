extends SceneTree
func _initialize():
 var data=JSON.parse_string(FileAccess.get_file_as_string("res://manifest.json"))
 var sizes={"tree_broadleaf":32,"tree_pine":32,"tree_fruit":32,"rock":16,"ore_copper":16,"bush_berries":16,"barrel":16,"fence_horizontal":32,"chest_closed":24,"chest_open":24,"chest_treasure":24,"workbench":32,"furnace":24,"bed":32,"palisade":32,"bridge_vertical":48,"cottage_closed":96,"cottage_open":96,"crafting_shed":96,"cave_entrance":64}
 for item in data.assets:
  var img=Image.load_from_file("res://"+item.file)
  var rect=img.get_used_rect()
  item["bbox"]=[rect.position.x,rect.position.y,rect.size.x,rect.size.y]
  var draw=sizes.get(item.id,16)
  item["expected_draw_size"]=[draw,draw]
  item["expected_draw_size_status"]="proposed_for_16px_grid_not_map_validated"
  item["pivot"]=[rect.position.x+rect.size.x/2,rect.end.y]
  item["pivot_status"]="bbox_bottom_center_provisional_ground_anchor"
  if item.id.begins_with("tree_"):
   item["collision_hint"]="small trunk only; canopy depth separately"
 var f=FileAccess.open("res://manifest.json",FileAccess.WRITE)
 f.store_string(JSON.stringify(data,"  "))
 f.close()
 print("MEASURED ",data.assets.size())
 quit()
