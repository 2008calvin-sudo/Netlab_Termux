#!/usr/bin/env bash
# =====================================================================
#  NetLab Movil - Menu de herramientas de REDES para el telefono
#  Funciona en: Termux SIN ROOT  y  Kali NetHunter SIN ROOT (rootless)
#  Herramientas pequenas: nmap, ping, traceroute, dig, whois, nc, curl,
#  iperf3, ssh y (opcional) termux-api para datos del Wi-Fi.
#  Solo usa escaneos que Android permite SIN root (TCP connect).
#
#  USO:  bash Termux_netlab.sh
#  IMPORTANTE: usalo SOLO en redes propias o de laboratorio, conectado
#  a tu Wi-Fi (no a datos moviles) o con autorizacion por escrito.
# =====================================================================

# ---------- Colores ----------
R=$'\e[31m'; G=$'\e[32m'; Y=$'\e[33m'; B=$'\e[34m'; C=$'\e[36m'; W=$'\e[1m'; N=$'\e[0m'

# Ctrl+C no cierra el menu (solo corta el comando en ejecucion)
trap '' INT

OUTDIR="$HOME/netlab_resultados"; mkdir -p "$OUTDIR"

# ---------- Entorno ----------
tiene() { command -v "$1" >/dev/null 2>&1; }

detectar_entorno() {
  if [[ -n "${PREFIX:-}" && "$PREFIX" == *com.termux* ]]; then
    ENTORNO="Termux"
    INSTALAR="pkg install nmap dnsutils traceroute openssh netcat-openbsd iperf3 curl whois python termux-api"
  elif grep -qi kali /etc/os-release 2>/dev/null; then
    ENTORNO="Kali NetHunter"
    INSTALAR="apt install nmap dnsutils traceroute openssh-client netcat-openbsd iperf3 curl whois python3"
  else
    ENTORNO="Linux"
    INSTALAR="apt install nmap dnsutils traceroute openssh-client netcat-openbsd iperf3 curl whois python3"
  fi
  CON_ROOT=0
  [[ $EUID -eq 0 && "$ENTORNO" != "Termux" ]] && CON_ROOT=1
}

# ---------- Red (autodeteccion con alternativas: Android limita 'ip') ----------
detectar_red() {
  local cidr=""
  GW_ESTIMADO=0
  if tiene ip; then
    cidr=$(ip -o -f inet addr show wlan0 2>/dev/null | awk '{print $4; exit}')
    [[ -z "$cidr" ]] && cidr=$(ip -o -f inet addr show 2>/dev/null | awk '$2!="lo"{print $4; exit}')
  fi
  MIIP="${cidr%%/*}"
  if [[ -z "$MIIP" ]] && tiene termux-wifi-connectioninfo; then
    MIIP=$(termux-wifi-connectioninfo 2>/dev/null | sed -n 's/.*"ip": *"\([^"]*\)".*/\1/p')
  fi
  if [[ -z "$MIIP" ]] && tiene python3; then
    MIIP=$(python3 -c 'import socket;s=socket.socket(socket.AF_INET,socket.SOCK_DGRAM);s.connect(("8.8.8.8",80));print(s.getsockname()[0])' 2>/dev/null)
  fi
  if [[ -n "$MIIP" && "$MIIP" != 127.* ]]; then
    RANGO="${MIIP%.*}.0/24"
    GATEWAY=$(getprop dhcp.wlan0.gateway 2>/dev/null)
    if [[ -z "$GATEWAY" ]]; then GATEWAY="${MIIP%.*}.1"; GW_ESTIMADO=1; fi
  else
    MIIP="desconocida"; RANGO="192.168.1.0/24"; GATEWAY="192.168.1.1"; GW_ESTIMADO=1
  fi
}

detectar_entorno
detectar_red

# ---------- Utilidades ----------
pausa() { echo; read -rp "${Y}Enter para continuar...${N}" _; }

banner() {
  clear
  echo "${C}${W}  NetLab Movil${N}${B}  - Redes desde el telefono (sin root)${N}"
  echo " Entorno: ${G}$ENTORNO${N}   Mi IP: ${G}$MIIP${N}"
  local gw="$GATEWAY"; [[ $GW_ESTIMADO -eq 1 ]] && gw="$GATEWAY ${Y}(estimado)${N}"
  echo " Rango: ${G}$RANGO${N}   Gateway: ${G}$gw${N}"
  echo "${R} Usalo solo en tu Wi-Fi / laboratorio / redes autorizadas.${N}"
  [[ $CON_ROOT -eq 1 ]] && echo "${Y} Tienes root: el repo 'netlab' (version Completa) te ofrece mas herramientas.${N}"
  echo
}

