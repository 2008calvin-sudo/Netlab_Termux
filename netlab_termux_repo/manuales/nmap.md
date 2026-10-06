# Manual básico: nmap

**Nivel:** junior · **Sirve para:** descubrir equipos y ver qué puertos y servicios tienen abiertos · **En NetLab:** menús 1 y 2

## ¿Qué es y para qué sirve?

`nmap` es el escáner de redes más usado. Un técnico lo usa para responder tres preguntas:

1. ¿Qué equipos están encendidos en mi red?
2. ¿Qué puertos tiene abiertos cada uno?
3. ¿Qué servicio (y versión) corre detrás de cada puerto?

Sirve para inventariar una red, comprobar que un firewall bloquea lo que debe y detectar servicios que nadie sabía que estaban encendidos.

## Estados de un puerto

| Estado | Significa |
|--------|-----------|
| `open` | Hay un servicio escuchando |
| `closed` | El equipo responde, pero no hay servicio en ese puerto |
| `filtered` | Algo (un firewall) bloquea y no se puede saber |

## Comandos básicos

| Comando | Qué hace |
|---------|----------|
| `nmap 192.168.1.1` | Escaneo normal: los 1000 puertos más comunes |
| `nmap -sn 192.168.1.0/24` | Solo busca equipos encendidos, sin escanear puertos |
| `nmap -F 192.168.1.1` | Escaneo rápido (100 puertos más comunes) |
| `nmap -p 22,80,443 192.168.1.1` | Solo esos puertos |
| `nmap -p 1-1024 192.168.1.1` | Un rango de puertos |
| `nmap -p- 192.168.1.1` | Los 65535 puertos (tarda más) |
| `sudo nmap -sS 192.168.1.1` | Escaneo SYN: envía SYN y corta antes de terminar el saludo TCP |
| `nmap -sT 192.168.1.1` | Escaneo TCP completo (no necesita root) |
| `sudo nmap -sU --top-ports 20 192.168.1.1` | Puertos UDP más comunes (DNS, DHCP, SNMP...) |
| `nmap -sV 192.168.1.1` | Detecta servicio y versión de cada puerto abierto |
| `sudo nmap -O 192.168.1.1` | Intenta adivinar el sistema operativo |
| `sudo nmap -A -T4 192.168.1.1` | Todo junto: SO, versiones, scripts y traceroute |
| `nmap -Pn 192.168.1.1` | No hace ping previo (útil si el equipo "no responde") |
| `nmap --open 192.168.1.1` | Muestra solo los puertos abiertos |
| `nmap -oN resultado.txt 192.168.1.1` | Guarda el resultado en un archivo |

**Rangos:** `192.168.1.0/24` equivale a las 254 direcciones de `192.168.1.1` a `192.168.1.254`.

## Práctica guiada

1. Averigua tu red: `ip -br addr` (ej. `192.168.1.25/24`).
2. Busca equipos vivos: `nmap -sn 192.168.1.0/24`.
3. Elige uno (tu router, por ejemplo) y escanéalo: `nmap -F 192.168.1.1`.
4. Mira las versiones: `nmap -sV 192.168.1.1`.
5. Con Suricata encendido, ejecuta `sudo nmap -A 192.168.1.1` y mira la alerta en EveBox.

## Errores comunes

| Mensaje | Qué hacer |
|---------|-----------|
| `requires root privileges` | Usa `sudo` (SYN, UDP y OS lo necesitan) |
| `Host seems down` | Prueba `-Pn`: el equipo puede estar bloqueando el ping |
| El escaneo tarda mucho | Usa `-F` o limita puertos con `-p` |

## Para pensar

- ¿Qué diferencia hay entre un puerto `closed` y uno `filtered`?
- ¿Por qué un escaneo `-sS` se llama "semiabierto"?

> **Importante:** escanea solo tus equipos, tu laboratorio o redes con autorización escrita. Para practicar, el proyecto Nmap permite pruebas moderadas contra `scanme.nmap.org`.
