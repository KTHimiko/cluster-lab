# Próxima ação

> Regra do ritmo semanal: ao **fim de todo bloco de trabalho**, apague a linha
> abaixo e escreva em uma frase qual é a próxima ação concreta.
> É isso que devolve o contexto no sábado seguinte em dois minutos em vez de
> quarenta.

**Agora:** sessão 2 (domingo) — `docs/02-sessao-domingo.md`. Clonar o head em
node01 e node02, MUNGE com chave compartilhada, NFS, e fechar com `srun -N2`.

---

## Diário de bordo

Uma entrada por sessão. Data, o que foi feito, o que quebrou, o que aprendeu.
O que quebrou é a parte mais valiosa — é o que vira resposta em entrevista.

### 2026-09-21 — sessão 0 (preparação)
- feito: repositório transferido da máquina secundária; levantamento do
  ambiente rodado; guia calibrado para 3 nós de 4 GB e disco de 10 GB.
- quebrou: `printf` do recon.sh falhava com formato iniciado por `--`; o bug
  só aparecia quando alguma ferramenta estava ausente, por isso passou
  despercebido na outra máquina.
- aprendi: `printf '--  ...'` é interpretado como fim de opções; usar

### 2026-09-21 — remoção do VirtualBox
- feito: VM `windows` (29 GB) e pacotes virtualbox removidos; módulos
  descarregados; grupo vboxusers eliminado. Disco: 53 GB -> 94 GB livres.
- quebrou: `modprobe -r` não descarrega módulo cujo arquivo já foi apagado
  pelo pacman; foi preciso `rmmod` na ordem de dependência.
- aprendi: remover o pacote não descarrega o módulo em memória — os dois
  passos são independentes.
  argumento posicional resolve.

### 2026-09-21 — pós-remoção
- feito: libvirtd habilitado e ativo; recon.sh corrigido para ler grupos da
  base de dados em vez das credenciais do processo.
- quebrou: `id -nG` sem argumento falha inteiro se um GID da sessão ficou
  órfão — e isso derrubava a verificação do grupo libvirt, gerando falso
  negativo.
- aprendi: `id -nG <usuário>` consulta a base; `id -nG` sozinho consulta o
  processo. Remover um grupo com sessão aberta deixa o GID órfão até relogar.

### 2026-09-21 — a armadilha dos dois escopos
- feito: descoberto que `virsh` de usuário comum conecta em `qemu:///session`,
  não em `qemu:///system`. A rede `default` já existia no escopo do sistema,
  inativa — o `net-list` vazio era ilusão de escopo, não ausência de rede.
- aprendi: `qemu:///session` e `qemu:///system` são espaços completamente
  separados. Fixar `LIBVIRT_DEFAULT_URI=qemu:///system` no shell evita horas
  de confusão. O guia e o recon.sh foram corrigidos.

### 2026-09-21 — etapa 1 concluída
- feito: rede `default` ativa e com autostart em `qemu:///system`; dnsmasq
  servindo DHCP em 192.168.122.2-254; 7 regras de NAT no nftables.
- quebrou: nada — mas `ip -br addr` mostra `virbr0 DOWN` e isso parece falha.
- aprendi: bridge Linux sem porta anexada fica em `NO-CARRIER`; a interface
  está administrativamente UP e o `ip -br` reporta o operstate. Sobe sozinha
  quando a primeira VM criar o vnet0.

### 2026-09-21 — chave SSH e template de cloud-init
- feito: par de chaves ed25519 gerado nesta máquina; criado
  `scripts/render-cloud-init.sh`, que injeta a chave e o hostname no template
  e escreve em `build/` (não versionado).
- quebrou: eu tinha assumido que a chave existia aqui, mas ela estava só na
  máquina secundária — o `sed` de injeção teria falhado silenciosamente.
- aprendi: material específico da máquina (chave, hostname) não entra no
  repositório. Versiona-se o template e gera-se o resto; assim o repositório
  fica publicável sem decisão sobre o que expor.

### 2026-09-21 — o seed que o cloud-init não achava
- feito: primeira VM criada com `virt-install --cloud-init` subiu sem o
  usuário e sem a chave. Diagnóstico por inspeção offline do disco (qemu-nbd
  + mount ro,noload) mostrou `user-data.txt` vazio e datasource
  `NoCloud [seed=dmi]`. O log do guest tinha a prova: `blkid -tLABEL=cidata`
  não encontrava nada.
- quebrou: `virt-install --cloud-init` (5.1) anexa o ISO sem o rótulo de
  volume `cidata` que o cloud-init procura — e apaga o arquivo do host logo
  após iniciar, impedindo inspeção.
- aprendi: o NoCloud localiza o seed pelo RÓTULO do volume, não pelo caminho
  nem pela ordem do dispositivo. Criado `scripts/make-seed.sh`, que monta o
  ISO com xorrisofs, rótulo `cidata`, e valida com blkid antes de terminar.
  Falha silenciosa é pior que falha barulhenta: a VM subia "perfeita".

### 2026-09-21 — genericcloud é virtio-only
- feito: `head` no ar e acessível. hostname `head`, usuário `luan` com sudo
  sem senha, cloud-init `done`, chrony ativo e relógio sincronizado.
- quebrou: o seed anexado como `device=cdrom` vai no barramento SATA, e a
  imagem `genericcloud` do Debian não tem driver ATA/AHCI — o dispositivo não
  existe dentro da VM. Sem datasource, o `ds-identify` desabilita o cloud-init
  por completo: sem rede, sem hostname, `ssh.service` falhando por não ter
  chaves de host.
- aprendi: três coisas. (1) Seed de cloud-init em imagem cloud vai em virtio,
  nunca em cdrom. (2) `--serial file` é obrigatório: quando a VM sobe sem
  rede, o log de console é a única janela para dentro. (3) Ausência total de
  menções a um serviço no log é sinal mais forte que erro — erro significa que
  tentou; silêncio significa que nem foi chamado.

### 2026-09-21 — sessão 1 completa
- feito: SLURM 22.05.8 e MUNGE 0.5.15 instalados no `head`. Partição `debug`
  no ar, nó em `idle`, `srun hostname`, `srun -n2` e `sbatch` verificados.
- quebrou: nada no SLURM. A topologia foi explicitada no `slurm.conf`
  (Sockets=2 CoresPerSocket=1 ThreadsPerCore=1) para evitar o nó cair em
  `drain` por divergência entre o detectado e o configurado.
- aprendi: `RealMemory` no slurm.conf precisa ficar abaixo da memória real
  (3800 para 3927 MB) — se passar, o nó é marcado como inválido.
