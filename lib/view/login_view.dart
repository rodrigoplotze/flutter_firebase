import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../controller/login_controller.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  static const Color _corPrincipal = Color(0xFF2196F3);
  static const Color _corBorda = Color(0xFFBDBDBD);

  @override
  Widget build(BuildContext context) {
    final ctrl = GetIt.I.get<LoginController>();

    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFFAFAFA),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 520,
                  ),
                  child: Form(
                    key: ctrl.formKey,
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Login',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF212121),
                              fontSize: 68,
                              fontWeight: FontWeight.w300,
                              height: 1,
                            ),
                          ),

                          const SizedBox(height: 90),

                          TextFormField(
                            controller: ctrl.emailController,
                            enabled: !ctrl.carregando,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [
                              AutofillHints.email,
                              AutofillHints.username,
                            ],
                            validator: ctrl.validarEmail,
                            onChanged: (_) {
                              ctrl.limparMensagemErro();
                            },
                            decoration: _criarDecoracaoCampo(
                              label: 'Email',
                              hint: '',
                              icone: Icons.email,
                            ),
                          ),

                          const SizedBox(height: 22),

                          TextFormField(
                            controller: ctrl.senhaController,
                            enabled: !ctrl.carregando,
                            obscureText: ctrl.ocultarSenha,
                            keyboardType: TextInputType.visiblePassword,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [
                              AutofillHints.password,
                            ],
                            validator: ctrl.validarSenha,
                            onChanged: (_) {
                              ctrl.limparMensagemErro();
                            },
                            onFieldSubmitted: (_) {
                              if (!ctrl.carregando) {
                                _realizarLogin(context, ctrl);
                              }
                            },
                            decoration: _criarDecoracaoCampo(
                              label: 'Senha',
                              hint: '',
                              icone: Icons.lock_outline,
                              sufixo: IconButton(
                                tooltip: ctrl.ocultarSenha
                                    ? 'Mostrar senha'
                                    : 'Ocultar senha',
                                onPressed: ctrl.alternarVisibilidadeSenha,
                                icon: Icon(
                                  ctrl.ocultarSenha
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),

                          if (ctrl.mensagemErro != null) ...[
                            const SizedBox(height: 12),
                            Container(
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
                                    size: 21,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      ctrl.mensagemErro!,
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 4),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: ctrl.carregando
                                  ? null
                                  : () {
                                      ctrl.prepararRecuperacaoSenha();

                                      Navigator.pushNamed(
                                        context,
                                        '/esqueceu-senha',
                                      );
                                    },
                              style: TextButton.styleFrom(
                                foregroundColor: _corPrincipal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                              ),
                              child: const Text(
                                'Esqueceu a senha?',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 70,
                            ),
                            child: SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: ctrl.carregando
                                    ? null
                                    : () {
                                        _realizarLogin(
                                          context,
                                          ctrl,
                                        );
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _corPrincipal,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: _corPrincipal
                                      .withValues(
                                        alpha: 0.6,
                                      ),
                                  elevation: 3,
                                  shadowColor: Colors.black38,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                child: ctrl.carregando
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Entrar',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 70),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Flexible(
                                child: Text(
                                  'Ainda não tem conta?',
                                  style: TextStyle(
                                    color: Color(0xFF616161),
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: ctrl.carregando
                                    ? null
                                    : () {
                                        Navigator.pushNamed(
                                          context,
                                          '/cadastro-usuario',
                                        );
                                      },
                                style: TextButton.styleFrom(
                                  foregroundColor: _corPrincipal,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                ),
                                child: const Text(
                                  'Cadastre-se',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _realizarLogin(
    BuildContext context,
    LoginController ctrl,
  ) async {
    final bool autenticado = await ctrl.entrar();

    if (!context.mounted) {
      return;
    }

    if (autenticado) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (route) => false,
      );
    }
  }

  InputDecoration _criarDecoracaoCampo({
    required String label,
    required String hint,
    required IconData icone,
    Widget? sufixo,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(
        icone,
        color: Colors.grey.shade600,
      ),
      suffixIcon: sufixo,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 20,
      ),
      labelStyle: TextStyle(
        color: Colors.grey.shade700,
        fontSize: 16,
      ),
      hintStyle: TextStyle(
        color: Colors.grey.shade700,
        fontSize: 17,
      ),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(
          color: _corBorda,
          width: 1.5,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(
          color: _corBorda,
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(
          color: _corPrincipal,
          width: 2,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.5,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 2,
        ),
      ),
    );
  }
}
