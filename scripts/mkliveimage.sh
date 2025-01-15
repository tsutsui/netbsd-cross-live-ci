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
# NETBSDSRCDIR: path to the NetBSD source directory containing build tools
# TOOLDIR: directory of NetBSD tooldir
# HOSTHOME: $HOME on the CI host
# HOST_IP: host IP address allowed ssh for login

if [ -z ${HOSTHOME} ]; then
	echo "HOSTHOME is not set"
	exit 1
fi
if [ -z ${RELEASEDIR} ]; then
	RELEASEDIR=pub/NetBSD/NetBSD-${RELEASE}
fi
if [ -z ${IMAGE} ]; then
	IMAGE=NetBSD-${RELEASE}-${MACHINE}.img
fi

#
# target dependent info
#
case "${MACHINE}" in
alpha)
 MACHINE_ARCH=alpha
 MACHINE_GNU_PLATFORM=alpha--netbsd		# for fdisk(8)
 TARGET_ENDIAN=le
 KERN_SET=kern-GENERIC
 SUFFIX_SETS=tgz
 EXTRA_SETS= # nothing
 RAW_PART=2		# raw partition is c:
 #USE_MBR=yes
 USE_MBR=no
 #USE_GPT=yes
 #USE_GPTMBR=yes
 OMIT_SWAPIMG=no	# include swap partition in output image for emulators
 RTC_LOCALTIME=no	# use rtclocaltime=YES in rc.d(8) for Windows machines
 MAKEFSOPTIONS="-o version=2"
 PRIMARY_BOOT=bootxx_ffsv2
 SECONDARY_BOOT=boot
 SECONDARY_BOOT_ARG= # nothing
 INSTALLBOOTOPTIONS="-v"
 INSTALLBOOT_AFTER_DISKLABEL=no
 VMHOSTNAME=qemupc
 DISKNAME=netbsd-ci-${MACHINE}
 if [ -z "${HOST_IP}" ] ; then
  HOST_IP=10.0.2.2	# qemu "-nic user" NAT default
 fi
 ;;
amd64)
 MACHINE_ARCH=x86_64
 MACHINE_GNU_PLATFORM=x86_64--netbsd		# for fdisk(8)
 TARGET_ENDIAN=le
 KERN_SET=kern-GENERIC
 SUFFIX_SETS=tar.xz
 EXTRA_SETS= # nothing
 RAW_PART=3		# raw partition is d:
 USE_MBR=no
 USE_GPT=yes
 USE_GPTMBR=yes
 OMIT_SWAPIMG=no	# include swap partition in output image for emulators
 RTC_LOCALTIME=yes	# use rtclocaltime=YES in rc.d(8) for Windows machines
 PRIMARY_BOOT=bootxx_ffsv1
 SECONDARY_BOOT=boot
 BOOTSPEC="./boot type=file mode=0444"
 SECONDARY_BOOT_ARG= # nothing
 EFIBOOT="bootx64.efi bootia32.efi"
 INSTALLBOOTOPTIONS="-v -o console=com0"	# to use serial console
 INSTALLBOOT_AFTER_DISKLABEL=no
 VMHOSTNAME=qemupc
 DISKNAME=netbsd-ci-${MACHINE}
 #HOST_IP=		# XXX check qemu settings
 ;;
evbarm)
 if [ -z "$MACHINE_ARCH" ]; then
  MACHINE_ARCH=earmv7hf
 fi
 RELEASEMACHINEDIR=${MACHINE}-${MACHINE_ARCH}
 if [ -z "${MACHINE_ARCH##*eb}" ]; then
  TARGET_ENDIAN=be
 else
  TARGET_ENDIAN=le
 fi
 if [ "$MACHINE_ARCH" = "aarch64" ]; then
  MACHINE_GNU_PLATFORM=aarch64--netbsd		# for fdisk(8)
  KERN_SET=kern-GENERIC64
  SUFFIX_SETS=tar.xz
  MAKEFSOPTIONS="-o version=2"
  EFIBOOT="bootaa64.efi"
 else
  MACHINE_GNU_PLATFORM=arm--netbsdelf		# for fdisk(8)
  KERN_SET=kern-GENERIC
  SUFFIX_SETS=tgz
  EFIBOOT="bootarm.efi"
 fi
 EXTRA_SETS= # nothing
 RAW_PART=2		# raw partition is c:
 USE_MBR=no
 USE_GPT=yes
 OMIT_SWAPIMG=no	# include swap partition in output image for emulators
 RTC_LOCALTIME=no	# use rtclocaltime=YES in rc.d(8) for Windows machines
 #PRIMARY_BOOT=bootxx
 #SECONDARY_BOOT=boot
 #SECONDARY_BOOT_ARG=/boot
 BOOTSPEC="./boot type=dir mode=0755"
 #INSTALLBOOTOPTIONS="-v"
 #INSTALLBOOT_AFTER_DISKLABEL=no
 VMHOSTNAME=qemuarm
 DISKNAME=netbsd-ci-${MACHINE}
 if [ -z "${HOST_IP}" ] ; then
  HOST_IP=10.0.2.2	# simh NAT default
 fi
 ;;
