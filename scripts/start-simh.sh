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

if [ -z ${HOSTHOME} ]; then
	echo "HOSTHOME is not set"
	exit 1
fi
if [ -z ${SIMH_BOOT} ] || [ ! -f ${SIMH_BOOT} ]; then
	echo "SIMH_BOOT is not set"
	exit 1
fi
if [ -z ${SIMH_BIN} ]; then
	# for debug
	SIMH_BIN=/usr/pkg/bin/simh-microvax3900
fi

cd $HOSTHOME
echo "start simh and wait for NetBSD to reach multi-user mode"
echo "boot dua0" | ${SIMH_BIN} ${SIMH_BOOT} > simh.log 2>&1 &
TIMEOUT=600
INTERVAL=5
while true; do
  if grep -q "^login:" simh.log; then
    cat simh.log
    echo
    echo "NetBSD/vax on simh is ready"
    break
  fi
  if [ "$SECONDS" -ge "$TIMEOUT" ]; then
    echo "Timeout: simh doesn't start properly"
    cat simh.log
    exit 1
  fi
  sleep $INTERVAL
  echo "waiting simh to reach multi-user ($SECONDS s)"
done
