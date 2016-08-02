#!/bin/sh +x

# Wrapper for build Alpine Linux package with khenarghot/alpine-build

BUILDERIMAGE=khenarghot/alpine-build
ABUILDERDIR=${HOME}/.abuild
CONFIGFILE=${ABUILDERDIR}/abuilder.conf
TARGET=${ABUILDERDIR}/packages
PACKAGER_PRIVKEY=/dev/null
NOCOMMAND=no


help() {
    cat <<EOF
Build Alpine Linux package with docker image khenarghot/alpine-build.

This command build alpine package in current directory and place resulting
package in ~/.abuild/packages

For configuration parametrs look ${CONFIGFILE}

Usage: 
   Build package from current directory:

   abuilder.sh

   Create template for apk package:

   abuilder.sh newbuild

   Call any other util:

   abuilder.sh <command>

   Generate keys:

   abuilder.sh <email> [destanation_dir]

EOF

}

__check_image() {
    docker images | grep -q ${IMAGE}
}

__preapre_envirion() {
    if [ ! -d ${ABUILDERDIR} ]; then
	echo "Not found dir ${ABUILDERDIR}" >&2;
	exit 1;
    fi;

    if [ -f ${CONFIGFILE} ]; then
	. ${CONFIGFILE}
    fi;

    if [ ! -f ${PACKAGER_PRIVKEY} ]; then
	echo "Not found private key. You shuld generate new one with $0 keygen command" >&2;
	NOCOMMAND=yes
    fi;
    if [ ! -f ${PACKAGER_PRIVKEY} ]; then
	echo "Not found public key ${PACKAGER_PRIVKEY}.pub." >&2;
	NOCOMMAND=yes
    fi
	
	
}

# ask for privkey unless non-interactive mode
# returns value in global $privkey
get_privkey_file() {
        local emailaddr default_name
        emailaddr=${PACKAGER##*<}
        emailaddr=${emailaddr%%>*}

        # if PACKAGER does not contain a valid email address, then ask git
        if [ -z "$emailaddr" ] || [ "${emailaddr##*@}" = "$emailaddr" ]; then
                emailaddr=$(git config --get user.email 2>/dev/null)
        fi

        default_name="${emailaddr:-$USER}-$(printf "%x" $(date +%s))"

        privkey="$ABUILD_USERDIR/$default_name.rsa"
        [ -n "$non_interactive" ] && return 0
        msg "Generating public/private rsa key pair for abuild"
        echo -n "Enter file in which to save the key [$privkey]: "

        read line
        if [ -n "$line" ]; then
                privkey="$line"
        fi
}



__keygen() {
    destanation_dir=${ABUILDERDIR}/
    emailaddr=$1
    shift
    if [ $# -gt 0 ]; then
       destanation_dir=$1/
       shift
    fi;
    default_name="${emailaddr:-$USER}-$(printf "%x" $(date +%s))"
    privkey=${destanation_dir}${default_name}.rsa

    openssl genrsa -out $privkey 2048

    openssl rsa -in $privkey -pubout -out ${privkey}.pub
}


__run_command() {
    if [ "${NOCOMMAND}" == "yes" ]; then
	echo "Disabled command execution" >&2
	exit -1
    fi;
    RUID=`id -u`
    RGID=`id -g`
    
    RSA_PRIVATE_KEY=$1
    shift
    
    RSA_PRIVATE_KEY_NAME=$(basename ${RSA_PRIVATE_KEY})
    docker run --rm="true"\
    -e RSA_PRIVATE_KEY="$(cat ${RSA_PRIVATE_KEY})" \
    -e RSA_PRIVATE_KEY_NAME="${RSA_PRIVATE_KEY_NAME}" \
    -e RUID=${RUID} -e RGID=${RGID} \
    -v "$PWD:/home/builder/package" \
    -v "${TARGET}:/packages" \
    -v "${RSA_PRIVATE_KEY}.pub:/etc/apk/keys/${RSA_PRIVATE_KEY_NAME}.pub" \
    ${BUILDERIMAGE} $@
}

__preapre_envirion

if [ $# -gt 0 ]; then
    case $1 in
	newbuild)
	    shift
	    __run_command ${PACKAGER_PRIVKEY} newapkbuild $@
	    exit 0
	    ;;
	keygen)
	    shift
	    __keygen $@
	    exit 0
	    ;;
	--help)
	    help
	    exit 0
	    ;;
    esac  
fi    

__run_command ${PACKAGER_PRIVKEY} $@

