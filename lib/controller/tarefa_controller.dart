import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TarefaController extends ChangeNotifier {
  TarefaController({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  bool _carregando = false;
  String _nomeUsuario = '';
  String? _mensagemErro;

  bool get carregando => _carregando;

  String get nomeUsuario => _nomeUsuario;

  String? get mensagemErro => _mensagemErro;

  User? get usuarioAtual => _firebaseAuth.currentUser;

  String? get usuarioId => _firebaseAuth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>
      get _tarefasCollection {
    return _firestore.collection('tarefas');
  }

  CollectionReference<Map<String, dynamic>>
      get _usuariosCollection {
    return _firestore.collection('usuarios');
  }

  // ---------------------------------------------------------------------------
  // CARREGAR USUÁRIO
  // ---------------------------------------------------------------------------

  Future<void> carregarUsuario() async {
    final User? usuario = _firebaseAuth.currentUser;

    if (usuario == null) {
      _nomeUsuario = '';
      notifyListeners();
      return;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>>
          documentoUsuario =
          await _usuariosCollection.doc(usuario.uid).get();

      final Map<String, dynamic>? dados =
          documentoUsuario.data();

      final String nomeFirestore =
          dados?['nomeCompleto']?.toString().trim() ?? '';

      if (nomeFirestore.isNotEmpty) {
        _nomeUsuario = nomeFirestore;
      } else if ((usuario.displayName ?? '').trim().isNotEmpty) {
        _nomeUsuario = usuario.displayName!.trim();
      } else {
        _nomeUsuario = usuario.email ?? 'Usuário';
      }
    } on FirebaseException catch (erro) {
      debugPrint(
        'Erro ao carregar usuário: ${erro.code}',
      );

      _nomeUsuario = usuario.displayName ??
          usuario.email ??
          'Usuário';
    } catch (erro) {
      debugPrint(
        'Erro inesperado ao carregar usuário: $erro',
      );

      _nomeUsuario = usuario.displayName ??
          usuario.email ??
          'Usuário';
    }

    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // LISTAR SOMENTE AS TAREFAS DO USUÁRIO AUTENTICADO
  // ---------------------------------------------------------------------------

  Stream<QuerySnapshot<Map<String, dynamic>>> listarTarefas() {
    final User? usuario = _firebaseAuth.currentUser;

    if (usuario == null) {
      return const Stream<
          QuerySnapshot<Map<String, dynamic>>>.empty();
    }

    return _tarefasCollection
        .where(
          'usuarioId',
          isEqualTo: usuario.uid,
        )
        .orderBy(
          'criadoEm',
          descending: true,
        )
        .snapshots();
  }

  // ---------------------------------------------------------------------------
  // ADICIONAR TAREFA
  // ---------------------------------------------------------------------------

  Future<bool> adicionarTarefa({
    required String titulo,
    required String descricao,
  }) async {
    final User? usuario = _firebaseAuth.currentUser;

    _mensagemErro = null;

    if (usuario == null) {
      _mensagemErro =
          'Nenhum usuário autenticado foi encontrado.';
      notifyListeners();
      return false;
    }

    final String tituloTratado = titulo.trim();
    final String descricaoTratada = descricao.trim();

    final String? erroTitulo =
        validarTitulo(tituloTratado);

    if (erroTitulo != null) {
      _mensagemErro = erroTitulo;
      notifyListeners();
      return false;
    }

    final String? erroDescricao =
        validarDescricao(descricaoTratada);

    if (erroDescricao != null) {
      _mensagemErro = erroDescricao;
      notifyListeners();
      return false;
    }

    _alterarCarregamento(true);

    try {
      await _tarefasCollection.add({
        'titulo': tituloTratado,
        'descricao': descricaoTratada,
        'concluida': false,

        // Vincula a tarefa ao usuário autenticado.
        'usuarioId': usuario.uid,

        'criadoEm': FieldValue.serverTimestamp(),
        'atualizadoEm': FieldValue.serverTimestamp(),
      });

      _mensagemErro = null;
      return true;
    } on FirebaseException catch (erro) {
      _mensagemErro = _traduzirErroFirestore(erro);
      return false;
    } catch (erro) {
      _mensagemErro =
          'Não foi possível adicionar a tarefa.';
      return false;
    } finally {
      _alterarCarregamento(false);
    }
  }

  // ---------------------------------------------------------------------------
  // EDITAR TAREFA
  // ---------------------------------------------------------------------------

  Future<bool> editarTarefa({
    required String tarefaId,
    required String titulo,
    required String descricao,
    required bool concluida,
  }) async {
    final User? usuario = _firebaseAuth.currentUser;

    _mensagemErro = null;

    if (usuario == null) {
      _mensagemErro =
          'Nenhum usuário autenticado foi encontrado.';
      notifyListeners();
      return false;
    }

    if (tarefaId.trim().isEmpty) {
      _mensagemErro =
          'Não foi possível identificar a tarefa.';
      notifyListeners();
      return false;
    }

    final String tituloTratado = titulo.trim();
    final String descricaoTratada = descricao.trim();

    final String? erroTitulo =
        validarTitulo(tituloTratado);

    if (erroTitulo != null) {
      _mensagemErro = erroTitulo;
      notifyListeners();
      return false;
    }

    final String? erroDescricao =
        validarDescricao(descricaoTratada);

    if (erroDescricao != null) {
      _mensagemErro = erroDescricao;
      notifyListeners();
      return false;
    }

    _alterarCarregamento(true);

    try {
      final DocumentReference<Map<String, dynamic>>
          referencia =
          _tarefasCollection.doc(tarefaId);

      final DocumentSnapshot<Map<String, dynamic>>
          documento =
          await referencia.get();

      if (!documento.exists) {
        _mensagemErro = 'A tarefa não foi encontrada.';
        return false;
      }

      final Map<String, dynamic>? dados =
          documento.data();

      if (dados?['usuarioId'] != usuario.uid) {
        _mensagemErro =
            'Você não possui permissão para editar esta tarefa.';
        return false;
      }

      await referencia.update({
        'titulo': tituloTratado,
        'descricao': descricaoTratada,
        'concluida': concluida,
        'atualizadoEm': FieldValue.serverTimestamp(),
      });

      _mensagemErro = null;
      return true;
    } on FirebaseException catch (erro) {
      _mensagemErro = _traduzirErroFirestore(erro);
      return false;
    } catch (erro) {
      _mensagemErro =
          'Não foi possível editar a tarefa.';
      return false;
    } finally {
      _alterarCarregamento(false);
    }
  }

  // ---------------------------------------------------------------------------
  // ALTERAR SITUAÇÃO DA TAREFA
  // ---------------------------------------------------------------------------

  Future<bool> alterarConclusaoTarefa({
    required String tarefaId,
    required bool concluida,
  }) async {
    final User? usuario = _firebaseAuth.currentUser;

    _mensagemErro = null;

    if (usuario == null) {
      _mensagemErro =
          'Nenhum usuário autenticado foi encontrado.';
      notifyListeners();
      return false;
    }

    try {
      final DocumentReference<Map<String, dynamic>>
          referencia =
          _tarefasCollection.doc(tarefaId);

      final DocumentSnapshot<Map<String, dynamic>>
          documento =
          await referencia.get();

      if (!documento.exists) {
        _mensagemErro = 'A tarefa não foi encontrada.';
        notifyListeners();
        return false;
      }

      final Map<String, dynamic>? dados =
          documento.data();

      if (dados?['usuarioId'] != usuario.uid) {
        _mensagemErro =
            'Você não possui permissão para alterar esta tarefa.';
        notifyListeners();
        return false;
      }

      await referencia.update({
        'concluida': concluida,
        'atualizadoEm': FieldValue.serverTimestamp(),
      });

      _mensagemErro = null;
      return true;
    } on FirebaseException catch (erro) {
      _mensagemErro = _traduzirErroFirestore(erro);
      notifyListeners();
      return false;
    } catch (erro) {
      _mensagemErro =
          'Não foi possível alterar a situação da tarefa.';
      notifyListeners();
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // EXCLUIR TAREFA
  // ---------------------------------------------------------------------------

  Future<bool> excluirTarefa(
    String tarefaId,
  ) async {
    final User? usuario = _firebaseAuth.currentUser;

    _mensagemErro = null;

    if (usuario == null) {
      _mensagemErro =
          'Nenhum usuário autenticado foi encontrado.';
      notifyListeners();
      return false;
    }

    if (tarefaId.trim().isEmpty) {
      _mensagemErro =
          'Não foi possível identificar a tarefa.';
      notifyListeners();
      return false;
    }

    _alterarCarregamento(true);

    try {
      final DocumentReference<Map<String, dynamic>>
          referencia =
          _tarefasCollection.doc(tarefaId);

      final DocumentSnapshot<Map<String, dynamic>>
          documento =
          await referencia.get();

      if (!documento.exists) {
        _mensagemErro = 'A tarefa não foi encontrada.';
        return false;
      }

      final Map<String, dynamic>? dados =
          documento.data();

      if (dados?['usuarioId'] != usuario.uid) {
        _mensagemErro =
            'Você não possui permissão para excluir esta tarefa.';
        return false;
      }

      await referencia.delete();

      _mensagemErro = null;
      return true;
    } on FirebaseException catch (erro) {
      _mensagemErro = _traduzirErroFirestore(erro);
      return false;
    } catch (erro) {
      _mensagemErro =
          'Não foi possível excluir a tarefa.';
      return false;
    } finally {
      _alterarCarregamento(false);
    }
  }

  // ---------------------------------------------------------------------------
  // LOGOUT
  // ---------------------------------------------------------------------------

  Future<bool> sair() async {
    _mensagemErro = null;
    _alterarCarregamento(true);

    try {
      await _firebaseAuth.signOut();

      _nomeUsuario = '';
      _mensagemErro = null;

      return true;
    } on FirebaseAuthException catch (erro) {
      _mensagemErro = erro.message ??
          'Não foi possível encerrar a sessão.';

      return false;
    } catch (erro) {
      _mensagemErro =
          'Não foi possível encerrar a sessão.';

      return false;
    } finally {
      _alterarCarregamento(false);
    }
  }

  // ---------------------------------------------------------------------------
  // VALIDAÇÕES
  // ---------------------------------------------------------------------------

  String? validarTitulo(String? valor) {
    final String titulo = valor?.trim() ?? '';

    if (titulo.isEmpty) {
      return 'Informe o título da tarefa.';
    }

    if (titulo.length < 3) {
      return 'O título deve possuir pelo menos 3 caracteres.';
    }

    if (titulo.length > 100) {
      return 'O título deve possuir no máximo 100 caracteres.';
    }

    return null;
  }

  String? validarDescricao(String? valor) {
    final String descricao = valor?.trim() ?? '';

    if (descricao.isEmpty) {
      return 'Informe a descrição da tarefa.';
    }

    if (descricao.length < 3) {
      return 'A descrição deve possuir pelo menos 3 caracteres.';
    }

    if (descricao.length > 500) {
      return 'A descrição deve possuir no máximo 500 caracteres.';
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // MENSAGENS E ESTADO
  // ---------------------------------------------------------------------------

  void limparMensagemErro() {
    if (_mensagemErro == null) {
      return;
    }

    _mensagemErro = null;
    notifyListeners();
  }

  void _alterarCarregamento(bool valor) {
    _carregando = valor;
    notifyListeners();
  }

  String _traduzirErroFirestore(
    FirebaseException erro,
  ) {
    switch (erro.code) {
      case 'permission-denied':
        return 'Você não possui permissão para '
            'realizar esta operação.';

      case 'unavailable':
        return 'O serviço está temporariamente indisponível.';

      case 'not-found':
        return 'A tarefa informada não foi encontrada.';

      case 'cancelled':
        return 'A operação foi cancelada.';

      case 'deadline-exceeded':
        return 'O servidor demorou muito para responder.';

      case 'failed-precondition':
        return 'A consulta necessita de um índice no Firestore.';

      default:
        return erro.message ??
            'Não foi possível realizar a operação.';
    }
  }
}