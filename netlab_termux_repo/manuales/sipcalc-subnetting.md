# Manual básico: sipcalc (subnetting)

**Nivel:** junior · **Sirve para:** calcular subredes y comprobar tus ejercicios del curso · **En NetLab (completo):** menú 7

## ¿Qué es y para qué sirve?

El **subnetting** (dividir una red en redes más pequeñas) es una de las habilidades centrales de CCNA y de cualquier técnico de redes. `sipcalc` calcula todo al instante, pero **aprende a hacerlo a mano**: la calculadora sirve para comprobar, no para reemplazar.

## Conceptos mínimos

- Una IPv4 tiene **32 bits**. El prefijo `/24` indica que los primeros 24 son de red y los 8 restantes de hosts.
- **Hosts útiles = 2^(bits de host) − 2** (se restan la dirección de red y la de broadcast).

| Prefijo | Máscara | Hosts útiles | Salto |
|---------|---------|--------------|-------|
| /24 | 255.255.255.0 | 254 | 256 |
| /25 | 255.255.255.128 | 126 | 128 |
| /26 | 255.255.255.192 | 62 | 64 |
| /27 | 255.255.255.224 | 30 | 32 |
| /28 | 255.255.255.240 | 14 | 16 |
| /29 | 255.255.255.248 | 6 | 8 |
| /30 | 255.255.255.252 | 2 | 4 |

## Comandos básicos

| Comando | Qué hace |
|---------|----------|
| `sipcalc 192.168.1.10/24` | Información completa de esa red |
| `sipcalc 192.168.1.10 255.255.255.0` | Igual, con máscara en lugar de prefijo |
| `sipcalc 192.168.10.0/24 -s 26` | Divide la red en subredes `/26` |
| `sipcalc 2001:db8::/64` | También calcula IPv6 |

## Cómo leer el resultado

- **Network address** → dirección de la red.
- **Broadcast address** → última dirección (no se asigna a equipos).
- **Usable range** → rango de IPs que sí puedes asignar.
- **Number of usable hosts** → cuántos equipos caben.
- **Wildcard mask** → inversa de la máscara (la usarás en las ACL de Cisco).

## Práctica guiada

**Ejercicio:** dividir `192.168.10.0/24` en 4 subredes iguales.

1. Para 4 subredes necesitas 2 bits más: `/24` pasa a `/26`.
2. Ejecuta: `sipcalc 192.168.10.0/24 -s 26`
3. Resultado esperado:

| Subred | Red | Rango útil | Broadcast |
|--------|-----|-----------|-----------|
| 1 | 192.168.10.0/26 | .1 – .62 | .63 |
| 2 | 192.168.10.64/26 | .65 – .126 | .127 |
| 3 | 192.168.10.128/26 | .129 – .190 | .191 |
| 4 | 192.168.10.192/26 | .193 – .254 | .255 |

**Para probar solo:** ¿cuántos hosts caben en `/27`? ¿Y a qué red pertenece `172.16.5.130/25`? Calcula a mano y comprueba con `sipcalc`.

## Errores comunes

| Problema | Qué hacer |
|----------|-----------|
| `command not found` | `sudo apt install sipcalc` |
| Resultados que no esperabas | Revisa si escribiste prefijo (`/24`) o máscara |

## Para pensar

- ¿Por qué se restan 2 direcciones al contar hosts?
- ¿Qué prefijo usarías en un enlace punto a punto entre dos routers?
