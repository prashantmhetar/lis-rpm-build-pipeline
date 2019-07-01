#!/bin/bash

#source the ips.sh

. ./new_ips.sh

NA="NotApplicable"

function write_debug() {
	echo "DEBUG    : $1"
}
function write_verbose() {
	echo "VERBOSE  : $1"
}
function write_info() {
	echo "INFO     : $1"
}

ips_sh=$(cat ./new_ips.sh)
for line in $ips_sh; do
	# do something with $line here
	write_verbose "line=$line"
	vm_name="$(cut -d'=' -f1 <<<$line)"
	write_debug "vm_name=$vm_name"
	version="$(cut -d'_' -f4 <<<$vm_name)"
	write_debug "version=$version"
	hardware="$(cut -d'_' -f5 <<<$vm_name)"
	write_debug "hardware=$hardware"
	update_number="$(cut -d'_' -f6 <<<$vm_name)"
	write_debug "update_number=$update_number"
	#Define the source directory
	if [[ "$hardware" == "x64" ]]; then
		arch_source_dir="x86_64"
		arch_destination_dir=$arch_source_dir
		lis_srpm_source="/root/rpmbuild/SRPMS/*"
	else
		arch_source_dir="i686"
		arch_destination_dir="x86"
		lis_srpm_source="$NA"
	fi
	lis_rpm_build_source="/root/rpmbuild/RPMS/$arch_source_dir"

	write_verbose "lis_rpm_build_source=$lis_rpm_build_source"
	write_verbose "lis_srpm_source=$lis_srpm_source"

	#Define the destination directory

	lis_rpm_build_destination="LISISO/RPMS${version}"
	lis_rpm_install_destination="LISISO/RPMS${version}"
	if [[ "$version" =~ ^5.* ]]; then
		if [[ "$update_number" =~ "update" ]]; then
			lis_rpm_build_destination="${lis_rpm_build_destination}_UPDATE"
		fi
		lis_rpm_build_destination="${lis_rpm_build_destination}/lis-$version/$arch_destination_dir"
	elif [[ "$version" =~ ^6.* ]]; then
		if [[ "$update_number" =~ "update" ]]; then
			lis_rpm_build_destination="$lis_rpm_build_destination/$update_number"
		fi
	elif [[ "$version" =~ ^7.* ]]; then
		if [[ "$update_number" =~ "update" ]]; then
			lis_rpm_build_destination="$lis_rpm_build_destination/$update_number"
		fi
	else
		write_debug "EXCEPTION: Incorrect Version : $version - $vm_name - $line "
	fi
	write_verbose "lis_rpm_build_destination=$lis_rpm_build_destination"
	ip=$(eval echo \$$vm_name)
	write_verbose "scp -r ${ip}:${lis_rpm_build_source}/* -> $lis_rpm_build_destination ..."
	mkdir -p $lis_rpm_build_destination
	kernel=$(ssh root@$ip "uname -r" 2> /dev/null)
	write_verbose $kernel
	if [[ "$update_number" =~ "update" ]]; then
		echo "errata_kernel_$update_number:$kernel" >> "$lis_rpm_install_destination/errata_update.txt"
	fi
	scp -r root@${ip}:${lis_rpm_build_source}/* $lis_rpm_build_destination
done
