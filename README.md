# Instituto Acesso — site institucional

Pacote estático recebido em `public_html5_atualizado.zip`, preparado para Nginx em Docker. O código-fonte React original não veio no ZIP: `site/` contém a versão compilada.

## O que foi preparado

- Container independente, sem banco e sem credenciais.
- Porta padrão apenas na própria VPS: `127.0.0.1:18085`.
- Verificação de saúde em `/healthz` e reinício automático.
- Scripts de depuração e analytics do Manus removidos do HTML.
- Formulário ajustado para abrir o aplicativo de e-mail do visitante; o visitante conclui o envio. Não há envio automático nem serviço de e-mail no servidor.
- Imagens ainda são carregadas do CloudFront e fontes do Google Fonts, conforme o pacote original. Não foi possível baixar as imagens nesta sessão devido à restrição de rede. As URLs precisam continuar disponíveis.

## 1. Conferir a VPS, sem alterar nada

```bash
cat /etc/os-release
docker --version
docker compose version
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Ports}}'
ss -lntp
command -v nginx apache2 httpd caddy
```

Se Docker/Compose não estiverem instalados, identificar a distribuição antes de instalar. Não substituir Docker, proxy ou redes existentes.

## 2. Acesso ao repositório

Repositório: https://github.com/eiderlinknett-jr12/instituto-acesso-site. Criado pelo proprietário como público. Este pacote não contém senhas, tokens ou chaves.

Por ser público, o clone por HTTPS não exige autenticação. Se o repositório passar a ser privado, use o acesso GitHub já configurado na VPS. Se não existir, uma deploy key somente de leitura pode ser criada na VPS e sua chave pública cadastrada em Settings → Deploy keys do repositório. Não copie chaves privadas nem tokens para este projeto. Não use a senha comum da conta GitHub para clonar por HTTPS.

## 3. Clonar e iniciar

Pré-requisitos: Git, Docker e plugin Compose disponíveis; acesso de rede ao GitHub; porta 18085 livre.

```bash
mkdir -p /opt/instituto-acesso
cd /opt/instituto-acesso
git clone https://github.com/eiderlinknett-jr12/instituto-acesso-site.git site
cd site
docker compose config --quiet
docker compose build --pull
docker compose up -d
docker compose ps
curl -fsS http://127.0.0.1:18085/healthz
curl -fsS http://127.0.0.1:18085/ | head -c 300
```

Os comandos não publicam o site nas portas 80/443. O proxy existente encaminhará o domínio para ele. Se 18085 estiver ocupada, escolher outra porta livre, gravar `SITE_PORT=PORTA_LIVRE` em `.env` antes de iniciar e usar a mesma porta no proxy.

Não reutilizar uma pasta `site` já existente sem verificar seu conteúdo.

## 4. Conectar o domínio ao proxy existente

Esta etapa depende do resultado da inspeção da VPS. Não iniciar um segundo proxy nas portas 80/443.

- Nginx instalado na VPS: há um exemplo de virtual host em `deploy/nginx-host.conf.example`, apontando para `http://127.0.0.1:18085`. Adicionar somente o novo domínio em um arquivo próprio, testar com `nginx -t` e só então recarregar. Configurar certificado válido para os dois nomes antes de ativar HTTPS.
- Nginx Proxy Manager, Traefik ou Caddy em Docker: conectar o novo container à rede do proxy existente e encaminhar para o serviço na porta 8080. O endereço `127.0.0.1` dentro do container do proxy não é o endereço da VPS. A configuração da rede deve ser definida após identificar o proxy.
- Se não houver proxy: escolher e configurar um, depois de conferir que 80/443 estão livres. Este pacote não instala um automaticamente.

## 5. DNS e HTTPS

1. Adicionar `institutoacesso.org.br` ao Cloudflare, se ainda não estiver lá.
2. Se necessário, alterar no registrador os nameservers para os dois valores exatos fornecidos pelo Cloudflare. Conferir também DNSSEC se já estiver ativo no provedor anterior.
3. Preservar registros de e-mail (MX, SPF, DKIM, DMARC) e de outros serviços.
4. Quando o proxy e o certificado estiverem prontos, configurar:

| Tipo | Nome | Conteúdo | Proxy |
| --- | --- | --- | --- |
| A | @ | 2.24.107.181 | Ativado |
| CNAME | www | institutoacesso.org.br | Ativado |

O IP acima foi informado pelo usuário e ainda não foi validado por conexão SSH. Conferir que é o IP público correto antes de mudar DNS. Registros A/AAAA conflitantes para esses mesmos nomes precisam ser revisados; não manter um AAAA apontando para um servidor que não hospede o site.

5. SSL/TLS → Full (strict), depois de o servidor responder em 443 com certificado válido para `institutoacesso.org.br` e `www.institutoacesso.org.br` (certificado público ou Cloudflare Origin CA).
6. Ativar Always Use HTTPS depois de testar HTTPS e ausência de ciclos de redirecionamento.

DNS não faz encaminhamento para a porta 18085: o proxy da VPS precisa atender o domínio nas portas padrão.

## Atualizações e reversão

```bash
cd /opt/instituto-acesso/site
git status --short
git rev-parse HEAD
git pull --ff-only
docker compose build --pull
docker compose up -d
docker compose ps
curl -fsS http://127.0.0.1:18085/healthz
```

Anote o commit anterior antes de atualizar. Para reverter, selecione esse commit com `git switch --detach COMMIT_ANTERIOR`, reconstrua e execute `docker compose up -d`. Não use limpeza global de Docker ou remoção de volumes.

## Validação feita nesta sessão

Arquivos do ZIP inspecionados sem executar o sistema original. JavaScript ajustado conferido sintaticamente; referências locais verificadas. Docker não está disponível no computador desta sessão, portanto o container ainda precisa ser validado na VPS. Nenhuma configuração da VPS ou do DNS foi alterada.

## Referências

- https://docs.docker.com/engine/network/port-publishing/
- https://developers.cloudflare.com/dns/zone-setups/full-setup/setup/
- https://developers.cloudflare.com/ssl/origin-configuration/ssl-modes/full-strict/
- https://docs.github.com/en/authentication/connecting-to-github-with-ssh/managing-deploy-keys
