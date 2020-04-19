#!/bin/sh
#
# 高機能Webサイト構築入門 -アンケートサイト構築スクリプト
#  Copyright(C) Yoshimasa Takami
#
# このスクリプトはrootで実行してください
#

# questionsデータベース作成
mysqladmin create questions

# questionsデータベースへhttpd/nobodyユーザが
# アクセスできるよう権限設定
mysql mysql < set_right.sql

# アクセス権限反映
mysqladmin reload

# www_dbテーブル作成
mysql questions < cre_www_db.sql