evbmips)
 if [ -z "$MACHINE_ARCH" ]; then
  MACHINE_ARCH=mipsel
 fi
 RELEASEMACHINEDIR=${MACHINE}-${MACHINE_ARCH}
 if [ -z "${MACHINE_ARCH##*eb}" ]; then
  TARGET_ENDIAN=be
 else
  TARGET_ENDIAN=le
 fi
 if [ "$MACHINE_ARCH" = "mips64el" ]; then
  MACHINE_GNU_PLATFORM=mips64el--netbsd		# for fdisk(8)
  #KERN_SET=kern-MALTA64
  KERN_SET=kern-MIPSSIM64
  MAKEFSOPTIONS="-o version=2"
 else
  MACHINE_GNU_PLATFORM=mipsel--netbsdelf	# for fdisk(8)
  #KERN_SET=kern-MALTA
  KERN_SET=kern-MIPSSIM
 fi
 SUFFIX_SETS=tgz
 EXTRA_SETS= # nothing
 RAW_PART=3		# raw partition is c:
 USE_MBR=no
 USE_GPT=no
 OMIT_SWAPIMG=no	# include swap partition in output image for emulators
 RTC_LOCALTIME=no	# use rtclocaltime=YES in rc.d(8) for Windows machines
 #PRIMARY_BOOT=bootxx
 #SECONDARY_BOOT=boot
 #SECONDARY_BOOT_ARG=/boot
 #BOOTSPEC="./boot type=file mode=0644"
 #INSTALLBOOTOPTIONS="-v"
 #INSTALLBOOT_AFTER_DISKLABEL=no
 VMHOSTNAME=qemumips
 DISKNAME=netbsd-ci-${MACHINE}
 if [ -z "${HOST_IP}" ] ; then
  HOST_IP=10.0.2.2	# simh NAT default
 fi
 ;;
hppa)
 IMAGEMB=2000		# firmware has 2GB limit to load bootloader
 MACHINE_ARCH=hppa
 MACHINE_GNU_PLATFORM=hppa--netbsdelf		# for fdisk(8)
 TARGET_ENDIAN=be
 KERN_SET=kern-GENERIC
 SUFFIX_SETS=tgz
 EXTRA_SETS= # nothing
 RAW_PART=2		# raw partition is c:
 USE_MBR=no
 OMIT_SWAPIMG=no	# include swap partition in output image for emulators
 RTC_LOCALTIME=no	# use rtclocaltime=YES in rc.d(8) for Windows machines
 PRIMARY_BOOT=xxboot
 SECONDARY_BOOT=boot
 #SECONDARY_BOOT_ARG=/boot
 BOOTSPEC="./boot type=file mode=0444"
 INSTALLBOOTOPTIONS="-v"
 INSTALLBOOT_AFTER_DISKLABEL=no
 VMHOSTNAME=qemuparisc
 DISKNAME=netbsd-ci-${MACHINE}
 if [ -z "${HOST_IP}" ] ; then
  HOST_IP=10.0.2.2	# simh NAT default
 fi
 ;;
i386)
 MACHINE_ARCH=i386
 MACHINE_GNU_PLATFORM=i486--netbsdelf		# for fdisk(8)
 TARGET_ENDIAN=le
 KERN_SET=kern-GENERIC
 SUFFIX_SETS=tgz
 EXTRA_SETS= # nothing
 RAW_PART=3		# raw partition is d:
 #USE_MBR=yes
 USE_MBR=no
 #USE_GPT=yes
 #USE_GPTMBR=yes
 OMIT_SWAPIMG=no	# include swap partition in output image for emulators
 RTC_LOCALTIME=yes	# use rtclocaltime=YES in rc.d(8) for Windows machines
 PRIMARY_BOOT=bootxx_ffsv1
 SECONDARY_BOOT=boot
 SECONDARY_BOOT_ARG= # nothing
 EFIBOOT="bootia32.efi"	# XXX: NetBSD/i386 doesn't provide bootx64.efi
 INSTALLBOOTOPTIONS="-v -o console=com0"	# to use serial console
 INSTALLBOOT_AFTER_DISKLABEL=no
 VMHOSTNAME=qemupc
 DISKNAME=netbsd-ci-${MACHINE}
 if [ -z "${HOST_IP}" ] ; then
  HOST_IP=10.0.2.2	# qemu "-nic user" NAT default
 fi
 ;;
