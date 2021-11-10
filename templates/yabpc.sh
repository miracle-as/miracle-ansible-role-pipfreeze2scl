#!/usr/bin/env bash
# Yet anohter build patch creator

PACKAGE=$1
NAME=`echo $PACKAGE | awk -F'==' '{ print $1 }'`
VERSION=`echo $PACKAGE | awk -F'==' '{ print $2 }'`
BUILDDIR="/root/rpmbuild"
BUILDOUT="$BUILDDIR/OUTPUT"
AUTOPATCHDIR="$BUILDDIR/AUTOPATCH"
mkdir $AUTOPATCHDIR >/dev/null 2>&1|| echo 
MYCRC="crc:$PACKAGE"
MYDIRKEY="pkgdir:${PACKAGE}"
MYKEY="filename:${PACKAGE}"
MYRPM="rpm:${PACKAGE}"
MYSPEC="specfile:${PACKAGE}"
MYSRPM="rpms:${PACKAGE}"
MYURL="url:${PACKAGE}"
MYAUTOPATCH="autopath:$AUTOPATCHDIR/$NAME-$VERSION.patch.sh"
AUTOPATCH="$AUTOPATCHDIR/$NAME-$VERSION.patch.sh"

if [[ $PACKAGE == "" ]];
then	
	echo "USAAGE"
	exit

fi

# error: package directory find_namespace: does not exist
# Need to be build whith python 3.8

cat $BUILDOUT/${PACKAGE}.rpmbuild.log |grep "find_namespace:" >/dev/null 2>&1
if [[ $? == 0 ]];
then
	SPECFILE=`redis-cli get $MYSPEC`
	echo 'sed -i "s/python3 /python3.8 /"  $1' > $AUTOPATCH
	chmod 755 $AUTOPATCH

        redis-cli set $MYAUTOPATCH "$AUTOPATCH"  >/dev/null 2>&1
fi
echo > $AUTOPATCH

# #!/usr/bin/env python
cat $BUILDOUT/${PACKAGE}.rpmbuild.log | grep "ERROR: ambiguous python shebang " >/tmp/ERROR_ambiguous_pythonr_shebang.tmp 2>&1
if [[ $? == 0 ]];
then
	for line in `cat /tmp/ERROR_ambiguous_pythonr_shebang.tmp  | tr ' ' '¤'`
	do
		FILENAME=`echo $line | tr '¤' ' ' | awk -F"ambiguous python shebang in " '{ print $2 }' |awk '{ print $1 }' | awk -F':' '{ print $1 }'`
		echo $FILENAME
	#	echo "sed -i \"s/python /python3 /\" \${RPM_BUILD_ROOT}${FILENAME}" >> $AUTOPATCH
	done
	chmod 755 $AUTOPATCH
fi



cat $BUILDOUT/${PACKAGE}.rpmbuild.log | grep "has shebang which doesn" >/tmp/has_shebang_which_doesn.tmp 2>&1
if [[ $? == 0 ]];
then
	for line in `cat /tmp/has_shebang_which_doesn.tmp | tr ' ' '¤'`
	do
		FILENAME=`echo $line | tr '¤' ' ' | awk -F"ERROR: " '{ print $2 }' |awk '{ print $1 }' `
		MYSEDCMD="sed -i "s¤instal¤JDJDJDJJDJDJDJDJDJDJD¤" $FILENAME"
		echo $MYSEDCMD

#sed '/<tag>/ r file2.txt' file1.txt^"
#
#		sed '/%install/ r /tmp/filen'  /tmp/docutils-0.16.spec
    		#awk "/%install/ { print; print "${MYSEDCMD}" ; next }1" /tmp/docutils-0.16.spec 
 #     		#awk '/%install/ { print; print "${COMMAND}" ; next }1' /tmp/docutils-0.16.spec > /tmp/docutils-0.16.spec.new
 #     		#awk '/%install/ { print; print "${COMMAND}" ; next }1' /tmp/docutils-0.16.spec > /tmp/docutils-0.16.spec.new
#		#mv /tmp/docutils-0.16.spec.new /tmp/docutils-0.16.spec
	done
	chmod 755 $AUTOPATCH
exit

#awk '/record=INSTALLED_FILES/ { print; print "sed -i \"'s#python#/usr/bin/python3#'\" /root/rpmbuild/BUILDROOT/uwsgitop-0.11-1.x86_64/usr/bin/uwsgitop" ; next }1' ${SPEC}  >/tmp/tmp.spec
#if [[ $? == 0 ]];
#then
#      cp  /tmp/tmp.spec $SPEC
##fi

#################################################
#shebang which doesn't start with '/' (python)
#################################################

####################################################
# hack one: always python3
###################################################
#sed -i "s/%{__python} /python3 /" $SPECFILE

####################################################
# hack two: kill all misplaces heading dots
###################################################
#awk '/record=INSTALLED_FILES/ { print; print "sed -i \"'s#^./#/#'\" INSTALLED_FILES " ; next }1' ${SPEC}  >/tmp/tmp.spec
#if [[ $? == 0 ]];
#then
      cp  /tmp/tmp.spec $SPEC
fi

###################################################
# hack Four: version ?
###################################################
sed -i "s/define version 0.0.0/define version ${VERSION}/" $SPEC
sed -i "s/define unmangled_version 0.0.0/define unmangled_version ${VERSION}/" $SPEC



awk '/record=INSTALLED_FILES/ { print; print "sed -i \"'s#python#/usr/bin/python3#'\" /root/rpmbuild/BUILDROOT/uwsgitop-0.11-1.x86_64/usr/bin/uwsgitop" ; next }1' ${SPEC}  >/tmp/tmp.spec
if [[ $? == 0 ]];
then
#      cp  /tmp/tmp.spec $SPEC
#fi

###################################################
# hack chardet
###################################################
#        if [[ $NAME == "chardet" ]];
#        then
#                awk '/record=INSTALLED_FILES/ { print; print "sed -i \"'s#python#python3#'\" /root/rpmbuild/BUILDROOT/chardet-3.0.4-1.x86_64/usr/lib/python3.6/site-packages/chardet/cli/chardetect.py" ; next }1' ${SPEC}  >/tmp/tmp.spec
#                if [[ $? == 0 ]];
#                then
#                        cp  /tmp/tmp.spec $SPEC
#                fi
#        fi
#

#        ###################################################
#        # hack docutils
#        ###################################################
#        if [[ $NAME == "docutils" ]];
#        then
#                awk '/record=INSTALLED_FILES/ { print; print "sed -i \"'s#python#python3#'\" /root/rpmbuild/BUILDROOT/docutils-0.16-1.x86_64/usr/lib/python3.6/site-packages/docutils/writers/xetex/__init__.py" ; next }1' ${SPEC}  >/tmp/tmp.spec
#                if [[ $? == 0 ]];
#                then
#                        cp  /tmp/tmp.spec $SPEC
#                fi
#        fi
#
#
