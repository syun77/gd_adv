#! /usr/bin/env python
# -*- coding: utf-8 -*-

import os
import sys
import glob
import platform

# macOS環境でのコンバートかどうか
FOR_MAC_ENABLE = (platform.system() == 'Darwin') # macOS環境かどうか

if FOR_MAC_ENABLE:
	PYTHON_APP = "python3"
else:
	PYTHON_APP = "python"

def usage():
	print("Usage: _conv.py [gmadv.py] [define_functions.h] [define_consts.txt] [input_dir] [output_dir]")

def main(tool, fFuncDef, fDefines, inputDir, inputFile, outDir):
	
	# Win環境は区切り文字が "\" なので "/" に置き換える
	tool      = tool.replace("\\", "/")
	inputDir  = inputDir.replace("\\", "/")
	inputFile = inputFile.replace("\\", "/")
	outDir    = outDir.replace("\\", "/")
	
	# *.advを取得
	if inputFile == "None":
		# フォルダ指定
		print("folder")
		advList = glob.glob("%s*.adv"%inputDir)
	else:
		# ファイル指定
		print("file")
		advList = [inputFile]
	
	print("--------------------------------------")
	print("tool: %s"%tool)
	print("fFuncDef:  %s"%fFuncDef)
	print("fDefines:  %s"%fDefines)
	print("inputDir:  %s"%inputDir)
	print("inputFile: %s"%inputFile)
	print("outDir:    %s"%outDir)
	print("--------------------------------------")

	for adv in advList:
		adv = adv.replace("\\", "/") # Win環境は区切り文字が￥なので置き換える
		fInput = adv
		PREFIX = "adv" # 数値始まりのファイルは GM:S で読み込めないのでプレフィクスをつける.
		fOut   = outDir + PREFIX + os.path.basename(adv).replace(".adv", ".csv")

		cmd = PYTHON_APP + " %s %s %s %s %s"%(
			tool, fFuncDef, fDefines, fInput, fOut)
		print("%s"%fInput)
		os.system(cmd)
		print("--------------------------------------")
		
		# ログを削除する
		fLog = fOut + ".log"
		if os.path.exists(fLog):
			os.remove(fLog)

if __name__ == '__main__':
	args = sys.argv
	argc = len(sys.argv)
	if argc < 7:
		# 引数が足りない
		print(args)
		print("Error: Not enough parameter. given=%d require=%d"%(argc, 7))
		usage()
		quit()

	# ツール
	tool = args[1]
	# 関数定義
	fFuncDef = args[2]
	# 定数定義
	fDefines = args[3]
	# 入力フォルダ
	inputDir = args[4]
	# 入力ファイル
	inputFile = args[5]
	# 出力フォルダ
	outDir = args[6]

	main(tool, fFuncDef, fDefines, inputDir, inputFile, outDir)
