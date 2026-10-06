# Checklist de diagnóstico de red (paso a paso)

**Nivel:** junior · **Para qué sirve:** investigar un problema de red con un orden fijo, sin adivinar, y dejar un diagnóstico que se pueda **escalar** · **Herramientas:** las de NetLab (cada paso enlaza a su manual)

## Cómo usar este checklist

Cuando algo falla, la tentación es probar cosas al azar. Este documento te da un **método**: ir de abajo hacia arriba por las capas (físico → enlace → red → transporte → DNS → aplicación), marcar cada casilla y **anotar el resultado**. Así sabes dónde falla y qué ya descartaste.

### Reglas de oro

1. **Una cosa a la vez.** Si cambias dos cosas juntas, no sabrás cuál arregló (o rompió) el problema.
2. **De abajo hacia arriba.** Si el cable está mal, no tiene sentido revisar el DNS.
3. **Anota todo:** qué comando ejecutaste, a qué hora y qué respondió. Si lo escalas, esa lista es tu informe.
4. **Compara con algo que funciona:** ¿anda en otro equipo? ¿antes funcionaba? ¿qué cambió?
5. **No arregles lo que no entiendes.** Si no sabes qué hace un comando, lee su manual primero.
6. **Si algo parece un ataque, no borres ni apagues nada:** escala de inmediato.
7. **Permisos:** trabaja solo sobre equipos y redes que estás autorizado a revisar.

---

## Paso 0 — Entender el problema

Antes de tocar nada, pregunta y anota:

- [ ] ¿**Qué** no funciona exactamente? (internet, una página, una impresora, un servidor, "está lento"...)
- [ ] ¿**Desde cuándo**? ¿Funcionaba antes?
- [ ] ¿**Qué cambió** hace poco? (cable, equipo nuevo, actualización, cambio de configuración)
- [ ] ¿A **cuántos** afecta? ¿A uno, a varios o a todos?
- [ ] ¿Es por **cable o Wi-Fi**?
- [ ] ¿Pasa **siempre** o a ratos?

**Define el alcance:**

| Si afecta a... | Sospecha primero... |
|----------------|---------------------|
| Un solo equipo | Ese equipo: cable, configuración IP, servicio |
| Varios equipos de una zona | Un switch, un access point, una VLAN |
| Toda la red | Router/gateway, DNS, proveedor de internet |
| Un solo servicio o sitio | El servicio, un firewall, DNS |

---

## Paso 1 — Capa física y enlace

