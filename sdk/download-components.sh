#!/usr/bin/env bash

# Copyright (C) 2013,2014 Embecosm Limited

# Contributor Simon Cook <simon.cook@embecosm.com>

# This file is a script to download toolchain source.

# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.

# You should have received a copy of the GNU General Public License along
# with this program.  If not, see <http://www.gnu.org/licenses/>.

# Usage:

# ./download-components.sh [--force | --no-force]
#                          [--clone | --download]
#                          [--https | --ssh ]
#                          [--infra-url <url> | --infra-us |
#                           --infra-uk | --infra-jp]
#                          [--help | -h]

# --force | --no-force

#     If --force is specified, attempt to remove the existing repository
#     before cloning or downloading. If the removal fails, the old version
#     will be used, but a warning printed.  Default --no-force.

# --clone | --download

#     If --clone is specified, attempt to clone the repository, otherwise if
#     --download is specified, attempt to download a tarball file of the
#     repository.  Default --download.

# --https | --ssh

#     If --clone is specified, the --https and --ssh flags are used to
#     select which transport git should use. Default --https.
#
#

# --infra-url <url>

#     Set the URL of the GCC infrastructure downloads. Default
#     http://www.netgull.com/gcc/infrastructure.

# --infra-us
# --infra-uk
# --infra-jp

#     Synonyms respectively for infrastructure URLs in the USA, UK and Japan

# --help | -h

#     Print out a brief help about this script and return with an error code.

# Note that earlier versions allowed specification of a location where the
# tools were to be downloaded. However recent versions do not download the SDK
# directory, so the script will only work if downloading is done in a fixed
# location relative to the pre-existing SDK directory (which contains this
# script).

# The script returns 1 on failure and 0 on success. Failure to delete a
# pre-existing version when specifying --force is not considered a failure.


################################################################################
#                                                                              #
#			       Shell functions                                 #
#                                                                              #
################################################################################

# Function to clone a git repository, checking out the relevant branch.

# @param[in] $1  The tool to clone
# @param[in] $2  The full repository URL
# @param[in] $3  The branch to checkout

# @return 0 on success, 1 on failure. Note that failure to remove components
#         when --force is in action is not considered a failure.
clone_tool() {
    tool=$1
    repo_url=$2
    branch=$3

    # If old source exists, delete
    if [ ${force} = "true" ]
    then
	if ! rm -rf ${tool} >> ${log} 2>&1
	then
	    echo "Warning: Unable to delete old ${tool}" | tee -a ${log}
	fi
    fi

    # Clone git repository if it does not already exist
    if [ ! -e ${tool} ]
    then
	echo "Cloning ${tool}..."
	if ! git clone -q -b ${branch} ${repo_url} ${tool} \
	         >> ${log} 2>&1
	then
	    echo "ERROR: Unable to clone ${tool}" | tee -a ${log}
	    return 1
	fi
    fi
}

# Function to download a specific tool branch or version

# @param[in] $1  The tool to download
# @param[in] $2  URL of archive directory
# @param[in] $3  Command to unpack the download
# @parma[in] $4  Branch or version packed file (i.e. with suffix such as tar.gz)
# @parma[in] $5  Unpacked main directory

# @return 0 on success, 1 on failure. Note that failure to remove components
#         when --force is in action is not considered a failure.
download_tool() {
    tool=$1
    archive_url=$2
    unpack_cmd=$3
    branch=$4
    unpacked_dir=$5

    # If --force is in action and old source exists, attempt delete
    if [ ${force} = "true" ]
    then
	if ! rm -rf ${tool} ${branch} >> ${log} 2>&1
	then
	    echo "Warning: Unable to delete old ${tool}" | tee -a ${log}
	fi
    fi

    # Download and unpack source if it does not already exist
    if [ ! -e ${tool} ]
    then
	echo "Downloading ${tool}..."
	if ! wget ${archive_url}/${branch} \
	    >> ${log} 2>&1
	then
	    echo "ERROR: Unable to download ${tool}" | tee -a ${log}
	    return 1
	fi
	if ! eval ${unpack_cmd} ${branch} >> ${log} 2>&1
	then
	    echo "ERROR: Unable to unpack ${tool}" | tee -a ${log}
	    return 1
	fi
	# Only move if the unpacked_dir is different to the tool
	if [ "x${unpacked_dir}" != "x${tool}" ]
	then
	    if ! mv ${unpacked_dir} ${tool} >> ${log} 2>&1
	    then
		echo "ERROR: Unable to move unpacked dir to ${tool}" \
		    | tee -a ${log}
		return 1
	    fi
	fi
	if ! rm ${branch} >> ${log} 2>&1
	then
	    echo "ERROR: Unable to remove packed file for ${tool}" \
		| tee -a ${log}
	    return 1
	fi
    fi
}


# Function to either download a tool or clone a git repository from GitHub,
# checking out the relevant branch.

# @param[in] $1 The tool to clone (will appear as a subdirectory of ${topdir}.
# @param[in] $2 The GitHub repo to clone/download.
# @param[in] $3 The branch to checkout/download.
# @param[in] $4 Github organization.