# Marca roja [falta] junto a una opcion si la herramienta no esta instalada
mk() { tiene "$1" || printf '%s' "${R}[falta]${N}"; }

necesita() { # herramienta
  if ! tiene "$1"; then
    echo "${R}[!] '$1' no esta instalado.${N}"
    echo "    Instalar todo lo necesario con:  ${W}$INSTALAR${N}"
    pausa; return 1
  fi
  return 0
}

# Pide un dato con valor por defecto; solo caracteres seguros, sin espacios ni '-' inicial
pedir() { # variable  pregunta  defecto
  local __in
  read -rp "$2 ${Y}[$3]${N}: " __in
  __in="${__in:-$3}"
  if [[ ! "$__in" =~ ^[A-Za-z0-9./:,_@=-]+$ || "$__in" == -* ]]; then
    echo "${R}[!] Entrada no permitida (sin espacios, y no puede empezar con '-').${N}"; return 1
  fi
  printf -v "$1" '%s' "$__in"
}

# Avisa si el objetivo NO parece una red privada y pide confirmacion
objetivo_ok() {
  local t="${1%%/*}"
  if [[ "$t" =~ ^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[01])\.|127\.|169\.254\.) ]]; then return 0; fi
  echo "${Y}[!] '$1' no parece una red privada.${N}"
  echo "    Escanear redes ajenas sin permiso puede ser ilegal."
  read -rp "    Es tu laboratorio o tienes autorizacion escrita? [s/N]: " r
  [[ "$r" =~ ^[sS]$ ]]
}

# Muestra explicacion + comando, pide confirmacion y lo ejecuta
# lanzar "Titulo" "Explicacion" "comando"
lanzar() {
  local titulo="$1" explica="$2" cmd="$3"
  echo
  echo "${W}${G}== $titulo ==${N}"
  echo "${C}Que hace:${N}"
  echo -e "$explica" | sed 's/^/  /'
  echo
  echo "${C}Comando:${N} ${W}$cmd${N}"
  echo
  read -rp "Ejecutar? [S/n]: " r
  [[ "$r" =~ ^[nN]$ ]] && return
  echo "${Y}(Ctrl+C corta el comando y vuelve al menu)${N}"
  echo "-----------------------------------------------------------"
  ( trap - INT; eval "$cmd" )
  echo "-----------------------------------------------------------"
  pausa
}

# =====================================================================
#  1) DESCUBRIMIENTO (sin ARP: Android no permite sockets crudos)
# =====================================================================
menu_descubrimiento() {
  while true; do
    banner
    echo "${W}[1] DESCUBRIMIENTO - Quien esta conectado en la red${N}"
    echo "    ${Y}Sin root no hay ARP: se detectan equipos que respondan por TCP.${N}"
    echo
    echo "  1) nmap - Ping sweep                (hosts vivos, sin escanear puertos) $(mk nmap)"
    echo "  2) nmap - Descubrimiento ampliado   (prueba varios puertos comunes)     $(mk nmap)"
    echo "  3) nmap - Solo listar/resolver      (no envia paquetes al objetivo)     $(mk nmap)"
    echo "  4) Hosts vistos por el telefono     (tabla ARP, puede estar bloqueada)"
    echo "  0) Volver"
    echo
    read -rp "${W}movil/descubrimiento> ${N}" op
    case $op in
      1|2|3) necesita nmap || continue
             pedir T "Rango/objetivo" "$RANGO" || { pausa; continue; }
             objetivo_ok "$T" || { echo "Cancelado."; pausa; continue; } ;;
    esac
    case $op in
      1) lanzar "nmap -sn (Ping sweep)" \
"nmap           : escaner de redes.
-sn            : solo comprueba si el host responde, NO escanea puertos.
--unprivileged : le dice a nmap que no tienes root (usa conexiones TCP normales).
Sin root usa conexiones a los puertos 80 y 443; un equipo que no responda ahi
puede no aparecer. Si faltan equipos, prueba la opcion 2." \
         "nmap -sn --unprivileged $T" ;;
      2) lanzar "nmap -sn -PS (ampliado)" \
