#!/bin/sh
#
# �ⵡǽWeb�����ȹ������� -���󥱡��ȥ����ȹ��ۥ�����ץ�
#  Copyright(C) Yoshimasa Takami
#
# ���Υ�����ץȤ�root�Ǽ¹Ԥ��Ƥ�������
#

# questions�ǡ����١�������
mysqladmin create questions

# questions�ǡ����١�����httpd/nobody�桼����
# ���������Ǥ���褦��������
mysql mysql < set_right.sql

# ������������ȿ��
mysqladmin reload

# www_db�ơ��֥����
mysql questions < cre_www_db.sql

