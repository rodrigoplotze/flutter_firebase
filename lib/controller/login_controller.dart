import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginController extends ChangeNotifier {
  LoginController({
    FirebaseAuth? firebaseAuth,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  // ---------------------------------------------------------------------------
  // FORMULÁRIOS
  // ---------------------------------------------------------------------------

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final GlobalKey<FormState> esqueceuSenhaFormKey =
      GlobalKey<FormState>();

  // ---------------------------------------------------------------------------
  // CONTROLLERS
  // ---------------------------------------------------------------------------

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController senhaController =
      TextEditingController();

  final TextEditingController esqueceuSenhaEmailController =
      TextEditingController();

  // ---------------------------------------------------------------------------
  // ESTADOS
  // ---------------------------------------------------------------------------

  bool _carregando = false;
  bool _ocultarSenha = true;

  String? _mensagemErro;

  // ---------------------------------------------------------------------------
  // GETTERS
  // ---------------------------------------------------------------------------

  bool get carregando => _carregando;

  bool get ocultarSenha => _ocultarSenha;

  String? get mensagemErro => _mensagemErro;

  User? get usuarioAtual => _firebaseAuth.currentUser;

  bool get usuarioAutenticado => usuarioAtual != null;

  Stream<User?> get authStateChanges =>
      _firebaseAuth.authStateChanges();

  // ---------------------------------------------------------------------------
  // CONTROLE DA SENHA
  // ---------------------------------------------------------------------------

  void alternarVisibilidadeSenha() {
    _ocultarSenha = !_ocultarSenha;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // MENSAGENS
  // ---------------------------------------------------------------------------

  void limparMensagemErro() {
    if (_mensagemErro == null) {
      return;
    }

    _mensagemErro = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // VALIDAÇÕES
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

  String? validarSenha(String? valor) {
    if (valor == null || valor.isEmpty) {
      return 'Informe a senha.';
    }

    if (valor.length < 6) {
      return 'A senha deve possuir pelo menos 6 caracteres.';
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // LOGIN
  // ---------------------------------------------------------------------------

  Future<bool> entrar() async {
    FocusManager.instance.primaryFocus?.unfocus();

    _mensagemErro = null;

    final bool formularioValido =
        formKey.currentState?.validate() ?? false;

    if (!formularioValido) {
      notifyListeners();
      return false;
    }

    _alterarCarregamento(true);

    try {
      final UserCredential credencial =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: senhaController.text,
      );

      if (credencial.user == null) {
        _mensagemErro =
            'Não foi possível identificar o usuário.';

        return false;
      }

      _mensagemErro = null;

      return true;
    } on FirebaseAuthException catch (erro) {
      _mensagemErro = _traduzirErroFirebase(erro);

      return false;
    } catch (erro) {
      _mensagemErro =
          'Ocorreu um erro inesperado. Tente novamente.';

      return false;
    } finally {
      _alterarCarregamento(false);
    }
  }

  // ---------------------------------------------------------------------------
  // RECUPERAÇÃO DE SENHA
  // ---------------------------------------------------------------------------

  Future<bool> enviarRecuperacaoSenha() async {
    FocusManager.instance.primaryFocus?.unfocus();

    _mensagemErro = null;

    final bool formularioValido =
        esqueceuSenhaFormKey.currentState?.validate() ?? false;

    if (!formularioValido) {
      notifyListeners();
      return false;
    }

    final String email =
        esqueceuSenhaEmailController.text.trim();

    _alterarCarregamento(true);

    try {
      await _firebaseAuth.sendPasswordResetEmail(
        email: email,
      );

      _mensagemErro = null;

      return true;
    } on FirebaseAuthException catch (erro) {
      _mensagemErro = _traduzirErroFirebase(erro);

      return false;
    } catch (erro) {
      _mensagemErro =
          'Não foi possível enviar o e-mail de recuperação.';

      return false;
    } finally {
      _alterarCarregamento(false);
    }
  }

  // ---------------------------------------------------------------------------
  // LOGOUT
  // ---------------------------------------------------------------------------

  Future<void> sair() async {
    try {
      await _firebaseAuth.signOut();

      emailController.clear();
      senhaController.clear();

      _mensagemErro = null;

      notifyListeners();
    } on FirebaseAuthException catch (erro) {
      _mensagemErro = _traduzirErroFirebase(erro);

      notifyListeners();
    } catch (erro) {
      _mensagemErro =
          'Não foi possível encerrar a sessão.';

      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // LIMPAR FORMULÁRIO LOGIN
  // ---------------------------------------------------------------------------

  void limparFormulario() {
    emailController.clear();
    senhaController.clear();

    _mensagemErro = null;
    _ocultarSenha = true;

    formKey.currentState?.reset();

    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // PREPARAR RECUPERAÇÃO
  // ---------------------------------------------------------------------------

  void prepararRecuperacaoSenha() {
    // Se o usuário já digitou o e-mail na tela de login,
    // o e-mail é levado automaticamente para a próxima tela.

    esqueceuSenhaEmailController.text =
        emailController.text.trim();

    _mensagemErro = null;

    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // LIMPAR RECUPERAÇÃO
  // ---------------------------------------------------------------------------

  void limparRecuperacaoSenha() {
    esqueceuSenhaEmailController.clear();

    _mensagemErro = null;

    esqueceuSenhaFormKey.currentState?.reset();

    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // LOADING
  // ---------------------------------------------------------------------------

  void _alterarCarregamento(bool valor) {
    _carregando = valor;

    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // TRATAMENTO DE ERROS FIREBASE
  // ---------------------------------------------------------------------------

  String _traduzirErroFirebase(
    FirebaseAuthException erro,
  ) {
    switch (erro.code) {
      case 'invalid-email':
        return 'O e-mail informado é inválido.';

      case 'user-disabled':
        return 'Este usuário foi desativado.';

      case 'user-not-found':
        return 'Nenhum usuário foi encontrado com este e-mail.';

      case 'wrong-password':
        return 'A senha informada está incorreta.';

      case 'invalid-credential':
        return 'E-mail ou senha incorretos.';

      case 'too-many-requests':
        return 'Muitas tentativas foram realizadas. '
            'Aguarde alguns minutos e tente novamente.';

      case 'network-request-failed':
        return 'Não foi possível acessar o servidor. '
            'Verifique sua conexão com a internet.';

      case 'operation-not-allowed':
        return 'A autenticação por e-mail e senha '
            'não está habilitada.';

      case 'email-already-in-use':
        return 'Este e-mail já está sendo utilizado.';

      case 'weak-password':
        return 'A senha informada é muito fraca.';

      default:
        return erro.message ??
            'Não foi possível realizar a operação.';
    }
  }

  // ---------------------------------------------------------------------------
  // DISPOSE
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();
    esqueceuSenhaEmailController.dispose();

    super.dispose();
  }
}