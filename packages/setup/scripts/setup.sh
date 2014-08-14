#!/bin/bash

export TERM=linux

. gettext.sh
export TEXTDOMAIN=openpctv

. /etc/lsb-release
[ -z ${DISTRIB_ID} ] && DISTRIB_ID=OpenPCTV
[ -f /etc/system.options ] && . /etc/system.options
[ -z $DEFTARGET ] && DEFTARGET=xbmc

source /etc/profile

grep -E -q "BCM2708|A20" /proc/cpuinfo && sleep 1.5

if grep -q -i arm /proc/cpuinfo; then
  ARCH=arm
  echo -e -n "\e[31m$(gettext "Press any key to enter setup,")\e[0m \e[32m$(gettext "or 3 seconds later enter") ${DEFTARGET}.\e[0m"
  read -s -n1 -t4
  result=$?
  if [ $result = 142 -o $result = 130 ]; then
    if [ $DEFTARGET = "xbmc" ]; then
      systemctl start getty\@ttymxc0
      systemctl start vdr-backend
      systemctl start xbmc
      exit 0
    elif [ $DEFTARGET = "vdr" ]; then
      systemctl start vdr
      exit 0
    fi
  elif [ $result = 0 ]; then
    clear
  fi
fi


DIALOG=/usr/bin/dialog
DIALOGOUT="/tmp/dialogout"
VDRETCDIR=/etc/vdr
EDIT=/bin/nano

MENUTMP=/tmp/menu.$$

RUN_LANG=/usr/bin/select-language
RUN_TARGET=/usr/bin/select-target
RUN_NET=/usr/bin/netconfig
RUN_DRV=/usr/bin/install-drivers
RUN_IR=/usr/bin/select-irdrv
RUN_MONITOR=/usr/bin/monitor.sh
RUN_AUDIO=/usr/bin/audio-config
RUN_CAM=/usr/bin/getcam
RUN_EPG=/usr/bin/update-epg
RUN_TRANS=/usr/bin/update-transponders
RUN_DVB=/usr/bin/update-dvbdevice
RUN_DISEQC=/usr/bin/diseqcsetup
RUN_CHANNELS=/usr/bin/update-channels
RUN_PLUGINS=/usr/bin/select-plugins
RUN_INSTALLER=/sbin/installator

function updatelocale
{
. /etc/locale.conf && export LANG
}

function setupinit
{
[ -f $RUN_LANG ] && $RUN_LANG
updatelocale
[ -f $RUN_NET ] && $RUN_NET
[ -f $RUN_DRV ] && $RUN_DRV
[ -f $RUN_TARGET ] && $RUN_TARGET
#[ -f $RUN_IR ] && $RUN_IR
#systemctl restart lircd
systemctl stop vdr
systemctl stop vdr-backend
[ -f $RUN_MONITOR ] && $RUN_MONITOR
[ -f $RUN_AUDIO ] && $RUN_AUDIO init
[ -f $RUN_CAM ] && $RUN_CAM
[ -f $RUN_EPG ] && $RUN_EPG
[ -f $RUN_TRANS ] && $RUN_TRANS
[ -f $RUN_DVB ] && $RUN_DVB
if dialog --defaultno --clear --yes-label "$(gettext "Configure VDR")" --no-label "$(gettext "Configure VDR later")" --yesno "$(gettext "The following configuration is for the VDR (note the XBMC uses VDR as a PVR backend), if you only use Engima2, then you do not need to configure or re-configure VDR later.")" 7 70; then
  [ -f $RUN_PLUGINS ] && $RUN_PLUGINS
  [ -f $RUN_DISEQC ] && $RUN_DISEQC
  [ -f $RUN_CHANNELS ] && $RUN_CHANNELS
fi
if dialog --clear --yes-label "$(gettext "Reboot")" --no-label "$(gettext "Main menu")" --yesno "$(gettext "Now, you have completed the most configurations of VDR(for Enigma2 need to be in its OSD menu) . Now you can select 'Reboot' or 'Main Menu' to continue the configuration.")" 8 70; then
  reboot
fi
}

