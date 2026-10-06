# Manual básico: ip y ss

**Nivel:** junior · **Sirve para:** ver la configuración de red de tu equipo y qué puertos tiene abiertos · **En NetLab:** menú 6 (básico) / menú 10 (completo)

## ¿Qué son y para qué sirven?

- **`ip`** muestra (y cambia) la configuración de red: interfaces, direcciones, rutas y tabla ARP.
- **`ss`** muestra los **sockets**: qué puertos escucha tu equipo y con quién está conectado.

Reemplazan a los comandos antiguos `ifconfig`, `route`, `arp` y `netstat`.

| Antiguo | Nuevo |
|---------|-------|
| `ifconfig` | `ip addr` |
| `route -n` | `ip route` |
| `arp -a` | `ip neigh` |
| `netstat -tulpn` | `ss -tulpn` |

## ip: comandos básicos

| Comando | Qué hace |
|---------|----------|
| `ip -br addr` | Resumen de interfaces, estado e IPs |
| `ip addr` | Detalle completo |
| `ip -br link` | Interfaces y su estado (UP/DOWN), con MAC |
| `ip route` | Tabla de rutas. La línea `default via X` es tu **gateway** |
| `ip neigh` | Tabla ARP (IP ↔ MAC) |
| `ip route get 8.8.8.8` | Por dónde saldría un paquete a esa IP |
| `sudo ip link set eth0 down` | Apaga una interfaz |
| `sudo ip link set eth0 up` | La enciende |

Cambiar una IP a mano (solo prueba, se pierde al reiniciar):

```bash
sudo ip addr add 192.168.50.10/24 dev eth0
sudo ip addr del 192.168.50.10/24 dev eth0
```

> Si estás conectado por SSH, no apagues la interfaz con la que entraste.

## ss: comandos básicos

| Comando | Qué hace |
|---------|----------|
| `ss -tulpn` | Puertos **escuchando** y qué programa los usa |
| `ss -tn` | Conexiones TCP activas |
| `ss -tn state established` | Solo las ya establecidas |
| `ss -s` | Resumen con totales |
| `ss -tulpn \| grep 22` | Buscar un puerto concreto |

Significado de las letras: `t` TCP · `u` UDP · `l` escuchando · `p` proceso · `n` números en vez de nombres.

## Práctica guiada

1. ¿Cuál es mi IP y máscara? → `ip -br addr`
2. ¿Cuál es mi gateway? → `ip route`
3. ¿Con quién hablé hace poco? → `ip neigh`
4. ¿Qué servicios tengo expuestos? → `sudo ss -tulpn`
5. Por cada puerto que no reconozcas, pregúntate: ¿lo necesito abierto?

## Errores comunes

| Problema | Qué hacer |
|----------|-----------|
| `ss` no muestra el proceso | Usa `sudo` |
| `Cannot find device` | Revisa el nombre con `ip -br link` |
| La interfaz aparece `DOWN` | Cable desconectado o `ip link set ... up` |

## Para pensar

- ¿Qué indica una línea `LISTEN 0.0.0.0:22`? ¿Y `127.0.0.1:22`?
- ¿Por qué conviene revisar los puertos abiertos de un equipo?