*¿Hay conexión física y el enlace funciona?* Manuales: [ip y ss](ip-ss.md) · [ethtool](https://github.com/2008calvin-sudo/netlab/blob/main/manuales/ethtool.md) · [arp-scan](https://github.com/2008calvin-sudo/netlab/blob/main/manuales/arp-scan.md)

- [ ] **Cable y luces:** el cable está firme y el puerto muestra luz de enlace.
- [ ] **Estado de la interfaz:**
  ```bash
  ip -br link
  ```
  Debe decir `UP`. Si dice `DOWN`, no hay enlace.
- [ ] **Velocidad y duplex** (solo cableado):
  ```bash
  sudo ethtool eth0
  ```
  Esperado: `Link detected: yes`, `Speed: 1000Mb/s` (o la de tu red), `Duplex: Full`.
- [ ] **Errores en la tarjeta:**
  ```bash
  sudo ethtool -S eth0 | grep -i err
  ```
  Si los contadores de errores suben, sospecha del cable.
- [ ] **¿Conoce a su vecino?** (tabla ARP)
  ```bash
  ip neigh
  ```
  El gateway debería aparecer con su MAC y estado `REACHABLE` o `STALE`. Si dice `FAILED` o `INCOMPLETE`, no responde ARP.

| Resultado | Significa | Qué hacer |
|-----------|-----------|-----------|
| `DOWN` / `Link detected: no` | Sin enlace | Cambia cable, puerto del switch, revisa que esté encendido |
| `Speed` más baja de lo normal (100 en vez de 1000) | Cable dañado o mal conectado | Cambia el cable |
| `Duplex: Half` o errores que suben | Desajuste de duplex o cable malo | Revisa el puerto del switch; cambia cable |
| `FAILED` en el gateway | No responde en capa 2 | Revisa VLAN, puerto, que el gateway esté encendido |

✅ Todo bien → **Paso 2**. ❌ Falla → corrige y repite este paso.

---

## Paso 2 — Capa de red (IP)

*¿Tengo una dirección correcta y llego a donde debo?* Manuales: [ip y ss](ip-ss.md) · [ping, traceroute y mtr](ping-traceroute-mtr.md) · [sipcalc](sipcalc-subnetting.md)

### 2.1 Mi configuración

- [ ] **Dirección y máscara:**
  ```bash
  ip -br addr
  ```
- [ ] **Gateway (puerta de enlace):**
  ```bash
  ip route
  ```
  Busca la línea `default via X.X.X.X`.

| Resultado | Significa |
|-----------|-----------|
| Sin IP en la interfaz | No obtuvo dirección (DHCP caído o cable) |
| IP `169.254.x.x` | El equipo no encontró un servidor DHCP y se asignó una dirección de emergencia |
| Máscara o red distinta a la de los demás | Mala configuración |
| No hay línea `default via` | No tiene gateway: no saldrá de su red |

### 2.2 La escalera del ping (de adentro hacia afuera)

- [ ] **Ping 1:** `ping -c 4 127.0.0.1` → ¿funciona la pila TCP/IP de mi equipo?
- [ ] **Ping 2:** `ping -c 4 <mi IP>` → ¿mi tarjeta está bien configurada?
- [ ] **Ping 3:** `ping -c 4 <gateway>` → ¿llego a mi router?
- [ ] **Ping 4:** `ping -c 4 8.8.8.8` → ¿llego a internet por IP?
- [ ] **Ping 5:** `ping -c 4 cisco.com` → ¿funciona la resolución de nombres? (si falla aquí y el 4 anda → **Paso 4**)

**La primera prueba que falla te dice dónde está el problema:**

| Falla el... | Causa probable |
|-------------|----------------|
| Ping 1 | Pila TCP/IP dañada o desactivada |
| Ping 2 | Interfaz mal configurada o apagada |
| Ping 3 | Problema local: cable, VLAN, IP/máscara, el router |
| Ping 4 | El router no sale a internet (proveedor, ruta, NAT) |
| Ping 5 (el 4 anda) | DNS → **Paso 4** |

### 2.3 Encontrar el punto de corte

- [ ] **Ruta salto a salto:**
  ```bash
  traceroute -n 8.8.8.8
  ```
- [ ] **Pérdida y latencia por salto:**
  ```bash
  mtr -rn -c 10 8.8.8.8
  ```
  Mira la columna `Loss%`: la pérdida que **continúa** hasta el final es real; si solo aparece en un salto intermedio y los siguientes están bien, suele ser que ese router limita las respuestas.

### 2.4 Otros chequeos de red

- [ ] **IP duplicada** (dos equipos con la misma IP, intermitencias):
  ```bash
  sudo arp-scan --localnet
  ```
  Busca la misma IP con **dos MAC distintas**.
- [ ] **MTU** (funciona lo pequeño, falla lo grande):
  ```bash
  ping -M do -s 1472 8.8.8.8
  ```
  Si responde `message too long`, baja el número hasta que pase y suma 28 para conocer el MTU real.

✅ Hay conectividad IP → **Paso 3**. ❌ Falla → corrige IP/gateway/ruta y repite.

---

## Paso 3 — Capa de transporte (TCP/UDP y puertos)

*Llego al equipo, ¿responde el servicio en su puerto?* Manuales: [netcat](netcat.md) · [nmap](nmap.md) · [ip y ss](ip-ss.md) · [tcpdump](https://github.com/2008calvin-sudo/netlab/blob/main/manuales/tcpdump.md)

- [ ] **Probar el puerto desde el cliente:**
  ```bash
  nc -zv -w 3 192.168.1.10 80
  ```
- [ ] **Confirmar con nmap:**
  ```bash
  nmap -p 80,443 192.168.1.10
  ```
- [ ] **En el servidor, ¿el servicio está escuchando?**
  ```bash
  sudo ss -tulpn | grep :80
  ```
  Fíjate en la dirección: `0.0.0.0:80` acepta conexiones de la red; `127.0.0.1:80` solo de la propia máquina.

| Resultado | Significa | Qué hacer |
|-----------|-----------|-----------|
| `succeeded` / `open` | El puerto responde | Sigue al Paso 4/5 |
| `Connection refused` / `closed` | El equipo responde, pero no hay servicio en ese puerto | Inicia el servicio (Paso 5) o revisa el puerto |
| `timed out` / `filtered` | Algo bloquea: firewall, ACL, ruta | Revisa firewall del servidor, del router y ACLs |

### Verlo con tcpdump (cuando hay dudas)

```bash
sudo tcpdump -i eth0 -n host 192.168.1.10 and port 80
```

| Qué ves | Interpretación |
|---------|----------------|
| `Flags [S]` y nada más | Tu SYN sale, pero no vuelve nada: filtrado o ruta |
| `Flags [S]` → `Flags [S.]` | SYN/ACK recibido: el puerto está abierto |
| `Flags [S]` → `Flags [R.]` | Reset: puerto cerrado |

✅ El puerto responde → **Paso 4** o **Paso 5**. ❌ Falla → firewall, ACL o servicio apagado.

---

## Paso 4 — Resolución de nombres (DNS)

*Funciona por IP, pero no por nombre.* Manual: [dig y whois](dig-whois.md)

- [ ] **¿Qué DNS usa mi equipo?**
  ```bash
  cat /etc/resolv.conf
  ```
- [ ] **Resolver con mi DNS:**
  ```bash
  dig cisco.com +short
  ```
- [ ] **Resolver con un DNS público:**
  ```bash
  dig @8.8.8.8 cisco.com +short
  ```

| Resultado | Significa | Qué hacer |
|-----------|-----------|-----------|
| Ambos responden | DNS correcto | Sigue al Paso 5 |
| Solo responde `@8.8.8.8` | Falla tu DNS local | Revisa servidor DNS configurado / DHCP |
| Ninguno responde | Sin salida a internet por el puerto 53 | Vuelve al Paso 2 |
| `NXDOMAIN` | El nombre no existe | Revisa cómo está escrito |

---

## Paso 5 — Aplicación y servicios

*Llego al puerto, pero el servicio no funciona bien.* Manuales: [systemctl](https://github.com/2008calvin-sudo/netlab/blob/main/manuales/systemctl.md) · [ip y ss](ip-ss.md)

- [ ] **Estado del servicio:**
  ```bash
  systemctl status nombre-servicio
  ```
- [ ] **¿Hay servicios fallidos?**
  ```bash
  systemctl --failed
  ```
- [ ] **Últimos registros:**
  ```bash
  journalctl -u nombre-servicio -n 50
  ```
- [ ] **Probar la respuesta web** (si aplica):
  ```bash
  curl -I http://192.168.1.10
  ```
  `200` = correcto · `301/302` = redirección · `403` = sin permiso · `404` = no encontrado · `500/503` = error del servidor.
- [ ] **Reiniciar** (solo si lo permiten y tras anotar el estado):
  ```bash
  sudo systemctl restart nombre-servicio
  ```

---

## Paso 6 — Rendimiento (si el problema es "está lento")

*Hay conexión, pero va mal.* Manuales: [iperf3](iperf3.md) · [iftop, nload y bmon](https://github.com/2008calvin-sudo/netlab/blob/main/manuales/iftop-nload-bmon.md) · [vnstat](https://github.com/2008calvin-sudo/netlab/blob/main/manuales/vnstat.md) · [Wireshark](https://github.com/2008calvin-sudo/netlab/blob/main/manuales/wireshark-tshark.md)

- [ ] **Latencia y pérdida:** `mtr -rn -c 20 <destino>`
- [ ] **¿Es mi red local o internet?** Mide entre dos equipos de tu red:
  ```bash
  iperf3 -s            # en un equipo
  iperf3 -c <IP>       # en el otro
  ```
  Si la red local va bien, el problema está fuera (proveedor/servicio).
- [ ] **¿Quién consume el ancho de banda?**
  ```bash
  sudo iftop -nP -i eth0
  ```
- [ ] **Historial** (¿es siempre a la misma hora?): `vnstat -h -i eth0`
- [ ] **Enlace físico:** vuelve a revisar `ethtool` (velocidad y duplex).
- [ ] **Retransmisiones** (captura en Wireshark, filtro): `tcp.analysis.retransmission`

| Resultado | Sospecha |
|-----------|----------|
| Pérdida de paquetes constante | Cable, Wi-Fi o enlace saturado |
| iperf3 muy por debajo de la velocidad del puerto | Cable, duplex, switch o Wi-Fi |
| Un equipo consume todo el ancho de banda | Descarga, copia o programa descontrolado |
| Muchas retransmisiones | Congestión o enlace con errores |

---

## Paso 7 — Si sospechas algo raro (seguridad)

*Conexiones desconocidas, alertas, equipos que no deberían estar.* Manuales: [Suricata + EveBox](https://github.com/2008calvin-sudo/netlab/blob/main/manuales/suricata-evebox.md) · [ip y ss](ip-ss.md) · [nmap](nmap.md)

- [ ] **Puertos abiertos inesperados:** `sudo ss -tulpn`
- [ ] **Conexiones activas:** `ss -tn`
- [ ] **Equipos desconocidos:** `sudo arp-scan --localnet`
- [ ] **Alertas del IDS:** revisa el panel de EveBox o `eve.json`.

> **Importante:** no borres registros, no apagues equipos y no "limpies" nada. **Anota y escala.** Cualquier cambio puede destruir evidencia.

---

## Paso 8 — Documentar y escalar

### ¿Cuándo escalar?

- [ ] Ya hiciste los pasos y la causa está **fuera de tu alcance** (proveedor, equipo que no administras, falta de permisos).
- [ ] Afecta a **muchos usuarios** o a un servicio crítico.
- [ ] Hay **sospecha de seguridad**.
- [ ] Hay **riesgo de pérdida de datos** o de dañar un equipo.
- [ ] Se acabó el **tiempo acordado** para resolverlo y no tienes causa.

Escalar a tiempo no es fallar: es parte del trabajo. Lo importante es escalar **con datos**.

### Plantilla de reporte de diagnóstico

Copia, completa y envía junto con el ticket.

```
REPORTE DE DIAGNÓSTICO
Fecha y hora:
Reportado por:
Tomado por:

1. EQUIPO AFECTADO
   Nombre / IP / MAC:
   Sistema operativo:
   Ubicación / conexión (cable o Wi-Fi):

2. PROBLEMA
   Descripción:
   Desde cuándo:
   Qué cambió antes:
   Alcance (uno / varios / todos):

3. PRUEBAS REALIZADAS
   Paso | Comando | Resultado | OK / FALLA
   -----|---------|-----------|-----------
   1    |         |           |
   2    |         |           |
   3    |         |           |

4. HIPÓTESIS
   Causa probable:
   Por qué:

5. ACCIONES TOMADAS
   (qué cambiaste y cuál fue el efecto)

6. ESTADO ACTUAL
   [ ] Resuelto   [ ] Mitigado   [ ] Sin resolver

7. ESCALADO A
   Persona / equipo:
   Motivo:

8. ADJUNTOS
   Salida de comandos, capturas de pantalla, archivos .pcap
```

> **Cuidado al compartir:** antes de adjuntar capturas o configuraciones, quita contraseñas, comunidades SNMP y datos sensibles.

---

## Síntoma → dónde mirar primero

| Lo que dice el usuario | Empieza por... |
|------------------------|----------------|
| "No tengo internet" | Paso 1 y 2 (escalera del ping) |
| "Entro por IP pero no por nombre" | Paso 4 (DNS) |
| "Una página o servicio no abre, lo demás sí" | Paso 3 y 5 |
| "Todo está lento" | Paso 6 |
| "Se corta a ratos" | Paso 1 (cable/duplex) y `mtr` con pérdida |
| "Solo falla en algunos equipos" | IP duplicada, VLAN, DHCP (Paso 2) |
| "Una impresora o equipo no responde" | Paso 1, 2 y 3 (¿misma red? ¿puerto?) |
| "Algo raro, conexiones que no conozco" | Paso 7 y escalar |

## Resumen visual

```
 ¿Sin conexión?
   │
   ├─ Paso 1: ¿enlace UP, velocidad/duplex bien?   ── No → cable / puerto
   │                         │ Sí
   ├─ Paso 2: ¿IP correcta? ¿ping al gateway?      ── No → IP / VLAN / router
   │                         │ Sí
   ├─ Paso 2: ¿ping a 8.8.8.8?                     ── No → router / proveedor
   │                         │ Sí
   ├─ Paso 4: ¿ping a un nombre?                   ── No → DNS
   │                         │ Sí
   ├─ Paso 3: ¿responde el puerto del servicio?    ── No → firewall / servicio
   │                         │ Sí
   └─ Paso 5/6: aplicación o rendimiento           ── No resuelto → Paso 8: escalar
```

## Chuleta de comandos

| Para... | Comando |
|---------|---------|
| Estado de interfaces | `ip -br link` |
| Mi IP y gateway | `ip -br addr` · `ip route` |
| Velocidad y duplex | `sudo ethtool eth0` |
| Tabla ARP | `ip neigh` |
| Probar conectividad | `ping -c 4 <destino>` |
| Ver la ruta | `traceroute -n <destino>` · `mtr -rn -c 10 <destino>` |
| Probar un puerto | `nc -zv -w 3 <IP> <puerto>` |
| Escanear puertos | `nmap -p <puertos> <IP>` |
| Puertos que escucho | `sudo ss -tulpn` |
| DNS | `dig <dominio> +short` · `dig @8.8.8.8 <dominio> +short` |
| Servicios | `systemctl status <svc>` · `journalctl -u <svc> -n 50` |
| Respuesta web | `curl -I http://<host>` |
| Ver paquetes | `sudo tcpdump -i eth0 -n <filtro>` |
| Velocidad entre equipos | `iperf3 -s` / `iperf3 -c <IP>` |
| Quién consume | `sudo iftop -nP -i eth0` |

> Con el tiempo cambiarás de entorno (Windows, equipos Cisco, la nube) y los comandos serán otros, pero **el método es el mismo**: de abajo hacia arriba, una cosa a la vez, y anotando todo.
