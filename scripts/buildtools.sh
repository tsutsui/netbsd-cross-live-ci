#! /bin/sh
#
# Copyright (c) 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018,
#  2019 2020, 2023, 2024, 2025 Izumi Tsutsui.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

err()
{
	echo $1 failed!
	exit 1
}

# input via environments
# MACHINE: target machine (port)
# RELEASE: NetBSD release version
# FTPHOST: NetBSD FTP mirror to download binary sets from
# RELEASEDIR: NetBSD release directory in ${FTPHOST}
# NETBSDSRCDIR: path to the NetBSD source directory containing build tools
# TOOLDIR: directory of NetBSD tooldir
# JOBS: number of jobs in parallel in build.sh
# HOSTHOME: $HOME on the CI host

if [ -z "${HOSTHOME}" ]; then
	echo "HOSTHOME is not set"
	exit 1
fi
if [ -z "${MACHINE}" ]; then
	echo "MACHINE is not set"
	exit 1
fi
if [ "${MACHINE}" = "evbarm" ] || [ "$MACHINE" = "evbmips" ]; then
	if [ -z "${MACHINE_ARCH}" ]; then
		echo "MACHINE_ARCH for ${MACHINE} is not set"
		exit 1
	fi
fi
if [ -z "${RELEASE}" ]; then
	RELEASE=10.1
fi
if [ -z "${FTPHOST}" ]; then
	FTPHOST=cdn.NetBSD.org
fi
if [ -z "${RELEASEDIR}" ]; then
	RELEASEDIR=pub/NetBSD/NetBSD-${RELEASE}
fi
if [ -z "${RELEASEMACHINEDIR}" ]; then
	RELEASEMACHINEDIR=${MACHINE}-${MACHINE_ARCH}
else
	RELEASEMACHINEDIR=${MACHINE}
fi
if [ -z "${NETBSDSRCDIR}" ]; then
	NETBSDSRCDIR=${HOSTHOME}/netbsd-src
fi
if [ -z "${TOOLDIR}" ]; then
	TOOLDIR=${NETBSDSRCDIR}/tooldir.${RELEASEMACHINEDIR}
fi
if [ -z "${JOBS}" ]; then
	JOBS=4
fi

#FTP=ftp
#FTP_OPTIONS=-V -o -
FTP=curl
FTP_OPTIONS=-sSL
TAR=tar

SRCSETS="gnusrc sharesrc src syssrc"
for SET in $SRCSETS; do
	echo "Downloading and extracting $SET.tgz..."
	${FTP} ${FTP_OPTIONS} \
	    https://$FTPHOST/$RELEASEDIR/source/sets/$SET.tgz \
	    | ${TAR} -C ${HOSTHOME} -zxf - \
	    || err ${FTP}
done
mv ${HOSTHOME}/usr/src ${NETBSDSRCDIR}

echo "Building NetBSD cross toolchains..."
[ -n "${MACHINE_ARCH}" ] && ARCH_OPT="-a ${MACHINE_ARCH}"
(cd $NETBSDSRCDIR && \
    sh build.sh -m $MACHINE $ARCH_OPT -U -u -N 0 -j $JOBS -T $TOOLDIR \
    -V MKGCC=no -V MKSHARE=no -V OBJMACHINE=1 tools) \
    || err build.sh
