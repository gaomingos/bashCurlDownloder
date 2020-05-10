## cURL 分片下载大文件脚本
`
 依赖程序库有 bash  curl ps bc ... 等等系统工具
`
### 使用方法
`
 chmod u+x d.sh dworker.sh
`
`
 ./d.sh <file name> <download url> [max thread]
`
#### 例如:
`
./d.sh   go1.14.2.src.tar.gz   https://dl.google.com/go/go1.14.2.src.tar.gz  20
`

