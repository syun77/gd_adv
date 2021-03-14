#!/usr/bin/env python
# -*- coding: utf-8 -*-

""" 構文木小数値クラス """
from node.node import Node
from code import Code

class Float(Node):
	def __init__(self, value):
		try:
			self.value = float(value)
		except:
			raise Exception("Error: Illigal parameter. ->%s"%value)
	def getValue(self):
		return self.value
	def run(self, writer):
		""" 小数値命令書き込み
		# [opecode, 数値]
		# [1,       4]
		# = 5byte
		"""
		writer.writeString(Code.CODE_FLOAT)
		writer.writeString(self.value)
		writer.writeLog("小数値, %f"%self.value)
		writer.writeCrlf()
		
