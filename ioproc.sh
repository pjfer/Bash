#!/bin/bash
LC_ALL=C
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
u=0

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
      b_nproc=$OPTARG
      f_nproc=1
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
      echo "Opção inválida: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

optt="-n -r -k6"

if (($rev == 1)); then
  if (($write == 1)); then
    if (($total == 1)); then
      optt="-n -k5"
    else
      optt="-n -k4"
    fi
    optt="-n -k7"
  else
    optt="-n -k6"
  fi
fi

regex='^[0-9]+$'
if [[ ${@: -1} =~ $regex ]]; then #falta fazer a verificação de ser o ultimo argumento
  s="${@: -1}" #vai buscar o ultimo elemento dos argumentos na bash
else
  echo "O último argumentos têm que ser os segundos!"
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
    rater+=($(($dif1 / $s)))
    dif2=$((${array[3]} - ${writeb[t]}))
    ratew+=($(($dif2 / $s)))
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
  if (($f_nproc == 1)) && (($b_nproc >= 0)); then
    c_nproc=1
    if (($c_nproc == $b_nproc)); then
      break
    else
      u=$((u+1))
    fi
  fi
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
  f_soma=$(($f_comm + $f_user + $f_datini + $f_datfim + $f_nproc))
  c_soma=$(($c_comm + $c_user + $c_datini + $c_datfim + $c_nproc))
  if (($f_soma == $c_soma)) && (($f_soma != 0)); then
    printf "%-15s %-15s %-10s %-10s %-10s %-10s %-10s %-10s\n" "${comm[-1]}" "${user[-1]}" "$pid" "${readb[-1]}" "${writeb[-1]}" "${rater[-1]}" "${ratew[-1]}" "${date[-1]}"
  fi
  if (($f_comm == 0)) && (($f_datini == 0)) && (($f_datfim == 0)) && (($f_user == 0)); then 
    printf "%-15s %-15s %-10s %-10s %-10s %-10s %-10s %-10s\n" "${comm[-1]}" "${user[-1]}" "$pid" "${readb[-1]}" "${writeb[-1]}" "${rater[-1]}" "${ratew[-1]}" "${date[-1]}"
  fi
done } | sort $optt
