#!/usr/bin/env bash
#
# The code fence's header-line: c arg1 arg2 : cmd1 {fileout} : cmd2 {file}
#
#echo "$@"
filetype=$1
filepath=$2
shift
shift
params=$@
fileout="/tmp/vim_a.out"

#echo "filepath=$filepath"
#echo "params=$params"
#echo "===vim-floaterm-repl:terminal_preview.sh===="
#echo "---------------------"

if ! command -v boxes &> /dev/null; then
    echo "Start $filetype"
else
    echo "Start $filetype" | boxes -d java-cmt
fi
echo ""

case $filetype in
  javascript | js)
     node $filepath $params
    ;;

  bash | sh)
     bash $filepath $params
    ;;

  go )
      go run $filepath $params
    ;;

  rust )
      filename=$(basename $filepath .rust)
      rustc $filepath $params && ./$filename
    ;;

  expect | Expect)
      expect $filepath $params
    ;;

  python | python3)
      python3 $filepath $params
    ;;

  awk )
      LC_ALL=C awk -f $filepath $params
    ;;

  c | C)
      rm -fr $fileout
      gcc -pthread -lrt -g -O0 -finstrument-functions -fms-extensions -o $fileout $filepath
      #gcc -pthread -std=c11 -lrt -g -O0 -finstrument-functions -fms-extensions -o $fileout $filepath

    ######################################################
    ###### For example, put our testcase as comment like this
    ######################################################
	#/*
	#https://linuxhint.com/using_mmap_function_linux/
	#mmap used to Writing file

	#size-of
	#	 file   map  write unmap
	#	 1024  2048  2048  2048

	#>>> {fileout}  1024  2048  2048  2048
	#>>> echo Normal

	#>>> {fileout}  1024  2048  2048  3048
	#>>> echo OK: unmap more size

	#>>> {fileout}  1024  2048  2048  5048
	#>>> echo ERROR: unmap > 4K page (Segmentation-fault)

	#>>> {fileout}  1024  2048  4096  2048
	#>>> echo OK: write < 4K-page

	#>>> {fileout}  1024  2048  4097  2048
	#>>> echo ERROR: write > 4K page (Bus error)

	#>>> size {fileout}
	#>>> ls -l {file}
	#*/

      # If code-fence provide test-data, use it, otherwise run directly
      # echo "LIBRARY_TRGT_CANV,CANV_MATCH<anything>"|awk -F "_TRGT_" '{print $NF}'
      # NF=2: testcase
      # NF=3: command
      if ! grep -q "^>>> " $filepath; then
          $fileout $params
      fi

      if grep -q "^>>>" $filepath; then
          awk -v fileout=$fileout -v filepath=$filepath '
                BEGIN {
                    FS=">>>"
                }
                /^>>>/ {
                    gsub("{file}", filepath, $NF)
                    gsub("{fileout}", fileout, $NF)

                    is_echo = match($NF, /([ \t]*)echo([ \t]*)(.*)$/, arr)
                    if (is_echo != 0) {
                        #print "#" $NF
                        print "#" arr[3]
                    }
                    else {
                        system("echo;")
                        system("echo $ " $NF ";" $NF)
                    }
                }' $filepath
          ## if has command, do it
          #if grep -q "^<<<" $filepath; then
          #    awk -v fileout=$fileout -v filepath=$filepath 'BEGIN {FS="<<<"}/^>>>/{gsub("{file}", filepath, $NF); gsub("{fileout}", fileout, $NF); system("echo " $NF ";" $NF)}' $filepath
          #fi
      fi
    ;;

  cpp | cxx | CPP | CXX)
      g++ -pthread -lrt -g -O0 -finstrument-functions -fms-extensions -o $fileout $filepath
      $fileout $params
    ;;

  *)
      $filetype $filepath $params
    ;;
esac


echo ""
echo "====================="
## Continue handle commands
#IFS=':'
## Reading the split string into array
#read -ra cmdArr <<< "$cmds"
#for cmd in "${cmdArr[@]}"; do
#    cmd=${cmd//{fileout\}/$fileout}
#    cmd=${cmd//{file\}/$filepath}
#    echo "---[$cmd]---"
#    eval $cmd
#done