"-sn                    : solo descubrimiento de hosts.
-PS22,80,443,445,3389  : intenta conectar a esos puertos (SSH, HTTP, HTTPS, SMB, RDP).
                         Un puerto abierto O cerrado que responda delata que el equipo
                         esta encendido.
--unprivileged         : modo sin root." \
         "nmap -sn --unprivileged -PS22,80,443,445,3389,8080 $T" ;;
      3) lanzar "nmap -sL (List scan)" \
"-sL : 'list scan'. Solo lista las IPs del rango y hace resolucion DNS inversa.
       No envia paquetes a los hosts." \
         "nmap -sL $T" ;;
      4) lanzar "Tabla ARP del telefono" \
"Muestra los equipos con los que el telefono hablo hace poco (IP y MAC).
Android 10 o superior suele bloquear este archivo para las apps: si sale
'Permission denied' es una limitacion del sistema, no un error tuyo." \
         "cat /proc/net/arp 2>&1 || echo 'No disponible en este Android'" ;;
      0) return ;;
    esac
  done
}

# =====================================================================
#  2) ESCANEO DE PUERTOS (nmap TCP connect)
# =====================================================================
menu_puertos() {
  necesita nmap || return
  while true; do
    banner
    echo "${W}[2] ESCANEO DE PUERTOS Y SERVICIOS - nmap (sin root)${N}"
    echo "    ${Y}Solo TCP connect (-sT). No hay SYN, UDP ni deteccion de SO sin root.${N}"
    echo
    echo "  1) Escaneo rapido            (-F, los 100 puertos mas comunes)"
    echo "  2) Escaneo TCP connect       (-sT, los 1000 puertos mas comunes)"
    echo "  3) Deteccion de versiones    (-sV, que servicio y version corre)"
    echo "  4) Scripts por defecto       (-sC, banners, SSL, etc.)"
    echo "  5) Versiones + scripts       (-sV -sC, el mas completo sin root)"
    echo "  6) Puertos especificos       (-p 22,80,443)"
    echo "  7) Todos los puertos         (-p-, tarda y gasta bateria)"
    echo "  8) Sin ping previo           (-Pn, si el equipo 'no responde')"
    echo "  9) Escanear y guardar        (-oN, guarda el resultado en un archivo)"
    echo "  0) Volver"
    echo
    read -rp "${W}movil/puertos> ${N}" op
    [[ "$op" == "0" ]] && return
    [[ ! "$op" =~ ^[1-9]$ ]] && continue
    pedir T "Objetivo (IP, rango o dominio)" "$GATEWAY" || { pausa; continue; }
    objetivo_ok "$T" || { echo "Cancelado."; pausa; continue; }
    case $op in
      1) lanzar "Escaneo rapido" \
"-F             : 'fast'. Solo los 100 puertos mas usados (en vez de 1000).
-sT            : TCP connect, el unico escaneo de puertos que Android permite sin root.
--unprivileged : modo sin root." "nmap --unprivileged -sT -F $T" ;;
      2) lanzar "Escaneo TCP connect" \
"-sT : completa el saludo TCP de 3 vias (SYN, SYN/ACK, ACK) usando el sistema.
       Es mas lento y deja mas huellas que un SYN scan, pero no necesita root." \
         "nmap --unprivileged -sT $T" ;;
      3) lanzar "Deteccion de versiones" \
"-sV : interroga los puertos abiertos para saber que servicio y que version
       corren (ej: OpenSSH 8.9, Apache 2.4.52)." "nmap --unprivileged -sT -sV $T" ;;
      4) lanzar "Scripts por defecto" \
"-sC : ejecuta los scripts NSE de la categoria 'default' (banners, informacion
       SSL, titulos web...). Seguros y utiles para empezar." "nmap --unprivileged -sT -sC $T" ;;
      5) lanzar "Versiones + scripts" \
"-sV -sC : versiones de servicios + scripts por defecto. Es lo mas parecido
           al escaneo agresivo (-A) que se puede hacer sin root.
