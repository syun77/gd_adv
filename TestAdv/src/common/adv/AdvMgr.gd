extends Node2D

# スクリプト管理
const AdvScript = preload("res://src/common/adv/AdvScript.gd")
# テキスト管理
const AdvTextMgr = preload("res://src/common/adv/AdvTextMgr.gd")

const AdvLayerBg       = preload("res://src/common/adv/AdvLayerBg.gd")
const AdvLayerCh       = preload("res://src/common/adv/AdvLayerCh.gd")
const AdvTalkText      = preload("res://src/common/adv/AdvTalkText.gd")
const AdvTalkTextScene = preload("res://src/common/adv/AdvTalkText.tscn")

# 状態
enum eState {
	INIT,
	EXEC,
	KEY_WAIT,
	SEL_WAIT,
	WAIT,
	OBJ_WAIT,
	FADE_WAIT,
	YIELD,
	YIELD2,
	END,
}

# メッセージの種類
enum eCmdMesType {
	NONE   = 0, # 改行なし
	PF     = 1, # 改行する
	CLICK  = 2, # クリック待ち
	NOTICE = 9, # 通知
}

# 内部管理変数
var _script:AdvScript        = null
var _talk_text:AdvTalkText   = null
var _bg_mgr:AdvLayerBg       = null
var _ch_mgr:AdvLayerCh       = null
var _msg              := AdvTextMgr.new()
var _state            = eState.INIT
var _next_state       = eState.INIT
var _wait             = 0

# プロパティ
var _script_path             = ""
var _start_funcname          = ""

# レイヤー
onready var _layer_bg   = $LayerBg
onready var _layer_talk = $LayerTalk

# 開始
func start(script_path, funcname:String) -> void:
	_script_path    = script_path
	_start_funcname = funcname
	
	# 通知テキストを非表示にしておく	
	AdvNoticeText.end()
	

# 開始処理
func _ready() -> void:
	_script = AdvScript.new(self)
	_talk_text = AdvTalkTextScene.instance()
	_layer_talk.add_child(_talk_text)
	_talk_text.hide()
	_bg_mgr  = AdvLayerBg.new([$AdvLayerBg/BellowBg, $AdvLayerBg/AboveBg])
	_ch_mgr  = AdvLayerCh.new([$AdvLayerCh/LeftCh, $AdvLayerCh/CenterCh, $AdvLayerCh/RightCh])
	
# 更新
func _process(delta: float) -> void:
	
	if AdvConst.DEBUG:
		if Input.is_action_just_pressed("ui_exit"):
			# ESC終了
			get_tree().quit()
	
	match _state:
		eState.INIT:
			_update_init()
		eState.EXEC:
			_update_exec()
		eState.KEY_WAIT:
			_update_key_wait(delta)
		eState.SEL_WAIT:
			_update_sel_wait(delta)
		eState.WAIT:
			_update_wait(delta)
		eState.END:
			# デバッグ用
			#get_tree().change_scene("res://src/common/adv/AdvMgr.tscn")
			queue_free()


	# 背景管理更新
	_bg_mgr.update(delta)
	# キャラ管理更新
	_ch_mgr.update(delta)
	
	if _state != _next_state:
		_state = _next_state

# 更新・初期化
func _update_init():
	if _script.open(_script_path) == false:
		Infoboard.error("スクリプトを開けません: %s"%_script_path)
		# スクリプト終了
		_next_state = eState.END
		return
	
	if _start_funcname != "":
		if _script.jump_funcname(_start_funcname) == false:
			Infoboard.warn("指定の関数が存在しません: %s"%_start_funcname)
			# スクリプト終了
			_next_state = eState.END
			return
		
	_next_state = eState.EXEC

# 更新・実行
func _update_exec():
	_script.update()
	if _script.is_end():
		# スクリプト終了
		_next_state = eState.END

# 更新・キー待ち
func _update_key_wait(delta:float):
	var ret = _talk_text.update_talk(delta, _msg.get_text())
	match ret:
		"SEL_WAIT":
			_next_state = eState.SEL_WAIT
		"EXEC":
			_msg.clear()
			_next_state = eState.EXEC
		_:
			pass # 続行

# 更新・選択肢
func _update_sel_wait(delta:float):
	var ret = _talk_text.update_select(delta, _script)
	match ret:
		"EXEC":
			_msg.clear()
			_next_state = eState.EXEC
		_:
			pass # 続行