macppc)
 MACHINE_ARCH=powerpc
 MACHINE_GNU_PLATFORM=powerpc--netbsd		# for fdisk(8)
 TARGET_ENDIAN=be
 KERN_SET=kern-GENERIC
 SUFFIX_SETS=tgz
 EXTRA_SETS= # nothing
 RAW_PART=2		# raw partition is c:
 USE_MBR=no
 OMIT_SWAPIMG=no	# include swap partition in output image for emulators
 RTC_LOCALTIME=no	# use rtclocaltime=YES in rc.d(8) for Windows machines
 PRIMARY_BOOT=bootxx
 SECONDARY_BOOT=ofwboot
 SECONDARY_BOOT_ARG=/ofwboot
 BOOTSPEC="./boot type=file mode=0444"
 INSTALLBOOTOPTIONS="-v"
 INSTALLBOOT_AFTER_DISKLABEL=no
 VMHOSTNAME=qemumac
 DISKNAME=netbsd-ci-${MACHINE}
 if [ -z "${HOST_IP}" ] ; then
  HOST_IP=10.0.2.2	# simh NAT default
 fi
 ;;
sparc)
 MACHINE_ARCH=sparc
 MACHINE_GNU_PLATFORM=sparc--netbsdelf		# for fdisk(8)
 TARGET_ENDIAN=be
 KERN_SET=kern-GENERIC
 SUFFIX_SETS=tgz
 EXTRA_SETS= # nothing
 RAW_PART=2		# raw partition is c:
 USE_MBR=no
 OMIT_SWAPIMG=no	# include swap partition in output image for emulators
 RTC_LOCALTIME=no	# use rtclocaltime=YES in rc.d(8) for Windows machines
 PRIMARY_BOOT=bootxx
 SECONDARY_BOOT=boot
 SECONDARY_BOOT_ARG=/boot
 BOOTSPEC="./boot type=file mode=0444"
 INSTALLBOOTOPTIONS="-v"
 INSTALLBOOT_AFTER_DISKLABEL=no
 VMHOSTNAME=qemusparc
 DISKNAME=netbsd-ci-${MACHINE}
 if [ -z "${HOST_IP}" ] ; then
  HOST_IP=10.0.2.2	# simh NAT default
 fi
 ;;
sparc64)
 MACHINE_ARCH=sparc64
 MACHINE_GNU_PLATFORM=sparc64--netbsd		# for fdisk(8)
 TARGET_ENDIAN=be
 KERN_SET=kern-GENERIC
 SUFFIX_SETS=tar.xz
 EXTRA_SETS= # nothing
 RAW_PART=2		# raw partition is c:
 USE_MBR=no
 OMIT_SWAPIMG=no	# include swap partition in output image for emulators
 RTC_LOCALTIME=no	# use rtclocaltime=YES in rc.d(8) for Windows machines
 MAKEFSOPTIONS="-o version=2"
 USE_SUNLABEL=yes
 PRIMARY_BOOT=bootblk
 SECONDARY_BOOT=ofwboot
 SECONDARY_BOOT_ARG=	# nothing
 INSTALLBOOTOPTIONS="-v"
 INSTALLBOOT_AFTER_DISKLABEL=no
 VMHOSTNAME=qemusparc
 DISKNAME=netbsd-ci-${MACHINE}
 if [ -z "${HOST_IP}" ] ; then
  HOST_IP=10.0.2.2	# simh NAT default
 fi
 ;;
vax)
 MACHINE_ARCH=vax
 MACHINE_GNU_PLATFORM=vax--netbsdelf		# for fdisk(8)
 TARGET_ENDIAN=le
 KERN_SET=kern-GENERIC
 SUFFIX_SETS=tgz
 EXTRA_SETS= # nothing
 RAW_PART=2		# raw partition is c:
 USE_MBR=no
 OMIT_SWAPIMG=no	# include swap partition in output image for emulators
 RTC_LOCALTIME=no	# use rtclocaltime=YES in rc.d(8) for Windows machines
 PRIMARY_BOOT=sdboot
 #SECONDARY_BOOT=boot	# /boot is in base.tgz
 BOOTSPEC="./boot type=file mode=0444"
 #SECONDARY_BOOT_ARG= # nothing
 INSTALLBOOTOPTIONS="-v"
 INSTALLBOOT_AFTER_DISKLABEL=yes
 VMHOSTNAME=microvax
 DISKNAME=netbsd-ci-${MACHINE}
 if [ -z "${HOST_IP}" ] ; then
  HOST_IP=10.0.2.2	# simh NAT default
 fi
 ;;
*)
	echo "Unsupported MACHINE (${MACHINE})"
	exit 1
	;;
esac

if [ -z "${RELEASEMACHINEDIR}" ]; then
	RELEASEMACHINEDIR=${MACHINE}
fi

if [ -z ${HOST_IP} ]; then
	echo "HOST_IP is not set"
	exit 1
fi

