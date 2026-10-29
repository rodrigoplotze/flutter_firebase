import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../controller/cadastro_usuario_controller.dart';

class CadastroUsuarioView extends StatelessWidget {
  const CadastroUsuarioView({super.key});

  static const Color _corPrincipal = Color(0xFF2196F3);
  static const Color _corBorda = Color(0xFFBDBDBD);

  @override
  Widget build(BuildContext context) {
    final ctrl = GetIt.I.get<CadastroUsuarioController>();

    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFFAFAFA),
          appBar: AppBar(
            backgroundColor: const Color(0xFFFAFAFA),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              tooltip: 'Voltar',
              onPressed: ctrl.carregando
                  ? null
                  : () {
                      Navigator.pop(context);
                    },
              icon: const Icon(
                Icons.arrow_back,
                color: Color(0xFF424242),
              ),
            ),
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  32,
                  12,
                  32,
                  32,
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
                          const Icon(
                            Icons.person_add_alt_1_outlined,
                            size: 72,
                            color: _corPrincipal,
                          ),

                          const SizedBox(height: 20),

                          const Text(
                            'Criar conta',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF212121),
                              fontSize: 38,
                              fontWeight: FontWeight.w400,
                            ),
                          ),

                          const SizedBox(height: 12),

                          const Text(
                            'Preencha os dados abaixo para '
                            'realizar seu cadastro.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF757575),
                              fontSize: 16,
                              height: 1.4,
                            ),
                          ),

                          const SizedBox(height: 42),

                          // ------------------------------------------------
                          // NOME COMPLETO
                          // ------------------------------------------------
                          TextFormField(
                            controller: ctrl.nomeCompletoController,
                            enabled: !ctrl.carregando,
                            keyboardType: TextInputType.name,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [
                              AutofillHints.name,
                            ],
                            validator: ctrl.validarNomeCompleto,
                            onChanged: (_) {
                              ctrl.limparMensagemErro();
                            },
                            decoration: _criarDecoracaoCampo(
                              label: 'Nome completo',
                              hint: 'Informe o nome completo',
                              icone: Icons.person_outline,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ------------------------------------------------
                          // E-MAIL
                          // ------------------------------------------------
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
                              hint: 'Informe o e-mail',
                              icone: Icons.email_outlined,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ------------------------------------------------
                          // SENHA
                          // ------------------------------------------------
                          TextFormField(
                            controller: ctrl.senhaController,
                            enabled: !ctrl.carregando,
                            obscureText: ctrl.ocultarSenha,
                            keyboardType: TextInputType.visiblePassword,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [
                              AutofillHints.newPassword,
                            ],
                            validator: ctrl.validarSenha,
                            onChanged: (_) {
                              ctrl.limparMensagemErro();

                              /*
                               * Se a confirmação já foi preenchida,
                               * revalida para verificar se as senhas
                               * continuam iguais.
                               */
                              if (ctrl
                                  .confirmarSenhaController
                                  .text
                                  .isNotEmpty) {
                                ctrl.formKey.currentState?.validate();
                              }
                            },
                            decoration: _criarDecoracaoCampo(
                              label: 'Senha',
                              hint: 'Mínimo de 6 caracteres',
                              icone: Icons.lock_outline,
                              sufixo: IconButton(
                                tooltip: ctrl.ocultarSenha
                                    ? 'Mostrar senha'
                                    : 'Ocultar senha',
                                onPressed: ctrl.carregando
                                    ? null
                                    : ctrl.alternarVisibilidadeSenha,
                                icon: Icon(
                                  ctrl.ocultarSenha
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ------------------------------------------------
                          // CONFIRMAÇÃO DA SENHA
                          // ------------------------------------------------
                          TextFormField(
                            controller: ctrl.confirmarSenhaController,
                            enabled: !ctrl.carregando,
                            obscureText: ctrl.ocultarConfirmacaoSenha,
                            keyboardType: TextInputType.visiblePassword,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [
                              AutofillHints.newPassword,
                            ],
                            validator: ctrl.validarConfirmacaoSenha,
                            onChanged: (_) {
                              ctrl.limparMensagemErro();
                            },
                            onFieldSubmitted: (_) {
                              if (!ctrl.carregando) {
                                _realizarCadastro(
                                  context,
                                  ctrl,
                                );
                              }
                            },
                            decoration: _criarDecoracaoCampo(
                              label: 'Confirmar senha',
                              hint: 'Digite novamente',
                              icone: Icons.lock_reset_outlined,
                              sufixo: IconButton(
                                tooltip: ctrl.ocultarConfirmacaoSenha
                                    ? 'Mostrar confirmação'
                                    : 'Ocultar confirmação',
                                onPressed: ctrl.carregando
                                    ? null
                                    : ctrl.alternarVisibilidadeConfirmacaoSenha,
                                icon: Icon(
                                  ctrl.ocultarConfirmacaoSenha
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),

                          // ------------------------------------------------
                          // MENSAGEM DE ERRO
                          // ------------------------------------------------
                          if (ctrl.mensagemErro != null) ...[
                            const SizedBox(height: 18),

                            Container(
                              padding: const EdgeInsets.all(14),
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
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      ctrl.mensagemErro!,
                                      style: TextStyle(
                                        color: Colors.red.shade700,
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

                          // ------------------------------------------------
                          // BOTÃO CADASTRAR
                          // ------------------------------------------------
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: ctrl.carregando
                                  ? null
                                  : () {
                                      _realizarCadastro(
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
                                  borderRadius: BorderRadius.circular(
                                    6,
                                  ),
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
                                      'Cadastrar',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ------------------------------------------------
                          // VOLTAR AO LOGIN
                          // ------------------------------------------------
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Flexible(
                                child: Text(
                                  'Já possui uma conta?',
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
                                        Navigator.pop(
                                          context,
                                        );
                                      },
                                style: TextButton.styleFrom(
                                  foregroundColor: _corPrincipal,
                                ),
                                child: const Text(
                                  'Entrar',
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

  // ---------------------------------------------------------------------------
  // REALIZAR CADASTRO
  // ---------------------------------------------------------------------------

  Future<void> _realizarCadastro(
    BuildContext context,
    CadastroUsuarioController ctrl,
  ) async {
    final bool cadastrado = await ctrl.cadastrar();

    if (!context.mounted || !cadastrado) {
      return;
    }

    final String nome = ctrl.nomeCompletoController.text.trim();

    await _mostrarCadastroRealizado(
      context,
      nome,
    );

    if (!context.mounted) {
      return;
    }

    ctrl.limparFormulario();

    /*
     * createUserWithEmailAndPassword mantém o usuário autenticado.
     * Por esse motivo, após o cadastro, a navegação pode seguir
     * diretamente para a Home.
     */
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/home',
      (route) => false,
    );
  }

  // ---------------------------------------------------------------------------
  // MENSAGEM DE SUCESSO
  // ---------------------------------------------------------------------------

  Future<void> _mostrarCadastroRealizado(
    BuildContext context,
    String nome,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.check_circle_outline,
            color: Colors.green,
            size: 56,
          ),
          title: const Text(
            'Cadastro realizado',
            textAlign: TextAlign.center,
          ),
          content: Text(
            'Olá, $nome!\n\n'
            'Sua conta foi criada com sucesso.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              height: 1.4,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _corPrincipal,
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // DECORAÇÃO DOS CAMPOS
  // ---------------------------------------------------------------------------

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
        color: Colors.grey.shade500,
        fontSize: 16,
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
