extends Node2D

############################################
# CastleDB管理
############################################

# CastleDBのデータパス
const PATH_CDB = "res://assets/data.cdb"

# データ種別
enum eColumnType {
	UNIQUE_ID   = 0,
	TEXT        = 1,
	BOOLEAN     = 2,
	INTEGER     = 3,
	FLOAT       = 4,
	ENUMERATION = 5,
	FLAGS       = 6,
	REFERENCE   = 7,
	LIST        = 8,
	COLOR       = 9,
	FILE        = 10,
	IMAGE       = 11,
}

var _cdb    = null
var _sheets = {}
var _values = {}

func _ready() -> void:
	var file = File.new()
	file.open(PATH_CDB, File.READ)
	var text = file.get_as_text()
	file.close()
	
	# JSONにパースする
	var json_parse = JSON.parse(text)
	_cdb = json_parse.result
	
	# ユニークIDのハッシュテーブルを作成する
	for sheet in _cdb["sheets"]:
		var name = sheet.name
		
		# ユニークIDを探す
		var uid  = null
		var has_value = false # "value" が存在するかどうか
		
		for column in sheet["columns"]:
			match int(column["typeStr"]):
				eColumnType.UNIQUE_ID:
					uid = column["name"] # ユニークIDの名称
				eColumnType.INTEGER:
					if column["name"] == "value":
						has_value = true
			
		if uid == null:
			continue # ユニークIDが存在しない
			
		var tbl_value = {}
		
		# テーブルを作成する
		var tbl = {}
		for line in sheet["lines"]:
			var id = line[uid]
			tbl[id] = line
			if has_value:
				var value = int(line["value"])
				tbl_value[value] = line
		_sheets[name] = tbl
		if has_value:
			_values[name] = tbl_value

# シート名指定でシート内のすべてのデータを取得する
func get_sheet(sheet:String):
	if sheet in _sheets:
		return _sheets[sheet]
	else:
		print("存在するシート:", _sheets.keys())
		Infoboard.error("Not found sheetname '%s'"%sheet)
		return null

# シートとid指定でデータを取得する
func search(sheet:String, id:String):
	var tbl = get_sheet(sheet)
	if tbl == null:
		return null
		
	if id in tbl:
		return tbl[id]
	else:
		Infoboard.error("Not found id '%s' (on 'sheet:%s')"%[id, sheet])
		return null

# シートとvalue指定でデータを取得する
func search_from_value(sheet:String, value:int):
	if not(sheet in _values):
		Infoboard.error("Not found sheetname '%s'"%sheet)
		return null
	var tbl = _values[sheet]
	if tbl == null:
		return null
	
	if value in tbl:
		return tbl[value]
	else:
		Infoboard.error("Not found value '%d' (on 'sheet:%s')"%[value, sheet])
		return null

# クリック可能なオブジェクトに情報を付与する
func scene_to_set_obj(scene, obj:Node2D) -> void:
	var regex = RegEx.new()
	regex.compile("obj(?<digit>[0-9]+)")
	var result = regex.search(obj.name)
	if result == null:
		Infoboard.error("クリック対象とならないオブジェクト名: %s"%obj.name)
		return
		
	var obj_id = int(result.get_string("digit"))
	var obj_info = null
	for info in scene["objs"]:
		if obj_id == int(info["id"]):
			obj_info = info
			break
	if obj_info == null:
		Infoboard.error("%sに未設定のオブジェクトID: %s"%[scene.id, obj.name])
		return

	obj.set_meta("enable", false)
	if "click" in obj_info:
		# クリック可能
		obj.set_meta("click", obj_info["click"])
		obj.set_meta("enable", true)

	if "on" in obj_info:
		# ONフラグの指定あり
		obj.set_meta("on", obj_info["on"])
	if "off" in obj_info:
		# OFFフラグの指定あり
		obj.set_meta("off", obj_info["off"])
	if "state" in obj_info:
		# STATEの指定あり
		obj.set_meta("state", obj_info["state"])
	
	# 隠しオブジェクトかどうか	
	obj.set_meta("hidden", false)
	if "hidden" in obj_info:
		obj.set_meta("hidden", obj_info["hidden"])
	if obj.get_meta("hidden"):
		obj.visible = false # 非表示にする.

# フラグ文字列に対応するフラグ番号を取得する
func bit_to_value(bit_id:String) -> int:
	var tbl = get_sheet("bits")
	if bit_id in tbl:
		return int(tbl[bit_id]["value"])
	else:
		return -1

# フラグ文字列からフラグが立っているかどうかを調べる
func bit_chk(bit_id:String) -> bool:
	var v = bit_to_value(bit_id)
	if v < 0:
		return false
	return Global.bit_chk(v)

# 変数文字列に対応する変数番号を取得する
func var_to_value(var_id:String) -> int:
	var tbl = get_sheet("vars")
	if var_id in tbl:
		return int(tbl[var_id]["value"])
	else:
		return -1
# 変数文字列から値を取得する
func var_get(var_id:String):
	var v = var_to_value(var_id)
	if v < 0:
		return 0
	return Global.var_get(v)
# 変数文字列から値を設定する
func var_set(var_id:String, value) -> void:
	var v = var_to_value(var_id)
	if v < 0:
		return
	Global.var_set(v, value)