if [ "${USE_GPT}" = "yes" ] && [ "${OMIT_SWAPIMG}" = "yes" ]; then
	echo "Cannot omit swap if USE_GPT=yes"
	exit 1
fi

#
# tooldir settings
#

if [ -z ${NETBSDSRCDIR} ]; then
	echo "NETBSDSRCDIR is not set"
	exit 1
fi

if [ -z ${TOOLDIR} ]; then
	echo "TOOLDIR is not set"
	exit 1
fi

if [ ! -d ${TOOLDIR} ]; then
	echo "set TOOLDIR first (${TOOLDIR})"
	exit 1
fi
if [ ! -x ${TOOLDIR}/bin/nbmake-${MACHINE} ]; then
	echo "build tools in ${TOOLDIR} first"
	exit 1
fi

#
# misc build settings
#

# tools binaries
TOOL_DISKLABEL=${TOOLDIR}/bin/nbdisklabel
TOOL_FDISK=${TOOLDIR}/bin/${MACHINE_GNU_PLATFORM}-fdisk
TOOL_GPT=${TOOLDIR}/bin/nbgpt
TOOL_INSTALLBOOT=${TOOLDIR}/bin/nbinstallboot
TOOL_MAKEFS=${TOOLDIR}/bin/nbmakefs
TOOL_SED=${TOOLDIR}/bin/nbsed
TOOL_SUNLABEL=${TOOLDIR}/bin/nbsunlabel

# host binaries
CAT=cat
CP=cp
DD=dd
#FTP=ftp
#FTP_OPTIONS=-V -o -
FTP=curl
FTP_OPTIONS=-sSL
MKDIR=mkdir
RM=rm
SH=sh
TAR=tar
if [ "$SUFFIX_SETS" = "tar.xz" ]; then
	TAR_FILTER="-J"
else
	TAR_FILTER="-z"
fi
TOUCH=touch

[ -z "${TARGETROOTDIR}" ] && TARGETROOTDIR=$HOSTHOME/targetroot.${MACHINE}
WORKDIR=$HOSTHOME/work.${MACHINE}

#
# target image size settings
#
if [ -z "$IMAGEMB" ]; then
	IMAGEMB=5120		# 5120MB
fi
#SWAPMB=512			# 512MB
SWAPMB=0			# no swap

if [ "${USE_GPT}" = "yes" ]; then
	EFIMB=36		# min size of FAT32 (recommended for sanity)
	GPTMB=1			# 1MB (for the secondary GPT table/header)
else
	EFIMB=0
	GPTMB=0
fi

IMAGESECTORS=$((${IMAGEMB} * 1024 * 1024 / 512))
EFISIZE=$((${EFIMB} * 1024 * 1024))
EFISECTORS=$((${EFISIZE} / 512))
GPTSECTORS=$((${GPTMB} * 1024 * 1024 / 512))
SWAPSECTORS=$((${SWAPMB} * 1024 * 1024 / 512))

LABELSECTORS=0
if [ "${USE_MBR}" = "yes" ] || [ "${USE_GPT}" = "yes" ]; then
#	LABELSECTORS=63		# historical
#	LABELSECTORS=32		# aligned
	LABELSECTORS=2048	# align 1MiB for modern flash
fi
BSDPARTSECTORS=$((${IMAGESECTORS} - ${LABELSECTORS} - ${EFISECTORS} - ${GPTSECTORS}))
FSSECTORS=$((${IMAGESECTORS} - ${SWAPSECTORS} - ${LABELSECTORS} - ${EFISECTORS} - ${GPTSECTORS}))
FSOFFSET=$((${LABELSECTORS} + ${EFISECTORS}))
SWAPOFFSET=$((${LABELSECTORS} + ${FSSECTORS}))
FSSIZE=$((${FSSECTORS} * 512))
HEADS=64
SECTORS=32
CYLINDERS=$((${IMAGESECTORS} / ( ${HEADS} * ${SECTORS} ) ))
FSCYLINDERS=$((${FSSECTORS} / ( ${HEADS} * ${SECTORS} ) ))
SWAPCYLINDERS=$((${SWAPSECTORS} / ( ${HEADS} * ${SECTORS} ) ))

# fdisk(8) parameters
MBRSECTORS=63
MBRHEADS=255
MBRCYLINDERS=$((${IMAGESECTORS} / ( ${MBRHEADS} * ${MBRSECTORS} ) ))
MBRNETBSD=169

# makefs(8) parameters
BLOCKSIZE=16384
FRAGSIZE=4096
DENSITY=8192

# temporary image work files
WORKMBR=${WORKDIR}/work.mbr
WORKMBRTRUNC=${WORKDIR}/work.mbr.truncated
WORKSWAP=${WORKDIR}/work.swap
WORKEFI=${WORKDIR}/work.efi
WORKEFIDIR=${WORKDIR}/work.efidir
WORKGPT=${WORKDIR}/work.gpt
WORKFS=${WORKDIR}/work.rootfs
WORKLABEL=${WORKDIR}/work.diskproto
WORKIMG=${WORKDIR}/work.img

