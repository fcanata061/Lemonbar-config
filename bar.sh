#!/bin/bash

# Fonte com powerline
FONT="Hack Nerd Font Mono:size=12"

# Ícones
ICON_CPU=""
ICON_MEM=""
ICON_TEMP=""
ICON_NET_ON=""
ICON_NET_OFF=""
ICON_DATE=""
ICON_TIME=""

# Separador powerline
SEP=""

# ====== Cores (formato lemonbar: #AARRGGBB) ======
# Transparência (AA), Vermelho, Verde, Azul
BASE="#cc1d1f21"   # fundo da barra
FG="#c5c8c6"       # texto padrão

CPU_BG="#cc81a2be"   # azul
MEM_BG="#ccb5bd68"   # verde
TEMP_BG="#ccde935f"  # laranja
NET_BG="#ccb294bb"   # roxo
DATE_BG="#cc8abeb7"  # cyan

# ====== Funções ======
cpu() {
    usage=$(grep 'cpu ' /proc/stat | awk '{u=($2+$4)*100/($2+$4+$5)} END {printf "%.1f",u}')
    echo "$ICON_CPU $usage%"
}

mem() {
    free_mem=$(free -m | awk '/Mem:/ { printf("%d/%dMB", $3, $2) }')
    echo "$ICON_MEM $free_mem"
}

temp() {
    # pega primeiro sensor de CPU
    t=$(sensors | grep -m1 'Package id 0:' | awk '{print $4}' | tr -d '+')
    [ -z "$t" ] && t="N/A"
    echo "$ICON_TEMP $t"
}

net() {
    dev=$(ip route | awk '/^default/ {print $5; exit}')
    if [ -n "$dev" ]; then
        ip=$(ip addr show "$dev" | awk '/inet / {print $2}' | cut -d/ -f1 | head -n1)
        echo "$ICON_NET_ON $dev:$ip"
    else
        echo "$ICON_NET_OFF Offline"
    fi
}

clock() {
    date "+$ICON_DATE %d/%m/%Y $ICON_TIME %H:%M"
}

# ====== Montador de blocos estilo powerline ======
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

# ====== Loop da barra ======
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