Puede tardar varios minutos." "nmap --unprivileged -sT -sV -sC $T" ;;
      6) pedir P "Puertos (ej: 22,80,443 o 1-1024)" "22,80,443" || { pausa; continue; }
         lanzar "Puertos especificos" \
"-p <lista> : escanea solo los puertos indicados. Acepta lista (22,80) y rangos (1-1024)." \
         "nmap --unprivileged -sT -p $P $T" ;;
      7) lanzar "Todos los puertos" \
"-p- : escanea los 65535 puertos TCP.
-T4  : velocidad agresiva pero razonable en Wi-Fi propia.
Puede tardar mucho; mantene el telefono cargando." "nmap --unprivileged -sT -p- -T4 $T" ;;
      8) lanzar "Sin ping previo" \
"-Pn : no hace descubrimiento previo; escanea aunque el equipo parezca apagado.
       Util cuando un firewall bloquea las pruebas de 'estas vivo?'." \
         "nmap --unprivileged -sT -Pn -F $T" ;;
      9) pedir F "Nombre del archivo" "escaneo_$(date +%H%M).txt" || { pausa; continue; }
         lanzar "Escanear y guardar" \
"-sV     : versiones de servicios.
-oN <f> : guarda la salida en formato normal (legible) en un archivo.
Guarda en: $OUTDIR" "nmap --unprivileged -sT -sV -oN $OUTDIR/$F $T" ;;
    esac
  done
}

# =====================================================================
#  3) DIAGNOSTICO
# =====================================================================
menu_diagnostico() {
  while true; do
    banner
    echo "${W}[3] DIAGNOSTICO - Conectividad y resolucion de problemas${N}"
    echo
    echo "  1) ping            - Conectividad basica        (capa 3, ICMP)"
    echo "  2) ping al gateway - Prueba rapida de tu red local"
    echo "  3) traceroute      - Ruta salto a salto         $(mk traceroute)"
    echo "  4) dig             - Consulta DNS               $(mk dig)"
    echo "  5) nc              - Probar si un puerto TCP responde $(mk nc)"
    echo "  6) whois           - Datos de una IP o dominio  $(mk whois)"
    echo "  7) curl            - Respuesta de una web (cabeceras) $(mk curl)"
    echo "  0) Volver"
    echo
    read -rp "${W}movil/diagnostico> ${N}" op
    case $op in
      1) necesita ping || continue; pedir T "Destino" "8.8.8.8" || { pausa; continue; }
         lanzar "ping" \
"-c 4 : envia 4 ICMP Echo Request y espera 4 Echo Reply.
Muestra tiempo (ms) y TTL. Perdida de paquetes = problema de conectividad." "ping -c 4 $T" ;;
      2) necesita ping || continue
         lanzar "ping al gateway" \
"Prueba tu enlace con el router. Si falla, el problema es local (Wi-Fi, IP, VLAN).
Si el gateway aparece como 'estimado', verifica su IP real en el menu 6." \
         "ping -c 4 $GATEWAY" ;;
      3) necesita traceroute || continue; pedir T "Destino" "8.8.8.8" || { pausa; continue; }
         lanzar "traceroute" \
"Envia paquetes con TTL creciente (1,2,3...). Cada router que descarta el paquete
responde 'TTL excedido' y asi se descubre cada salto del camino.
-n : sin resolver nombres (mas rapido).
Algunos Android bloquean parte de esto: si falla o sale todo '* * *', es una limitacion." \
         "traceroute -n $T" ;;
      4) necesita dig || continue; pedir T "Dominio" "cisco.com" || { pausa; continue; }
         pedir Q "Tipo de registro (A, AAAA, MX, NS, TXT)" "A" || { pausa; continue; }
         lanzar "dig" \
"Consulta un servidor DNS. Tipos: A (IPv4), AAAA (IPv6), MX (correo), NS (servidores
de nombres), TXT. +short muestra solo la respuesta.
Si no funciona, prueba con un DNS concreto agregando @8.8.8.8." "dig $T $Q +short" ;;
      5) necesita nc || continue
         pedir T "Host/IP" "$GATEWAY" || { pausa; continue; }
         pedir P "Puerto" "80" || { pausa; continue; }
         objetivo_ok "$T" || { echo "Cancelado."; pausa; continue; }
         lanzar "nc prueba de puerto" \
