# Próxima ação

> Regra do ritmo semanal: ao **fim de todo bloco de trabalho**, apague a linha
> abaixo e escreva em uma frase qual é a próxima ação concreta.
> É isso que devolve o contexto no sábado seguinte em dois minutos em vez de
> quarenta.

**Agora:** habilitar o libvirtd (`sudo systemctl enable --now libvirtd`), abrir uma
sessão nova para o grupo `libvirt` valer, e seguir para a Etapa 1 — definir a
rede do libvirt.
`docs/01-sessao-sabado.md`), relogar para o grupo `libvirt` valer, e conferir
com `./scripts/recon.sh`.

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
