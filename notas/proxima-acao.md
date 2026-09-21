# Próxima ação

> Regra do ritmo semanal: ao **fim de todo bloco de trabalho**, apague a linha
> abaixo e escreva em uma frase qual é a próxima ação concreta.
> É isso que devolve o contexto no sábado seguinte em dois minutos em vez de
> quarenta.

**Agora:** sessão 6 — documentação final e diagrama de arquitetura no README.
O cluster já roda carga real (varreduras do clonal-lab). Acesso:
`ssh luan@192.168.122.10`.

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

### 2026-09-21 — sessão 2 completa, cluster de três nós no ar
- feito: node01 e node02 criados do zero (sem virt-clone), IPs fixos por
  reserva DHCP, /etc/hosts uniforme, MUNGE com chave compartilhada validado
  por autenticação cruzada, NFS do /home, SLURM multi-nó. `srun -N2`,
  `srun -N3` e job em lote de 6 tarefas nos três nós, todos verificados.
- quebrou: duas coisas. (1) O cloud-init escreve `127.0.1.1 <hostname>` no
  /etc/hosts, fazendo cada nó resolver o próprio nome para loopback — quebra
  o registro do slurmd com sintoma confuso. (2) Um comando meu falhou com
  exit 127 porque zsh não faz divisão em palavras de variável não-citada como
  o bash faz; `$SSH` virou um comando único inexistente.
- aprendi: (1) evitar virt-clone em cluster — machine-id duplicado faz o
  systemd-networkd pedir o mesmo IP para todos os clones. (2) O teste que
  vale no MUNGE é a validação cruzada (`munge -n` num nó, `unmunge` no
  outro), não comparar md5 da chave: md5 igual com relógio dessincronizado
  ainda falha. (3) Em zsh, use função ou `${=var}` para dividir argumentos.

### 2026-09-21 — sessão 3: containers no cluster
- feito: Apptainer 1.5.3 nos três nós (variante sem setuid), imagens no /home
  compartilhado, `srun -N3 apptainer exec` e sbatch de exemplo verificados
  com FastQC real do quay.io/biocontainers.
- quebrou: nada. O Apptainer não existe nos repositórios do Debian 12 — nem
  como `apptainer` nem como `singularity-container` — então veio do .deb
  oficial do upstream.
- aprendi: (1) o NFS paga dividendos além dos dados: baixei o .deb de 32 MB
  uma vez e instalei nos três a partir do mesmo arquivo, mesmo princípio de
  uma imagem servir o cluster inteiro. (2) `APPTAINER_CACHEDIR` deve ficar em
  disco local; só a imagem final vai para o NFS, porque travamento de arquivo
  sobre NFS é frágil. (3) A variante sem setuid funciona porque
  max_user_namespaces > 0 no guest — é a escolha certa, menos superfície de
  ataque que o binário privilegiado.

**Nota:** commits desta sessão ainda NÃO foram publicados no GitHub, a pedido.
Para publicar: `git push origin master`.

### 2026-09-21 — sessão 4: Nextflow sobre o cluster
- feito: Java 17 e Nextflow 26.04 no head; perfis local/slurm/container;
  pipeline de teste distribuindo 6 tarefas duas por nó, cada uma como job, e
  o mesmo pipeline rodando dentro de container sem alterar uma linha.
  Habilitado `jobcomp/filetxt` para ter histórico de jobs.
- quebrou: duas falhas silenciosas. (1) `--tarefas 6` chega como string, e
  `1..params.tarefas` conta errado sem erro — pedi 4 e rodaram 7, pedi 9 e
  rodaram 20. (2) O Apptainer limpa o ambiente, então `$SLURM_JOB_ID` e
  `$SLURM_CPUS_ON_NODE` somem dentro do container.
