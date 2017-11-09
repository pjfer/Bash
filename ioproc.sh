#!/bin/bash
function abc(){
  pastas=$(ls /proc)
  numeros=()
  c=0
  for i in $pastas; do
    case $i in 
    [0-9]*)
      numeros[c]=$i
      c=$((c+1))
      ;;
    esac
  done
  c=0
  array=()
  comm=()
  details=()
  user=()
  readb=()
  writeb=()
  rater=()
  ratew=()
  date=()
  printf "%-15s %-10s %-10s %-10s %-10s %-10s %-10s %-10s\n" "COMM" "USER" "PID" "READB" "WRITEB" "RATER" "RATEW" "DATE"
  for pid in ${numeros[@]}; do
    p=0
    comm+=("$(cat /proc/$pid/comm)")
    access=$?
    details+=("$(cat /proc/$pid/io)")
    permissao=$?
    if (($permissao == 0)) && (($access == 0)); then
      for k in ${details[-1]}; do
        array[p]=$k
        p=$((p+1))
      done
    else
      for k in $(seq 0 1 13); do
        array[p]=-1
        p=$((p+1))
      done
    fi
    user+=("$(ls -ld /proc/$pid | awk '{print $3}')")
    readb+=(${array[1]})
    writeb+=(${array[3]})
    rater+=(${array[9]})
    ratew+=(${array[11]})
    date+=("$(ls -ld /proc/$pid | awk '{print $6 " " $7 " " $8}')")
    printf "%-15s %-10s %-10s %-10s %-10s %-10s %-10s %-10s\n" "${comm[-1]}" "${user[-1]}" "$pid" "${readb[-1]}" "${writeb[-1]}" "${rater[-1]}" "${ratew[-1]}" "${date[-1]}"
  done
  return 0
}


function abcd() {
  comm=$(ps -A | awk '{print $4}' | grep -v 'CMD')
  user=$(ps aux | awk '{print $1}' | grep -v 'USER')
  printf "%s \t %s" "$comm" "$user"
  return 0
}

abc
