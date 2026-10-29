import 'package:device_preview_plus/device_preview_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase/firebase_options.dart';
import 'package:get_it/get_it.dart';

import 'controller/cadastro_usuario_controller.dart';
import 'controller/login_controller.dart';
import 'controller/tarefa_controller.dart';
import 'view/cadastrar_usuario_view.dart';
import 'view/esqueceu_senha_view.dart';
import 'view/home_view.dart';
import 'view/login_view.dart';

final g = GetIt.instance;

Future<void> main() async {
  //
  // INICIALIZAÇÃO FIREBASE
  //
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  //
  // DEPENDÊNCIAS
  //
  g.registerSingleton<LoginController>(LoginController());
  g.registerSingleton<CadastroUsuarioController>(CadastroUsuarioController());
  g.registerSingleton<TarefaController>(TarefaController());

  runApp(
    DevicePreview(builder: (context) => MainApp()),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tarefas',
      debugShowCheckedModeBanner: false,
      home: LoginView(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
        ),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginView(),
        '/esqueceu-senha': (context) => const EsqueceuSenhaView(),
        '/cadastro-usuario': (context) => const CadastroUsuarioView(),
        '/home': (context) => const HomeView(),
      },
    );
  }
}
