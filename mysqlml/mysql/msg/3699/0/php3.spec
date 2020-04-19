%define patch_level 2

# anyone update ok :-)
# See [VineSeed-Plus:00193]

# for Vine-2.1 (default)
%{!?RH7:%define contentdir /home/httpd/html}

# for RedHat7
%{?RH7:%define contentdir /var/www}

%{?with_mysql:Requires: MySQL}
%{?with_mysql:BuildRequires: MySQL-devel}

%{?with_pgsql:Requires: postgresql}
%{?with_pgsql:BuildRequires: postgresql-devel}

%{?with_mcrypt:Requires: libmcrypt22}
%{?with_mcrypt:BuildRequires: libmcrypt22-devel}

%define php_mandir manual/php

%define dso_sysconfdir /etc/httpd/conf
%define cgi_sysconfdir /etc/php/cgi

Name: php3
Version: 3.0.18
Release: 0vl2
Summary: PHP: Hypertext Preprocessor
Group: Development/Languages
License: GPL2
Source0: ftp://ftp.happysize.co.jp/php-ja-jp/php-%{version}-i18n-ja-%{patch_level}.tar.gz
#Source0: http://www.php.net/distributions/php-3.0.18.tar.gz
#Source1: http://www.cityfujisawa.ne.jp/~louis/apps/phpfi/patch/php-3.0.18j-patch.tgz
#Source1: http://snaps.php.net/manual/ja/manual-ja-current.tar.gz
#Source2: http://snaps.php.net/manual/en/manual-en-current.tar.gz
Source1: http://www.php.net/manual/ja/manual.tar.gz
#Source2: http://www.php.net/manual/en/manual.tar.gz
Patch: php-3.0.18-i18n-ja-2.zlib.patch.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-root

%description
PHP: Hypertext Preprocessor

%package cgi
Group: Development/Languages
Summary: command-line/cgi version of PHP: Hypertext Preprocessor
%description cgi
command-line/cgi version of PHP: Hypertext Preprocessor

%package manual
Group: Development/Languages
Summary: manual for PHP: Hypertext Preprocessor
%description manual
manual for PHP: Hypertext Preprocessor

%prep
#%setup -q -a 1 -n php-%{version}
#patch -p1 -b --suffix .i18n -s< I18N-ja.diff
%setup -q -n php-%{version}-i18n-ja-%{patch_level}
%patch -p1 -b .zlib

mkdir -p %{php_mandir}/{ja,en}
tar zxf %{SOURCE1} -C %{php_mandir}/ja
#tar zxf %{SOURCE2} -C %{php_mandir}/en
#for i in %{php_mandir}/{ja,en} ; do
#    ln -s manual.html $i/index.html
#done

%build
# info automake
mv aclocal.m4 acinclude.m4
aclocal
autoconf
autoheader
#./buildconf
export CFLAGS="${RPM_OPT_FLAGS}"

## build DSO

mkdir build_DSO
(cd build_DSO

../configure \
--with-apxs=/usr/sbin/apxs \
--with-shared-apache=/etc/httpd \
--with-mod_charset=yes \
--with-gd \
%{?with_mysql:--with-mysql=/usr} \
%{?with_pgsql:--with-pgsql=/usr} \
%{?with_mcrypt:--with-mcrypt} \
%{?with_xml:--with-xml} \
--with-zlib=/usr \
--enable-sysvshm=yes \
--enable-sysvsem=yes \
--with-config-file-path=%{dso_sysconfdir} \
--enable-mbregex \
--enable-safe-mode=yes \
--enable-track-vars=yes \
--enable-magic-quotes=yes \
--enable-debugger=yes \
--enable-bcmath=yes \
--enable-force-cgi-redirect=yes \
--enable-discard-path=yes \
--enable-memory-limit=yes \
--enable-i18n \
--with-gdbm \
--enable-versioning
#--with-system-regex=yes \
#--with-zlib-dir=/usr \

# `/usr/sbin/apxs -q CFLAGS` adds optflags :-<
# This is an example for Vine-2.1
perl -i.bak -p -e 's/-O2 -m486 -fno-strength-reduce//' Makefile */Makefile

make)