# 更新・一時停止
func _update_wait(delta:float):
	_wait -= delta
	if _wait <= 0:
		_next_state = eState.EXEC	

# 背景を表示
func _DRB(_args:PoolStringArray) -> int:
	var id  = _script.pop_stack()
	var eft = _script.pop_stack()
	_bg_mgr.draw_bg(id, eft)
	return AdvConst.eRet.CONTINUE
	
# 背景を消去
func _ERB(_args:PoolStringArray) -> int:
	var eft = _script.pop_stack()
	_bg_mgr.erase_bg(eft)
	return AdvConst.eRet.CONTINUE

# キャラクターを表示
func _DRC(_args:PoolStringArray) -> int:
	var pos = _script.pop_stack()
	var id  = _script.pop_stack()
	var eft = _script.pop_stack()
	_ch_mgr.draw_ch(pos, id, eft)
	
	return AdvConst.eRet.CONTINUE

# キャラクターを消去
func _ERC(_args:PoolStringArray) -> int:
	var pos = _script.pop_stack()
	var eft = _script.pop_stack()
	_ch_mgr.erase_ch(pos, eft)
	
	return AdvConst.eRet.CONTINUE
	
# 顔ウィンドウ表示
func _FACE(args:PoolStringArray) -> int:
	var id = int(args[0])
	_talk_text.draw_face(id)
	return AdvConst.eRet.CONTINUE
	
# 話者名を表示
func _NAME(args:PoolStringArray) -> int:
	_talk_text.set_name(args[0])
	return AdvConst.eRet.CONTINUE
	
# 顔ウィンドウと話者名を消去する
func _CLS(_args:PoolStringArray) -> int:
	_talk_text.erase_face()
	_talk_text.clear_name()
	return AdvConst.eRet.CONTINUE

# メッセージ解析
func _MSG(args:PoolStringArray) -> int:
	var is_exit = false
	var type = eCmdMesType.NONE
	if args[0] != "":
		type = int(args[0])
	if type == eCmdMesType.NOTICE:
		# 通知メッセージ
		AdvNoticeText.start(args[1])
		return AdvConst.eRet.YIELD
	
	var ret = AdvConst.eRet.CONTINUE
	var texts = args[1]
	_msg.add(texts)
	match type:
		eCmdMesType.CLICK:
			# TODO: 未実装
			pass
		eCmdMesType.PF:
			_talk_text.show()
			_talk_text.start()
			_next_state = eState.KEY_WAIT
			ret = AdvConst.eRet.YIELD
	
	return ret

func _WAIT(_args:PoolStringArray) -> int:
	_wait = _script.pop_stack() / 60.0
	_next_state = eState.WAIT
	return AdvConst.eRet.YIELD
	
# 選択肢のメッセージテキスト
func _SEL(args:PoolStringArray) -> int:
	# テキストの行数
	var cnt = int(args[0])
	for i in range(cnt):
		var texts = args[1 + i]
		_msg.add(texts)
	_talk_text.sel_clear()
	return AdvConst.eRet.CONTINUE

func _SEL_ANS(args:PoolStringArray) -> int:
	var cnt = min(int(args[0]), AdvConst.MAX_SEL_ITEM)
	for i in range(cnt):
		var texts = args[1 + i]
		_talk_text.sel_add(i, texts)
	
	return AdvConst.eRet.CONTINUE

func _SEL_ANS2(args:PoolStringArray) -> int:
	var idx = int(args[0])
	var ret = _script.pop_stack()
	if !ret:
		 # 表示条件を満たさなかったので除外する
		_talk_text.set_exclude(idx)
	return AdvConst.eRet.CONTINUE

func _SEL_GOTO(args:PoolStringArray) -> int:
	_talk_text.sel_addr(args)
	
	# テキスト表示→選択肢へ
	_next_state = eState.KEY_WAIT
	_talk_text.show()
	_talk_text.start()
	return AdvConst.eRet.YIELD

func _JUMP_SCENE(_args:PoolStringArray) -> int:
	# シーンジャンプ
	var idx = _script.pop_stack()
	var name = ""
	var data = CastleDB.search_from_value("scenes", idx)
	if data:
		name = data["id"]
	Infoboard.script("[JUMP_SCENE] %s(%d)"%[name, idx])
	Global.next_room = idx
	return AdvConst.eRet.EXIT # 強制終了

