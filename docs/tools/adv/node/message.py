#!/usr/bin/env python
# -*- coding: utf-8 -*-

from node.node import Node
from code import Code
import re

""" 構文木メッセージクラス """
class Message(Node):
	def __init__(self, message):
		# TODO: フォーマットチェック
		prefix = message[0]
		suffix = message[len(message)-1]
		if suffix == "/":
			# 改ページ記号がある
			self.pagefeed = 1
			message = message[:len(message)-1]
		elif suffix == "@":
			# クリック待ちがある
			self.pagefeed = 2
			message = message[:len(message)-1]
		elif prefix == ":":
			# 通知メッセージ
			self.pagefeed = 9
			message = message[1:]
		else:
			self.pagefeed = False
		
		# 話者名チェック
		name = None
		face = None
		if prefix == "[":
			# 話者名の指定がある
			m = re.match(r'[\[].+[\]]', message)
			if m != None:
				message = message.replace(m.group(), "")
				name = re.sub(r'[\[\]]', "", m.group())
				idx = name.find(":")
				if idx >= 0: # [話者名:顔ID]
					splitStr = name.split(":")
					name = splitStr[0]
					face = splitStr[1]
		
		self.message = message
		self.name = name
		self.face = face
		
	def run(self, writer, is_write_message=True):
		""" メッセージ命令書き込み
		# [opecode, 改ページフラグ, 文字列]
		# [1,       1,           ?]
		# = 2+?byte
		"""
		
		if self.face != None:
			# 顔ウィンドウ表示
			writer.writeString(Code.CODE_FACE)
			writer.writeString(self.face)
			writer.writeLog("顔ウィンドウ, %s"%(self.face))
			writer.writeCrlf()
			
		if self.name != None:
			# 話者名書き込み
			writer.writeString(Code.CODE_NAME)
			writer.writeString(self.name)
			writer.writeLog("話者名, %s"%(self.name))
			writer.writeCrlf()
		
		if is_write_message == False:
			# "[MESSAGE]" コマンドは描画しない
			return self.message # 呼び出し側で書き込む

		writer.writeString(Code.CODE_MESSAGE)
		if self.pagefeed == 1:
			ff = Code.MSG_FF
		elif self.pagefeed == 2:
			ff = Code.MSG_CLICK
		elif self.pagefeed == 9:
			ff = Code.MSG_NOTICE
		else:
			ff = Code.MSG_NEXT
		writer.writeString(ff)
		writer.writeString(self.message)
		writer.writeLog("メッセージ, %d, %s"%(self.pagefeed, self.message))
		writer.writeCrlf()
