#!/bin/bash

date=$(stat -c %Y "$1")
echo $date

