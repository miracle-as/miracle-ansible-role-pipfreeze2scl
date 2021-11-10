#!/usr/bin/bash
CMD=$0
PACKAGE=$1
NAME=`echo $PACKAGE | awk -F'==' '{ print $1 }'`
VERSION=`echo $PACKAGE | awk -F'==' '{ print $2 }'`
ACTION=$2
QUIET="no"
BUILDDIR="/root/rpmbuild"
BUILDOUT="$BUILDDIR/OUTPUT"
BUILDOUT="$BUILDDIR/OUTPUT"
AUTOPATCHDIR="$BUILDDIR/AUTOPATCH"
mkdir $AUTOPATCHDIR >/dev/null 2>&1 || touch AUTOPATCHDIR
MYAUTOPATCH="autopath:$AUTOPATCHDIR/$NAME-$VERSION.patch.sh"
AUTOPATCH="$AUTOPATCHDIR/$NAME-$VERSION.patch.sh"
FAILEDRPMS="$BUILDDIR/OUTPUT/failed.txt"
mkdir $BUILDOUT >/dev/null 2>&1 || touch $BUILDOUT
touch $FAILEDRPMS
MYCRC="crc:$PACKAGE"
MYDIRKEY="pkgdir:${PACKAGE}"
MYKEY="filename:${PACKAGE}"
MYRPM="rpm:${PACKAGE}"
MYSPEC="specfile:${PACKAGE}"
MYSRPM="rpms:${PACKAGE}"
MYURL="url:${PACKAGE}"
MYERR="error:{$PACKAGE}"

usage ()
{
echo "usage $CMD"
echo $1
exit 1
}

check_args ()
{
if [[ $PACKAGE == "" ]];
then
	usage "Package missing"
fi
}

logme ()
{
if [[ $QUIET != "yes" ]];
then
	TEXT=$1
	echo "`date`: $1"
fi
}

download_source ()
{
NAME=`echo $PACKAGE | awk -F'==' '{ print $1 }'`
VERSION=`echo $PACKAGE | awk -F'==' '{ print $2 }'`
MYKEY="filename:${PACKAGE}"
MYCRC="crc:$PACKAGE"
FILE=`redis-cli get $MYKEY 2>&1`
echo $FILE  |strings |grep "$VERSION" >/dev/null 2>&1
if [[ $? != 0 ]];
then
	logme "Download"
	echo $PACKAGE > /tmp/requirements.txt
	cd /tmp && DOWNLOAD=`python3 /usr/local/bin/pip-downloader.py `
	FILENAME=`echo $DOWNLOAD | awk -F"Filename:" '{ print $2 }' |awk '{ print $1 }' `
	URL=`echo $DOWNLOAD | awk -F"URL:" '{ print $2 }'`
	MYURL="url:${PACKAGE}"
	redis-cli set $MYURL "$URL"  >/dev/null 2>&1
	if [[ -f $FILENAME ]];
	then
		logme "Download $FILENAME"
		MYKEY="filename:${PACKAGE}"
		redis-cli set $MYKEY "$FILENAME"  >/dev/null 2>&1
	else
		logme "ERROR: $PACKAGE $FILENAME"
			exit 1
		fi
	else
		logme "$PACKAGE Already Downloaded"
		
	fi
}


build_wheels ()
{
	python3 setup.py bdist_wheel >/tmp/buildwheels.log 2>&1
	
}


