#!/usr/bin/env python
# -*- coding: utf-8 -*-

""" 字句解析モジュール """

import re
import shlex

class LexerReader:
	""" テキスト読み込みクラス """
	DISP_ERROR_LINE = 5 # エラー時に表示する行数 (実際はこの2倍+1行表示する)
	def __init__(self, filepath):
		""" コンストラクタ """
		self.shlex = shlex.shlex(open(filepath, "r", encoding='utf_8'))
		self.shlex.commenters = [] # "//"
		self.token = "dummy"
		self.shlex.whitespace = [" ", "\t"]
		self.filepath = filepath
		self.column = 1 # ソース列番号（トークン単位）
	def read(self):
		""" トークン読み込み """
		self.token = self.shlex.get_token()
		if self.token == '\n':
			self.column = 1
		else:
			self.column += len(self.token)
		return self.token
	def unread(self, token):
		""" トークンを戻す """
		self.shlex.push_token(token)
		self.column -= len(token)
	def isEof(self):
		""" ファイルの終端に達したかどうか """
		return self.token == self.shlex.eof
	def getLineno(self):
		""" 現在の行番号を返す """
		return self.shlex.lineno
	def getColumnNo(self):
		""" 現在の列番号を返す """
		return self.column
	def getFilename(self):
		return self.filepath
	def getLineText(self, lineno=-1):
		""" 現在の行の文字列を返す """
		if lineno == -1:
			no = self.getLineno() - 1
		else:
			no = lineno
		f = open(self.filepath, "r")
		lines = f.readlines()
		nStart = no - self.DISP_ERROR_LINE
		nEnd = no + self.DISP_ERROR_LINE
		ret = ""
		for i in range(nStart, nEnd):
			if i < 0 or i >= len(lines):
				continue

			numstr = "%6d: "%(i+1)
			cursor = "  "
			if i == no:
				cursor = "> "
			ret += cursor + numstr + lines[i]
		f.close()
		return ret


