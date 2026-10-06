# Manual básico: dig y whois

**Nivel:** junior · **Sirve para:** consultar DNS y saber a quién pertenece un dominio o una IP · **En NetLab:** menú 5 (básico) / menú 6 (completo)

## ¿Qué son y para qué sirven?

- **DNS** traduce nombres (`cisco.com`) a direcciones IP. Usa el puerto **53**.
- **`dig`** consulta servidores DNS y te muestra exactamente qué responden.
- **`whois`** te dice quién registró un dominio o a qué organización pertenece una IP.

Cuando "internet no anda" pero el `ping` por IP funciona, casi siempre es DNS.

## dig: comandos básicos

| Comando | Qué hace |
|---------|----------|
| `dig cisco.com` | Consulta completa (registro A) |
| `dig cisco.com +short` | Solo la respuesta |
| `dig cisco.com MX` | Servidores de correo |
| `dig cisco.com NS` | Servidores de nombres |
| `dig cisco.com TXT` | Registros de texto |
| `dig @8.8.8.8 cisco.com` | Pregunta a un DNS concreto |
| `dig -x 8.8.8.8` | Búsqueda inversa (de IP a nombre) |
| `dig cisco.com +trace` | Muestra el camino de la resolución |

### Tipos de registro

| Tipo | Contiene |
|------|----------|
| `A` | IPv4 del nombre |
| `AAAA` | IPv6 del nombre |
| `MX` | Servidores de correo |
| `NS` | Servidores DNS del dominio |
| `CNAME` | Alias a otro nombre |
| `PTR` | Nombre de una IP (inversa) |
| `TXT` | Texto (SPF, verificaciones) |

### Cómo leer la salida de `dig`

- `status: NOERROR` → resolvió bien. `NXDOMAIN` → ese nombre no existe.
- `ANSWER SECTION` → la respuesta.
- `Query time` → cuánto tardó el DNS.
- `SERVER` → qué DNS respondió.

## whois: comandos básicos

| Comando | Qué hace |
|---------|----------|
| `whois cisco.com` | Datos del dominio |
| `whois 8.8.8.8` | Organización dueña de la IP |
| `whois cisco.com \| head -n 40` | Solo las primeras líneas |

## Práctica guiada

1. `dig cisco.com +short` → ¿qué IP devuelve?
2. `dig -x` con esa IP → ¿vuelve el mismo nombre?
3. `dig cisco.com MX +short` → ¿quién recibe su correo?
4. Compara `dig @8.8.8.8 cisco.com` con `dig @1.1.1.1 cisco.com`.
5. Mira qué DNS usa tu equipo: `cat /etc/resolv.conf`

## Errores comunes

| Problema | Qué hacer |
|----------|-----------|
| `command not found: dig` | `sudo apt install bind9-dnsutils` |
| `connection timed out` | El DNS no responde: prueba otro con `@8.8.8.8` |
| `NXDOMAIN` | Revisa cómo escribiste el nombre |

## Para pensar

- ¿Qué diferencia hay entre un registro `A` y un `CNAME`?
- Si cambias de DNS y todo vuelve a funcionar, ¿qué estaba fallando?
