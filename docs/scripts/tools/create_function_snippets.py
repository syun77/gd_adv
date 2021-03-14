#!/usr/bin/env python
# -*- coding: utf-8 -*-

# =======================================
# define_functions.h に定義した関数を
# functions.code-snippets に反映させるスクリプト
# =======================================
import os
import sys
import shlex
import re
import json

# -----------------------------------------------------------
ROOT = os.path.abspath(os.path.dirname(__file__)).replace("¥¥", "/")

# 関数定義ファイル1
PATH_SRC = ROOT + "/../common/define_functions.h"

# 関数ドキュメントファイル
PATH_DOC = ROOT + "/../common/function_docs.txt"

# 出力ファイル
PATH_DST = ROOT + "/../../.vscode/functions.code-snippets"
# -----------------------------------------------------------

# 関数データ
class FunctionData:
	def __init__(self, name, args, comment):
		# コンストラクタ
		self.name    = name    # 関数名
		self.args    = args    # 引数リスト
		self.comment = comment # コメント
		
	def to_body(self):
		str = self.name + "("
		idx = 1
		if len(self.args) >= 1:
			# 引数がある
			for arg in self.args:
				arg = arg.replace('"', '\\"') # ダブルクオートをエスケープする
				str += "${%d:%s}"%(idx, arg)
				if idx < len(self.args):
					str += ", " # 次の引数がある
				idx += 1
		
		str += ")\\n$%d"%idx
		
		return str
	
	def to_string(self):
		# JSON文字列に変換する
		body = self.to_body()
		name = self.comment
		if name == "":
			name = self.name

		str = """	"%s":
	{
		"prefix": "%s",
		"body": "%s",
		"description": "%s",
	},
"""%(name, self.name, body, self.comment)
		return str
	
def parse_docs(path):
	# 関数の説明テキストを解析
	f = open(path, "r", encoding="utf-8")
	docs = {}
	key  = ""
	text = ""
	for line in f.read().split("\n"):
		line = line.strip()
		#if line == "":
		#	continue # 空行はスキップする
		
		if re.match(r'^\*', line):
			if key != "":
				docs[key] = text
				text = ""
			key = line.replace("*", "").strip()
		else:
			text += line + "\\n"
	
	if not key in docs:
		# 未登録であれば最後の項目を追加
		docs[key] = text
	
	f.close()
	return docs

def main():
	
	# ドキュメントファイルを解析
	docs = parse_docs(PATH_DOC)
	
	# 関数定義ファイルを解析
	func_list = []
	fSrc = open(PATH_SRC, encoding="utf-8")
	for line in fSrc.read().split("\n"):
		line = line.strip()
		if line == "":
			continue # 空行
		if re.match(r'^//', line):
			continue # コメント行
		data = list(map(lambda s: s.strip(), line.split(",")))
		
		name = data[0] # 関数名
		args = data[2:] # 引数リスト
		if len(args) >= 1 and args[0] == "":
			args = [] # 無効な引数を除去
		
		# コメント
		comment = ""
		if name in docs:
			comment = docs[name] # コメントの定義があれば取り出す
		
		func = FunctionData(name, args, comment)
		func_list.append(func)
	
	fSrc.close()

	str = "{\n"
	for func in func_list:
		str += func.to_string()
	str += "}"
	
	fDst = open(PATH_DST, "w", encoding="utf-8")
	fDst.write(str)
	fDst.close()
	#print(str)
	
	print("done.")

if __name__ == '__main__':
	main()