- aprendi: (1) usar `as int` em parâmetro de linha de comando. (2)
  `apptainer.envWhitelist` devolve as variáveis do SLURM ao container — e a
  perda de `CPUS_ON_NODE` é a pior, porque ferramentas dimensionam
  paralelismo por ela e passam a assumir a máquina inteira, competindo com
  outros jobs sem nada falhar. (3) `bash .command.run` no diretório da tarefa
  reproduz uma falha exatamente.

**Nota:** commits das sessões 3 e 4 e o material de estudo ainda NÃO foram
publicados, a pedido. Para publicar: `git push origin master`.

### 2026-09-21 — reescrita de histórico não apaga do servidor
- feito: repositório apagado e recriado do zero. Verificado: 25 commits,
  todos com autoria única, contribuidor único, e os SHAs antigos retornando
  "No commit found" na API e 404 na web.
- quebrou: a reescrita com `filter-branch` mais force-push limpou o histórico
  alcançável, e a API de contribuidores já listava só o dono — mas os commits
  antigos continuavam **acessíveis por SHA direto** (HTTP 200), carregando o
  rodapé removido.
- aprendi: reescrever histórico torna objetos inalcançáveis por referência,
  não os apaga do servidor. O GitHub mantém commits órfãos acessíveis por
  tempo indeterminado. A única garantia é recriar o repositório. Se algum dia
  vazar segredo num commit, force-push NÃO resolve: rotacione o segredo e
  recrie o repositório.

### 2026-09-21 — sessão 5: pipeline nf-core de ponta a ponta
- feito: `nf-core/demo` 1.2.0 executado com sucesso no cluster. Oito processos
  viraram jobs independentes distribuídos pelos três nós; 76 arquivos de
  saída, 29 MB, relatório MultiQC de 2,4 MB. O cache de containers da sessão 3
  foi reaproveitado.
- quebrou: nada nesta execução, mas a configuração existe justamente para
  evitar o modo de falha mais cruel do conjunto — pipeline nf-core declara
  requisitos para cluster grande (um processo pode pedir 36 GB), e sem
  `resourceLimits` o SLURM aceita o job e ele fica PENDING para sempre,
  esperando um nó que não existe. Nada falha, nada avisa.
- aprendi: (1) `resourceLimits` é o mecanismo atual; `--max_memory` faz
  pipelines recentes falharem na validação de esquema, e tutoriais antigos
  ainda ensinam a forma velha. (2) `-r <versão>` não é formalidade: sem fixar,
  o mesmo comando roda código diferente em datas diferentes. (3) Nunca adaptei
  o pipeline — descrevi o cluster em vinte linhas e o resto funcionou.

### 2026-09-21 — cgroups: os limites viraram restrições
- feito: cgroup v2 configurado nos três nós. `ProctrackType=proctrack/cgroup`,
  `TaskPlugin=task/cgroup,task/affinity`, `JobAcctGatherType=jobacct_gather/cgroup`,
  e `SelectTypeParameters` de `CR_Core` para `CR_Core_Memory`.
- quebrou: nada na configuração, mas o teste de antes e depois é o achado.
  O mesmo job que pedia 128 MB e alocava 900 MB terminava como `COMPLETED`;
  agora morre com `JobState=OUT_OF_MEMORY` e o slurmd registra
  `task/cgroup: hit memory limit`. CPU também: um job de 1 núcleo passa a ver
  `nproc = 1` em vez dos 2 da máquina.
- aprendi: (1) `CR_Core` sozinho faz o escalonador **ignorar** o `--mem` dos
  jobs — sem `CR_Core_Memory` a memória nem é recurso consumível. (2) Debian 12
  já vem com hierarquia unificada e `Delegate=yes` no slurmd, então não foi
  preciso mexer em systemd nem em parâmetro de boot. (3) `task/affinity` junto
  com `task/cgroup` é o que faz `nproc` respeitar a alocação, que era o
  problema real por trás da perda de `SLURM_CPUS_ON_NODE` dentro de container.