"-z      : solo comprueba si el puerto esta abierto, sin enviar datos.
-v      : muestra el resultado (succeeded / refused).
-w 3    : espera maximo 3 segundos.
'refused' = el host responde pero el puerto esta cerrado; 'timed out' = filtrado." \
         "nc -zv -w 3 $T $P" ;;
      6) necesita whois || continue; pedir T "IP o dominio" "cisco.com" || { pausa; continue; }
         lanzar "whois" "Consulta a quien pertenece una IP o dominio (organizacion, rango, contacto)." \
         "whois $T | head -n 40" ;;
      7) necesita curl || continue; pedir T "URL (ej http://192.168.1.1 o https://cisco.com)" "https://cisco.com" || { pausa; continue; }
         lanzar "curl -I" \
"-I : pide solo las cabeceras HTTP.
Codigos: 200 correcto, 301/302 redireccion, 403 sin permiso, 404 no encontrado,
500/503 error del servidor.
-m 10 : se rinde a los 10 segundos." "curl -I -m 10 $T" ;;
      0) return ;;
    esac
  done
}

# =====================================================================
#  4) RENDIMIENTO - iperf3
# =====================================================================
menu_iperf() {
  while true; do
    banner
    echo "${W}[4] RENDIMIENTO - iperf3 (medir velocidad entre dos equipos)${N}"
    echo
    echo "  Mi IP: ${G}$MIIP${N}   Puerto por defecto: 5201"
    echo
    echo "  1) Servidor                      (este telefono espera conexiones) $(mk iperf3)"
    echo "  2) Cliente TCP                   (mide subida hacia el servidor)"
    echo "  3) Cliente TCP inverso           (mide bajada desde el servidor)"
    echo "  4) Cliente UDP                   (perdida de paquetes y jitter)"
    echo "  0) Volver"
    echo
    echo "  Necesitas otro equipo (PC) en la misma red con 'iperf3 -s' o 'iperf3 -c'."
    echo
    read -rp "${W}movil/iperf3> ${N}" op
    [[ "$op" =~ ^[1-4]$ ]] && { necesita iperf3 || continue; }
    case $op in
      1) lanzar "iperf3 servidor" \
"-s : modo servidor. Queda escuchando en el puerto 5201 hasta Ctrl+C.
En el OTRO equipo ejecuta: iperf3 -c $MIIP" "iperf3 -s" ;;
      2) pedir S "IP del servidor" "$GATEWAY" || { pausa; continue; }
         lanzar "iperf3 cliente TCP" \
"-c <ip> : modo cliente, se conecta al servidor.
-t 10    : prueba de 10 segundos.
Resultado en Mbits/sec: velocidad real de tu Wi-Fi (no la teorica)." "iperf3 -c $S -t 10" ;;
      3) pedir S "IP del servidor" "$GATEWAY" || { pausa; continue; }
         lanzar "iperf3 cliente inverso" \
"-R : reverso. El servidor envia y tu recibes, asi mides la BAJADA." "iperf3 -c $S -t 10 -R" ;;
      4) pedir S "IP del servidor" "$GATEWAY" || { pausa; continue; }
         pedir BW "Ancho de banda objetivo (ej 10M)" "10M" || { pausa; continue; }
         lanzar "iperf3 cliente UDP" \
"-u      : usa UDP en vez de TCP.
-b <bw>  : velocidad a enviar (ej 10M = 10 Mbit/s).
Muestra Jitter y % de paquetes perdidos: clave para VoIP y video." "iperf3 -c $S -u -b $BW -t 10" ;;
      0) return ;;
    esac
  done
}

# =====================================================================
#  5) SSH a routers / switches / servidores
# =====================================================================
menu_ssh() {
  while true; do
    banner
    echo "${W}[5] SSH - Conectarse a routers, switches y servidores${N}"
    echo
    echo "  1) Conectar por SSH                       $(mk ssh)"
    echo "  2) Conectar a un Cisco ANTIGUO            (algoritmos legacy)"
    echo "  0) Volver"
    echo
    read -rp "${W}movil/ssh> ${N}" op
    [[ "$op" =~ ^[12]$ ]] && { necesita ssh || continue; }
    case $op in
      1) pedir U "Usuario" "admin" || { pausa; continue; }
         pedir H "IP o nombre del equipo" "$GATEWAY" || { pausa; continue; }
         lanzar "ssh" \