# temprary work files for rootfs
WORKFSTAB=${WORKDIR}/work.fstab
WORKSPEC=${WORKDIR}/work.spec

# GPT label names for fstab(5)
GPTROOTLABEL=${DISKNAME}_root
GPTSWAPLABEL=${DISKNAME}_swap

echo "Creating liveimage for ${MACHINE}..."

echo "Removing ${WORKDIR}..."
${RM} -rf ${WORKDIR}
${MKDIR} -p ${WORKDIR}

#
# fetch and extract binary sets
#
URL_SETS=http://${FTPHOST}/${RELEASEDIR}/${RELEASEMACHINEDIR}/binary/sets
#SETS="${KERN_SET} modules base rescue etc comp games gpufw man misc tests text xbase xcomp xetc xfont xserver ${EXTRA_SETS}"
#SETS="${KERN_SET} modules base rescue etc comp ${EXTRA_SETS}"
#SETS="${KERN_SET} base rescue etc comp ${EXTRA_SETS}"
SETS="${KERN_SET} base etc comp misc text xbase xcomp xetc xserver ${EXTRA_SETS}"

${RM} -rf ${TARGETROOTDIR}
${MKDIR} -p ${TARGETROOTDIR}
for set in ${SETS}; do
	echo "Fetch and extract ${set}.${SUFFIX_SETS}..."
	${FTP} ${FTP_OPTIONS} \
	    ${URL_SETS}/${set}.${SUFFIX_SETS} \
	    | ${TAR} -C ${TARGETROOTDIR} ${TAR_FILTER} -xf - \
	    || err ${FTP}
done

# XXX /var/spool/ftp/hidden is unreadable
chmod u+r ${TARGETROOTDIR}/var/spool/ftp/hidden

# XXX replace secondary bootloader /usr/mdec/ofwboot with the -current one
#     to make a created image bootable it with OpenBIOS on qemu-system-ppc
if [ "${MACHINE}" = "macppc" ]; then
	echo "Fetch and extract ${SECONDARY_BOOT} from HEAD..."
	HEAD_URL_SETS=https://nycdn.NetBSD.org/pub/NetBSD-daily/HEAD/latest/${MACHINE}/binary/sets
	${FTP} ${FTP_OPTIONS} \
	    ${HEAD_URL_SETS}/base.${SUFFIX_SETS} \
	    | ${TAR} -C ${TARGETROOTDIR} ${TAR_FILTER} -xf - \
	    ./usr/mdec/${SECONDARY_BOOT} \
	    || err ${FTP}
fi

# copy secondary boot for bootstrap
# XXX probabry more machine dependent
if [ ! -z ${SECONDARY_BOOT} ]; then
	echo "Copying secondary boot..."
	${CP} ${TARGETROOTDIR}/usr/mdec/${SECONDARY_BOOT} ${TARGETROOTDIR}
fi

# prepare MBR partition
if [ "${USE_MBR}" = "yes" ]; then
	echo "Creating MBR labels..."
	${DD} if=/dev/zero of=${WORKMBR} count=1 \
	    seek=$((${IMAGESECTORS} - 1)) \
	    || err ${DD}
	${TOOL_FDISK} -f -u \
	    -b ${MBRCYLINDERS}/${MBRHEADS}/${MBRSECTORS} \
	    -0 -a -s ${MBRNETBSD}/${FSOFFSET}/${BSDPARTSECTORS} \
	    -i -c ${TARGETROOTDIR}/usr/mdec/mbr \
	    -F ${WORKMBR} \
	    || err ${TOOL_FDISK}
	${DD} if=${WORKMBR} of=${WORKMBRTRUNC} count=${LABELSECTORS} \
	    || err ${DD}
fi

# prepare the primary and secondary GPT partition
if [ "${USE_GPT}" = "yes" ]; then
	echo "Creating GPT headers and tables..."
	${DD} if=/dev/zero of=${WORKMBR} count=1 \
	    seek=$((${IMAGESECTORS} - 1)) \
	    || err ${DD}
	${TOOL_GPT} ${WORKMBR} create || err ${TOOL_GPT}
	${TOOL_GPT} ${WORKMBR} add -a 1m -s ${EFISECTORS} \
	    -t efi -l "EFI system" || err ${TOOL_GPT}
	${TOOL_GPT} ${WORKMBR} add -a 1m -s ${FSSECTORS} \
	    -t ffs -l ${GPTROOTLABEL} || err ${TOOL_GPT}
	if [ "${SWAPMB}" -gt "0" ]; then
		${TOOL_GPT} ${WORKMBR} add -a 1m -s ${SWAPSECTORS} \
		    -t swap -l ${GPTSWAPLABEL} || err ${TOOL_GPT}
	fi
	${DD} if=${WORKMBR} of=${WORKMBRTRUNC} count=${LABELSECTORS} \
	    || err ${DD}
	${DD} if=${WORKMBR} of=${WORKGPT} \
	    skip=$((${IMAGESECTORS} - ${GPTSECTORS})) count=${GPTSECTORS} \
	    || err ${DD}
