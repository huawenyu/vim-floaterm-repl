#!/usr/bin/env bash
filetype=$1
filepath=$2
shift
shift
params=$@
echo "Start $filetype $filepath"
echo "====================="
echo ''
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
  python | python3) 
      python3 $filepath $params
    ;;

  *)
      $filetype $filepath $params
    ;;
esac

echo ''
echo "====================="