"ssh usuario@equipo : abre una terminal remota cifrada en el router, switch o servidor.
Para salir: escribe 'exit'.
La primera vez te pregunta si confias en la huella del equipo: responde 'yes'." \
         "ssh $U@$H" ;;
      2) pedir U "Usuario" "admin" || { pausa; continue; }
         pedir H "IP del equipo" "$GATEWAY" || { pausa; continue; }
         lanzar "ssh con algoritmos legacy" \
"Los IOS antiguos solo ofrecen algoritmos que OpenSSH moderno desactivo.
Si ves 'no matching key exchange method found', estas opciones los habilitan
SOLO para esta conexion:
-o KexAlgorithms=+diffie-hellman-group14-sha1
-o HostKeyAlgorithms=+ssh-rsa
Usalo solo en laboratorio: son algoritmos debiles." \
         "ssh -o KexAlgorithms=+diffie-hellman-group14-sha1 -o HostKeyAlgorithms=+ssh-rsa $U@$H" ;;
      0) return ;;
    esac
  done
}

# =====================================================================
#  6) MI RED (Android limita 'ip': se usa termux-api cuando existe)
# =====================================================================
menu_info() {
  while true; do
    banner
    echo "${W}[6] INFORMACION DE MI RED${N}"
    echo
    echo "  1) Wi-Fi actual           (red, senal, velocidad, IP)  $(mk termux-wifi-connectioninfo)"
    echo "  2) Redes Wi-Fi cercanas   (canales y senal)            $(mk termux-wifi-scaninfo)"
    echo "  3) Interfaces e IPs       (ip -br addr)"
    echo "  4) Tabla de rutas         (ip route)"
    echo "  5) DNS configurado"
    echo "  6) Mi IP publica          (consulta un servicio externo)"
    echo "  0) Volver"
    echo
    read -rp "${W}movil/info> ${N}" op
    case $op in
      1) necesita termux-wifi-connectioninfo || continue
         lanzar "Wi-Fi actual" \
"Muestra datos de tu conexion: ssid (nombre), bssid (MAC del router), frequency_mhz
(2412-2484 = 2.4 GHz, 5000+ = 5 GHz), rssi (senal en dBm) y link_speed_mbps.
Senal: -50 excelente, -60 buena, -70 aceptable, -80 mala.
Necesita la app Termux:API instalada y el permiso de ubicacion." \
         "termux-wifi-connectioninfo" ;;
      2) necesita termux-wifi-scaninfo || continue
         lanzar "Redes Wi-Fi cercanas" \
"Lista las redes Wi-Fi que ve el telefono con su canal/frecuencia y senal.
Sirve para ver si muchas redes comparten tu canal (congestion).
Necesita Termux:API y el permiso de ubicacion." "termux-wifi-scaninfo" ;;
      3) lanzar "ip -br addr" \
"Resumen de interfaces: estado (UP/DOWN) y direcciones IP con mascara (CIDR).
wlan0 es el Wi-Fi; rmnet* son los datos moviles.
Android 11 o superior puede bloquear este comando: es una limitacion del sistema." \
         "ip -br addr 2>&1 || ifconfig 2>&1 || echo 'No disponible en este Android'" ;;
      4) lanzar "ip route" \
"Tabla de enrutamiento. La linea 'default via X' es tu gateway (puerta de enlace).
Si no funciona, el menu 8 permite escribir el gateway a mano." \
         "ip route 2>&1 || echo 'No disponible en este Android'" ;;
      5) lanzar "DNS" \
"Servidores DNS que usa el telefono. En Android se leen de las propiedades del
sistema; si salen vacias, mira la configuracion del Wi-Fi del telefono." \
         "getprop net.dns1; getprop net.dns2; cat /etc/resolv.conf 2>/dev/null" ;;
      6) necesita curl || continue
         lanzar "IP publica" \
"Pregunta a un servicio externo (ifconfig.me) con que IP sales a internet.
Si es distinta de tu IP local, hay NAT. Envia una consulta fuera de tu red." \
         "curl -s -m 10 https://ifconfig.me; echo" ;;
      0) return ;;
    esac
  done
}

