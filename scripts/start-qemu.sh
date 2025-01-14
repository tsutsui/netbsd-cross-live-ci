#! /bin/sh
#
# Copyright (c) 2025 Izumi Tsutsui.
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

if [ -z "${HOSTHOME}" ] && [ ! -d "${HOSTHOME}" ]; then
	echo "HOSTHOME is not set"
	exit 1
fi
if [ -z "${IMAGE}" ]; then
	echo "IMAGE is not set"
	exit 1
fi
	# for debug
case "${MACHINE}" in
alpha)
	DRIVEIF="ide"
	NETMODEL="e1000"
	QEMU_MD_OPT="-kernel $TARGETROOTDIR/netbsd -append \"rootdev=/dev/wd0\""
	[ -z "${QEMU_BIN}" ] && QEMU_BIN=/usr/pkg/bin/qemu-system-alpha
	;;
evbarm)
	DRIVEIF="virtio"
	NETMODEL="virtio"
	if [ -z "${QEMU_BIOS}" ]; then
		QEMU_BIOS="QEMU_EFI.fd"
	fi
	QEMU_MD_OPT="-M virt -bios ${QEMU_BIOS}"
	case "${MACHINE_ARCH}" in
		aarch64)
		QEMU_MD_OPT="${QEMU_MD_OPT} -cpu cortex-a53"
		[ -z "${QEMU_BIN}" ] && QEMU_BIN=/usr/pkg/bin/qemu-system-aarch64
		;;
		*)
		QEMU_MD_OPT="${QEMU_MD_OPT} -cpu cortex-a15"
		[ -z "${QEMU_BIN}" ] && QEMU_BIN=/usr/pkg/bin/qemu-system-arm
		;;
	esac
	;;
i386)
	DRIVEIF="virtio"
	NETMODEL="virtio"
	[ -z "${QEMU_BIN}" ] && QEMU_BIN=/usr/pkg/bin/qemu-system-i386
	;;
amd64)
	DRIVEIF="virtio"
	NETMODEL="virtio"
	[ -z "${QEMU_BIN}" ] && QEMU_BIN=/usr/pkg/bin/qemu-system-x86_64
	;;
macppc)
	QEMU_MEM=256
	DRIVEIF="ide"
	NETMODEL="e1000"	# XXX sungem doesn't work on qemu 8.2.2
	[ -z "${QEMU_BIN}" ] && QEMU_BIN=/usr/pkg/bin/qemu-system-ppc
	;;
sparc)
	QEMU_MEM=256
	DRIVEIF="scsi"
	NETMODEL="lance"
	[ -z "${QEMU_BIN}" ] && QEMU_BIN=/usr/pkg/bin/qemu-system-sparc
	;;
sparc64)
	QEMU_MEM=256
	DRIVEIF="ide"
	NETMODEL="sunhme"
	[ -z "${QEMU_BIN}" ] && QEMU_BIN=/usr/pkg/bin/qemu-system-sparc64
	;;
*)
	echo "MACHINE \"${MACHINE}\" is not supported"
	exit 1
	;;
esac

if [ -z "${SSH_PORT}" ]; then
	SSH_PORT=10020
fi
if [ -z "${QEMU_MEM}" ]; then
	QEMU_MEM=1024
fi
if [ ! -x "$(which ${QEMU_BIN})" ]; then
	echo "${QEMU_BIN} is not installed."
	exit 1
fi

QEMU_OPT="-m ${QEMU_MEM} -nographic -drive file=${IMAGE},if=${DRIVEIF},index=0,media=disk,format=raw,cache=unsafe -net nic,model=${NETMODEL} -net user,hostfwd=tcp::${SSH_PORT}-:22"

EMULATOR=qemu
BOOTLOG="${EMULATOR}.log"

cd $HOSTHOME
echo "start $EMULATOR and wait for NetBSD to reach multi-user mode"
${QEMU_BIN} ${QEMU_OPT} ${QEMU_MD_OPT} > $BOOTLOG 2>&1 &
TIMEOUT=120
INTERVAL=5
WAITSECONDS=0
while true; do
  if grep -q "^login:" $BOOTLOG; then
    cat $BOOTLOG
    echo
    echo "NetBSD/$MACHINE on $EMULATOR is ready"
    break
  fi
  if [ "$WAITSECONDS" -ge "$TIMEOUT" ]; then
    echo "Timeout: $EMULATOR doesn't start properly"
    cat $BOOTLOG
    exit 1
  fi
  sleep $INTERVAL
  WAITSECONDS=$(($WAITSECONDS + $INTERVAL))
  echo "waiting $EMULATOR to reach multi-user ($WAITSECONDS s)"
done
