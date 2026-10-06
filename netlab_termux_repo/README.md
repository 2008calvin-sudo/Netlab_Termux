# NetLab Termux (Móvil, sin root)

> Repositorio hermano de [**netlab**](https://github.com/2008calvin-sudo/netlab) (versiones de PC: básico, completo y los 22 manuales). Este contiene **todo lo móvil**, autocontenido: no necesitás el otro para usarlo.

Versión de bolsillo de NetLab: un menú en Bash, estilo *setoolkit*, que explica cada comando antes de ejecutarlo, pero usando **solo lo que funciona en un teléfono Android sin root**. Pocas herramientas, todas pequeñas.

> **Aviso legal:** usá este script **solo en tu propio Wi-Fi, en un laboratorio o con autorización por escrito**. Escanear redes ajenas puede ser ilegal.

> **Nota sobre su origen:** lo armó un estudiante de redes con ayuda de una IA (Claude, de Anthropic). **Todavía no fue probado en muchos modelos de teléfono**: si algo falla en el tuyo, abrí un *issue* con tu versión de Android.

## Herramientas (lista corta)

| Herramienta | Para qué | Paquete Termux |
|---|---|---|
| `nmap` | Descubrir equipos y puertos (modo sin root) | `nmap` |
| `ping`, `traceroute` | Conectividad y ruta | `traceroute` (ping ya viene) |
| `dig`, `whois` | DNS y propietario de un dominio | `dnsutils`, `whois` |
| `nc` | Probar un puerto | `netcat-openbsd` |
| `iperf3` | Medir velocidad con otro equipo | `iperf3` |
| `ssh` | Entrar a routers, switches, servidores | `openssh` |
| `curl` | Probar webs y ver tu IP pública | `curl` |
| `termux-api` | Datos del Wi-Fi (señal, canal) | `termux-api` + app **Termux:API** |

Instalar todo de una vez en **Termux**:

```bash
pkg update
pkg install nmap dnsutils traceroute openssh netcat-openbsd iperf3 curl whois python termux-api
```

En **NetHunter sin root** (Kali dentro de Termux) se usa `apt` y no hay `sudo`:

```bash
apt update
apt install nmap dnsutils traceroute openssh-client netcat-openbsd iperf3 curl whois python3
```

El menú **7** te muestra qué tenés y qué te falta.

## Cómo bajarlo al teléfono

**Opción A: con git (recomendada)**

```bash
pkg install git
git clone https://github.com/2008calvin-sudo/netlab-termux.git
cd netlab-termux
bash Termux_netlab.sh
```

**Opción B: solo el script**

```bash
curl -O https://raw.githubusercontent.com/2008calvin-sudo/netlab-termux/main/Termux_netlab.sh
bash Termux_netlab.sh
```

**Opción C: lo descargaste con el navegador**

```bash
termux-setup-storage            # una sola vez; aceptá el permiso
cp ~/storage/downloads/Termux_netlab.sh ~
bash Termux_netlab.sh
```

Usá siempre `bash Termux_netlab.sh` (no `./`): evita problemas de permisos en Android.

## Qué se puede y qué no (sin root)

Android sin root **no permite sockets crudos**. Por eso:

| Función | Sin root | Alternativa |
|---|---|---|
| Descubrir equipos (`nmap -sn`) | ✔ por conexión TCP/ping normal | Menú 1 |
| Ver la tabla ARP | ⚠ a menudo bloqueada en Android 10+ | Menú 1 intenta `/proc/net/arp` |
| Escaneo de puertos TCP (`-sT`, `-sV`, `-sC`) | ✔ | Menú 2 |
| Escaneo SYN (`-sS`), UDP (`-sU`), SO (`-O`) | ✘ necesita root | Usá la versión Completa en la PC (repo netlab) |
| `arp-scan`, `netdiscover` | ✘ necesita root | PC |
| `tcpdump` / captura de tráfico | ✘ necesita root | PC, o la app PCAPdroid |
| `ip`, `ss` | ⚠ limitados según Android | Menú 6 prueba alternativas |
| ping, traceroute, dig, nc, curl, iperf3, ssh | ✔ | Menús 3, 4 y 5 |
| Señal y canales Wi-Fi | ✔ con Termux:API | Menú 6 |

Si tu NetHunter **sí tiene root**, usá la [versión Completa](https://github.com/2008calvin-sudo/netlab/blob/main/completo/README.md).

## Requisitos y consejos

- Instalá Termux desde **F-Droid** (la versión de Play Store está desactualizada).
- Para `termux-wifi-*`: instalá la app **Termux:API** y dale permiso de **Ubicación**.
- Si `nmap` no resuelve nombres: agregá `--system-dns`.
- Los resultados se guardan en `~/netlab_resultados`.
- `Ctrl+C` corta el comando y vuelve al menú.

## Manuales en el teléfono

El menú **9 (Manuales)** deja leer 9 manuales directo en la terminal, sin salir de Termux:

1. Checklist de diagnóstico móvil (empezá por acá)
2. Checklist completa + plantilla de reporte
3. ping y traceroute · nmap · dig y whois · netcat · iperf3 · ip y ss · subnetting

Cómo usarlo:
- Opción **d**: los descarga (o los copia, si clonaste todo el repo) a `~/netlab_manuales`. Necesitás internet solo esa vez.
- Después elegís el número y se abre el manual. Con `q` salís; las flechas o `Espacio` mueven la página.
- Opción **p**: abre el manual en **PDF** con el visor de tu teléfono (usa `termux-open`).
- Quedan guardados: se leen **sin conexión**.

**PDF sueltos:** la carpeta [`pdf/`](pdf/) tiene los 9 manuales en PDF (formato A5, pensado para pantalla de celular). Podés bajarlos directo desde GitHub, sin usar Termux. Los 22 manuales de la versión de PC están en el repo [netlab](https://github.com/2008calvin-sudo/netlab/tree/main/manuales).

Los textos de los 9 manuales están en [`manuales/`](manuales/), y se pueden leer en el navegador del teléfono desde GitHub.

## Estructura

```
netlab-termux/
├── Termux_netlab.sh
├── checklist-diagnostico-movil.md
├── manuales/      ← 8 manuales + checklist completa (texto)
├── pdf/           ← los mismos en PDF para el celular
├── LICENSE
└── README.md
```

## Para aprender más

- [Checklist de diagnóstico móvil](checklist-diagnostico-movil.md): el método paso a paso, adaptado al teléfono.
- Manuales: [nmap](manuales/nmap.md) · [ping/traceroute](manuales/ping-traceroute-mtr.md) · [dig/whois](manuales/dig-whois.md) · [netcat](manuales/netcat.md) · [iperf3](manuales/iperf3.md) · [ip y ss](manuales/ip-ss.md) · [subnetting](manuales/sipcalc-subnetting.md)
- [Checklist completa](manuales/checklist-diagnostico.md) con plantilla de reporte
- [netlab-profesional](https://github.com/2008calvin-sudo/netlab-profesional): diagnóstico automático para teléfono y PC (solo para técnicos con experiencia)

## Licencia

MIT. Ver [LICENSE](LICENSE).
