#!/bin/bash

if (($# < 1)); then
  echo "Número de argumentos inválido!"
  exit 1
fi

b_comm=""
f_comm=0
b_datini=""
f_datini=0
b_datfim=""
f_datfim=0
b_user=""
f_user=0
b_nproc=""
f_nproc=0
rev=0
write=0
total=0
y=0
regex='^[0-9]+$'

while getopts ":c:s:e:u:p:rwt" opt; do
  case $opt in
    c)
      b_comm=$OPTARG
      f_comm=1
      ;;
    s)      
      b_datini=$OPTARG
      f_datini=1
      ;;
    e)
      b_datfim=$OPTARG
      f_datfim=1
      ;;
    u)
      b_user=$OPTARG
      f_user=1
      ;;
    p)
      if (($OPTARG >= 1)) && [[ $OPTARG =~ $regex ]]; then
        b_nproc=$OPTARG
        f_nproc=1
      else
        echo "O argumento do p tem de ser um número maior ou igual a 1!" >&2
        exit 1
      fi
      ;;
    r)
      rev=1
      ;;
    w)
      write=1
      ;;
    t)
      total=1
      ;;
    :)
      echo "A opção -$OPTARG requere um argumento!" >&2
      exit 1
      ;;
    \?) 
      echo "Opções válidas: -c [arg] -u [arg] -p [arg] -s [arg] -e [arg] -t -w -r" >&2
      exit 1
      ;;
  esac
done

if (($f_datini == 1)) && (($f_datfim == 1)); then
  d1=$(date -d"$b_datini" +%s)
  d2=$(date -d"$b_datfim" +%s)
  if (($d1 >= $d2)); then
    echo "A data inicial tem de ser menor ou igual à data final!"
    exit 1
  fi
fi

optt="-n -r -k6"

if (($rev == 1)); then
  optt="-n -k6"
  if (($total == 1)); then
    if (($write == 1)); then
      optt="-n -k5"
    else
      optt="-n -k4"
    fi
  else
    if (($write == 1)); then
      optt="-n -k7"
    fi
  fi
else
  if (($write == 1)); then
    optt="-n -r -k7"
  fi
fi

if [[ ${@: -1} =~ $regex ]] && ((${@: -1} > 0)); then
  s="${@: -1}"
else
  echo "O último argumento tem que ser os segundos e maior do que 0!"
  exit 1
fi

directories=$(ls /proc)
numbers=()
c=0
for i in $directories; do
  case $i in 
  [0-9]*)
         numbers[c]=$i
         c=$((c+1))
         ;;
  esac
done
   
array=()
comm=()
details=()
user=()
readb=()
writeb=()
rater=()
ratew=()
date=()
t=0
for pid in ${numbers[@]}; do
  p=0
  details+=("$(cat /proc/$pid/io 2>/dev/null)")
  permission=$?
  if (($permission == 0)); then
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
  readb+=(${array[1]})
  writeb+=(${array[3]})
done
sleep $s
printf "%-15s %-15s %-10s %-10s %-10s %-10s %-10s %-10s\n" "COMM" "USER" "PID" "READB" "WRITEB" "RATER" "RATEW" "DATE"
{ for pid in ${numbers[@]}; do
  p=0
  p_comm="$(cat /proc/$pid/comm 2>/dev/null)"
  comm+=("${p_comm% *}")
  access=$?
  details+=("$(cat /proc/$pid/io 2>/dev/null)")
  permission=$?
  if (($permission == 0)) && (($access == 0)); then
    for k in ${details[-1]}; do
      array[p]=$k
      p=$((p+1))
    done
    dif1=$((${array[1]} - ${readb[t]}))
    rater+=($(bc <<< "scale = 2; ($dif1 / $s)"))
    dif2=$((${array[3]} - ${writeb[t]}))
    ratew+=($(bc <<< "scale = 2; ($dif2 / $s)"))
  else
    rater+=("-1")
    ratew+=("-1")
    for k in $(seq 0 1 13); do
      array[p]=-1
      p=$((p+1))
    done
  fi
  t=$((t+1))
  user+=("$(ls -ld /proc/$pid 2>/dev/null| awk '{print $3}')")
  readb+=(${array[1]})
  writeb+=(${array[3]})
  date+=("$(ls -ld /proc/$pid 2>/dev/null| awk '{print $6 " " $7 " " $8}')")
  c_comm=0
  c_datini=0
  c_datfim=0
  c_user=0
  if (($f_comm == 1)) && [[ ${comm[-1]} =~ ^$b_comm$ ]]; then
    c_comm=1
  fi
  if [[ ${date[-1]} != "" ]]; then
    if (($f_datini == 1)); then
      d1=$(date -d"${date[-1]}" +%s)
      d2=$(date -d"$b_datini" +%s)
      if (($d1 >= $d2)); then
        c_datini=1
      fi
    fi
    if (($f_datfim == 1)); then
      d1=$(date -d"${date[-1]}" +%s)
      d2=$(date -d"$b_datfim" +%s)
      if (($d1 <= $d2)); then
        c_datfim=1
      fi
    fi
  fi
  if (($f_user == 1)) && [[ ${user[-1]} == $b_user ]]; then
    c_user=1
  fi
  f_soma=$(($f_comm + $f_user + $f_datini + $f_datfim))
  c_soma=$(($c_comm + $c_user + $c_datini + $c_datfim))
  if (($f_soma == $c_soma)) && (($f_soma != 0)); then
    printf "%-15s %-15s %-10s %-10s %-10s %-10s %-10s %-10s\n" "${comm[-1]}" "${user[-1]}" "$pid" "${readb[-1]}" "${writeb[-1]}" "${rater[-1]}" "${ratew[-1]}" "${date[-1]}"
  fi
  if (($f_comm == 0)) && (($f_datini == 0)) && (($f_datfim == 0)) && (($f_user == 0)) && (($f_nproc == 0)); then 
    printf "%-15s %-15s %-10s %-10s %-10s %-10s %-10s %-10s\n" "${comm[-1]}" "${user[-1]}" "$pid" "${readb[-1]}" "${writeb[-1]}" "${rater[-1]}" "${ratew[-1]}" "${date[-1]}"
  fi
done } | head -$b_nproc | sort $optt
