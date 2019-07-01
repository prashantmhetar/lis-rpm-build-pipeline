################################################################################
#
# This script is to automate upgradation of Linux Integration Services for
# Microsoft Hyper-V
#
################################################################################
#!/bin/bash
source ../commonfunctions.sh

upgradebaserpm()
{
	checkrpms
	upgradebuildrpm
}


FILE=./errata_update.txt
if [ -f $FILE ]; then
	errata_list=$(cat $FILE)
	update_max=`cat $FILE | wc -l`
        for line in $errata_list; do
	        update="$(cut -d':' -f1 <<<$line)"
		update_number=$(echo $update | tr -cd '[[:digit:]]')
	        errata_version="$(cut -d':' -f2 <<<$line)"
        	echo "update_number=$update_number errata_version=$errata_version"
		if ! IsInstalledKernelOlderThanErrataKernel $errata_version; then
			num=`expr $update_number - 1`
        		echo "upgrading for update $num"
			if [ $num == 0 ]; then 
				upgradebaserpm
			else
				upgradebuildrpm $num 

			fi
			exit 0
		elif [ $update_number == $update_max ]; then
			echo "upgrading for max update $update_number"
			upgradebuildrpm $num
		fi
		
	done
else
	echo "upgrade default rpms"
	upgradebaserpm
fi