## build CGI

mkdir build_CGI
(cd build_CGI
../configure \
--with-mod_charset=yes \
--with-gd \
%{?with_mysql:--with-mysql=/usr} \
%{?with_pgsql:--with-pgsql=/usr} \
%{?with_mcrypt:--with-mcrypt} \
--with-zlib=/usr \
--enable-sysvshm=yes \
--enable-sysvsem=yes \
--with-config-file-path=%{cgi_sysconfdir} \
--enable-mbregex \
--enable-safe-mode=yes \
--enable-track-vars=yes \
--enable-magic-quotes=yes \
--enable-debugger=yes \
--enable-bcmath=yes \
--enable-force-cgi-redirect=yes \
--enable-discard-path=yes \
--enable-memory-limit=yes \
--enable-i18n \
--with-gdbm \
--enable-versioning \
#%{?with_xml:--with-xml} \
#--with-system-regex=yes \
#--with-zlib-dir=/usr \

perl -i.bak -p -e 's/-O2 -m486 -fno-strength-reduce//' Makefile */Makefile
make
)

%install
[ -n "$RPM_BUILD_ROOT" -a "$RPM_BUILD_ROOT" != / ] && rm -rf ${RPM_BUILD_ROOT}
mkdir -p $RPM_BUILD_ROOT/usr/lib/apache
mkdir -p $RPM_BUILD_ROOT/etc
mkdir -p $RPM_BUILD_ROOT%{_bindir}
mkdir -p $RPM_BUILD_ROOT%{dso_sysconfdir}
mkdir -p $RPM_BUILD_ROOT%{cgi_sysconfdir}

install -m 755 build_DSO/libphp3.so $RPM_BUILD_ROOT/usr/lib/apache
install -m755 -s build_CGI/php $RPM_BUILD_ROOT%{_bindir}
install -m 644 php3.ini-dist $RPM_BUILD_ROOT%{dso_sysconfdir}/php3.ini
install -m 644 php3.ini-dist $RPM_BUILD_ROOT%{cgi_sysconfdir}/php3.ini

mkdir -p $RPM_BUILD_ROOT%{contentdir}
tar cf - manual/ | tar xf - -C $RPM_BUILD_ROOT%{contentdir}

%clean
[ -n "$RPM_BUILD_ROOT" -a "$RPM_BUILD_ROOT" != / ] && rm -rf ${RPM_BUILD_ROOT}

%post
perl -i.bak -p -e 's/^#(LoadModule\s+php3_module\s+modules\/libphp3\.so).*$/$1/;s/^#(AddModule\s+mod_php3.c).*$/$1/' /etc/httpd/conf/httpd.conf
/etc/rc.d/init.d/httpd reload

%postun
perl -i.bak -p -e 's/^(LoadModule\s+php3_module\s+modules\/libphp3\.so).*$/#$1/;s/^(AddModule\s+mod_php3.c).*$/#$1/' /etc/httpd/conf/httpd.conf
/etc/rc.d/init.d/httpd reload

%files
%defattr(-,root,root)
%doc BUGS CHANGES CODING_STANDARDS COPYING CREDITS ChangeLog LICENSE README.* apidoc.txt press-release-3.0.txt php-3.0.18j-patch.README
/usr/lib/apache/*
%{dso_sysconfdir}/php3.ini

%files cgi
%defattr(-,root,root)
%{cgi_sysconfdir}/php3.ini
%{_bindir}/php

%files manual
%defattr(-,root,root)
%{contentdir}/%{php_mandir}

%changelog
* Fri Dec 15 2000 Yasuhide OOMORI <dasen@icntv.ne.jp>
- [php3-3.0.18-0vl2]
- updated to php-3.0.18-i18n-ja-2
- bundle English manual too

* Mon Dec 11 2000 Yasuhide OOMORI <dasen@icntv.ne.jp>
- [php3-3.0.18-0vl1]
- use pre-patched source

* Fri Dec  1 2000 Yasuhide OOMORI <dasen@icntv.ne.jp>
- [php3-3.0.18-0]
- first attempt.

