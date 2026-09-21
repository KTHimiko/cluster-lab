# Contexto do projeto

Documento de continuidade. Leia isto primeiro ao retomar o trabalho — em outra
máquina, depois de uma pausa longa, ou numa sessão nova de assistente.

## O que é isto

Um cluster HPC de laboratório. Mas o cluster não é o objetivo final: é a peça
central de um plano maior de mudança de carreira.

**Repositório:** <https://github.com/KTHimiko/cluster-lab> (público)

**Roteiro completo:** <https://claude.ai/artifact/HepfDfE6WMB2kZPeUvFzgc>
(privado, abre na conta do Luan; o progresso fica salvo e sincroniza entre
dispositivos)

## As decisões já tomadas

Não reabra estas sem motivo novo — foram discutidas e fechadas.

**Objetivo de longo prazo.** Construir capacidade em biologia computacional
até ser dono de um ativo defensável, e eventualmente fundar uma empresa em
volta dele. Sem capital inicial.

**Nicho fixado.** Modelagem baseada em agentes da competição clonal em tecidos
envelhecidos, calibrada contra dados públicos de hematopoiese clonal (CHIP).
Escolhido por ser pequeno o bastante para virar referência em 18 meses, por ter
porta de doença limpa (risco cardiovascular), e por aproveitar direto o projeto
Linhagens — simulação de micélio baseada em agentes, que é matematicamente o
mesmo problema de competição por recurso compartilhado.

**Estratégia de entrada.** Entrar no campo pela **infraestrutura**, não pela
análise. Núcleos de bioinformática e centros de HPC contratam por Linux, rede,
armazenamento e agendador de filas — não por biologia. É a única porta que
aceita a formação atual (redes de computadores) sem requalificação prévia, e
coloca o trabalho dentro do laboratório.

**Por isso este repositório existe.** Ele é simultaneamente a peça central do
currículo de infraestrutura e os entregáveis `f1-1`, `f1-2` e `f1-8` do
roteiro. Um projeto, dois objetivos.

## Restrições reais

- **Tempo:** blocos longos nos fins de semana. Durante a semana, só leitura
  curta. O ritmo está descrito no roteiro; a regra central é escrever a próxima
  ação ao fim de cada bloco (ver `notas/proxima-acao.md`).
- **Dinheiro:** orçamento zero. Nada neste plano depende de compra, assinatura
  ou dado de acesso controlado. Coortes que cobram taxa (UK Biobank, dbGaP)
  estão fora por enquanto.
- **Emprego atual:** fora da área de formação. Trocá-lo por uma vaga de
  infra/redes é a maior alavanca de retorno do plano, e é a Fase 0 do roteiro.

## Aviso de portabilidade

Os comandos estão calibrados para a **máquina principal** (`192.168.0.10`):

```
Arch Linux · kernel 7.2.4 · Ryzen 7 5800X, 16 threads · 46 GB RAM
94 GB livres em / · /dev/kvm presente · nenhum outro hipervisor
libvirt 12.7, qemu 11.1, virt-install e dnsmasq instalados
usuário no grupo libvirt · libvirtd ainda não habilitado
```

O VirtualBox 7.2 e sua VM `windows` foram removidos em 2026-09-21, liberando
40 GB. Era o único concorrente pelo `/dev/kvm` e a razão de o disco ser
gargalo — não é mais.

Dimensionamento escolhido: **3 nós de 4 GB e disco de 20 GB**. Sobra memória
(caberiam 20 nós) e sobra disco.

**Em outra máquina, refaça o levantamento antes de seguir os comandos:**

```bash
./scripts/recon.sh | tee notas/recon-$(hostname).txt
```

A arquitetura e as metas mínimas continuam válidas em qualquer lugar; os
comandos e o dimensionamento, não necessariamente.

## Estado atual

Cluster de três nós operacional.

Sessão 1 (sábado) — etapas 0 a 5:

- rede `default` do libvirt ativa com autostart, NAT e DHCP funcionando
- pool de armazenamento `default` ativo
- imagem base do Debian 12 e disco copy-on-write do `head`
- nó `head` no ar e acessível por SSH, provisionado por cloud-init:
  hostname correto, usuário `luan` com sudo sem senha, chrony ativo e
  relógio sincronizado
- SLURM 22.05.8 e MUNGE 0.5.15 no `head`: `srun`, `srun -n2` e `sbatch`
  verificados, nó em estado `idle`

Sessão 2 (domingo) também concluída:

- três nós com IPs fixos por reserva DHCP: `head` .10, `node01` .11,
  `node02` .12 — criados do zero, sem `virt-clone`
- `/etc/hosts` idêntico nos três, sem a linha `127.0.1.1` que o cloud-init
  escreve e que quebra o registro do `slurmd`
- MUNGE com a mesma chave nos três, validado por autenticação cruzada
- NFS: `/home` do head montado nos dois nós
- SLURM multi-nó: `srun -N2` e `srun -N3` verificados, além de um job em
  lote de 6 tarefas distribuídas pelos três nós

Sessão 3 (Apptainer) também concluída:

- Apptainer 1.5.3 nos três nós, variante **sem setuid** (o kernel do guest
  tem namespaces de usuário sem privilégio habilitados)
- imagens no `/home` compartilhado: `alpine.sif` e `fastqc.sif`, este último
  do `quay.io/biocontainers`, o registro que os módulos nf-core usam
- `srun -N3 apptainer exec` e um sbatch de exemplo verificados: FastQC
  v0.12.1 respondendo nos três nós a partir de uma única imagem

Sessão 4 (Nextflow) também concluída:

- Java 17 e Nextflow 26.04 no `head` — só ele precisa, os nós executam
  scripts shell gerados pelo pipeline
- três perfis em `config/nextflow.config`: `local`, `slurm` e `container`
- `workDir` em `/home/luan/nf-work`, sobre o NFS
- pipeline de teste verificado nos dois modos: 6 tarefas distribuídas duas
  por nó, cada uma como job do SLURM, e depois as mesmas dentro de container
- registro de jobs concluídos habilitado (`jobcomp/filetxt`), já que o
  `sacct` completo exigiria `slurmdbd` com banco

Sessão 5 (nf-core) também concluída:

- `nf-core/demo` 1.2.0 executado de ponta a ponta com `-profile test,apptainer`
  e configuração própria do cluster (`config/nfcore-cluster.config`)
- 8 processos distribuídos pelos três nós como jobs independentes: SEQTK_TRIM
  e FASTQC em paralelo por amostra, COWPY e MULTIQC agregando
- 76 arquivos de saída, 29 MB, com relatório MultiQC de 2,4 MB
- a peça que faz funcionar é `resourceLimits`: sem truncar os pedidos do
  pipeline ao tamanho real dos nós, os jobs ficariam pendentes para sempre

**Próxima:** sessão 6 — documentação final e diagrama, para o repositório ficar
apresentável a quem chega sem contexto.

Próxima ação concreta: ver `notas/proxima-acao.md`.
