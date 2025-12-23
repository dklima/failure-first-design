# Failure-First Design Scripts

Scripts e templates do artigo "Pare de Desenhar Arquitetura. Comece a Desenhar Falhas."

## Conteúdo

### Ruby

- **retry_with_backoff.rb** - Retry com exponential backoff e jitter para evitar retry storms
- **http_with_timeout.rb** - Requisições HTTP com timeouts configurados corretamente
- **health_controller.rb** - Controller Rails com health checks liveness/readiness

### Chaos Engineering (Bash)

- **chaos_network.sh** - Simulação de problemas de rede com tc (traffic control)
- **chaos_cpu.sh** - Simulação de CPU sob pressão com stress-ng
- **chaos_disk.sh** - Simulação de disco cheio
- **toxiproxy_postgres.sh** - Simulação de latência no banco com Toxiproxy

### Templates

- **postmortem_template.md** - Template para documentar incidentes

## Requisitos

### Para scripts de chaos engineering:

```bash
# Ubuntu/Debian
sudo apt install iproute2 stress-ng
wget https://github.com/Shopify/toxiproxy/releases/download/v2.9.0/toxiproxy_2.9.0_linux_amd64.deb
sudo dpkg -i toxiproxy_2.9.0_linux_amd64.deb

# Fedora
sudo dnf install iproute stress-ng toxiproxy
```

## Uso

```bash
# Tornar scripts executáveis
chmod +x *.sh

# Simular latência de rede
./chaos_network.sh eth0 latency

# Simular CPU sob pressão
./chaos_cpu.sh full 4 60

# Configurar Toxiproxy para PostgreSQL
./toxiproxy_postgres.sh setup
./toxiproxy_postgres.sh latency-variable 2000 1000
```

## Aviso

Esses scripts são para **ambientes de staging/teste**. Use com cuidado e sempre tenha um plano de rollback antes de executar qualquer experimento de chaos engineering.

## Idioma

Os comentários nos scripts estão em inglês para que sejam úteis para mais pessoas.

## Licença

MIT
