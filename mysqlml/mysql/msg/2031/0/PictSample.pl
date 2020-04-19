#!/usr/local/bin/perl

#
# ���ʥ����� ���ʥ���ݡ���
#
# $ARGV[1,,n]	: ������HTML�ե�����(ʣ����)
#
# @Author = Shogo Hamamoto 15/Apr/2000

use File::Basename;
use DBI;

# �ѥ�᥿
my $filter		= " perl -n -p -e 's/\r/\n/g' | nkf -e |";	# DOS���Ԥ�ShiftJIS����С���
my $dbi			= "mysql";									# DBMS̾
my $database	= "XXXXXXXX"								# DB̾
my $host		= "xxxxxxxxxxx";							# DB�ۥ���̾
my $user		= "xxxxxxxx";								# DB�桼��̾
my $pass		= "xxxxxx";									# �ѥ����
my $table		= "Items";									# ���ʥơ��֥�̾
my $scale		= "1/4";									# ���ࡦ�ͥ���ν̾�������

# STDIN����¸
open(SAVEIN, ">&STDIN");
close(STDIN);

# DB��³
my $dbh = DBI->connect("DBI:$dbi:$database:$host", $database, $pass);
my $sth = $dbh->prepare(q{INSERT INTO $table VALUES (?, ?, ?, ?)}) || die $dbh->errstr;

# ���ʥ������ѡ���
while ($ARGV = shift){
	my($base, $path, $type) = fileparse($ARGV, '\.htm');
	my $ItemCode = $base;
	
	open(STDIN, "cat $ARGV | $filter");
	while(<STDIN>){
		if (/^<H2>��(.*)<BR>$/){				# ����̾
			my $ItemName = $1;
		}elsif (/^<IMG SRC="(\S*)">$/){		# ���ʲ����ե�����̾
			my $ItemPictureFileName = $1;
		}elsif (/^<H3>����������<BR>$/){		# ��������
			my $ItemInfo = &ParseItemInfo();
		}
	}
	close(STDIN);
	print "���ʥ�����:$ItemCode\n����̾:$ItemName\n�ե�����̾:$ItemPictureFileName\n�Ҳ�:$ItemInfo\n";
	
	# ���ʲ����ե�������ɤ߹���
	open(PICT, "$path$ItemPictureFileName")  || die "���ʲ����ե����륪���ץ�";
	my $pict = "";
	my $w;
	while(<PICT>){
		read(PICT, $w, 300000);
		$pict = $pict.$w;
	}
	close(PICT);
	
	# ���ʲ����ե����뤫�饵�ࡦ�ͥ������
	my $thumb = "";
	open(PICT, "djpeg -pnm -scale $scale $path$ItemPictureFileName | cjpeg |") || die "���ʲ����ե����륪���ץ�";
	while(<PICT>){
		read(PICT, $w, 300000);
		$thumb = $thumb.$w;
	}
	close(PICT);
	
	# DB�񤭹���
	$sth->execute($ItemCode, $ItemName, $pict, $ItemInfo, $thumb) || die $dbh->errstr;
}

# DB����
$dbh->disconnect;

#end;

sub ParseItemInfo{
	my $ItemInfo;

	<STDIN>; # 1�Զ��ɤ�
	$_ = <STDIN>;
	chop;
	$ItemInfo = $_;
	$_ = <STDIN>;
	while(not(/^<H3>���������±��屡����<BR>$/)){
		if (not(/^<BR>$/)){
			$ItemInfo = $ItemInfo."\n".$_;
		}
		$_ = <STDIN>;
	}
	$ItemInfo;
}

