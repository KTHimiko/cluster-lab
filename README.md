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
| Controle de recursos | cgroup v2 (CPU e memória confinadas) |
| Autenticação de nós | MUNGE (chave compartilhada) |
| Armazenamento | NFS (`/home` exportado do head) |
| Containers | Apptainer 1.5.3 (sem setuid) |
| Orquestração de workflow | Nextflow 26.04 (executor SLURM) |

## Estado

| Etapa | Status |
|---|---|
| Rede libvirt e pool de armazenamento | **feito** |
| Imagem base Debian + disco copy-on-write | **feito** |
| VM base provisionada com cloud-init | **feito** |
| SLURM em nó único (`srun hostname`) | **feito** |
| Três nós provisionados (sem clonagem) | **feito** |
| MUNGE com chave compartilhada | **feito** |
| NFS entre head e nós | **feito** |
| `srun -N2 hostname` nos dois nós | **feito** |
| Apptainer nos três nós, container via `srun` | **feito** |
| Nextflow com executor SLURM + containers | **feito** |
| Confinamento de recursos por cgroup | **feito** |
| Pipeline nf-core executado no cluster | **feito** |

## Continuidade

Ao retomar em outra máquina ou depois de uma pausa, leia `CONTEXT.md` primeiro.

## Estrutura

```
config/   configuração versionada: cloud-init, slurm.conf, hosts, nextflow
scripts/  provisionamento e levantamento de ambiente
notas/    diário de bordo, com o que quebrou em cada etapa
```

## Por que este projeto existe

Vagas de infraestrutura em computação científica pedem uma combinação
específica: administração Linux, rede, armazenamento compartilhado e
agendador de filas. Este repositório é a demonstração prática dessa pilha,
montada e documentada de ponta a ponta.
