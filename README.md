# cluster-lab

Cluster HPC de três nós construído do zero em KVM/libvirt, com agendador de
filas, autenticação distribuída, armazenamento compartilhado por rede e
execução de pipelines científicos em container.

Projeto de laboratório: o objetivo é reproduzir, em escala reduzida e com
hardware doméstico, a arquitetura que núcleos de bioinformática e centros de
computação de alto desempenho operam em produção.

## Arquitetura

```
                       rede libvirt  192.168.122.0/24
                                 |
        +------------------------+------------------------+
        |                        |                        |
   +---------+              +---------+              +---------+
   |  head   |              | node01  |              | node02  |
   |         |              |         |              |         |
   | slurmctld              | slurmd  |              | slurmd  |
   | slurmd  |              |         |              |         |
   | munged  |              | munged  |              | munged  |
   | NFS srv |              | NFS cli |              | NFS cli |
   +---------+              +---------+              +---------+
        |                        |                        |
        +------- /home exportado por NFS ------------------+

   2 vCPU / 2 GB / 20 GB por nó
```

## Pilha

| Camada | Tecnologia |
|---|---|
| Virtualização | KVM / QEMU / libvirt |
| Provisionamento | cloud-init, imagem cloud Debian |
| Agendador | SLURM (`slurmctld`, `slurmd`) |
| Autenticação de nós | MUNGE (chave compartilhada) |
| Armazenamento | NFS (`/home` exportado do head) |
| Containers | Apptainer |
| Orquestração de workflow | Nextflow + nf-core |

## Estado

| Etapa | Status |
|---|---|
| Rede libvirt e pool de armazenamento | **feito** |
| Imagem base Debian + disco copy-on-write | **feito** |
| VM base provisionada com cloud-init | em andamento |
| SLURM em nó único (`srun hostname`) | pendente |
| Clonagem para 3 nós | pendente |
| MUNGE com chave compartilhada | pendente |
| NFS entre head e nós | pendente |
| `srun -N2 hostname` nos dois nós | pendente |
| Apptainer instalado | pendente |
| Pipeline nf-core executado no cluster | pendente |

## Continuidade

Ao retomar em outra máquina ou depois de uma pausa, leia `CONTEXT.md` primeiro.

## Estrutura

```
docs/     guias de execução, uma sessão por arquivo
config/   arquivos de configuração versionados (slurm.conf, exports, XML)
notas/    diário de bordo e a próxima ação
```

## Por que este projeto existe

Vagas de infraestrutura em computação científica pedem uma combinação
específica: administração Linux, rede, armazenamento compartilhado e
agendador de filas. Este repositório é a demonstração prática dessa pilha,
montada e documentada de ponta a ponta.
