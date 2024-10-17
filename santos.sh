#!/bin/bash

date=$(stat -c %Y "$1")
echo $date



while getopts ":cb:r:" opt; do
  case $opt in
    c)
      echo "Option c"
      ;;
    b)
      echo "Option b with value $OPTARG"
      ;;
    r)
      echo "Option r with value $OPTARG"
      ;;
    \?)
    echo "Other: $opt, $OPTARG"
      ;;
  esac
done