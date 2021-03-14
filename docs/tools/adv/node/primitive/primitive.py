#!/usr/bin/env python
# -*- coding: utf-8 -*-

import re
from code import Code

def parsePrivitiveSettings(filename):
	""" 組み込み関数の設定ファイルを読み込む """
	ret = {}
	f = open(filename, "r", encoding='utf_8')
	for line in f:
		line = line.strip()
		line = re.sub(r'//.+', '', line) # コメントを削除
		if len(line.strip()) == 0:
			# コメント行
			continue

		p = PrimitiveSettings(line)
		ret[p.name] = p
	f.close()

	return ret

class PrimitiveSettings:
	""" 組み込み関数の設定情報 """
	def __init__(self, line):
		data = line.split(",")
		if len(data) == 1:
			raise ValueError("define_functions.h に命令コードが指定されていません")
		self.name = data[0].strip() # 0番目は関数名
		self.code = data[1].strip() # 1番目は命令コード
		self.params = [] # 引数リスト
		self.count = 0 # 引数の数
		self.count_max = 0 # 最大引数の数
		for d in data[2:]:
			d = d.strip()
			info = {} # 引数情報
			info["default"] = None
			if d == "":
				# 引数なし
				self.count_max = -1
			elif '=' in d:
				# デフォルト引数あり
				p = d.split('=')
				info["key"] = p[0].strip()
				try:
					info["default"] = float(p[1])
				except:
					info["default"] = p[1].replace('"', '') # 文字列引数
			else:
				info["key"] = d
				self.count += 1
			self.count_max += 1
			# 引数リストに追加
			self.params.append(info)

class Primitive:
	""" 構文木 組み込み命令クラス """
	def __init__(self, settings, paramList):
		self.settings = settings
		self.name = settings.name
		self.paramList = paramList
		count = len(self.paramList)
		if count < settings.count or settings.count_max < count:
			# 引数が正しくない
			raise Exception("Error: %s() invalid parameter count. need [%d] but [%d]"%(self.name, settings.count, count))
		self.count = count

	def run(self, writer):
		# 引数をスタックに積む (逆順)
		for i in range(self.settings.count_max-1, -1, -1):
			if i >= self.count:
				# デフォルトパラメータを使用する
				param = self.settings.params[i]
				val = param["default"]
				try:
					if val.is_integer():
						# 整数値
						val = int(val)
						writer.writeString(Code.CODE_INTEGER)
						writer.writeString(val)
						writer.writeLog("数値, %d"%val)
						writer.writeCrlf()
					else:
						# 小数値
						writer.writeString(Code.CODE_FLOAT)
						writer.writeString(val)
						writer.writeLog("小数値, %d"%val)
						writer.writeCrlf()
				except:
					# 文字列
					writer.writeString(Code.CODE_STRING)
					writer.writeString(val)
					writer.writeLog("文字列, %s"%val)
					writer.writeCrlf()
			else:
				node = self.paramList[i]
				node.run(writer)
		# 命令コード書き込み
		writer.writeString(self.settings.code)
		log = self.settings.code
		writer.writeLog(log)
		writer.writeCrlf()
	def getInstance():
		""" インスタンスの生成 """
		return None
	getInstance = staticmethod(getInstance)