#!/usr/bin/env python
# -*- coding: utf-8 -*-

""" 構文木文字列クラス """
from node.node import Node
from code import Code

class String(Node):
	def __init__(self, value):
		self.value = value.replace('"', "") # '"' を削除
	def getValue(self):
		return self.value
	def run(self, writer):
		""" 文字列命令書き込み
		# [opecode, 文字列]
		# [1,       4]
		# = 5byte
		"""
		writer.writeString(Code.CODE_STRING)
		writer.writeString(self.value)
		writer.writeLog("文字列, %s"%self.value)
		writer.writeCrlf()
		
