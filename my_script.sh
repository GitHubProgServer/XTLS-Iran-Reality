#!/bin/bash

#-----------------------FUNCTION: Change standard SSH port --------------------
function SSHPortChange {

# Initialisation of var with #Port 22 line
sshLineToFind="#Port 22"
# Initialisation of var with path to file with ssh settings
sshSettingsFileName="/etc/ssh/sshd_config"

echo -n "Input new SSH port: "
read sshNewPort
sshLineNew="Port $sshNewPort"

#echo "Line to insert: $sshLineNew"

sshLineToFindNum=$(sed -n "/$sshLineToFind/=" $sshSettingsFileName)
if [[ $sshLineToFindNum -gt 0 ]]
then
        sed -i "s/$sshLineToFind/$sshLineNew/" $sshSettingsFileName
        echo "SSH Port 22 was changed on $sshNewPort"
        #restarting ssh demon
        systemctl restart sshd
else
        echo "#Port 22 line wasn't found"
fi


}
#-------------------------------------------------------------------------------


#-----------------------FUNCTION: Fail2Ban Change Settings----------------------

function Fail2BanSetUp {

cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

#----------------------------------Set up buntime in Fail2Ban-------------------
# Initialisation of file name
fileNameToChange="/etc/fail2ban/jail.local"

# Initialisation  str for finding
firstLineToFind="^\# \"bantime\" is the number of seconds that a host is banned."
secondLineToFind="bantime  = 10m"
# Initialisation value of str which to be expected to set up
newBantimeLine="bantime  = 30m"

# Find number of first line
numLine=$(sed -n "/$firstLineToFind/=" $fileNameToChange)

# Calculation namber of next line after first line
nextLine=$((numLine+1))

# Read value of  next line
nextLineVal=$(sed -n "$nextLine p" $fileNameToChange)
#echo $nextLineVal

# Bantime will be setted up only if both first and second line would be equal to firstLineToFind and secondLineToFind
echo "1):"
if [[ $numLine ]] && [[ $nextLineVal = $secondLineToFind ]]
then
        sed -i "$nextLine c\\$newBantimeLine" $fileNameToChange
        echo "Bantime has been changed to 30m"
else
        echo "Bantime=10m line has not been found!"
fi

#-------------------------------------------------------------------------------
#----------------------------------Add "enabled = true" to [sshd] section--------
sshdLineToFind="^\[sshd\]"
# sshdLineNum=$(grep -Fn "/^\[sshd\]/=" jail_test.local)  - this line doesn't work

sshdLineNum=$(sed -n "/$sshdLineToFind/=" $fileNameToChange)

#echo $sshdLineNum

echo "2):"
if [[ $sshdLineNum -gt 0 ]]
then
        numLineForIns=$((sshdLineNum+2))
        sed -i "$numLineForIns i enabled \= true" $fileNameToChange
        echo "enabled = true was added"
else
        echo "[sshd] section was't found"
fi

echo "3):"
systemctl enable fail2ban
echo "4):"
systemctl restart fail2ban
echo "5):"
systemctl status fail2ban
echo ""
}
#-------------------------------------------------------------------------------


#-----------------------Change network settings---------------------------------
function NetworkChangeSetting {

#--------/etc/sysctl.conf-----------
sysctlFilePath="/etc/sysctl.conf"

lineToAppend1="net.ipv4.tcp_keepalive_time = 90"
lineToAppend2="net.ipv4.ip_local_port_range = 1024 65535"
lineToAppend3="net.ipv4.tcp_fastopen = 3"
lineToAppend4="net.core.default_qdisc=fq"
lineToAppend5="net.ipv4.tcp_congestion_control=bbr"
lineToAppend6="fs.file-max = 65535000"

sed -i "$ a $lineToAppend1" $sysctlFilePath
sed -i "$ a $lineToAppend2" $sysctlFilePath
sed -i "$ a $lineToAppend3" $sysctlFilePath
sed -i "$ a $lineToAppend4" $sysctlFilePath
sed -i "$ a $lineToAppend5" $sysctlFilePath
sed -i "$ a $lineToAppend6" $sysctlFilePath

#-----------------------------------
#-------/etc/security/limits.conf---
limitsFilePath="/etc/security/limits.conf"

lineToAppend7="* soft     nproc          655350"
lineToAppend8="* hard     nproc          655350"
lineToAppend9="* soft     nofile         655350"
lineToAppend10="* hard     nofile         655350"
lineToAppend11="root soft     nproc          655350"
lineToAppend12="root hard     nproc          655350"
lineToAppend13="root soft     nofile         655350"
lineToAppend14="root hard     nofile         655350"

sed -i "$ a $lineToAppend7" $limitsFilePath
sed -i "$ a $lineToAppend8" $limitsFilePath
sed -i "$ a $lineToAppend9" $limitsFilePath
sed -i "$ a $lineToAppend10" $limitsFilePath
sed -i "$ a $lineToAppend11" $limitsFilePath
sed -i "$ a $lineToAppend12" $limitsFilePath
sed -i "$ a $lineToAppend13" $limitsFilePath
sed -i "$ a $lineToAppend14" $limitsFilePath

sysctl -p
echo "Settings in files /etc/sysctl.conf and /etc/security/limits.conf were changed and applied."
#-----------------------------------
}
#-------------------------------------------------------------------------------

