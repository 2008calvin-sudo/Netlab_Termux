# Manual básico: ping, traceroute y mtr

**Nivel:** junior · **Sirve para:** comprobar si hay conectividad y encontrar dónde se corta · **En NetLab:** menú 5 (básico) / menú 6 (completo)

## ¿Qué son y para qué sirven?

Son las primeras herramientas que usa un técnico ante un "no tengo internet".

| Herramienta | Responde a |
|-------------|-----------|
| `ping` | ¿Llego a ese equipo? ¿Cuánto tarda? |
| `traceroute` | ¿Por qué routers pasa mi tráfico? |
| `mtr` | Lo mismo, pero midiendo pérdida y latencia en cada salto, en vivo |

`ping` usa mensajes **ICMP** (Echo Request / Echo Reply).

## ping

| Comando | Qué hace |
|---------|----------|
| `ping 8.8.8.8` | Envía pings hasta que pulses `Ctrl+C` |
| `ping -c 4 8.8.8.8` | Envía solo 4 |
| `ping -i 0.5 8.8.8.8` | Un ping cada 0,5 s |
| `ping -s 1000 8.8.8.8` | Cambia el tamaño del paquete |
| `ping -M do -s 1472 8.8.8.8` | Prueba el MTU: prohíbe fragmentar |
| `ping -6 ::1` | Ping por IPv6 |

**Cómo leerlo:**
- `time=12 ms` → latencia.
- `ttl=64` → pista del sistema (Linux ≈ 64, Windows ≈ 128, equipos Cisco ≈ 255).
- `0% packet loss` → todo bien. Cualquier pérdida es un problema.

## traceroute

| Comando | Qué hace |
|---------|----------|
| `traceroute 8.8.8.8` | Muestra cada salto hasta el destino |
| `traceroute -n 8.8.8.8` | Sin resolver nombres (más rápido) |
| `sudo traceroute -I 8.8.8.8` | Usa ICMP en vez de UDP |

Funciona enviando paquetes con **TTL** 1, 2, 3... Cada router que descarta el paquete avisa, así se descubre el camino. Los `* * *` indican un salto que no responde (a veces es solo un firewall).

## mtr

| Comando | Qué hace |
|---------|----------|
| `mtr 8.8.8.8` | Vista interactiva en vivo |
| `mtr -rn -c 10 8.8.8.8` | Informe de 10 ciclos, sin DNS |

Fíjate en **Loss%** (pérdida) y **Avg** (latencia promedio) en cada salto.

## Método para diagnosticar (de adentro hacia afuera)

1. `ping 127.0.0.1` → ¿funciona mi pila TCP/IP?
2. `ping <mi IP>` → ¿mi tarjeta está bien configurada?
3. `ping <gateway>` → ¿llego a mi router?
4. `ping 8.8.8.8` → ¿llego a internet por IP?
5. `ping google.com` → ¿funciona el DNS?

La primera prueba que falla te dice en qué capa está el problema.

## Errores comunes

| Mensaje | Significa |
|---------|-----------|
| `Destination Host Unreachable` | No hay ruta o el equipo no responde ARP |
| `Request timed out` / sin respuesta | El destino o un firewall no contesta |
| `Name or service not known` | Falla el DNS |
| `message too long` | El paquete supera el MTU del camino |

## Para pensar

- Si `ping 8.8.8.8` funciona pero `ping google.com` no, ¿qué falla?
- ¿Qué indica un salto con `* * *` si los siguientes sí responden?
