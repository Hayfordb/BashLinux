#!/bin/bash

help(){

    echo "Опции:"
    echo "  --host              Показать всю информацию о хосте"
    echo "  --user              Показать всю информацию о юзере"
    echo "  --help              Показать help"
    echo "  -c                  Количество ядер CPU"
    echo "  -m                  Объём оперативной памяти в системе/ количество использованной оперативной памяти"
    echo "  -d                  Информацию о дисках: какие диски есть в системе, их размер/ сколько свободно на диске (в процентах)/ количество ошибок"
    echo "  -l                  Среднюю загрузку системы (load average)"
    echo "  -t                  Текущее время в системе"
    echo "  -u                  Время работы системы (uptime)"
    echo "  -n                  Информация о сетевых интерфейсах"
    echo "  -p                  Порты, которые слушаются на системе"
    echo "  -a                  Список пользователей в системе"
    echo "  -k                  Список root-пользователей в системе"
    echo "  -w                  Список залогиненных пользователей в момент запуска скрипта"
    
}

get_cpu_proc(){
proc=$(nproc)
    echo "Количество ядер CPU: $proc"
}

get_memory_info(){
memory=$(grep -i "memtotal"  /proc/meminfo | awk '{print $2, $3}')
    echo "Объем памяти: $memory"

used_memory=$(awk '/MemTotal/ {memtotal = $2}
                    /MemFree/ {memfree = $2}
                    /Cached/ {cached = $2}
                    /Buffers/ {buffers = $2}
                    END {print memtotal - memfree - cached - buffers " kB"}' /proc/meminfo)
    echo "Объем используемой памяти $used_memory"
}

get_disk_info() {
    disk_info=$(lsblk -o NAME,SIZE,TYPE | awk '$3 == "disk" {print $1, $2}')
    
    echo "Информация о дисках:"
    while read -r name size; do
        
        free_space=$(df -h | grep "/dev/$name" | awk '{print $5}')
        if [ -z "$free_space" ]; then
            free_space="Нет данных (диск не смонтирован)"
        fi

        errors=$(dmesg | grep -i "$name" | grep -i "error" | wc -l)

        echo -e "Диск: $name\n  Размер: $size\n  Свободно: $free_space\n  Количество ошибок: $errors\n"
    done <<< "$disk_info"
}

get_load_average(){
    load_average=$(cat /proc/loadavg)
    echo "Средняя загрузка системы: $load_average"
}

get_current_time(){
    current_time=$(date +%T)
    echo "Ткущее время системы: $current_time"
}

get_uptime(){
    uptime=$(cat /proc/uptime | awk '{print $1}')
    echo "Время работы системы в сек. : $uptime"
}

get_network_info(){

    printf "%-30s %-20s %-25s %-34s %-35s %-20s\n" "Интерфейс" "Статус" "IP" "Пакеты входящие" "Пакеты исходящие" "Кол-во ошибок"
    printf "%-20s %-15s %-25s %-20s %-20s %-20s\n" "--------------------" "---------------" "-------------------------" "--------------------" "--------------------" "---------------"

  
    network_name=$(ip -o link show | awk -F': ' '{print $2}' | awk -F'@' '{print $1}')


    for interface in $network_name; do
       
        status=$(cat /sys/class/net/$interface/operstate)

        ip_addr=$(ip -o -f inet addr show $interface | awk '{print $4}')
        if [[ -z $ip_addr ]]; then
            ip_addr="-"
        fi

        pack_in=$(cat /proc/net/dev | grep $interface | awk '{print $3}')
        pack_out=$(cat /proc/net/dev | grep $interface | awk '{print $11}')
        face_error=$(cat /proc/net/dev | grep $interface | awk '{print $4 + $12}')
 

        printf "%-20s %-15s %-25s %-20s %-20s %-20s\n" "$interface" "$status" "$ip_addr" "$pack_in" "$pack_out" "$face_error"
    done
}

get_listen_ports(){
    listen_ports=$(ss -tuln | grep LISTEN | awk '{print $5}' | awk -F':' '{print $NF}')
    echo -e "Прослушиваемые порты:\n$listen_ports"
}

get_users_in_system(){
    get_users=$(cat /etc/passwd | awk -F':' '{print $1}')
    echo -e "Юзеры в системе: $get_users"
}

get_root_users(){
    get_root=$(cat /etc/passwd | awk -F':' '$3 == 0 {print $0}')
    echo -e "Рут юзеры:\n$get_root"
}

get_login_users(){
    login_users=$(w | awk '{print $1}')
    echo -e "Список залогиненных юзеров:\n$login_users"
}


OPTIONS=$(getopt -o "cmdltunpakw" -l "host,user,help" -- "$@")

if [[ $# -eq 0 ]]; then
    echo "Скрипт запущен без опций"
    help
    exit 0
fi

eval set -- "$OPTIONS"

while true; do
    case "$1" in
        -c)
            get_cpu_proc
            shift
            ;;

        -m)
            get_memory_info
            shift
            ;;

        -d)
            get_disk_info
            shift
            ;;

        -l)
            get_load_average
            shift
            ;;

        -t)
            get_current_time
            shift
            ;;
        
        -u)
            get_uptime
            shift
            ;;

        -n)
            get_network_info
            shift
            ;;

        -p)
            get_listen_ports
            shift
            ;;
        
        -a)
            get_users_in_system
            shift
            ;;

        -k)
            get_root_users
            shift
            ;;
        
        -w)
            get_login_users
            shift
            ;;

        --host)
            get_cpu_proc
            echo
            get_memory_info
            echo 
            get_disk_info
            echo
            get_load_average
            echo
            get_current_time
            echo
            get_uptime
            echo
            get_network_info
            echo
            get_listen_ports
            shift
            ;;
        
        --user)
            get_users_in_system
            echo
            get_root_users
            echo
            get_login_users
            shift
            ;;
        
        --help)
            help
            shift
            break
            ;;

        --)
            shift
            break
            ;;
    esac
done