# =====================================================================
#  7) HERRAMIENTAS INSTALADAS
# =====================================================================
menu_estado() {
  banner
  echo "${W}[7] HERRAMIENTAS INSTALADAS${N}"
  echo
  local t faltan=0
  for t in nmap ping traceroute dig whois nc curl iperf3 ssh python3 termux-wifi-connectioninfo; do
    if tiene "$t"; then printf "  %-28s ${G}instalado${N}\n" "$t"
    else printf "  %-28s ${R}falta${N}\n" "$t"; faltan=$((faltan+1)); fi
  done
  echo
  if [[ $faltan -gt 0 ]]; then
    echo "  Instalar lo que falte:"
    echo "  ${W}$INSTALAR${N}"
    [[ "$ENTORNO" == "Termux" ]] && echo "  (Para termux-wifi-*: instala tambien la app Termux:API desde F-Droid.)"
    [[ "$ENTORNO" == "Termux" && ! -d "$HOME/storage" ]] && echo "  (Para ver tus archivos: termux-setup-storage)"
  else
    echo "  ${G}Todo listo.${N}"
  fi
  echo
  echo "  Resultados guardados en: $OUTDIR"
  pausa
}

# =====================================================================
#  8) CONFIGURAR OBJETIVO / RANGO
# =====================================================================
menu_config() {
  banner
  echo "${W}[8] CONFIGURAR IP, RANGO Y GATEWAY${N}"
  echo "  Si la deteccion automatica fallo o el gateway es 'estimado', corrigelos aqui."
  echo
  pedir MIIP "Mi IP" "$MIIP" || { pausa; return; }
  pedir RANGO "Rango (CIDR, ej 192.168.1.0/24)" "$RANGO" || { pausa; return; }
  pedir GATEWAY "Gateway" "$GATEWAY" || { pausa; return; }
  GW_ESTIMADO=0
  echo "${G}Listo.${N}"; sleep 1
}

# =====================================================================
#  9) MANUALES (leer en el telefono, sin conexion una vez descargados)
# =====================================================================
RAW_URL="https://raw.githubusercontent.com/2008calvin-sudo/netlab-termux/main"
DIR_MAN="$HOME/netlab_manuales"
# archivo|titulo|ruta en el repo
MANUALES=(
  "checklist-diagnostico-movil.md|Checklist de diagnostico MOVIL (empieza aqui)|checklist-diagnostico-movil.md"
  "checklist-diagnostico.md|Checklist de diagnostico completa + reporte|manuales/checklist-diagnostico.md"
  "ping-traceroute-mtr.md|ping y traceroute|manuales/ping-traceroute-mtr.md"
  "nmap.md|nmap|manuales/nmap.md"
  "dig-whois.md|dig y whois|manuales/dig-whois.md"
  "netcat.md|netcat (nc)|manuales/netcat.md"
  "iperf3.md|iperf3|manuales/iperf3.md"
  "ip-ss.md|ip y ss|manuales/ip-ss.md"
  "sipcalc-subnetting.md|Subnetting|manuales/sipcalc-subnetting.md"
)

visor() { # archivo
  if tiene less; then less -R "$1"; else cat "$1"; fi
}

