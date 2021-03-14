#!/usr/bin/env python
# -*- coding: utf-8 -*-

class TokenType:
	""" トークンの種類定義 """
	INT      = 'INT'    # 数値
	FLOAT    = 'FLOAT'  # 小数値
	STRING   = 'STRING' # 文字列
#	LABEL    = 258 # ラベル・ファンクション
	BIT      = 'BIT' # フラグ (%100とか)
	VAR      = 'VAR' # 変数（$100とか）
	QUOTES   = 'QUOTES' # '"' で囲まれた文字列
	IADD     = '+=' # += 加算
	ISUB     = '-=' # -= 減算
	IMUL     = '*=' # *= 乗算
	IDIV     = '/=' # /= 除算
	TRUE     = 'TRUE' # 真
	FALSE    = 'FALSE' # 偽
	LESS     = '<=' # <=
	GREATER  = '>=' # >=
	EQ       = '==' # ==
	NE       = '!=' # !=
	AND      = '&&' # &&
	OR       = '||' # ||
	CRLF     = 'CRLF' # 改行
	IF       = 'IF' # if
	ELSE     = 'ELSE' # else
	ELIF     = 'ELIF' # elif
	WHILE    = 'WHILE' # while
	SELECT   = 'SELECT' # select
	DEF      = 'DEF' # def
	FUNCTION = 'FUNCTION' # function
	GOTO     = 'GOTO' # goto
	CALL     = 'CALL' # call
	RETURN   = 'RETURN' # return
	CONTINUE = 'CONTINUE' # continue
	BREAK    = 'BREAK' # break
	COLOR    = 'COLOR' # #ffffff
	SYMBOL   = 'SYMBOL' # 変数・関数
	LABEL    = 'LABEL' # ラベル
	NS_BIT   = 'eBit' # 名前空間 (フラグ)
	NS_VAR   = 'eVar' # 名前空間 (変数)
	NS_SCENE = 'eScene' # 名前空間 (シーン)
	NS_SYSBIT= 'eSys' # 名前空間 (システムフラグ)ß