from tokentype import TokenType
class Lexer:
	""" 字句解析クラス """
	def __init__(self, lexReader):
		""" コンストラクタ """
		self.lexReader = lexReader # ファイル読み込みオブジェクト
		self.token  = ""           # トークン
		self.ttype   = 0            # トークンの種類
		self.reserved = { # 予約語テーブル
			"true":   TokenType.TRUE,
			"false":  TokenType.FALSE,
			"and":    TokenType.AND,
			"or":     TokenType.OR,
			"if":     TokenType.IF,
			"else":   TokenType.ELSE,
			"elif":   TokenType.ELIF,
			"while":  TokenType.WHILE,
			"select": TokenType.SELECT,
			"def":    TokenType.FUNCTION,
			"goto":   TokenType.GOTO,
			"call":   TokenType.CALL,
			"return": TokenType.RETURN,
			"continue": TokenType.CONTINUE,
			"break":  TokenType.BREAK,
			"eBit":   TokenType.NS_BIT,
			"eVar":   TokenType.NS_VAR,
			"eScene": TokenType.NS_SCENE,
			"eSys":   TokenType.NS_SYSBIT,
		}
		self.varDefines = { # 変数の定数
		}
		self.bitDefines = { # フラグの定数
		}
		self.sceneDefines = { # シーンの定数
		}
		self.sysbitDefines = { # システムフラグの定数
		}

		self.nsTable = {
			TokenType.NS_BIT:   self.bitDefines,
			TokenType.NS_VAR:   self.varDefines,
			TokenType.NS_SCENE: self.sceneDefines, 
			TokenType.NS_SYSBIT: self.sysbitDefines,
		}
	def fatal(self, msg):
		""" エラー書き込む """
		line = self.getLineText()
		message = "Fatal :%s\n%s"%(msg, line)
		self.writeLog(message)
		raise Exception(message)
	def writeLog(self, msg):
		""" ログ書き込み """
		message = "%s(%d, %d) %s"%(
			self.getFinename(),
			self.getLineno(),
			self.getColumnno(),
			msg)
		print(message)
	def getLineText(self, lineno=-1):
		""" 現在の行の文字列を返す """
		return self.lexReader.getLineText(lineno)
	def getToken(self):
		return self.token
	def getLineno(self):
		return self.lexReader.getLineno()
	def getColumnno(self):
		return self.lexReader.getColumnNo()
	def getFinename(self):
		return self.lexReader.getFilename()
	def unread(self, token):
		""" トークンを戻す """
		self.lexReader.unread(token)
	def advance(self):
		""" 次のトークンに進める """
		token = self.lexReader.read()
		self.token = token
		if self.lexReader.isEof():
			return False
		elif token == "\n":
			self.ttype = TokenType.CRLF
			self.token = token
		elif re.match('"', token):
			if re.match('".+"', token):
				# メッセージ
				self.ttype  = TokenType.QUOTES
				self.token = token
			else:
				# 閉じ忘れメッセージ
				self.fatal("Invalid syntax. no QUOTE corresponding.")
		elif token == '+':
			token = self.lexReader.read()
			if token == '=':
				self.ttype = TokenType.IADD
			else:
				self.ttype = '+'
				self.lexReader.unread(token)
		elif token == '-':
			token = self.lexReader.read()
			if token == '=':
				self.ttype = TokenType.ISUB
			else:
				self.ttype = '-'
				self.lexReader.unread(token)
		elif token == '*':
			token = self.lexReader.read()
			if token == '=':
				self.ttype = TokenType.IMUL
			else:
				self.ttype = '*'
				self.lexReader.unread(token)
		elif token == '/':
			token = self.lexReader.read()
			if token == '=':
				self.ttype = TokenType.IDIV
			elif token == '/':
				# コメント文字列
				while True:
					# 行末まで進める
					token = self.lexReader.read()
					if token == '\n' or self.lexReader.isEof():
						#self.advance()
						self.ttype = TokenType.CRLF
						self.token = '\n'
						break
					
					idx = token.find('\n')
					if idx > -1:
						# コメント中の改行エスケープをエラーにする
						self.fatal("Invalid escape sequence in COMMENT.")
						
			elif token == '*':
				# コメントブロック開始
				while True:
					# コメントブロック終端まで進める
					token = self.lexReader.read()
					if token == '*' or self.lexReader.isEof():
						token = self.lexReader.read()
						if token == '/' or self.lexReader.isEof():
							# 終端に達した
							self.ttype = TokenType.CRLF
							self.token = '\n'
							break
					if re.match('".*[\n].*"', token):
						# 改行エスケープをエラーにする
						self.fatal("Invalid escape sequence in BLOCK COMMENT.")
			else:
				self.ttype = '/'
				self.lexReader.unread(token)
		elif token == '<':
			token = self.lexReader.read()
			if token == '=':
				self.ttype = TokenType.LESS
			else:
				self.ttype = '<'
				self.lexReader.unread(token)
		elif token == '>':
			token = self.lexReader.read()
			if token == '=':
				self.ttype = TokenType.GREATER
			else:
				self.ttype = '>'
				self.lexReader.unread(token)
		elif token == '&':
			token = self.lexReader.read()
			if token == '&':
				self.ttype = TokenType.AND
			else:
				self.fatal("Invalid syntax.")
		elif token == '|':
			token = self.lexReader.read()
			if token == '|':
				self.ttype = TokenType.OR
			else:
				self.fatal("Invalid syntax.")
		elif token == '=':
			token = self.lexReader.read()
			if token == '=':
				self.ttype = TokenType.EQ
			else:
				self.ttype = '='
				self.lexReader.unread(token)
		elif token == '[':
			self.ttype = token
		elif token == ']':
			self.ttype = token
		elif token == '{':
			self.ttype = token
		elif token == '}':
			self.ttype = token
		elif token == '(':
			self.ttype = token
		elif token == ')':
			self.ttype = token
		elif token == ',':
			self.ttype = token
		elif token == '!':
			token = self.lexReader.read()
			if token == '=':
				self.ttype = TokenType.NE
			else:
				self.ttype = '!'
				self.lexReader.unread(token)
		elif re.match("@", token):
			# 文字列リテラル
			token = self.lexReader.read()
			if re.match('".*"', token):
				# メッセージ
				self.ttype = TokenType.STRING
				self.token = token
			else:
				# 閉じ忘れメッセージ
				self.fatal("Invalid syntax. don't string.")

		elif re.match("\d", token):
			nextToken = self.lexReader.read()
			if nextToken == ".":
				next2Token = self.lexReader.read()
				token += nextToken + next2Token
				if re.match("\d", next2Token):
					# 小数値
					self.ttype = TokenType.FLOAT
					self.token = token
				else:
					self.fatal("Error: Illigal NUMBER '%s'"%token) # 正しい数値でない
			else:
				# 整数値
				self.lexReader.unread(nextToken) # 戻す
				if re.match("0x[\dA-Fa-f]+", token):
					# 16進数を10進数に変換する
					token = "%s"%int(token, 16)
				if re.fullmatch('[\d]+', token) == None:
					self.fatal("Error: Illigal NUMBER '%s'"%token) # 数値でない
				self.ttype = TokenType.INT
				self.token = token
		elif re.match("[_a-zA-Z][_a-zA-Z\d]*", token):
			if token in self.reserved:
				# 予約語にマッチ
				self.ttype = self.reserved[token]
				if self.ttype in [TokenType.CALL, TokenType.FUNCTION, TokenType.GOTO]:
					# ファンクション
					token = self.lexReader.read()
					if re.match("[_a-zA-Z][_a-zA-Z\d]*", token):
						self.token = token
					else:
						self.fatal("Error: Illigal LABEL or FUNCTION '%s'"%token)
				elif self.ttype in self.nsTable:
					# 名前空間
					nsTbl = self.nsTable[self.ttype]
					token2 = self.lexReader.read()
					if token2 == ".":
						token3 = self.lexReader.read()
						if token3 in nsTbl:
							self.ttype = TokenType.INT
							self.token = "%d"%nsTbl[token3]
						else:
							self.fatal("Error: Illigal namespace '%s'"%(token+token2+token3))
					else:
						self.fatal("Error: Illigal namespace '%s'"%(token+token2))
				else:
					# それ以外の予約語
					self.token = token
			else:
				nextToken = self.lexReader.read()
				if nextToken == ":":
					# ラベル
					self.ttype = TokenType.LABEL
					self.token = token
				else:
					# シンボル
					self.lexReader.unread(nextToken) # 戻す
					self.ttype  = TokenType.SYMBOL
					self.token = token
		elif token == "#":
			token = self.lexReader.read()
			if re.match("[\da-fA-F]+", token):
				self.ttype  = TokenType.COLOR
				self.token = "#" + token
			else:
				self.fatal("Invalid syntax.")
		elif token == "$":
			token = self.lexReader.read()
			if re.match("\d+", token):
				self.ttype = TokenType.VAR
				self.token = "$"+token
			elif token in self.varDefines: # 定数テーブルから取得
				self.ttype = TokenType.VAR
				self.token = "$%d"%self.varDefines[token]
			else:
				self.fatal("Invalid syntax. %s"%token)
		elif re.match("[\$][\d]+", token):
			self.ttype = TokenType.VAR
			self.token = token
		elif token == "%":
			token = self.lexReader.read()
			if re.match("\d+", token):
				self.ttype = TokenType.BIT
				self.token = "%"+token
			elif token in self.bitDefines: # 定数テーブルから取得
				self.ttype = TokenType.BIT
				self.token = "%%%d"%self.bitDefines[token]
			else:
				self.fatal("Invalid syntax. %s"%token)
		elif re.match("[\%][\d]+", token):
			self.ttype = TokenType.BIT
			self.token = token
		return True