menu_manuales() {
  while true; do
    banner
    echo "${W}[9] MANUALES${N}  ${B}(guardados en $DIR_MAN)${N}"
    echo
    local i=1 m f t r estado
    for m in "${MANUALES[@]}"; do
      IFS='|' read -r f t r <<< "$m"
      if [[ -f "$DIR_MAN/$f" ]]; then estado="${G}[descargado]${N}"; else estado="${R}[falta]${N}"; fi
      printf "  %d) %-45s %s\n" "$i" "$t" "$estado"
      i=$((i+1))
    done
    echo
    echo "  p) Abrir un manual en PDF (con el visor del telefono)"
    echo "  d) Descargar / actualizar todos los manuales (texto y PDF)"
    echo "  0) Volver"
    echo
    read -rp "${W}movil/manuales> ${N}" op
    case $op in
      d|D) menu_descargar_manuales ;;
      p|P) menu_pdf ;;
      0) return ;;
      *)
        if [[ "$op" =~ ^[0-9]+$ ]] && (( op >= 1 && op <= ${#MANUALES[@]} )); then
          IFS='|' read -r f t r <<< "${MANUALES[$((op-1))]}"
          if [[ -f "$DIR_MAN/$f" ]]; then visor "$DIR_MAN/$f"
          else echo "${R}[!] Todavia no lo descargaste. Usa la opcion d.${N}"; pausa; fi
        fi ;;
    esac
  done
}

menu_pdf() {
  local i=1 m f t r n files=()
  echo
  for m in "${MANUALES[@]}"; do
    IFS='|' read -r f t r <<< "$m"; f="${f%.md}.pdf"
    [[ -f "$DIR_MAN/pdf/$f" ]] || continue
    files+=("$DIR_MAN/pdf/$f"); printf "  %d) %s\n" "$i" "$t"; i=$((i+1))
  done
  if [[ ${#files[@]} -eq 0 ]]; then echo "${R}[!] No hay PDF. Usa la opcion d.${N}"; pausa; return; fi
  read -rp "Numero (Enter = cancelar): " n
  [[ "$n" =~ ^[0-9]+$ ]] && (( n >= 1 && n <= ${#files[@]} )) || return
  if tiene termux-open; then termux-open "${files[$((n-1))]}"
  else echo "Abri esta ruta con tu visor de PDF: ${files[$((n-1))]}"; pausa; fi
}

menu_descargar_manuales() {
  local m f t r base
  base="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
  mkdir -p "$DIR_MAN"
  echo
  for m in "${MANUALES[@]}"; do
    IFS='|' read -r f t r <<< "$m"
    if [[ -f "$base/$r" ]]; then            # ya los tienes (descargaste todo el repo)
      cp "$base/$r" "$DIR_MAN/$f" && echo "  ${G}copiado${N}     $f"
    elif tiene curl && curl -fsS -m 20 -o "$DIR_MAN/$f" "$RAW_URL/$r" 2>/dev/null; then
      echo "  ${G}descargado${N} $f"
    else
      rm -f "$DIR_MAN/$f"
      echo "  ${R}fallo${N}      $f  (sin internet o sin curl)"
    fi
  done
  mkdir -p "$DIR_MAN/pdf"
  for m in "${MANUALES[@]}"; do
    IFS='|' read -r f t r <<< "$m"
    f="${f%.md}.pdf"
    if [[ -f "$base/pdf/$f" ]]; then cp "$base/pdf/$f" "$DIR_MAN/pdf/$f" && echo "  ${G}copiado${N}     pdf/$f"
    elif tiene curl && curl -fsS -m 30 -o "$DIR_MAN/pdf/$f" "$RAW_URL/pdf/$f" 2>/dev/null; then echo "  ${G}descargado${N} pdf/$f"
    else rm -f "$DIR_MAN/pdf/$f"; echo "  ${R}fallo${N}      pdf/$f"; fi
  done
  echo
  echo "Listo. Ya puedes leerlos sin conexion. Tip: en el visor, q para salir."
  echo "PDF: opcion p del menu de manuales (o en la carpeta $DIR_MAN/pdf)."
  pausa
}

# =====================================================================
#  MENU PRINCIPAL
# =====================================================================
while true; do
  banner
  echo "${W}MENU PRINCIPAL${N}"
  echo
  echo "  1) Descubrimiento        ${B}(nmap: quien esta conectado)${N}"
  echo "  2) Escaneo de puertos    ${B}(nmap: -sT, -sV, -sC ...)${N}"
  echo "  3) Diagnostico           ${B}(ping, traceroute, dig, nc, curl)${N}"
  echo "  4) Rendimiento           ${B}(iperf3 servidor / cliente)${N}"
  echo "  5) SSH                   ${B}(routers, switches, servidores)${N}"
  echo "  6) Informacion de mi red ${B}(Wi-Fi, IP, DNS)${N}"
  echo "  7) Herramientas instaladas / como instalarlas"
  echo "  8) Configurar IP, rango y gateway"
  echo "  9) Manuales               ${B}(leer y descargar al telefono)${N}"
  echo "  0) Salir"
  echo
  read -rp "${W}netlab-movil> ${N}" op
  case $op in
    1) menu_descubrimiento ;;
    2) menu_puertos ;;
    3) menu_diagnostico ;;
    4) menu_iperf ;;
    5) menu_ssh ;;
    6) menu_info ;;
    7) menu_estado ;;
    8) menu_config ;;
    9) menu_manuales ;;
    0|q|Q) echo "Hasta luego!"; exit 0 ;;
  esac
done
