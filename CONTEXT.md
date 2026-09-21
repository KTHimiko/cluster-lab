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

Os comandos em `docs/01-sessao-sabado.md` foram escritos para uma máquina
específica:

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

Sessão 1 (sábado) em andamento, etapas 0 a 4 concluídas:

- rede `default` do libvirt ativa com autostart, NAT e DHCP funcionando
- pool de armazenamento `default` ativo
- imagem base do Debian 12 e disco copy-on-write do `head`
- nó `head` no ar e acessível por SSH, provisionado por cloud-init:
  hostname correto, usuário `luan` com sudo sem senha, chrony ativo e
  relógio sincronizado

- SLURM 22.05.8 e MUNGE 0.5.15 no `head`: `srun`, `srun -n2` e `sbatch`
  verificados, nó em estado `idle`

**A sessão 1 (sábado) está completa** — a meta mínima era `srun hostname`
responder, e responde. A próxima é a sessão 2 (domingo): clonar para três
nós, distribuir a chave do MUNGE, montar o NFS e fechar com `srun -N2`.

Próxima ação concreta: ver `notas/proxima-acao.md`.
