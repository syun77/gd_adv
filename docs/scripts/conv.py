#! /usr/bin/env python
# -*- coding: utf-8 -*-

import os
import sys
import re
import glob
import shutil
import platform

ROOT = os.path.abspath(os.path.dirname(__file__))
os.chdir(ROOT)

# 出力データのルート
DATA_ROOT = os.path.abspath(ROOT + "/../../datafiles/data/") + "/"

# macOS環境でのコンバートかどうか
FOR_MAC_ENABLE = (platform.system() == 'Darwin') # macOS環境かどうか

# ・CastleDBファイル
PATH_SRC_CDB = DATA_ROOT + "data.cdb"

if FOR_MAC_ENABLE:
	# GM:S2がデバッグ実行するときの Included Files フォルダの場所
	DIR_YOYO_RUNNER = os.environ["HOME"] + "/Library/Application Support/com.yoyogames.macyoyorunner/game/assets/data/"
	# ・ADVフォルダ
	DIR_ADV = DIR_YOYO_RUNNER + "adv/"
	DIR_DST_CDB = DIR_YOYO_RUNNER + ""
	
	PYTHON_APP = "python3"
else:
	PYTHON_APP = "python"

def usage():
	print("Usage: conv.py [inputDir]")

def execute(root, inputDir, inputFile="None"):
	
	if inputFile is "None":
		print("======================================")
		print("Convert: %s"%inputDir)
		print("======================================")
	else:
		print("======================================")
		print("Convert: %s"%inputFile)
		print("======================================")
		
	# ツール
	tool = "%s/../tools/adv/gmadv.py"%(root)
	# 関数定義
	funcDef = "%s/common/define_functions.h"%(root)
	# 定数定義
	defines = "%s/common/const_header.txt"%(root)

	# 入力フォルダ
	inputDir = "%s/%s/"%(root, inputDir)

	# 出力フォルダ
	outDir = DATA_ROOT + "adv/"
	
	# 入力フォルダをカレントディレクトリに設定
	os.chdir(inputDir)

	target = inputFile
	
	# ■cdbから定数ヘッダを出力
	cmd = PYTHON_APP + " ../_convCdbHeader.py " + PATH_SRC_CDB
	os.system(cmd)
	
	# ■スクリプトコンバート
	cmd = PYTHON_APP + " ../_conv.py %s %s %s %s %s %s"%(
		tool, funcDef, defines, inputDir, target, outDir)
	os.system(cmd)
	
	if FOR_MAC_ENABLE:
		# MacOSX環境用.
		# デバッグ実行環境に直接 *.csv をコピーする (ホットリロード対応)
		if os.path.exists(DIR_ADV):
			# フォルダが存在するのでいったん削除
			shutil.rmtree(DIR_ADV)
		shutil.copytree(outDir, DIR_ADV)
		
		# data.cdb もコピーする
		shutil.copy(PATH_SRC_CDB, DIR_DST_CDB)


def main(inputDir, inputFile):
	# ルートディレクトリ取得
	root = os.path.dirname(os.path.abspath(__file__))
	
	# 指定のフォルダのみをコンバートする
	execute(root, inputDir, inputFile)
	
if __name__ == '__main__':
	args = sys.argv
	argc = len(sys.argv)
	if argc < 2:
		# 引数が足りない
		print(args)
		print("Error: Not enough parameter. given=%d require=%d"%(argc, 2))
		usage()
		quit()

	# 対象フォルダ
	inputDir = args[1]

	# 入力ファイル
	inputFile = "None"
	if argc == 3:
		inputFile = args[2]

	main(inputDir, inputFile)
