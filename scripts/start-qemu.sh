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

if [ -z "${HOSTHOME}" ]; then
	echo "HOSTHOME is not set"
	exit 1
fi
if [ -z "${QEMU_BIN}" ]; then
	# for debug
	case "${MACHINE}" in
	i386)
		QEMU_BIN=/usr/pkg/bin/qemu-system-i386
		;;
	amd64)
		QEMU_BIN=/usr/pkg/bin/qemu-system-x86_64
		;;
	*)
		echo "${MACHINE} is not supported"
		exit 1
		;;
	esac
fi
if [ -z "${SSH_PORT}" ]; then
	SSH_PORT=10020
fi
if [ ! -x "$(which ${QEMU_BIN})" ]; then
	echo "${QEMU_BIN} is not installed."
	exit 1
fi

QEMU_OPT="-m 1024 -nographic -drive file=${IMAGE},if=virtio,index=0,media=disk,format=raw,cache=unsafe -net nic,model=virtio -net user,hostfwd=tcp::${SSH_PORT}-:22"
BOOTLOG="qemu.log"

cd $HOSTHOME
echo "start qemu and wait for NetBSD to reach multi-user mode"
${QEMU_BIN} ${QEMU_OPT} > $BOOTLOG 2>&1 &
TIMEOUT=120
INTERVAL=5
WAITSECONDS=0
while true; do
  if grep -q "^login:" $BOOTLOG; then
    cat $BOOTLOG
    echo
    echo "NetBSD/$MACHINE on qemu is ready"
    break
  fi
  if [ "$WAITSECONDS" -ge "$TIMEOUT" ]; then
    echo "Timeout: qemu doesn't start properly"
    cat $BOOTLOG
    exit 1
  fi
  sleep $INTERVAL
  WAITSECONDS=$(($WAITSECONDS + $INTERVAL))
  echo "waiting simh to reach multi-user ($WAITSECONDS s)"
done