checkpackage ()
{
        NAME=`echo $PACKAGE | awk -F'==' '{ print $1 }'`
        VERSION=`echo $PACKAGE | awk -F'==' '{ print $2 }'`
        MYKEY="filename:${PACKAGE}"
        MYURL="url:${PACKAGE}"
        MYCRC="crc:$PACKAGE"
	MYDIRKEY="pkgdir:${PACKAGE}"
        FILE=`redis-cli get $MYKEY 2>&1`
	/usr/bin/rm -r /tmp/sandbox >/dev/null 2>&1 || logme "cleaner"
	mkdir /tmp/sandbox
	cd /tmp/sandbox
	echo $FILE|grep tar.gz >/dev/null 2>&1
	if [[ $? == 0 ]];
	then
		tar xf $FILE
		if [[ $? == 0 ]];
		then
			logme "Source extrated"
		else
			logme "Extration failed"
			exit 22
		fi
	fi
	echo $FILE|grep "\.zip" >/dev/null 2>&1
	if [[ $? == 0 ]];
	then
		unzip $FILE >/dev/null 2>&1
		if [[ $? == 0 ]];
		then
			logme "Source extrated"
		else
			logme "Extration failed"
			exit 22
		fi
	fi

	PKGDIR=`ls -1`
	logme "Check $PKGDIR"
	MYDIRKEY="pkgdir:${PACKAGE}"
	redis-cli set $MYDIRKEY "${PKGDIR}" >/dev/null 2>&1
 	cd $PKGDIR
	touch README.md
	touch CHANGELOG.rst
	python3.8 setup.py bdist_rpm --spec-only >/tmp/specfile.$package.log 2>&1
	if [[ $? == 0 ]]
	then
		logme "spec file created"
	else
		echo "error: $PACKAGE - spec creation failed"
		cat /tmp/specfile.$package.log
		exit
	fi
		
	cd dist
	SPEC=`ls -1`
	SPECDST="/root/rpmbuild/SPECS/${NAME}-${VERSION}.spec"
	MYSPEC="specfile:${PACKAGE}"
	logme "SPEC create and saving it"
	###################
	sed -i "s/define version 0.0.0/define version ${VERSION}/" $SPEC
	sed -i "s/define unmangled_version 0.0.0/define unmangled_version ${VERSION}/" $SPEC
	
	if [[ -f $AUTOPATCH ]];
	then
		logme "Autopatch specfile"
		$AUTOPATCH $SPEC
	fi

	cp $SPEC $SPECDST
	redis-cli set $MYSPEC "$SPECDST" >/dev/null 2>&1  
	/usr/bin/rm -r /tmp/sandbox
}

build_rpm ()
{
        NAME=`echo $PACKAGE | awk -F'==' '{ print $1 }'`
        VERSION=`echo $PACKAGE | awk -F'==' '{ print $2 }'`
        MYKEY="filename:${PACKAGE}"
        MYURL="url:${PACKAGE}"
        MYCRC="crc:$PACKAGE"
        MYDIRKEY="pkgdir:${PACKAGE}"
	MYSPEC="specfile:${PACKAGE}"
        FILE=`redis-cli get $MYKEY 2>&1`
        SPEC=`redis-cli get $MYSPEC 2>&1`
	rpmbuild -ba -D 'debug_package %{nil}'  $SPEC  >$BUILDOUT/${PACKAGE}.rpmbuild.log 2>&1 || logme "failed build of $PACKAGE"
	grep "^Wrote: "  $BUILDOUT/${PACKAGE}.rpmbuild.log > $BUILDOUT/$PACKAGE.written 
	if [[ $? == 0 ]];
	then
		logme "RPMs build"
		for RPM in `cat $BUILDOUT/$PACKAGE.written | awk -F"^Wrote: "  '{ print $1 }' `
		do	
			MYRPM="rpm:${PACKAGE}"
			MYSRPM="rpms:${PACKAGE}"
			SRPM=`echo $RPM |grep "/SRPMS/"`
			RPM=`echo $RPM |grep "/RPMS/"`
			redis-cli set $MYRPM "$RPM" >/dev/null 2>&1  
			redis-cli set $MYSRPM "$SRPM" >/dev/null 2>&1  
		done
	else
		logme "RPMS Failed to build"
		redis-cli set $MYERR "$BUILDOUT/${PACKAGE}.rpmbuild.log" >/dev/null 2>&1  
		yabpc.sh $PACKAGE	
	fi
}	
	
	

	

check_args
logme "$PACKAGE $ACTION"

MYRPM="rpm:${PACKAGE}"
MYSRPM="rpms:${PACKAGE}"
SRPM=`redis-cli get $MYSRPM 2>&1`
RPM=`redis-cli get $MYRPM 2>&1`
if [[ $RPM == "" ]];
then
	logme "Build package"
	download_source
	checkpackage
	build_rpm
else
	logme "Package already build"
fi

exit

