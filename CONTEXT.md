# Contexto do projeto

Documento de continuidade. Leia isto primeiro ao retomar o trabalho — em outra
máquina, depois de uma pausa longa, ou numa sessão nova de assistente.

## O que é isto

Um cluster HPC de laboratório. Mas o cluster não é o objetivo final: é a peça
central de um plano maior de mudança de carreira.

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
53 GB livres em / (disco a 79% — a restrição desta máquina)
/dev/kvm presente · VirtualBox 7.2 instalado e convivendo
estado inicial: nenhuma ferramenta de virtualização instalada
```

Dimensionamento escolhido: **3 nós de 4 GB e disco de 10 GB**. A memória sobra
(caberiam 20 nós); o disco é o limite.

**Em outra máquina, refaça o levantamento antes de seguir os comandos:**

```bash
./scripts/recon.sh | tee notas/recon-$(hostname).txt
```

A arquitetura e as metas mínimas continuam válidas em qualquer lugar; os
comandos e o dimensionamento, não necessariamente.

## Estado atual

Nada foi executado ainda. Nenhuma VM criada, nenhum serviço configurado. O
repositório contém apenas documentação de execução e configuração de partida.

Próxima ação concreta: ver `notas/proxima-acao.md`.