fi

#
# create target fs
#
echo "Preparing /etc/fstab..."
${CAT} > ${WORKFSTAB} <<EOF
ROOT.a		/		ffs	rw,log		1 1
ROOT.b		none		none	sw		0 0
kernfs		/kern		kernfs	rw		0 0
ptyfs		/dev/pts	ptyfs	rw		0 0
procfs		/proc		procfs	rw		0 0
/dev/cd0a	/cdrom		cd9660	ro,noauto	0 0
tmpfs		/tmp		tmpfs	rw,-s=128M	0 0
tmpfs		/var/shm	tmpfs	rw,-sram%25	0 0
EOF

if [ "${SWAPMB}" = "0" ]; then
	${TOOL_SED} -i	-e "s/ROOT.b/#ROOT.b/" ${WORKFSTAB}
fi
if [ "${USE_GPT}" = "yes" ]; then
	${TOOL_SED} -i\
		-e "s/ROOT.a/ROOT./"					\
		-e "s/ROOT.b/NAME=${GPTSWAPLABEL}/"			\
		${WORKFSTAB}
fi
${CP} ${WORKFSTAB} ${TARGETROOTDIR}/etc/fstab

echo "Setting liveimage specific configurations in /etc/rc.conf..."
${CAT} ${TARGETROOTDIR}/etc/rc.conf | \
    ${TOOL_SED} -e 's/rc_configured=NO/rc_configured=YES/' > ${WORKDIR}/rc.conf
if [ ${RTC_LOCALTIME}x = "yesx" ]; then
	echo rtclocaltime=YES		>> ${WORKDIR}/rc.conf
else
	echo \#rtclocaltime=YES		>> ${WORKDIR}/rc.conf
fi
if [ "${SWAPMB}" = "0" ]; then
	echo no_swap=YES		>> ${WORKDIR}/rc.conf
fi
cat >> ${WORKDIR}/rc.conf <<EOF
hostname=${VMHOSTNAME}
ccd=NO
raidframe=NO
cgd=NO
savecore=NO
#update_motd=NO
dmesg=NO
quota=NO
ldconfig=NO
modules=NO
certctl_init=YES
ppp=NO
syslogd=NO
cron=NO
postfix=NO
bthcid=NO
sdpd=NO
fccache=NO
virecover=NO
entropy=""
makemandb=NO
dhcpcd=YES
sshd=YES
EOF

${CP} ${WORKDIR}/rc.conf ${TARGETROOTDIR}/etc

echo "Preparing spec file for makefs..."
${CAT} ${TARGETROOTDIR}/etc/mtree/* | \
	${TOOL_SED} -e 's/ size=[0-9]*//' > ${WORKSPEC}
${SH} ${TARGETROOTDIR}/dev/MAKEDEV -s all | \
	${TOOL_SED} -e '/^\. type=dir/d' -e 's,^\.,./dev,' >> ${WORKSPEC}
# spec for optional files/dirs
${CAT} >> ${WORKSPEC} <<EOF
${BOOTSPEC}
./cdrom				type=dir  mode=0755
./kern				type=dir  mode=0755
./netbsd			type=file mode=0755
./proc				type=dir  mode=0755
./tmp				type=dir  mode=1777
EOF

echo "Setup target ssh_config..."
cat > ${WORKDIR}/sshd_config <<EOF
AllowUsers root@${HOST_IP}
PermitRootLogin yes
#PermitEmptyPasswords yes
#AuthenticationMethods none
#UsePam no
IgnoreUserKnownHosts yes
EOF
cat ${TARGETROOTDIR}/etc/ssh/sshd_config >> ${WORKDIR}/sshd_config
cp ${WORKDIR}/sshd_config ${TARGETROOTDIR}/etc/ssh

echo "Setup target ssh_host keys..."
ssh-keygen -t ecdsa -f ${TARGETROOTDIR}/etc/ssh/ssh_host_ecdsa_key -N '' -q
ssh-keygen -t ed25519 -f ${TARGETROOTDIR}/etc/ssh/ssh_host_ed25519_key -N '' -q
ssh-keygen -t rsa -f ${TARGETROOTDIR}/etc/ssh/ssh_host_rsa_key -N '' -q

echo "Setup host ssh_host keys..."
mkdir -p $HOSTHOME/.ssh
ssh-keygen -t ed25519 -f $HOSTHOME/.ssh/id_ed25519 -N '' -q