# @return  The result of the underlying call to clone or download a tool.
github_tool () {
    tool=$1
    repo=$2
    branch=$3
    organization=$4

    if [ ${clone} = "true" ]
    then
	clone_tool "${tool}" "${git_transport_prefix}/${organization}/${repo}" \
	    "${branch}"
    else
	download_tool "${tool}" \
			"https://github.com/${organization}/${repo}/archive" \
			"tar xf" "${branch}.tar.gz" "${repo}-${branch}"
    fi
}

# Function that loops over all component versions and downloads them

# @return 0 on success, anything else indicates failure
download_components() {
    # Clone/Download repositories from GitHub

    OLD_IFS=${IFS}
    IFS="
" # We only want the newline character

    res="ok"
    for line in `grep -v -e '^#' -e '^$' ${basedir}/sdk/components.conf`
    do
        line=(${line//:/$IFS})
	class=${line[0]}

	case ${class} in
	toolchain)
	    tool=${line[1]}
	    branch=${line[2]}
	    repo=${line[3]}
	    org=${line[4]}

	    if ! github_tool "${tool}" "${repo}" "${branch}" "${org}"
	    then
		res="fail"
		break
	    fi

	    ;;

	gccinfra)
	    name=${line[1]}
	    version=${line[2]}
	    suffix=${line[3]}

	    if ! gcc_component ${name} ${version} ${suffix}
	    then
		res="fail"
		break
	    fi

	    ;;

	other)
	    name=${line[1]}
	    version=${line[2]}
	    suffix=${line[3]}
	    proto=${line[4]}
	    base=${line[5]}

	    if ! other_component ${name} ${version} ${suffix} ${proto}:${base}
	    then
		res="fail"
		break
	    fi

	    ;;

	*)
	    tool=${line[1]}
	    branch=${line[2]}
	    repo=${line[3]}
	    org="${class}"

	    if ! github_tool "${tool}" "${repo}" "${branch}" "${org}"
	    then
		res="fail"
		break
	    fi

	    ;;

	esac


    done


    # Restore IFS before returning
    IFS=${OLD_IFS}

    [ "xok" = "x${res}" ]
}


# Function to download a GCC infrastructure component

# @param[in] $1 Component name
# @param[in] $2 File name with version
# @param[in] $3 Compressed file suffix

# @return  The result of the underlying call to download a tool.
gcc_component () {
    tool=$1
    file=$2
    packed_name=${file}.$3

    mkdir -p gcc-infrastructure; cd gcc-infrastructure
    download_tool "${tool}" "${infra_url}" "tar xf" "${packed_name}" "${file}"
    cd ..
}


# Function to download any other component

# @param[in] $1 Component name
# @param[in] $2 File name with version
# @param[in] $3 Compressed file suffix
# @param[in] $4 URL for the download

# @return  The result of the underlying call to download a tool.
other_component () {
    tool=$1
    file=$2
    packed_name=${file}.$3
    url=$4

    mkdir -p gcc-infrastructure; cd gcc-infrastructure
    download_tool "${tool}" "${url}" "tar xf" "${packed_name}" "${file}"
    cd ..
}


# Function to check for relative directory and makes it absolute

# @param[in] $1  The directory to make absolute if necessary.
absolutedir() {
    case ${1} in

	/*)
	    echo "${1}"
	    ;;

	*)
	    echo "${PWD}/${1}"
	    ;;
    esac
}


################################################################################
#                                                                              #
#			       Parse arguments                                 #
#                                                                              #
################################################################################

# Defaults

force="false"
clone="false"
git_transport_prefix="https://github.com"

infra_url="http://gcc.gnu.org/pub/gcc/infrastructure"

until
opt=$1
case ${opt} in

    --force)
	force="true"
	;;

    --no-force)
	force="false"
	;;

    --clone)
	clone="true"
	;;

    --download)
	clone="false"
	;;

    --ssh)
	git_transport_prefix="git@github.com:"
	;;

    --https)
	git_transport_prefix="https://github.com"
	;;

    --infra-url)
	shift
	infra_url="$1"
	;;

    --infra-us)
	infra_url="http://www.netgull.com/gcc/infrastructure"
	;;

    --infra-uk)
	infra_url="http://mirrors-uk.go-parts.com/gcc/infrastructure"
	;;

    --infra-jp)
	infra_url="http://ftp.tsukuba.wide.ad.jp/software/gcc/infrastructure"
	;;

    ?*)
	echo "Usage: ./download-components.sh [--force | --no-force]"
	echo "                                [--clone | --download]"
	echo "                                [--https | --ssh]"
	echo "                                [--infra-url <url> | --infra-us |"
	echo "                                 --infra-uk | --infra-jp]"
	echo "                                [--help | -h]"
	exit 1
	;;

    *)
	;;
esac
[ "x${opt}" = "x" ]
do
    shift
done


################################################################################
#                                                                              #
#			     Download everything                               #
#                                                                              #
################################################################################

# Move to basedir location

basedir="$(cd "$(dirname "$0")/.." && pwd)"
cd "${basedir}"

# Set the release parameters
. ${basedir}/sdk/define-release.sh

# Set up a log file
log="${LOGDIR}/clone-$(date -u +%F-%H%M).log"
rm -f "${log}"

echo "Logging to ${log}"


# Download all components defined in 'component-versions'
if ! download_components
then
    echo "ERROR: Failed to download components" | tee -a ${log}
    exit 1
fi

if [ "${res}" = "ok" ]
then
    echo "Download complete"
else
    echo "Download incomplete - see log for failures"
fi
