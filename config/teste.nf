#!/usr/bin/env nextflow

/*
 * Pipeline mínimo para verificar que o Nextflow está de fato distribuindo
 * trabalho pelo cluster, e não rodando tudo na máquina que submeteu.
 *
 * Cada tarefa reporta em qual nó executou e sob qual job do SLURM. Se os
 * nomes variarem e os IDs de job existirem, o executor está funcionando.
 *
 *   nextflow run teste.nf -profile slurm
 *   nextflow run teste.nf -profile container
 */

params.tarefas = 6

process ONDE_RODOU {
    tag "tarefa ${n}"

    // Só tem efeito quando um perfil habilita containers. Nos perfis `local`
    // e `slurm` esta linha é ignorada — o mesmo pipeline roda com e sem
    // container, sem alteração no código.
    container 'quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0'

    input:
    val n

    output:
    stdout

    script:
    """
    if command -v fastqc >/dev/null; then amb="container"; else amb="nó cru"; fi
    echo "tarefa ${n} | nó \$(hostname) | job SLURM \${SLURM_JOB_ID:-nenhum} | \$amb"
    """
}

process RESUMO {
    input:
    val linhas

    output:
    stdout

    script:
    """
    echo "--- tarefas ---"
    printf '%s\\n' '${linhas.join("\n")}'
    echo "--- distribuição por nó ---"
    printf '%s\\n' '${linhas.join("\n")}' | awk '{print \$5}' | sort | uniq -c | sort -rn
    """
}

workflow {
    // `as int` é obrigatório: parâmetro vindo da linha de comando chega como
    // texto, e um intervalo entre número e texto produz contagem errada
    // silenciosamente — o pipeline roda, só que com o número errado de tarefas.
    Channel.of(1..(params.tarefas as int))
        | ONDE_RODOU
        | map { it.trim() }
        | collect
        | RESUMO
        | view
}