echo "Setup host ssh_config..."
cat > $HOSTHOME/.ssh/config <<EOF
StrictHostKeyChecking no
Host *
 IdentityFile ~/.ssh/id_ed25519
EOF

echo "Setup target ssh authorized_keys..."
mkdir -p ${TARGETROOTDIR}/root/.ssh
touch ${TARGETROOTDIR}/root/.ssh/authorized_keys
cat $HOSTHOME/.ssh/id_ed25519.pub >> ${TARGETROOTDIR}/root/.ssh/authorized_keys
chmod 600 ${TARGETROOTDIR}/root/.ssh/authorized_keys

cat >> ${WORKSPEC} <<EOF
./etc/ssh/ssh_host_ecdsa_key type=file uname=root gname=wheel  mode=0600
./etc/ssh/ssh_host_ecdsa_key.pub type=file uname=root gname=wheel  mode=0644
./etc/ssh/ssh_host_ed25519_key type=file uname=root gname=wheel  mode=0600
./etc/ssh/ssh_host_ed25519_key.pub type=file uname=root gname=wheel  mode=0644
./etc/ssh/ssh_host_rsa_key type=file uname=root gname=wheel  mode=0600
./etc/ssh/ssh_host_rsa_key.pub type=file uname=root gname=wheel  mode=0644
./root/.ssh type=dir uname=root gname=wheel mode=0755
./root/.ssh/authorized_keys type=file uname=root gname=wheel  mode=0600
EOF

echo "Enable PKG_PATH in dot files..."
${TOOL_SED} -i -e "/^#export PKG_PATH/ s/^#//" ${TARGETROOTDIR}/root/.profile
${TOOL_SED} -i -e "/^#setenv PKG_PATH/ s/^#//" ${TARGETROOTDIR}/root/.cshrc

if [ ! -z "${GITHUB_WORKSPACE}" ] && [ -d ${GITHUB_WORKSPACE} ]; then
	echo "Copying ${GITHUB_WORKSPACE} files to target image..."
	mkdir -p ${TARGETROOTDIR}${HOSTHOME}
	(cd $HOSTHOME && ${TAR} --exclude _actions \
	    --exclude _PipelineMapping --exclude _temp -cf - work | \
	    (cd ${TARGETROOTDIR}${HOSTHOME}; ${TAR} -xf -) )
	cat >> ${WORKSPEC} <<EOF
./home type=dir uname=root gname=wheel mode=0755
.${HOME} type=dir uname=root gname=wheel mode=0755
.${HOME}/work type=dir uname=root gname=wheel mode=0755
EOF
fi

echo "Creating rootfs..."
${TOOL_MAKEFS} -M ${FSSIZE} -m ${FSSIZE} \
	-B ${TARGET_ENDIAN} \
	-F ${WORKSPEC} -N ${TARGETROOTDIR}/etc \
	-o bsize=${BLOCKSIZE},fsize=${FRAGSIZE},density=${DENSITY} \
	${MAKEFSOPTIONS} \
	${WORKFS} ${TARGETROOTDIR} \
	|| err ${TOOL_MAKEFS}

if [ ${PRIMARY_BOOT}x != "x" ] && [ "${INSTALLBOOT_AFTER_DISKLABEL}x" != "yesx" ]; then
echo "Installing bootstrap..."
${TOOL_INSTALLBOOT} ${INSTALLBOOTOPTIONS} -m ${MACHINE} ${WORKFS} \
    ${TARGETROOTDIR}/usr/mdec/${PRIMARY_BOOT} ${SECONDARY_BOOT_ARG} \
    || err ${TOOL_INSTALLBOOT}
fi

#
# create EFI system partition
#
if [ "${USE_GPT}" = "yes" ]; then
	echo "Creating EFI system partition..."
	echo "Removing ${WORKEFIDIR}..."
	${RM} -rf ${WORKEFIDIR}
	${MKDIR} -p ${WORKEFIDIR}
	${MKDIR} -p ${WORKEFIDIR}/EFI/boot
	for boot in ${EFIBOOT}; do
		${CP} ${TARGETROOTDIR}/usr/mdec/${boot} ${WORKEFIDIR}/EFI/boot
	done
	${RM} -f ${WORKEFI}
	${TOOL_MAKEFS} -M ${EFISIZE} -m ${EFISIZE} \
	    -B ${TARGET_ENDIAN} -t msdos -o fat_type=32,sectors_per_cluster=1 \
	    ${WORKEFI} ${WORKEFIDIR} \
	    || err ${TOOL_MAKEFS}
fi

if [ "${OMIT_SWAPIMG}x" != "yesx" ] && [ "$SWAPMB" -gt "0" ]; then
	echo "Creating swap fs"
	${DD} if=/dev/zero of=${WORKSWAP} \
	    seek=$((${SWAPSECTORS} - 1)) count=1 \
	    || erro ${DD}
