#!/bin/bash

# =======================
# Lemonbar Powerline Bar
# =======================

FONT="Hack Nerd Font Mono:size=12"

# Ícones (Nerd Fonts / FontAwesome)
ICON_CPU=""
ICON_MEM=""
ICON_TEMP=""
ICON_NET_ON=""
ICON_NET_OFF=""
ICON_DATE=""
ICON_TIME=""

SEP=""   # Separador Powerline

# -----------------------
# Tema (nord, dracula, gruvbox, solarized-dark, solarized-light)
# -----------------------
THEME="dracula"

set_theme() {
    case "$THEME" in
        nord)
            BASE="#cc2e3440"; FG="#d8dee9"
            CPU_BG="#cc81a1c1"; MEM_BG="#cc5e81ac"; TEMP_BG="#cc88c0d0"
            NET_BG="#b48ead"; DATE_BG="#a3be8c"
            ;;
        dracula)
            BASE="#cc282a36"; FG="#f8f8f2"
            CPU_BG="#bd93f9"; MEM_BG="#ff5555"; TEMP_BG="#f1fa8c"
            NET_BG="#6272a4"; DATE_BG="#50fa7b"
            ;;
        gruvbox)
            BASE="#cc282828"; FG="#ebdbb2"
            CPU_BG="#d79921"; MEM_BG="#98971a"; TEMP_BG="#d65d0e"
            NET_BG="#458588"; DATE_BG="#b16286"
            ;;
        solarized-dark)
            BASE="#cc002b36"; FG="#93a1a1"
            CPU_BG="#268bd2"; MEM_BG="#2aa198"; TEMP_BG="#b58900"
            NET_BG="#6c71c4"; DATE_BG="#859900"
            ;;
        solarized-light)
            BASE="#cceee8d5"; FG="#073642"
            CPU_BG="#2aa198"; MEM_BG="#859900"; TEMP_BG="#b58900"
            NET_BG="#268bd2"; DATE_BG="#d33682"
            ;;
        *)
            echo "Tema inválido, usando dracula" >&2
            THEME="dracula"; set_theme
            ;;
    esac
}
set_theme

# -----------------------
# Funções de status
# -----------------------
cpu() {
    usage=$(grep 'cpu ' /proc/stat | awk '{u=($2+$4)*100/($2+$4+$5)} END {printf "%.1f",u}')
    echo "$ICON_CPU $usage%"
}

mem() {
    free_mem=$(free -m | awk '/Mem:/ { printf("%d/%dMB", $3, $2) }')
    echo "$ICON_MEM $free_mem"
}

temp() {
    t=$(sensors | grep -m1 'Package id 0:' | awk '{print $4}' | tr -d '+')
    [ -z "$t" ] && t="N/A"
    echo "$ICON_TEMP $t"
}

# Variáveis globais para cálculo de taxa de rede
last_rx=0
last_tx=0
last_time=0

net() {
    dev=$(ip route | awk '/^default/ {print $5; exit}')
    if [ -z "$dev" ]; then
        echo "$ICON_NET_OFF Offline"
        return
    fi

    rx=$(cat /sys/class/net/$dev/statistics/rx_bytes)
    tx=$(cat /sys/class/net/$dev/statistics/tx_bytes)
    now=$(date +%s)

    if [ $last_time -eq 0 ]; then
        last_rx=$rx; last_tx=$tx; last_time=$now
        echo "$ICON_NET_ON $dev 0.0↓ 0.0↑"
        return
    fi

    interval=$((now - last_time))
    [ $interval -le 0 ] && interval=1

    rx_rate=$(( (rx - last_rx) / interval ))
    tx_rate=$(( (tx - last_tx) / interval ))

    last_rx=$rx; last_tx=$tx; last_time=$now

    # formata em B/s, KB/s, MB/s
    format_rate() {
        if [ $1 -gt 1048576 ]; then
            echo "$(awk "BEGIN {printf \"%.1f\", $1/1048576}")MB/s"
        elif [ $1 -gt 1024 ]; then
            echo "$(awk "BEGIN {printf \"%.1f\", $1/1024}")KB/s"
        else
            echo "${1}B/s"
        fi
    }

    down=$(format_rate $rx_rate)
    up=$(format_rate $tx_rate)

    echo "$ICON_NET_ON $dev $down↓ $up↑"
}

clock() {
    date "+$ICON_DATE %d/%m/%Y $ICON_TIME %H:%M"
}

# -----------------------
# Helpers
# -----------------------
block() {
    local bg=$1
    local text=$2
    local nextbg=$3

    echo -n "%{B$bg}%{F$FG} $text "

    if [ -n "$nextbg" ]; then
        echo -n "%{B$nextbg}%{F$bg}$SEP"
    else
        echo -n "%{B$BASE}%{F$bg}$SEP"
    fi
}

# -----------------------
# Loop principal
# -----------------------
while :; do
    line=""
    line+="$(block $CPU_BG "$(cpu)" $MEM_BG)"
    line+="$(block $MEM_BG "$(mem)" $TEMP_BG)"
    line+="$(block $TEMP_BG "$(temp)" $NET_BG)"
    line+="$(block $NET_BG "$(net)" $DATE_BG)"
    line+="$(block $DATE_BG "$(clock)")"
    echo -e "$line"
    sleep 2
done | lemonbar -g x24 -B "$BASE" -F "$FG" -f "$FONT" -f "FontAwesome:size=12"
