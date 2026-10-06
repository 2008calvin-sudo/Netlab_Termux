# Manual básico: netcat (nc)

**Nivel:** junior · **Sirve para:** probar si un puerto responde y entender cómo conversan TCP y UDP · **En NetLab (completo):** menú 6

## ¿Qué es y para qué sirve?

`nc` (netcat) abre una conexión TCP o UDP cruda con cualquier puerto. Es una "navaja suiza" para comprobar rápidamente:

- ¿Está abierto el puerto 80 de ese servidor?
- ¿Responde el servicio de correo?
- ¿Puedo comunicarme entre dos equipos?

Es más simple que `nmap` cuando solo quieres probar **un** puerto.

## Comandos básicos

| Comando | Qué hace |
|---------|----------|
| `nc -zv 192.168.1.1 80` | Prueba si el puerto 80 está abierto (`-z` no envía datos, `-v` explica) |
| `nc -zv -w 3 192.168.1.1 22` | Espera como máximo 3 segundos |
| `nc -zv 192.168.1.1 20-25` | Prueba un rango de puertos |
| `nc -zvu 192.168.1.1 53` | Prueba un puerto **UDP** |
| `nc 192.168.1.1 80` | Abre una conexión interactiva |
| `nc -l 4444` | Escucha en el puerto 4444 (modo servidor) |

## Cómo leer el resultado

| Resultado | Significa |
|-----------|-----------|
| `succeeded!` / `open` | El puerto está abierto |
| `Connection refused` | El equipo responde, pero no hay servicio en ese puerto |
| `timed out` | Nadie contesta: probablemente un firewall |

## Práctica guiada 1: chat entre dos equipos

1. Equipo A (servidor): `nc -l 4444`
2. Equipo B (cliente): `nc <IP de A> 4444`
3. Escribe en cualquiera de los dos: el texto aparece en el otro.
4. Mientras tanto, mira el tráfico: `sudo tcpdump -i eth0 -n port 4444`

Así ves que TCP hace el saludo de 3 vías antes de enviar tus mensajes.

## Práctica guiada 2: hablarle a un servidor web a mano

```bash
nc example.com 80
```
Luego escribe esto y pulsa Enter **dos veces**:
```
HEAD / HTTP/1.0
```
Recibirás las cabeceras HTTP del servidor (`200 OK`, tipo de servidor, etc.).

## Errores comunes

| Problema | Qué hacer |
|----------|-----------|
| `nc: command not found` | `sudo apt install netcat-openbsd` |
| `nc -l -p 4444` da error | En la versión openbsd se escribe `nc -l 4444` (sin `-p`) |
| Siempre da `timed out` | Revisa firewall y que la IP sea correcta |

## Para pensar

- ¿Qué diferencia hay entre `refused` y `timed out`?
- ¿Por qué probar UDP con `nc` es menos fiable que probar TCP?

> Úsalo solo en tus equipos o en laboratorio.
