# ===============================
# ADV共通
# ===============================
extends Node

class_name AdvUtilObj

# 無効なアイテムID
const ITEM_INVALID = 0

enum eDir {
	DOWN  = 0,
	LEFT  = 1,
	RIGHT = 2,
	UP    = 3,
}

enum eItemState {
	NONE, # 未所持
	HAS,  # 所持している
	DEL,  # 削除した
}

# ----------------------------
# アイテム関連
# ----------------------------
func item_add(idx:int, is_play_se:bool=true) -> bool:
	if item_has(idx):
		return false # すでに所持している
	
	if is_play_se:
		# TODO: アイテム獲得SEの再生
		pass
	
	item_set_state(idx, eItemState.HAS)
	item_equip(idx) # 自動で装備する
	
	return true

func item_all_none() -> bool:
	for i in range(AdvConst.MAX_ITEM):
		if item_get_state(i) != eItemState.NONE:
			return false # 何かアイテムを取得済み
	return true

func item_no_have_any() -> bool:
	return item_count() == 0

func item_cdb_search(idx:int, key:String):
	var data = CastleDB.search_from_value("items", idx)
	var ret = data.get(key, null)
	if key == "flag":
		return CastleDB.bit_to_value(ret)
	else:
		return ret

# 指定のアイテムを装備しているかどうか
func item_chk(idx:int) -> bool:
	return Global.var_get(Adv.eVar.ITEM) == idx

# 装備を外す
func item_unequip() -> void:
	Global.var_set(Adv.eVar.ITEM, AdvConst.ITEM_INVALID)

# 2つのアイテムをクラフトチェック
func item_check_craft(itemID1:int, itemID2:int) -> int:
	var lines = CastleDB.get_sheet("items")
	for item in lines.values():
		var craft_flag = item.get("craft_flag", "")
		if CastleDB.bit_chk(craft_flag) == false:
			# まだフラグが立っていないのでクラフトできない
			continue
	
		var materials = item.get("materials", null)
		if materials == null:
			# 素材の定義がない
			continue

		var cnt = 0
		for material in materials:
			var item_id = material.get("material", "")
			var item2 = CastleDB.search("items", item_id)
			var v = item2.get("value", ITEM_INVALID)
			if v == itemID1 or v == itemID2:
				cnt += 1
				if cnt >= 2:
					# クラフトできた
					return item.get("value")

	# クラフトできなかった
	return ITEM_INVALID;

func item_count() -> int:
	var ret = 0
	for i in range(AdvConst.MAX_ITEM):
		if item_has(i):
			ret += 1
	
	return ret

func item_del(idx:int) -> bool:
	if item_has(idx):
		# 削除可能
		item_set_state(idx, eItemState.DEL)
		if item_chk(idx):
			# 装備していたら外す
			item_unequip()
		
		return true
	return false

func item_del_all() -> void:
	for i in range(AdvConst.MAX_ITEM):
		item_del(i)

func item_equip(idx:int) -> bool:
	if item_has(idx):
		# 装備可能
		Global.var_set(Adv.eVar.ITEM, idx)
		return true
	
	return false

func item_get_state(idx:int) -> int:
	if idx < ITEM_INVALID or AdvConst.MAX_ITEM <= idx:
		return eItemState.NONE
	
	return Global.item_get(idx)

func item_has(idx:int) -> bool:
	return item_get_state(idx) == eItemState.HAS

func item_remove(idx:int) -> bool:
	if item_del(idx):
		# 削除できた
		item_set_state(idx, eItemState.None)
		return true
	return false

func item_set_state(idx:int, state:int) -> void:
	if idx < ITEM_INVALID or AdvConst.MAX_ITEM <= idx:
		return
	
	Global.item_set(idx, state)
