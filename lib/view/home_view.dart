import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../controller/tarefa_controller.dart';



class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final TarefaController ctrl;

  static const Color _corPrincipal = Color(0xFF2196F3);

  @override
  void initState() {
    super.initState();

    ctrl = GetIt.I.get<TarefaController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ctrl.carregarUsuario();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),

          appBar: AppBar(
            backgroundColor: _corPrincipal,
            foregroundColor: Colors.white,
            elevation: 2,
            automaticallyImplyLeading: false,
            titleSpacing: 20,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tarefas',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  ctrl.nomeUsuario.isEmpty
                      ? 'Carregando usuário...'
                      : ctrl.nomeUsuario,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Sair',
                onPressed: ctrl.carregando
                    ? null
                    : () {
                        _confirmarSaida();
                      },
                icon: const Icon(
                  Icons.logout,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),

          body: Stack(
            children: [
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: ctrl.listarTarefas(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return _construirErroListagem(
                      snapshot.error,
                    );
                  }

                  final List<QueryDocumentSnapshot<Map<String, dynamic>>>
                  documentos = snapshot.data?.docs ?? [];

                  if (documentos.isEmpty) {
                    return _construirListaVazia();
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      await ctrl.carregarUsuario();
                    },
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        18,
                        16,
                        100,
                      ),
                      itemCount: documentos.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final documento = documentos[index];

                        return _construirTarefa(
                          documento,
                        );
                      },
                    ),
                  );
                },
              ),

              if (ctrl.carregando)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black12,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
            ],
          ),

          floatingActionButton: FloatingActionButton.extended(
            onPressed: ctrl.carregando
                ? null
                : () {
                    _abrirDialogAdicionar();
                  },
            backgroundColor: _corPrincipal,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Nova tarefa'),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // ITEM DA LISTA
  // ---------------------------------------------------------------------------

  Widget _construirTarefa(
    QueryDocumentSnapshot<Map<String, dynamic>> documento,
  ) {
    final Map<String, dynamic> dados = documento.data();

    final String titulo = dados['titulo']?.toString() ?? 'Sem título';

    final String descricao = dados['descricao']?.toString() ?? '';

    final bool concluida = dados['concluida'] == true;

    final Timestamp? criadoEm = dados['criadoEm'] is Timestamp
        ? dados['criadoEm'] as Timestamp
        : null;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1.5,
      color: concluida ? const Color(0xFFF1F8F2) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: concluida ? Colors.green.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          12,
          12,
          8,
          8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Tooltip(
                  message: concluida
                      ? 'Marcar como pendente'
                      : 'Marcar como concluída',
                  child: Checkbox(
                    value: concluida,
                    activeColor: Colors.green,
                    onChanged: ctrl.carregando
                        ? null
                        : (bool? valor) async {
                            await ctrl.alterarConclusaoTarefa(
                              tarefaId: documento.id,
                              concluida: valor ?? false,
                            );
                          },
                  ),
                ),

                const SizedBox(width: 4),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      titulo,
                      style: TextStyle(
                        color: concluida
                            ? Colors.grey.shade600
                            : const Color(0xFF212121),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        decoration: concluida
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                  ),
                ),

                PopupMenuButton<String>(
                  tooltip: 'Opções da tarefa',
                  onSelected: (opcao) {
                    switch (opcao) {
                      case 'editar':
                        _abrirDialogEditar(
                          tarefaId: documento.id,
                          titulo: titulo,
                          descricao: descricao,
                          concluida: concluida,
                        );
                        break;

                      case 'excluir':
                        _confirmarExclusao(
                          tarefaId: documento.id,
                          titulo: titulo,
                        );
                        break;
                    }
                  },
                  itemBuilder: (context) {
                    return const [
                      PopupMenuItem<String>(
                        value: 'editar',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined),
                            SizedBox(width: 12),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'excluir',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Excluir',
                              style: TextStyle(
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.only(
                left: 52,
                right: 12,
              ),
              child: Text(
                descricao.isEmpty ? 'Sem descrição.' : descricao,
                style: TextStyle(
                  color: concluida
                      ? Colors.grey.shade500
                      : Colors.grey.shade700,
                  fontSize: 15,
                  height: 1.4,
                  decoration: concluida
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
            ),

            const SizedBox(height: 14),

            Padding(
              padding: const EdgeInsets.only(
                left: 52,
                right: 4,
              ),
              child: Row(
                children: [
                  _construirStatus(concluida),

                  const Spacer(),

                  if (criadoEm != null)
                    Text(
                      _formatarData(
                        criadoEm.toDate(),
                      ),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),

                  IconButton(
                    tooltip: 'Editar tarefa',
                    onPressed: ctrl.carregando
                        ? null
                        : () {
                            _abrirDialogEditar(
                              tarefaId: documento.id,
                              titulo: titulo,
                              descricao: descricao,
                              concluida: concluida,
                            );
                          },
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: _corPrincipal,
                    ),
                  ),

                  IconButton(
                    tooltip: 'Excluir tarefa',
                    onPressed: ctrl.carregando
                        ? null
                        : () {
                            _confirmarExclusao(
                              tarefaId: documento.id,
                              titulo: titulo,
                            );
                          },
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirStatus(bool concluida) {
    final Color cor = concluida ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            concluida ? Icons.check_circle_outline : Icons.schedule_outlined,
            color: cor,
            size: 16,
          ),
          const SizedBox(width: 5),
          Text(
            concluida ? 'Concluída' : 'Pendente',
            style: TextStyle(
              color: cor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LISTA VAZIA
  // ---------------------------------------------------------------------------

  Widget _construirListaVazia() {
    return RefreshIndicator(
      onRefresh: () async {
        await ctrl.carregarUsuario();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        children: const [
          SizedBox(height: 100),
          Icon(
            Icons.task_alt_outlined,
            size: 90,
            color: Color(0xFFBDBDBD),
          ),
          SizedBox(height: 24),
          Text(
            'Nenhuma tarefa cadastrada',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF424242),
              fontSize: 21,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Clique em "Nova tarefa" para adicionar '
            'a primeira tarefa.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF757575),
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ERRO DE LISTAGEM
  // ---------------------------------------------------------------------------

  Widget _construirErroListagem(
    Object? erro,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 72,
              color: Colors.red,
            ),
            const SizedBox(height: 18),
            const Text(
              'Não foi possível carregar as tarefas.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              erro?.toString() ?? 'Verifique sua conexão e tente novamente.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ADICIONAR TAREFA
  // ---------------------------------------------------------------------------

  Future<void> _abrirDialogAdicionar() async {
    final TextEditingController tituloController = TextEditingController();

    final TextEditingController descricaoController = TextEditingController();

    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    ctrl.limparMensagemErro();

    final bool? salvar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool enviando = false;
        String? erro;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> adicionar() async {
              if (!(formKey.currentState?.validate() ?? false)) {
                return;
              }

              setDialogState(() {
                enviando = true;
                erro = null;
              });

              final bool sucesso = await ctrl.adicionarTarefa(
                titulo: tituloController.text,
                descricao: descricaoController.text,
              );

              if (!dialogContext.mounted) {
                return;
              }

              if (sucesso) {
                Navigator.pop(dialogContext, true);
                return;
              }

              setDialogState(() {
                enviando = false;
                erro = ctrl.mensagemErro;
              });
            }

            return AlertDialog(
              title: const Row(
                children: [
                  Icon(
                    Icons.add_task_outlined,
                    color: _corPrincipal,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('Nova tarefa'),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: tituloController,
                          enabled: !enviando,
                          autofocus: true,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.next,
                          maxLength: 100,
                          validator: ctrl.validarTitulo,
                          decoration: const InputDecoration(
                            labelText: 'Título',
                            hintText: 'Informe o título da tarefa',
                            prefixIcon: Icon(Icons.title),
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: descricaoController,
                          enabled: !enviando,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.newline,
                          maxLines: 4,
                          maxLength: 500,
                          validator: ctrl.validarDescricao,
                          decoration: const InputDecoration(
                            labelText: 'Descrição',
                            hintText: 'Descreva a tarefa',
                            alignLabelWithHint: true,
                            prefixIcon: Icon(Icons.description),
                            border: OutlineInputBorder(),
                          ),
                        ),

                        if (erro != null) ...[
                          const SizedBox(height: 8),
                          _construirMensagemErro(
                            erro!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: enviando
                      ? null
                      : () {
                          Navigator.pop(
                            dialogContext,
                            false,
                          );
                        },
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: enviando ? null : adicionar,
                  style: FilledButton.styleFrom(
                    backgroundColor: _corPrincipal,
                  ),
                  icon: enviando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    enviando ? 'Salvando...' : 'Salvar',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    tituloController.dispose();
    descricaoController.dispose();

    if (!mounted || salvar != true) {
      return;
    }

    _mostrarMensagem(
      'Tarefa adicionada com sucesso.',
      Colors.green,
    );
  }

  // ---------------------------------------------------------------------------
  // EDITAR TAREFA
  // ---------------------------------------------------------------------------

  Future<void> _abrirDialogEditar({
    required String tarefaId,
    required String titulo,
    required String descricao,
    required bool concluida,
  }) async {
    final TextEditingController tituloController = TextEditingController(
      text: titulo,
    );

    final TextEditingController descricaoController = TextEditingController(
      text: descricao,
    );

    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    bool tarefaConcluida = concluida;

    ctrl.limparMensagemErro();

    final bool? salvar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool enviando = false;
        String? erro;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> editar() async {
              if (!(formKey.currentState?.validate() ?? false)) {
                return;
              }

              setDialogState(() {
                enviando = true;
                erro = null;
              });

              final bool sucesso = await ctrl.editarTarefa(
                tarefaId: tarefaId,
                titulo: tituloController.text,
                descricao: descricaoController.text,
                concluida: tarefaConcluida,
              );

              if (!dialogContext.mounted) {
                return;
              }

              if (sucesso) {
                Navigator.pop(dialogContext, true);
                return;
              }

              setDialogState(() {
                enviando = false;
                erro = ctrl.mensagemErro;
              });
            }

            return AlertDialog(
              title: const Row(
                children: [
                  Icon(
                    Icons.edit_note_outlined,
                    color: _corPrincipal,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('Editar tarefa'),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: tituloController,
                          enabled: !enviando,
                          autofocus: true,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.next,
                          maxLength: 100,
                          validator: ctrl.validarTitulo,
                          decoration: const InputDecoration(
                            labelText: 'Título',
                            prefixIcon: Icon(Icons.title),
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: descricaoController,
                          enabled: !enviando,
                          textCapitalization: TextCapitalization.sentences,
                          maxLines: 4,
                          maxLength: 500,
                          validator: ctrl.validarDescricao,
                          decoration: const InputDecoration(
                            labelText: 'Descrição',
                            alignLabelWithHint: true,
                            prefixIcon: Icon(Icons.description),
                            border: OutlineInputBorder(),
                          ),
                        ),

                        CheckboxListTile(
                          value: tarefaConcluida,
                          enabled: !enviando,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: const Text('Tarefa concluída'),
                          subtitle: Text(
                            tarefaConcluida
                                ? 'A tarefa está concluída.'
                                : 'A tarefa está pendente.',
                          ),
                          onChanged: (valor) {
                            setDialogState(() {
                              tarefaConcluida = valor ?? false;
                            });
                          },
                        ),

                        if (erro != null) ...[
                          const SizedBox(height: 8),
                          _construirMensagemErro(
                            erro!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: enviando
                      ? null
                      : () {
                          Navigator.pop(
                            dialogContext,
                            false,
                          );
                        },
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: enviando ? null : editar,
                  style: FilledButton.styleFrom(
                    backgroundColor: _corPrincipal,
                  ),
                  icon: enviando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    enviando ? 'Salvando...' : 'Salvar alterações',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    tituloController.dispose();
    descricaoController.dispose();

    if (!mounted || salvar != true) {
      return;
    }

    _mostrarMensagem(
      'Tarefa atualizada com sucesso.',
      Colors.green,
    );
  }

  // ---------------------------------------------------------------------------
  // EXCLUIR TAREFA
  // ---------------------------------------------------------------------------

  Future<void> _confirmarExclusao({
    required String tarefaId,
    required String titulo,
  }) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.delete_outline,
            color: Colors.red,
            size: 48,
          ),
          title: const Text(
            'Excluir tarefa',
            textAlign: TextAlign.center,
          ),
          content: Text(
            'Deseja realmente excluir a tarefa '
            '"$titulo"?\n\n'
            'Esta operação não poderá ser desfeita.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmar != true || !mounted) {
      return;
    }

    final bool excluida = await ctrl.excluirTarefa(tarefaId);

    if (!mounted) {
      return;
    }

    if (excluida) {
      _mostrarMensagem(
        'Tarefa excluída com sucesso.',
        Colors.green,
      );
    } else {
      _mostrarMensagem(
        ctrl.mensagemErro ?? 'Não foi possível excluir a tarefa.',
        Colors.red,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // LOGOUT
  // ---------------------------------------------------------------------------

  Future<void> _confirmarSaida() async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.logout,
            color: _corPrincipal,
            size: 48,
          ),
          title: const Text(
            'Sair do aplicativo',
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'Deseja realmente encerrar sua sessão?',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _corPrincipal,
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );

    if (confirmar != true || !mounted) {
      return;
    }

    final bool saiu = await ctrl.sair();

    if (!mounted) {
      return;
    }

    if (saiu) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    } else {
      _mostrarMensagem(
        ctrl.mensagemErro ?? 'Não foi possível encerrar a sessão.',
        Colors.red,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // COMPONENTES AUXILIARES
  // ---------------------------------------------------------------------------

  Widget _construirMensagemErro(String mensagem) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.red.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensagem,
              style: TextStyle(
                color: Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarMensagem(
    String mensagem,
    Color cor,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensagem),
          backgroundColor: cor,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  String _formatarData(DateTime data) {
    final String dia = data.day.toString().padLeft(2, '0');

    final String mes = data.month.toString().padLeft(2, '0');

    final String hora = data.hour.toString().padLeft(2, '0');

    final String minuto = data.minute.toString().padLeft(2, '0');

    return '$dia/$mes/${data.year} às $hora:$minuto';
  }
}
