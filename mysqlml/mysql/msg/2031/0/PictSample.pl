#!/usr/local/bin/perl

#
# 商品カタログ 商品インポート
#
# $ARGV[1,,n]	: カタログHTMLファイル(複数可)
#
# @Author = Shogo Hamamoto 15/Apr/2000

use File::Basename;
use DBI;

# パラメタ
my $filter		= " perl -n -p -e 's/\r/\n/g' | nkf -e |";	# DOS改行とShiftJISコンバート
my $dbi			= "mysql";									# DBMS名
my $database	= "XXXXXXXX"								# DB名
my $host		= "xxxxxxxxxxx";							# DBホスト名
my $user		= "xxxxxxxx";								# DBユーザ名
my $pass		= "xxxxxx";									# パスワード
my $table		= "Items";									# 商品テーブル名
my $scale		= "1/4";									# サム・ネイルの縮小サイズ

# STDINの保存
open(SAVEIN, ">&STDIN");
close(STDIN);

# DB接続
my $dbh = DBI->connect("DBI:$dbi:$database:$host", $database, $pass);
my $sth = $dbh->prepare(q{INSERT INTO $table VALUES (?, ?, ?, ?)}) || die $dbh->errstr;

# 商品カタログパース
while ($ARGV = shift){
	my($base, $path, $type) = fileparse($ARGV, '\.htm');
	my $ItemCode = $base;
	
	open(STDIN, "cat $ARGV | $filter");
	while(<STDIN>){
		if (/^<H2>■(.*)<BR>$/){				# 商品名
			my $ItemName = $1;
		}elsif (/^<IMG SRC="(\S*)">$/){		# 商品画像ファイル名
			my $ItemPictureFileName = $1;
		}elsif (/^<H3>○製品説明<BR>$/){		# 商品説明
			my $ItemInfo = &ParseItemInfo();
		}
	}
	close(STDIN);
	print "商品コード:$ItemCode\n商品名:$ItemName\nファイル名:$ItemPictureFileName\n紹介:$ItemInfo\n";
	
	# 商品画像ファイルの読み込み
	open(PICT, "$path$ItemPictureFileName")  || die "商品画像ファイルオープン";
	my $pict = "";
	my $w;
	while(<PICT>){
		read(PICT, $w, 300000);
		$pict = $pict.$w;
	}
	close(PICT);
	
	# 商品画像ファイルからサム・ネイルを作る
	my $thumb = "";
	open(PICT, "djpeg -pnm -scale $scale $path$ItemPictureFileName | cjpeg |") || die "商品画像ファイルオープン";
	while(<PICT>){
		read(PICT, $w, 300000);
		$thumb = $thumb.$w;
	}
	close(PICT);
	
	# DB書き込み
	$sth->execute($ItemCode, $ItemName, $pict, $ItemInfo, $thumb) || die $dbh->errstr;
}

# DB切断
$dbh->disconnect;

#end;

sub ParseItemInfo{
	my $ItemInfo;

	<STDIN>; # 1行空読み
	$_ = <STDIN>;
	chop;
	$ItemInfo = $_;
	$_ = <STDIN>;
	while(not(/^<H3>○包装／病院医院価格<BR>$/)){
		if (not(/^<BR>$/)){
			$ItemInfo = $ItemInfo."\n".$_;
		}
		$_ = <STDIN>;
	}
	$ItemInfo;
}

