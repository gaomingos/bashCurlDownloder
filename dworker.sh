#!/bin/bash
  
offset1=$1
offset2=$2
part=$3
downloadUrl=$4
lockfile=$5

retry=3
err=0
while [ $retry -gt 0 ]
do
  curl  --range $offset1-$offset2 -o "$part" "$downloadUrl" 
  if [ $? -eq 0 ];then
   retry=0
   err=0
  else
   rm -f $part
   err=1
   retry=$(($retry - 1))
  fi
done
if [ $err -eq 0 ];then
 echo "--range $offset1-$offset2 download OK." >> $lockfile
else
 echo "--range $offset1-$offset2 download ERROR! Plase Retry Part: curl  --range $offset1-$offset2 -o $part $downloadUrl " >> $lockfile
fi
