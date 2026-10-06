# Manual básico: iperf3

**Nivel:** junior · **Sirve para:** medir la velocidad real entre dos equipos de tu red · **En NetLab (completo):** menú 5

## ¿Qué es y para qué sirve?

El "test de velocidad" de internet mide tu salida a internet. `iperf3` mide la velocidad **entre dos equipos tuyos** (por ejemplo, dos PCs conectadas a un switch). Así compruebas el rendimiento real de un cable, un switch, un Wi-Fi o una VLAN.

Necesitas **dos equipos**: uno hace de **servidor** y el otro de **cliente**.

```
 Cliente  ─────── red a medir ───────►  Servidor
iperf3 -c IP                            iperf3 -s
```

## Comandos básicos

**En el equipo servidor:**

| Comando | Qué hace |
|---------|----------|
| `iperf3 -s` | Queda esperando conexiones (puerto 5201) |

**En el equipo cliente:**

| Comando | Qué hace |
|---------|----------|
| `iperf3 -c 192.168.1.10` | Prueba de 10 s hacia el servidor (subida) |
| `iperf3 -c 192.168.1.10 -t 30` | Prueba de 30 segundos |
| `iperf3 -c 192.168.1.10 -R` | Invertida: mide la **bajada** |
| `iperf3 -c 192.168.1.10 -P 4` | 4 conexiones en paralelo |
| `iperf3 -c 192.168.1.10 -u -b 10M` | Prueba **UDP** a 10 Mbit/s |
| `iperf3 -c 192.168.1.10 -p 5202` | Otro puerto |

## Cómo leer el resultado

- **Bitrate** → velocidad real (Mbits/sec o Gbits/sec).
- **Retr** (TCP) → paquetes retransmitidos. Muchos = enlace con problemas.
- **Jitter** y **Lost/Total** (UDP) → variación del retraso y paquetes perdidos. Clave para VoIP y video.

Ejemplo: un puerto Fast Ethernet debería dar cerca de **94 Mbits/sec**; uno Gigabit, cerca de **940 Mbits/sec**. Si da mucho menos, algo anda mal (cable, duplex, Wi-Fi).

## Práctica guiada

1. En el equipo A: `iperf3 -s`
2. En el equipo B: `iperf3 -c <IP de A>`
3. Prueba la otra dirección: `iperf3 -c <IP de A> -R`
4. Compara Wi-Fi contra cable.
5. Prueba UDP: `iperf3 -c <IP de A> -u -b 50M` y mira la pérdida.

## Errores comunes

| Mensaje | Qué hacer |
|---------|-----------|
| `Connection refused` | El servidor no está corriendo, o IP/puerto equivocado |
| `unable to connect` / se cuelga | Un firewall bloquea el puerto 5201 |
| `the server is busy running a test` | Espera a que termine la otra prueba |

## Recomendación

Cuando el instalador pregunte si ejecutar `iperf3` como servicio automático, responde **No**. Úsalo solo cuando lo necesites, para no dejar un puerto abierto.

## Para pensar

- ¿Por qué un test contra otro equipo de tu red no depende de tu proveedor de internet?
- ¿Qué podría causar que un enlace Gigabit solo dé 100 Mbits/sec?