fi

echo "Copying target disk image..."
rm -f ${WORKIMG}
if [ "${USE_MBR}" != "yes" ] && [ "${USE_GPT}" != "yes" ] && [ "$SWAPMB" = "0" ]; then
	# no need to concatinate images
	mv ${WORKFS} ${WORKIMG}
else
	${TOUCH} ${WORKIMG}
	# add MBR and the primary GPT partition region
	if [ ${LABELSECTORS} != 0 ]; then
		${CAT} ${WORKMBRTRUNC} >> ${WORKIMG} || err ${CAT}
	fi
	# add EFI FAT partition
	if [ "${USE_GPT}" = "yes" ]; then
		${CAT} ${WORKEFI} >> ${WORKIMG} || err ${CAT}
	fi
	# add NetBSD root partition
	${CAT} ${WORKFS} >> ${WORKIMG} || err ${CAT}
	# add swap
	if [ "${OMIT_SWAPIMG}x" != "yesx" ] && [ "$SWAPMB" -gt "0" ]; then
		${CAT} ${WORKSWAP} >> ${WORKIMG} || err ${CAT}
	fi
	# add the secondary GPT table (at the end of the target image)
	if [ "${USE_GPT}" = "yes" ]; then
		${CAT} ${WORKGPT} >> ${WORKIMG} || err ${CAT}
	fi
fi

if [ ! -z ${USE_SUNLABEL} ]; then
	echo "Creating sun disklabel..."
	printf 'V ncyl %d\nV nhead %d\nV nsect %d\na %d %d/0/0\nb %d %d/0/0\nW\n' \
	    ${CYLINDERS} ${HEADS} ${SECTORS} \
	    ${FSOFFSET} ${FSCYLINDERS} ${FSCYLINDERS} ${SWAPCYLINDERS} | \
	    ${TOOL_SUNLABEL} -nq ${WORKIMG} \
	    || err ${TOOL_SUNLABEL}
fi

if [ "${USE_GPT}" = "yes" ]; then
	echo "Finalize GPT entries..."
	if [ "${USE_GPTMBR}" = "yes" ]; then
		${TOOL_GPT} ${WORKIMG} biosboot -i 2 \
		    -c ${TARGETROOT}/usr/mdec/gptmbr.bin || err ${TOOL_GPT}
	fi
	${TOOL_GPT} ${WORKIMG} set -a bootme -i 2 || err ${TOOL_GPT}
else
	echo "Creating disklabel..."
	${CAT} > ${WORKLABEL} <<EOF
type: ESDI
disk: ${DISKNAME}
label:
flags:
bytes/sector: 512
sectors/track: ${SECTORS}
tracks/cylinder: ${HEADS}
sectors/cylinder: $((${HEADS} * ${SECTORS}))
cylinders: ${CYLINDERS}
total sectors: ${IMAGESECTORS}
rpm: 3600
interleave: 1
trackskew: 0
cylinderskew: 0
headswitch: 0		# microseconds
track-to-track seek: 0	# microseconds
drivedata: 0

8 partitions:
#        size    offset     fstype [fsize bsize cpg/sgs]
a:    ${FSSECTORS} ${FSOFFSET} 4.2BSD ${FRAGSIZE} ${BLOCKSIZE} 128
b:    ${SWAPSECTORS} ${SWAPOFFSET} swap
c:    ${BSDPARTSECTORS} ${FSOFFSET} unused 0 0
d:    ${IMAGESECTORS} 0 unused 0 0
EOF
	if [ "${SWAPMB}" = "0" ]; then
		${TOOL_SED} -i -e "s/^b: /#b: /" ${WORKLABEL}
	fi
	if [ "${RAW_PART}" = "2" ]; then
		${TOOL_SED} -i -e "s/^c: /#c: /" -e "s/^d: /c: /" ${WORKLABEL}
	fi

	${TOOL_DISKLABEL} -R -F -M ${MACHINE} -B ${TARGET_ENDIAN} ${WORKIMG} ${WORKLABEL} \
	    || err ${TOOL_DISKLABEL}
fi

if [ ${PRIMARY_BOOT}x != "x" ] && [ "${INSTALLBOOT_AFTER_DISKLABEL}x" = "yesx" ]; then
echo "Installing bootstrap..."
${TOOL_INSTALLBOOT} ${INSTALLBOOTOPTIONS} -m ${MACHINE} ${WORKIMG} \
    ${TARGETROOTDIR}/usr/mdec/${PRIMARY_BOOT} ${SECONDARY_BOOT_ARG} \
    || err ${TOOL_INSTALLBOOT}
fi

mv ${WORKIMG} ${IMAGE}
echo "Creating image \"${IMAGE}\" complete."
