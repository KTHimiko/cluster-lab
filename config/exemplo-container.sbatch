#!/bin/bash
# Exemplo mínimo do padrão que sustenta bioinformática em HPC:
# uma imagem de container no armazenamento compartilhado, executada por
# vários nós ao mesmo tempo, orquestrada pelo escalonador.
#
# Submeta a partir do head:
#   sbatch config/exemplo-container.sbatch
#
#SBATCH --job-name=container
#SBATCH --output=/home/luan/container-%j.out
#SBATCH --nodes=3
#SBATCH --ntasks-per-node=1
#SBATCH --time=00:05:00

IMAGEM=/home/luan/containers/fastqc.sif

# O caminho da imagem é o MESMO em todos os nós porque /home vem por NFS.
# Sem armazenamento compartilhado, cada nó precisaria de uma cópia local e
# você teria que garantir que são idênticas — que é o problema que o NFS
# resolve de uma vez.
if [ ! -f "$IMAGEM" ]; then
  echo "imagem ausente: $IMAGEM" >&2
  echo "puxe antes com: apptainer pull $IMAGEM docker://quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0" >&2
  exit 1
fi

srun apptainer exec "$IMAGEM" bash -c '
  echo "nó $(hostname) | tarefa $SLURM_PROCID | $(fastqc --version)"
'
