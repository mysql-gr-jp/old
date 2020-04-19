#!/bin/sh

MYSQL="mysql -AB"  ;  # mysql���ޥ�ɤλ��ꡣ�ѥ����̤äƤ��ʤ������ѹ�
MYOPT=""

ECHO=/bin/echo ; # echo -n ���Ǥ��� echo ���ޥ�ɤλ���
SED=sed        ; # sed -e ���Ǥ��� sed ���ޥ�ɤλ���

FIX=0

MAXLEN=3  ; # max ujis EUC-JP char length

TABCODE=`$ECHO -n -e '\011'` ; #TAB 0x09

TMPF=/tmp/__mysql_change_char_len.tmp.$$

#########################################
# getopts ���Ȥ��ʤ�shell�����뤫��
parse_arg()
{
    userflag=0 ; hostflag=0 ; portflag=0; socketflag=0
    for arg do
       if [ 1 = $userflag ]; then  MYOPT="$MYOPT -u$arg" ; userflag=0 ; continue; fi
       if [ 1 = $hostflag ]; then  MYOPT="$MYOPT -h$arg" ; hostflag=0 ; continue; fi
       if [ 1 = $portflag ]; then  MYOPT="$MYOPT -P$arg" ; portflag=0 ; continue; fi
       if [ 1 = $socketflag ]; then  MYOPT="$MYOPT -S$arg" ; socketflag=0 ; continue; fi
       case "$arg" in
	    --fix) FIX=1 	        ;;
            --sjis) MAXLEN=2            ;;
            --user=*) a=${arg#--user=} ;     MYOPT="$MYOPT -u$a" ; userflag=0    ;;
            -u?*)     a=${arg#-u} ;          MYOPT="$MYOPT -u$a" ; userflag=0    ;;
            -u)                                                    userflag=1    ;;
            --password=*) a=${arg#--password=} ; MYOPT="$MYOPT -p$a"  ;;
            -p*)          a=${arg#-p}          ; MYOPT="$MYOPT -p$a"  ;;
            --host=*) a=${arg#--host=} ; MYOPT="$MYOPT -h$a" ;  hostflag=0 ;;
            -h?*)     a=${arg#-h}      ; MYOPT="$MYOPT -h$a" ;  hostflag=0 ;;
            -h)                                                 hostflag=1 ;;
            --port=*) a=${arg#--port=} ; MYOPT="$MYOPT -P$a" ;  portflag=0 ;;
            -P?*)     a=${arg#-P}      ; MYOPT="$MYOPT -P$a" ;  portflag=0 ;;
            -P)                                                 portflag=1 ;;
            --socket=*) a=${arg#--socket=} ; MYOPT="$MYOPT -S$a" ;  socketflag=0 ;;
            -S?*)       a=${arg#-S}        ; MYOPT="$MYOPT -S$a" ;  socketflag=0 ;;
            -S)                                                     socketflag=1 ;;
	    --help) phelp
	        exit 0;
	        ;;
       esac
    done
}

#=============================
phelp()
{
   cat <<EOF

  $0 [--user=user_name|-uuser_name|-u user_name] [--password=passwd|-ppasswd] [--fix]

  --fix :  fix char(N) -> char(M). if not set this, $0 check table only

EOF
}




#########################################
#########################################
parse_arg "$@"

MY="$MYSQL $MYOPT"

#============================
V=`$MY -N -e 'SELECT VERSION()'`

case "$V" in
   *3.*|*4.0*)
       echo "you should not run this program on $V"
       exit 0;
esac

#============================
# mysql �ʳ��Υǡ����١����ˤĤ��� loop

for db in `$MY -N -e 'SHOW DATABASES'`
do
   if [ "mysql" = $db ]; then
      continue
   fi
   echo
   echo "====== $db ======="

   #=====================
   #  loop : table

   header=1

   $MY $db -e 'SHOW TABLE STATUS' | \
   while read line
   do
      OIFS=$IFS
      IFS="$TABCODE" ; # TAB
      set $line  ;  # store tab separated values into $1,$2...
      IFS=$OIFS

      #--- 1���ܤ򸫤ơ�Name, Version �Υե�����ɤΰ��֤��Τ�. �ǽ��1���ܤΤ�
      if [ 1 = $header ]; then
	 cname=0  ;  cversion=0  ; i=1
         while [ $# -gt 0 ]
         do
            case "$1" in
              [Nn][aA][mM][eE])  cname=$i ;;
              [Vv][eE][rR][sS][iI][oO][nN])  cversion=$i ;;
            esac
            if [ $cname -gt 0 ] && [ $cversion -gt 0 ]; then  break; fi
            shift
            i=`expr $i + 1`
         done

         if [ $cname -eq 0 ] || [ $cversion -eq 0 ]; then
            echo 'cant find Name,Version column when SHOW TABLE STATUS. exit.'
            exit
         fi

         header=0
         continue
      fi


      #---- 2���� �ʹ� ------------
      # �ơ��֥�̾�� frm �С����������
      tablename="" ;   version=""  ;    i=1
      while [ $# -gt 0 ]
      do
	 if [ $i -eq $cname ]; then     tablename="$1";   fi
	 if [ $i -eq $cversion ]; then  version="$1"  ;   fi
         if [ "x$tablename" != "x" ] && [ "x$version" != "x" ]; then      break;     fi
         shift
         i=`expr $i + 1`
      done

      if [ "x$tablename" = "x" ] || [ "x$version" = "xNULL" ]; then
         echo "  ... BAD TABLE $tablename. skip."
         echo
         continue
      fi


      #-------
      if [ $version -lt 9 ]; then
         echo "  ----- $tablename : $version -----"

         changeline=""

         #-- SHOW CREATE TABLE �� mysql -e �Ǽ¹Ԥ��ƥ�����쥯�Ȥ���ȡ����Ԥ� \n �ˤʤäƤ��뤿�ᡢsed.
         #-- wile read �γ����ͤ���äƤ��������Τǡ�fd 9 �˰��ä�����

         $MY -N $db -e "SHOW CREATE TABLE $tablename" | $SED -e "s@\\\\n@\n@g" -e 's/`//g' > $TMPF
exec 9<&0 < $TMPF
         while read field cinfo
         do
            case "$cinfo" in
                 *[cC][hH][aA][rR]\(*\)*)
                     len=`echo $cinfo | $SED -e 's/.*[cC][hH][aA][rR](\([0-9]*\)).*/\1/'`
                     newlen=`expr $len \* $MAXLEN + $MAXLEN - 1`
                     if [ $newlen -gt 255 ]; then   newlen=255;    fi

                     cmd=`echo $cinfo | $SED -e "s/[cC][hH][aA][rR]([0-9]*)/CHAR($newlen)/" -e 's/,$//'`

                     if [ "x$changeline" != "x" ]; then
                        changeline="$changeline ,"
                     fi

                     changeline="$changeline CHANGE $field $field $cmd"

echo "        C: $field $cinfo -> $cmd"
                     ;;
            esac
         done
exec 0<&9 9<&-
rm $TMPF

         if [ "x$changeline" != "x" ]; then
            echo "    ALTER TABLE $tablename $changeline"
            if [ 1 = $FIX ]; then
               $MY $db -e "ALTER TABLE $tablename $changeline"
            fi
            echo
         fi
      fi
      #----------

   done
   #=== loop : table ===

done