# ---------------------------------------
# アイテム関連
# ---------------------------------------
func _ITEM_ADD(_args:PoolStringArray) -> int:
	# アイテム追加
	var item_id = _script.pop_stack()
	var flag = AdvUtil.item_cdb_search(item_id, "flag")
	if flag >= 0:
		# 取得フラグをONにする
		Global.bit_on(flag)
	var name = AdvUtil.item_cdb_search(item_id, "name")
	Infoboard.send("[ITEM_ADD] %s(%d)"%[name, item_id])
	var text = name + Adv.ITEM_GET_MESSAGE
	# 通知テキストを表示
	AdvNoticeText.start(text)
	
	AdvUtil.item_add(item_id)
	return AdvConst.eRet.CONTINUE

func _ITEM_ADD2(_args:PoolStringArray) -> int:
	# アイテム追加
	var item_id = _script.pop_stack()
	var flag = AdvUtil.item_cdb_search(item_id, "flag")
	if flag >= 0:
		# 取得フラグをONにする
		Global.bit_on(flag)
	var name = AdvUtil.item_cdb_search(item_id, "name")
	Infoboard.send("[ITEM_ADD2] %s(%d)"%[name, item_id])
	var text = name + Adv.ITEM_GET_MESSAGE
	
	# 通知テキストは表示しない
	
	AdvUtil.item_add(item_id)
	return AdvConst.eRet.CONTINUE

func _ITEM_HAS(_args:PoolStringArray) -> int:
	# アイテムを所持しているかどうか
	var item_id = _script.pop_stack()
	var has = AdvUtil.item_has(item_id)
	var name = AdvUtil.item_cdb_search(item_id, "name")
	Global.var_set(Adv.eVar.RET, 1 if has else 0)
	var has_str = "true" if has else "false"
	Infoboard.send("[ITEM_HAS] %s(%d): %s"%[name, item_id, has_str])
	return AdvConst.eRet.CONTINUE

func _ITEM_DEL(_args:PoolStringArray) -> int:
	# アイテムを削除する
	var item_id = _script.pop_stack()
	AdvUtil.item_del(item_id)
	var name = AdvUtil.item_cdb_search(item_id, "name")
	Infoboard.send("[ITEM_DEL] %s(%d)"%[name, item_id])
	return AdvConst.eRet.CONTINUE

func _ITEM_DEL_ALL(_args:PoolStringArray) -> int:
	# アイテムをすべて削除する
	AdvUtil.item_del_all()
	Infoboard.send("[ITEM_DEL_ALL]")
	return AdvConst.eRet.CONTINUE

func _ITEM_CHK(_args:PoolStringArray) -> int:
	# アイテムを装備しているかどうか
	var item_id = _script.pop_stack()
	var ret = AdvUtil.item_check(item_id)
	Global.var_set(Adv.eVar.RET, 1 if ret else 0)
	var name = AdvUtil.item_cdb_search(item_id, "name")
	var chk_str = "true" if ret else "false"
	Infoboard.send("[ITEM_CHK] %s(%d): %s"%[name, item_id, chk_str])
	return AdvConst.eRet.CONTINUE

func _ITEM_UNEQUIP(_args:PoolStringArray) -> int:
	# アイテムの装備を外す
	AdvUtil.item_unequip()
	Infoboard.send("[ITEM_UNEQUIP]")
	return AdvConst.eRet.CONTINUE

func _CRAFT_CHK(_args:PoolStringArray) -> int:
	# 合成チェック
	var itemID1 = _script.pop_stack()
	var itemID2 = _script.pop_stack()
	var ret = AdvUtil.item_check_craft(itemID1, itemID2)
	var name1 = AdvUtil.item_cdb_search(itemID1, "name")
	var name2 = AdvUtil.item_cdb_search(itemID2, "name")
	Infoboard.send("[CRAFT_CHK] itemID:(%s, %s) -> %s"%[name1, name2, "true" if ret else "false"])
	Global.var_set(Adv.eVar.RET, ret);
	return AdvConst.eRet.CONTINUE
	
func _ITEM_DETAIL(_args:PoolStringArray) -> int:
	# アイテムの詳細情報を表示する
	var item_id = _script.pop_stack()
	var detail = AdvUtil.item_cdb_search(item_id, "detail")
	if detail == "":
		# 詳細メッセージなし
		return AdvConst.eRet.CONTINUE
	
	AdvNoticeText.start(detail)
	return AdvConst.eRet.CONTINUE
