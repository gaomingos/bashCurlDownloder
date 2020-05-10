#!/bin/bash
fileName=$1
downloadUrl=$2
totalTh=$3
dir=`pwd`
tmpDir="$dir/.tpm.part"
lockfile="$tmpDir/lock"
log="$dir/out.$fileName.log"
cat /dev/null > $log
mkdir $tmpDir
touch $lockfile
if [ -z "$fileName" ];then
 echo "参数错误!  示例:  d.sh <fileName> <downloadUrl> [threadNumber]"
 echo "参数错误!  示例:  d.sh <fileName> <downloadUrl> [threadNumber]" >> $log
 exit 1
fi
if [ -z "$downloadUrl" ];then
 echo "参数错误!  示例:  d.sh <fileName> <downloadUrl> [threadNumber]"
 echo "参数错误!  示例:  d.sh <fileName> <downloadUrl> [threadNumber]" >> $log
 exit 1
fi
if [ -z "$totalTh" ];then
 totalTh=100
fi
if [ $totalTh -gt 150 ];then
 totalTh=100
fi
CURL=curl
len=$($CURL -I  "$downloadUrl" | grep "Content-Length" | awk '{print $2}' | sed 's///g' | sed 's/\n//g')
echo "获取文件大小: $len bytes"
echo "获取文件大小: $len bytes" >> $log
if [ -z "$len" ];then
 echo "获取文件长度错误! 退出..."
 echo "获取文件长度错误! 退出..." >> $log
 exit 1
fi
if [ $len -lt 1 ];then
 echo "文件长度为 0 ! 退出..."
 echo "文件长度为 0 ! 退出..." >> $log
 exit 1
fi

# 1 MB = 1048576 bytes
#m=1048576
# 500KB
#m=512000
# 300KB
m=307200

if [ $len -le $m ];then
 echo "文件不大于 1 MB, 单线程下载即可."
 echo "文件不大于 1 MB, 单线程下载即可." >> $log
 $CURL "$downloadUrl"  -o "$dir/$fileName"   >> $log 2>&1
 echo "文件下载中..." 
 echo "文件下载中..." >> $log
 exit 0
fi


mod=$(($len % $m))
cnt=$(($len / $m))

total=$cnt

if [ $mod -ne 0 ];then
  total=$(($cnt + 1))
fi

echo "文件大于 1 MB, 使用多线程下载, 每个线程下载最多 1 MB"
echo "文件大于 1 MB, 使用多线程下载, 每个线程下载最多 1 MB" >> $log
echo "下载总的分片数: $total"
echo "下载总的分片数: $total" >> $log


part=1


while [ $part -lt $total ]
do
  offset1=$(($part * $m + $part - 1 - $m))
  offset2=$(($offset1 + $m))
  touch "$tmpDir/file.part.$part"
  if [ $part -lt $(($total - 1)) ];then
   echo "下载分片 $part --range $offset1-$offset2" >> $log
   nohup ./dworker.sh  $offset1  $offset2 "$tmpDir/file.part.$part"  "$downloadUrl" $lockfile > /dev/null 2>&1  &
  else
   echo "下载分片 $part --range $offset1-$len"   >> $log
   nohup ./dworker.sh  $offset1 $len "$tmpDir/file.part.$part" "$downloadUrl"  $lockfile  > /dev/null 2>&1 &
  fi
  thread=$(ps aux|grep "./dworker.sh" | grep -v "grep"|wc -l)
  while [ $thread -ge $totalTh ]
  do
    echo -ne "已经达到最大下载线程数量: $totalTh, 等待中... 总分片数: $total  已经运行线程数: $part \r"
    sleep 20
    thread=$(ps aux|grep "./dworker.sh" | grep -v "grep"|wc -l)
  done
  echo -ne "最大下载线程数量: $totalTh, 总分片数: $total  当前正在下载分片数: $thread   已经运行线程数: $part \r"
  part=$(($part+1))
done

# 等待文件下载完成
echo "文件正在下载..."
lock=$(cat $lockfile | wc -l)
while [ $lock -lt $(($total - 1)) ]
do
  sleep 5 
  lock=$(cat $lockfile | wc -l)
  bcount=($(ls -l $tmpDir | grep file.part.* | awk '{print $5}'))
  cbytes=0
  for((i=0;i<${#bcount[@]};i++))
  do 
     cbytes=$(($cbytes + ${bcount[i]}))
  done
  d=$(($len - $cbytes))
  p=$(echo "scale=4;$cbytes/$len*100.00" | bc)
  echo -ne "下载还剩余: $d  bytes   已完成: $p % \r"
done

echo "下载完成, 合并分片文件..."
echo "下载完成, 合并分片文件..." >> $log
part=1
while [ $part -lt $total ]
do
 cat "$tmpDir/file.part.$part" >> "$dir/$fileName"
 part=$(($part + 1))
 
done
err=$(cat $lockfile| grep "ERROR")
if [ -n "$err" ];then
 echo "有分片下载错误！！！！！"
 echo $err
 exit 1
fi
rm -rf "$tmpDir"

echo "分片文件合并完成: $dir/$fileName"
echo "分片文件合并完成: $dir/$fileName" >> $log

echo "下载任务结束!"
echo "下载任务结束!" >> $log

exit 0


