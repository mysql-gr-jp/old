# MySQL dump 8.13
#
# Host: localhost    Database: nss_mysql
#--------------------------------------------------------
# Server version	3.23.37-Max-log

#
# Table structure for table 'groups'
#

DROP TABLE IF EXISTS groups;
CREATE TABLE groups (
  group_id int(11) NOT NULL auto_increment,
  group_name varchar(30) default NULL,
  status char(1) NOT NULL default 'N',
  PRIMARY KEY  (group_id)
) TYPE=MyISAM;

#
# Dumping data for table 'groups'
#

INSERT INTO groups (group_id, group_name, status) VALUES (1,'nssmysql','A');

#
# Table structure for table 'user'
#

DROP TABLE IF EXISTS user;
CREATE TABLE user (
  user_id int(11) NOT NULL auto_increment,
  user_name text NOT NULL,
  realname varchar(32) NOT NULL default '',
  shell varchar(20) NOT NULL default '/bin/bash',
  password varchar(40) NOT NULL default '',
  status char(1) NOT NULL default 'N',
  uid int(11) NOT NULL default '0',
  homedir varchar(20) NOT NULL default '/dev/null',
  PRIMARY KEY  (user_id)
) TYPE=MyISAM;

#
# Dumping data for table 'user'
#

INSERT INTO user (user_id, user_name, realname, shell, password, status, uid, homedir) VALUES (1,'hoho','hoho hoho','/bin/bash','hoppfcCGi9P8I','A',1000,'/dev/null');

#
# Table structure for table 'user_group'
#

DROP TABLE IF EXISTS user_group;
CREATE TABLE user_group (
  user_id int(11) NOT NULL default '0',
  group_id int(11) NOT NULL default '0'
) TYPE=MyISAM;

#
# Dumping data for table 'user_group'
#

INSERT INTO user_group (user_id, group_id) VALUES (1,1);


