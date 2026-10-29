import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CadastroUsuarioController extends ChangeNotifier {
  CadastroUsuarioController({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  // ---------------------------------------------------------------------------
  // FORMULÁRIO
  // ---------------------------------------------------------------------------

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // ---------------------------------------------------------------------------
  // CONTROLLERS
  // ---------------------------------------------------------------------------

  final TextEditingController nomeCompletoController =
      TextEditingController();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController senhaController =
      TextEditingController();

  final TextEditingController confirmarSenhaController =
      TextEditingController();

  // ---------------------------------------------------------------------------
  // ESTADOS
  // ---------------------------------------------------------------------------

  bool _carregando = false;
  bool _ocultarSenha = true;
  bool _ocultarConfirmacaoSenha = true;

  String? _mensagemErro;

  // ---------------------------------------------------------------------------
  // GETTERS
  // ---------------------------------------------------------------------------

  bool get carregando => _carregando;

  bool get ocultarSenha => _ocultarSenha;

  bool get ocultarConfirmacaoSenha =>
      _ocultarConfirmacaoSenha;

  String? get mensagemErro => _mensagemErro;

  // ---------------------------------------------------------------------------
  // VISIBILIDADE DAS SENHAS
  // ---------------------------------------------------------------------------

  void alternarVisibilidadeSenha() {
    _ocultarSenha = !_ocultarSenha;
    notifyListeners();
  }

  void alternarVisibilidadeConfirmacaoSenha() {
    _ocultarConfirmacaoSenha =
        !_ocultarConfirmacaoSenha;

    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // MENSAGEM DE ERRO
  // ---------------------------------------------------------------------------

  void limparMensagemErro() {
    if (_mensagemErro == null) {
      return;
    }

    _mensagemErro = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // VALIDAÇÃO DO NOME
  // ---------------------------------------------------------------------------

  String? validarNomeCompleto(String? valor) {
    final String nome = valor?.trim() ?? '';

    if (nome.isEmpty) {
      return 'Informe o nome completo.';
    }

    if (nome.length < 3) {
      return 'O nome deve possuir pelo menos 3 caracteres.';
    }

    final List<String> partesNome = nome
        .split(RegExp(r'\s+'))
        .where((parte) => parte.isNotEmpty)
        .toList();

    if (partesNome.length < 2) {
      return 'Informe o nome e o sobrenome.';
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // VALIDAÇÃO DO E-MAIL
  // ---------------------------------------------------------------------------

  String? validarEmail(String? valor) {
    final String email = valor?.trim() ?? '';

    if (email.isEmpty) {
      return 'Informe o e-mail.';
    }

    final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Informe um e-mail válido.';
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // VALIDAÇÃO DA SENHA
  // ---------------------------------------------------------------------------

  String? validarSenha(String? valor) {
    final String senha = valor ?? '';

    if (senha.isEmpty) {
      return 'Informe a senha.';
    }

    if (senha.length < 6) {
      return 'A senha deve possuir pelo menos 6 caracteres.';
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // VALIDAÇÃO DA CONFIRMAÇÃO DA SENHA
  // ---------------------------------------------------------------------------

  String? validarConfirmacaoSenha(String? valor) {
    final String confirmacao = valor ?? '';

    if (confirmacao.isEmpty) {
      return 'Confirme a senha.';
    }

    if (confirmacao != senhaController.text) {
      return 'As senhas não são iguais.';
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // CADASTRAR USUÁRIO
  // ---------------------------------------------------------------------------

  Future<bool> cadastrar() async {
    FocusManager.instance.primaryFocus?.unfocus();

    _mensagemErro = null;

    final bool formularioValido =
        formKey.currentState?.validate() ?? false;

    if (!formularioValido) {
      notifyListeners();
      return false;
    }

    final String nomeCompleto =
        _normalizarNome(nomeCompletoController.text);

    final String email =
        emailController.text.trim().toLowerCase();

    final String senha = senhaController.text;

    _alterarCarregamento(true);

    User? usuarioCriado;

    try {
      /*
       * 1. Cria a conta no Firebase Authentication.
       */
      final UserCredential credencial =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );

      usuarioCriado = credencial.user;

      if (usuarioCriado == null) {
        _mensagemErro =
            'Não foi possível identificar o usuário criado.';

        return false;
      }

      /*
       * 2. Atualiza o nome de exibição no Firebase Authentication.
       */
      await usuarioCriado.updateDisplayName(nomeCompleto);

      /*
       * 3. Armazena os dados complementares no Cloud Firestore.
       *
       * Estrutura:
       *
       * usuarios
       *   └── UID_DO_USUARIO
       *        ├── uid
       *        ├── nomeCompleto
       *        ├── email
       *        ├── criadoEm
       *        └── atualizadoEm
       */
      await _db
          .collection('usuarios')
          .doc(usuarioCriado.uid)
          .set({
        'uid': usuarioCriado.uid,
        'nomeCompleto': nomeCompleto,
        'email': email,
        'criadoEm': FieldValue.serverTimestamp(),
        'atualizadoEm': FieldValue.serverTimestamp(),
      });

      /*
       * 4. Recarrega os dados do usuário.
       */
      await usuarioCriado.reload();

      _mensagemErro = null;

      return true;
    } on FirebaseAuthException catch (erro) {
      _mensagemErro = _traduzirErroFirebaseAuth(erro);

      return false;
    } on FirebaseException catch (erro) {
      /*
       * Se o Authentication criou a conta, mas o Firestore falhou,
       * tenta excluir a conta para evitar usuário incompleto.
       */
      await _excluirUsuarioIncompleto(usuarioCriado);

      _mensagemErro = _traduzirErroFirestore(erro);

      return false;
    } catch (erro) {
      await _excluirUsuarioIncompleto(usuarioCriado);

      _mensagemErro =
          'Ocorreu um erro inesperado durante o cadastro.';

      return false;
    } finally {
      _alterarCarregamento(false);
    }
  }

  // ---------------------------------------------------------------------------
  // EXCLUIR CONTA INCOMPLETA
  // ---------------------------------------------------------------------------

  Future<void> _excluirUsuarioIncompleto(
    User? usuario,
  ) async {
    if (usuario == null) {
      return;
    }

    try {
      await usuario.delete();
    } catch (erro) {
      debugPrint(
        'Não foi possível excluir o usuário incompleto: $erro',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // NORMALIZAR NOME
  // ---------------------------------------------------------------------------

  String _normalizarNome(String nome) {
    return nome
        .trim()
        .split(RegExp(r'\s+'))
        .where((parte) => parte.isNotEmpty)
        .map((parte) {
          if (parte.length == 1) {
            return parte.toUpperCase();
          }

          return '${parte[0].toUpperCase()}'
              '${parte.substring(1).toLowerCase()}';
        })
        .join(' ');
  }

  // ---------------------------------------------------------------------------
  // ALTERAR CARREGAMENTO
  // ---------------------------------------------------------------------------

  void _alterarCarregamento(bool valor) {
    _carregando = valor;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // ERROS DO FIREBASE AUTHENTICATION
  // ---------------------------------------------------------------------------

  String _traduzirErroFirebaseAuth(
    FirebaseAuthException erro,
  ) {
    switch (erro.code) {
      case 'email-already-in-use':
        return 'Já existe uma conta cadastrada com este e-mail.';

      case 'invalid-email':
        return 'O e-mail informado é inválido.';

      case 'operation-not-allowed':
        return 'O cadastro por e-mail e senha não está habilitado.';

      case 'weak-password':
        return 'A senha informada é muito fraca.';

      case 'network-request-failed':
        return 'Não foi possível acessar o servidor. '
            'Verifique sua conexão com a internet.';

      case 'too-many-requests':
        return 'Muitas tentativas foram realizadas. '
            'Aguarde alguns minutos e tente novamente.';

      default:
        return erro.message ??
            'Não foi possível criar a conta.';
    }
  }

  // ---------------------------------------------------------------------------
  // ERROS DO CLOUD FIRESTORE
  // ---------------------------------------------------------------------------

  String _traduzirErroFirestore(
    FirebaseException erro,
  ) {
    switch (erro.code) {
      case 'permission-denied':
        return 'O aplicativo não possui permissão para '
            'salvar os dados do usuário.';

      case 'unavailable':
        return 'O serviço de armazenamento está indisponível. '
            'Tente novamente em alguns instantes.';

      case 'cancelled':
        return 'A operação de cadastro foi cancelada.';

      case 'deadline-exceeded':
        return 'O servidor demorou muito para responder. '
            'Tente novamente.';

      default:
        return erro.message ??
            'A conta foi criada, mas não foi possível '
                'salvar os dados do perfil.';
    }
  }

  // ---------------------------------------------------------------------------
  // LIMPAR FORMULÁRIO
  // ---------------------------------------------------------------------------

  void limparFormulario() {
    nomeCompletoController.clear();
    emailController.clear();
    senhaController.clear();
    confirmarSenhaController.clear();

    _mensagemErro = null;
    _ocultarSenha = true;
    _ocultarConfirmacaoSenha = true;

    formKey.currentState?.reset();

    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // DISPOSE
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    nomeCompletoController.dispose();
    emailController.dispose();
    senhaController.dispose();
    confirmarSenhaController.dispose();

    super.dispose();
  }
}