#-----------------------Add Hosta name in file /etc/hosts-----------------------
function AddHostNameInHostFile{
host_fileName="/etc/hosts"

hostNameVar=`hostname`

lineToAddIn_hosts="127.0.0.1    $hostNameVar"

#echo "строка для добавления: $lineToAddIn_hosts"

findHostNameNumLine=$(sed -n "/$hostNameVar/=" $host_fileName)



if [[ $findHostNameNumLine == "" ]]
then
        sed -i "$ a $lineToAddIn_hosts" $host_fileName
        #echo "подстрока добавлена в файл в строку: $findHostNameNumLine"
#else
        #echo "подсрока уже содержиться в строке: $findHostNameNumLine"

fi

}
#-------------------------------------------------------------------------------

#--------------Upload file xray.service and move to destination folder /etc/systemd/system-------------------------------
function UploadFileOfService{

xrayServiceDestFolder="/etc/systemd/system/"                                    # veriable with destination folder for xray.service file
xrayServiceFileName="xray.service"                                              # veriable with xray.service file name
xrayServiceFullPath="${xrayServiceDestFolder}${xrayServiceFileName}"            # veriable with full path to destination folder fro xray.service file

echo $xrayServiceFullPath

temp_dir_for_upload="/usr/tmp_xray_settings"

if [[ -f $xrayServiceFullPath ]]                                                        # check existing of object and check if it is file
then
        #echo "-------------------"
        rm $xrayServiceFullPath
        #echo "файл существует и удален"
#else
        #echo "файл НЕ найден"

fi

mkdir $temp_dir_for_upload                                                      # create temp folder for upload
cd $temp_dir_for_upload
wget https://raw.githubusercontent.com/GitHubProgServer/XTLS-Iran-Reality/main/xray_nobody.service
mv xray_nobody.service $xrayServiceFileName                                     # rename uploaded file to current name

mv "${temp_dir_for_upload}/${xrayServiceFileName}" $xrayServiceFullPath         # remove xray.service to folder with services

rm -r $temp_dir_for_upload                                                      # remove temp folder

}
#-------------------------------------------------------------------------------

#--------------------------------MAIN PART OF SCRIPT----------------------------

echo ""
echo "-------------------------------SCRIPT LOG---------------------------------"

apt update -y
apt upgrade -y
apt install nano -y
apt install fail2ban -y
apt install unzip -y

SSHPortChange
Fail2BanSetUp
NetworkChangeSetting
AddHostNameInHostFile
UploadFileOfService

mkdir /opt/xray
cd /opt/xray
wget https://github.com/bootmortis/iran-hosted-domains/releases/latest/download/iran.dat
wget https://github.com/XTLS/Xray-core/releases/download/v1.8.3/Xray-linux-64.zip
unzip Xray-linux-64.zip
rm Xray-linux-64.zip
echo "--------------------------------------------------------"
echo "UUID:"
/opt/xray/xray uuid
echo "Pub key+Private key:"
/opt/xray/xray x25519
echo "shot ID:"
openssl rand -hex 8
echo "Shadowsocks Pass:"
openssl rand -base64 16





echo "-------------------------------SCRIPT ENDED------------------------------"
#--------------------------------END MAIN PART OF SCRIPT------------------------

