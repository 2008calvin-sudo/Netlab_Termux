# Checklist de diagnóstico desde el teléfono

Versión móvil de la [checklist completa](manuales/checklist-diagnostico.md). Mismo método: **de abajo hacia arriba, un paso a la vez, anotando cada resultado**. No se automatiza a propósito: así sabés qué falló y por qué.

## Paso 1 — Wi-Fi (capa física)

```bash
termux-wifi-connectioninfo
```

- [ ] Conectado a la red correcta (`ssid`)
- [ ] Señal (`rssi`): **-50 excelente · -60 buena · -70 aceptable · -80 mala**
- [ ] Banda: 2.4 GHz (más alcance, más congestión) o 5 GHz (más rápida, menos alcance)

```bash
termux-wifi-scaninfo
```

- [ ] ¿Muchas redes en el mismo canal que la tuya? Si sí, hay interferencia.

**[FALLA]** señal peor que -80 → acercate al AP o cambiá de banda antes de seguir.

## Paso 2 — Escalera de ping (capa 3)

- [ ] **Ping 1:** `ping -c 4 127.0.0.1` (la pila local funciona)
- [ ] **Ping 2:** `ping -c 4 TU_IP` (tu IP la ves en el banner o en el menú 6)
- [ ] **Ping 3:** `ping -c 4 TU_GATEWAY` (llegás al router)
- [ ] **Ping 4:** `ping -c 4 8.8.8.8` (llegás a Internet)
- [ ] **Ping 5:** `ping -c 4 google.com` (el DNS funciona)

El primer ping que falla marca dónde mirar. Si Ping 4 funciona y Ping 5 no → problema de DNS.

## Paso 3 — Ruta

```bash
traceroute -n 8.8.8.8
```

- [ ] ¿En qué salto se corta? Anotá la IP.

## Paso 4 — Puertos (capa 4)

```bash
nc -zv HOST 443
nmap --unprivileged -sT -Pn -p 22,80,443 HOST
```

- [ ] `succeeded`/`open` → el servicio escucha
- [ ] `refused` → el host responde pero el servicio está apagado
- [ ] Sin respuesta (timeout) → firewall o host caído

## Paso 5 — DNS

```bash
dig google.com
dig @8.8.8.8 google.com
```

- [ ] Con tu DNS falla pero con 8.8.8.8 funciona → falla el DNS de tu red.

## Paso 6 — Servicio (capa 7)

```bash
curl -I https://sitio.com
```

- [ ] Código 200/301/302 → el servicio responde
- [ ] 4xx/5xx → problema en el servidor o la aplicación

## Paso 7 — Rendimiento

```bash
iperf3 -c SERVIDOR
```

- [ ] Anotá velocidad de subida y bajada; comparala con lo contratado.

## Paso 8 — Reporte y escalamiento

Si no lo resolviste, usá la **plantilla de reporte** de la [checklist completa](manuales/checklist-diagnostico.md) y adjuntá los resultados anotados en cada paso.

## ¿Y lo que necesita root?

| Comando de la PC | En el teléfono |
|---|---|
| `ip addr`, `ss` | Menú 6 (puede estar limitado) |
| `arp-scan`, `netdiscover` | No disponible sin root → usá la PC |
| `tcpdump`, Wireshark | No disponible sin root → usá la PC o PCAPdroid |
| `ethtool` | No aplica (es Wi-Fi) → `termux-wifi-connectioninfo` |
| `nmap -sS/-sU/-O` | Solo `-sT` sin root |
