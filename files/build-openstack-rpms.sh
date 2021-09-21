#!/usr/bin/env bash


PKDIR="/var/lib/ostack/packages/"

for MODULE in $(ls -1  $PKDIR)
do
    echo "`date`: finding source packages in $MODULE"
    for MYDIR in $(tree -L 1 -d ${PKDIR}/${MODULE} |awk '{ print $2 }'|egrep  -iv "directory|directories" |grep -i [a-z])
    do  
        cd ${PKDIR}/${MODULE}/${MYDIR}
        if [[ $? == 0 ]];
        then
          echo "`date`: changedir"
       	  if [[ ! -f setup.cfg ]];
          then    
            echo "`date`: Setup cfg file is missing"
            echo "[metadata]" > setup.cfg
            echo "name = opestackrpm-${MODULE}" >> setup.cfg
	      fi

          grep -i "name =" setup.cfg >/dev/null 2>&1
          if [[ $? == 0 ]];
          then
            echo "`date`: We have the entry in the file"
            grep -v "name = openstackrpm-" setup.cfg >/dev/null 2>&1
            if [[ $? == 0 ]];
            then
		sed -i "s/name = /name = openstackrpm-/" setup.cfg >/dev/null 2>&1
            fi
          else
            echo "`date`: We are missing the entry in the file"
	    grep "\[metadate\]" setup.cfg >/dev/null 2>&1
            if [[ $? == 0 ]]; 
            then
                sed "s/[metadata]/[metadata]\name = opestackrpm-${MODULE}/"
            else
		mv setup.cfg setup.cfg.save
                echo "[metadata]" > setup.cfg
                echo "name = opestackrpm-${MODULE}" >> setup.cfg
                cat setup.cfg.save >> setup.cfg
            fi
          fi
         grep "name = openstackrpm-" setup.cfg >/dev/null 2>&1
	     if [[ $? == 0 ]];
         then
	       /var/lib/openstack/venv/builder/venv/bin/python setup.py bdist_rpm
	     fi
       fi
    done
done