function MainMenu
{
updatelocale
echo "${DIALOG} --clear --no-cancel --backtitle \"${DISTRIB_ID} $(gettext "configuration")\" --menu \"$(gettext "Main menu")\" 22 60 15 \\" > $MENUTMP
[ -f $RUN_LANG ] && echo "Lang \"$(gettext "Set global location and language")\" \\" >> $MENUTMP
[ -f $RUN_TARGET ] && echo "Target \"$(gettext "Set the default target")\" \\" >> $MENUTMP
[ -f $RUN_NET ] && echo "Netconf \"$(gettext "Configure Network Environment")\" \\" >> $MENUTMP
[ -f $RUN_DRV ] && echo "Driver \"$(gettext "Install additional DVB driver")\" \\" >> $MENUTMP
#[ -f $RUN_IR ] && echo "Lirc \"$(gettext "Select IR device")\" \\" >> $MENUTMP
[ -f $RUN_MONITOR ] && echo "Monitor \"$(gettext "Set the monitor's best resolution")\" \\" >> $MENUTMP
[ -f $RUN_AUDIO ] && echo "Audio \"$(gettext "Sound card Configuration")\" \\" >> $MENUTMP
[ -f $RUN_TRANS ] && echo "Uptran \"$(gettext "Update Satellite Transponders")\" \\" >> $MENUTMP
[ -f $RUN_EPG ] && echo "EPG \"$(gettext "Update EPG data")\" \\" >> $MENUTMP
[ -f $RUN_PLUGINS ] && echo "Plugins \"$(gettext "Select VDR-plugins")\" \\" >> $MENUTMP
[ -f $RUN_CAM ] && echo "CAM \"$(gettext "Select a software emulated CAM")\" \\" >> $MENUTMP
[ -f $RUN_DISEQC ] && echo "DiSEqC \"$(gettext "DiSEqC configuration")\" \\" >> $MENUTMP
[ -f $RUN_CHANNELS ] && echo "Scan \"$(gettext "Auto scan channels")\" \\" >> $MENUTMP
#grep -q BCM2708 /proc/cpuinfo && echo "VDR \"$(gettext "Start VDR with rpihddevice frontend")\" \\" >> $MENUTMP
[ -x /usr/bin/runxbmc ] && echo "XBMC \"$(gettext "Start XBMC pvr with VDR backend")\" \\" >> $MENUTMP
[ -x /usr/bin/runvdr ] && echo "VDR \"$(gettext "Start VDR frontend")\" \\" >> $MENUTMP
[ -x /usr/bin/runenigma2 ] && echo "Enigma2 \"$(gettext "Start Enigam2 frontend")\" \\" >> $MENUTMP
[ X$ARCH != "Xarm" -a -f $RUN_INSTALLER ] && echo "Install \"$(gettext "Install OpenPCTV to your hard disk")\" \\" >> $MENUTMP
echo "Exit \"$(gettext "Exit to login shell")\" \\" >> $MENUTMP
echo "Reboot \"$(gettext "Reboot") ${DISTRIB_ID}\" 2> $DIALOGOUT" >> $MENUTMP
. $MENUTMP
rm $MENUTMP
case "$(cat $DIALOGOUT)" in
    Lang)	$RUN_LANG
		MainMenu
		;;
    Target)	$RUN_TARGET
		MainMenu
		;;
    Netconf)	$RUN_NET
		MainMenu
		;;
    Driver)	$RUN_DRV
		$RUN_DVB
		MainMenu
		;;
    Lirc)	$RUN_IR
		systemctl restart lircd
    		MainMenu
 		;;
    Uptran)	$RUN_TRANS
    		MainMenu
  		;;
    EPG)	$RUN_EPG
		MainMenu
		;;
    Plugins)	$RUN_PLUGINS
		MainMenu
		;;
    CAM)	$RUN_CAM
		MainMenu
		;;
    DiSEqC)	systemctl stop vdr
		systemctl stop vdr-backend
		$RUN_DISEQC
    		MainMenu
  		;;
    Scan)	systemctl stop vdr
		systemctl stop vdr-backend
		$RUN_CHANNELS
		MainMenu
		;;
    Monitor)	$RUN_MONITOR
		MainMenu
		;;
    Audio)	$RUN_AUDIO
		MainMenu
		;;
    VDR)	systemctl start vdr
		;;
    Enigma2)	systemctl start enigma2pc
		;;
    XBMC)	systemctl start getty\@ttymxc0
		systemctl start vdr-backend
		systemctl start xbmc
		;;
    Install)	$RUN_INSTALLER
		;;
    Reboot)	reboot
		;;
    Exit)	clear
		systemctl start getty\@tty1
		systemctl start getty\@ttymxc0
    		exit 0
    		;;
esac
rm $DIALOGOUT
}

[ X$1 = "Xinit" -a ! -f /etc/system.options ] && setupinit
MainMenu
