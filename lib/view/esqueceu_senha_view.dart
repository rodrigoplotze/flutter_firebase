import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../controller/login_controller.dart';



class EsqueceuSenhaView extends StatelessWidget {
  const EsqueceuSenhaView({super.key});

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

          appBar: AppBar(
            backgroundColor: const Color(0xFFFAFAFA),
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Color(0xFF424242),
              ),
              onPressed: ctrl.carregando
                  ? null
                  : () {
                      Navigator.pop(context);
                    },
            ),
          ),

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
                    key: ctrl.esqueceuSenhaFormKey,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        // --------------------------------------------------
                        // ÍCONE
                        // --------------------------------------------------

                        const Icon(
                          Icons.lock_reset_outlined,
                          size: 80,
                          color: _corPrincipal,
                        ),

                        const SizedBox(height: 24),

                        // --------------------------------------------------
                        // TÍTULO
                        // --------------------------------------------------

                        const Text(
                          'Esqueceu a senha?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF212121),
                            fontSize: 32,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // --------------------------------------------------
                        // INSTRUÇÃO
                        // --------------------------------------------------

                        const Text(
                          'Informe o e-mail utilizado em seu cadastro. '
                          'Enviaremos as instruções para redefinir sua senha.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF757575),
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 48),

                        // --------------------------------------------------
                        // EMAIL
                        // --------------------------------------------------

                        TextFormField(
                          controller:
                              ctrl.esqueceuSenhaEmailController,
                          enabled: !ctrl.carregando,
                          keyboardType:
                              TextInputType.emailAddress,
                          textInputAction:
                              TextInputAction.done,
                          autofillHints: const [
                            AutofillHints.email,
                          ],
                          validator: ctrl.validarEmail,
                          onChanged: (_) {
                            ctrl.limparMensagemErro();
                          },
                          onFieldSubmitted: (_) {
                            if (!ctrl.carregando) {
                              _enviarEmail(
                                context,
                                ctrl,
                              );
                            }
                          },
                          decoration: _criarDecoracaoCampo(
                            label: 'Email',
                            hint: 'Informe o e-mail',
                            icone: Icons.email_outlined,
                          ),
                        ),

                        // --------------------------------------------------
                        // MENSAGEM DE ERRO
                        // --------------------------------------------------

                        if (ctrl.mensagemErro != null) ...[
                          const SizedBox(height: 16),

                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius:
                                  BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.red.shade200,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red.shade700,
                                  size: 21,
                                ),

                                const SizedBox(width: 10),

                                Expanded(
                                  child: Text(
                                    ctrl.mensagemErro!,
                                    style: TextStyle(
                                      color:
                                          Colors.red.shade700,
                                      fontSize: 14,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 32),

                        // --------------------------------------------------
                        // BOTÃO ENVIAR
                        // --------------------------------------------------

                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: ctrl.carregando
                                ? null
                                : () {
                                    _enviarEmail(
                                      context,
                                      ctrl,
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _corPrincipal,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  _corPrincipal.withValues(
                                alpha: 0.6,
                              ),
                              elevation: 3,
                              shadowColor: Colors.black38,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(6),
                              ),
                            ),
                            child: ctrl.carregando
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Enviar',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight:
                                          FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // --------------------------------------------------
                        // VOLTAR AO LOGIN
                        // --------------------------------------------------

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Lembrou sua senha?',
                              style: TextStyle(
                                color: Color(0xFF616161),
                                fontSize: 16,
                              ),
                            ),

                            TextButton(
                              onPressed: ctrl.carregando
                                  ? null
                                  : () {
                                      Navigator.pop(
                                        context,
                                      );
                                    },
                              child: const Text(
                                'Entrar',
                                style: TextStyle(
                                  color: _corPrincipal,
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.w600,
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
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  // ENVIAR EMAIL
  // -------------------------------------------------------------------------

  Future<void> _enviarEmail(
    BuildContext context,
    LoginController ctrl,
  ) async {
    final bool enviado =
        await ctrl.enviarRecuperacaoSenha();

    if (!context.mounted) {
      return;
    }

    if (!enviado) {
      return;
    }

    final String email =
        ctrl.esqueceuSenhaEmailController.text.trim();

    // Evita manter mensagem de erro anterior.
    ctrl.limparMensagemErro();

    await _mostrarSucesso(
      context,
      email,
    );
  }

  // -------------------------------------------------------------------------
  // DIALOG DE SUCESSO
  // -------------------------------------------------------------------------

  Future<void> _mostrarSucesso(
    BuildContext context,
    String email,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.mark_email_read_outlined,
            color: _corPrincipal,
            size: 52,
          ),
          title: const Text(
            'E-mail enviado',
            textAlign: TextAlign.center,
          ),
          content: Text(
            'As instruções para redefinir sua senha '
            'foram enviadas para:\n\n$email\n\n'
            'Verifique também a pasta de spam.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              height: 1.4,
            ),
          ),
          actionsAlignment:
              MainAxisAlignment.center,
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _corPrincipal,
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (!context.mounted) {
      return;
    }

    // Retorna automaticamente para a tela de login.
    Navigator.pop(context);
  }

  // -------------------------------------------------------------------------
  // DECORAÇÃO DO CAMPO
  // -------------------------------------------------------------------------

  InputDecoration _criarDecoracaoCampo({
    required String label,
    required String hint,
    required IconData icone,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,

      prefixIcon: Icon(
        icone,
        color: Colors.grey.shade600,
      ),

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
        color: Colors.grey.shade500,
        fontSize: 17,
      ),

      floatingLabelBehavior:
          FloatingLabelBehavior.always,

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