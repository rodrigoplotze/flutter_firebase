# Tarefas

Aplicativo de gerenciamento de tarefas desenvolvido em **Flutter**, com autenticação de usuários pelo **Firebase Authentication**, armazenamento de dados no **Cloud Firestore** e gerenciamento de dependências com **GetIt**.

Cada usuário pode criar uma conta, autenticar-se, recuperar a senha e gerenciar exclusivamente as próprias tarefas. As tarefas são sincronizadas em tempo real com o Cloud Firestore.

## Funcionalidades

### Autenticação

- Cadastro com nome completo, e-mail, senha e confirmação da senha;
- Autenticação com e-mail e senha;
- Recuperação de senha por e-mail;
- Exibição do nome do usuário autenticado;
- Encerramento da sessão;
- Redirecionamento para a tela de login após o logout.

### Gerenciamento de tarefas

- Listagem em tempo real das tarefas do usuário autenticado;
- Cadastro de novas tarefas;
- Edição do título, da descrição e da situação da tarefa;
- Marcação da tarefa como concluída ou pendente;
- Exclusão de tarefas com confirmação;
- Separação das tarefas por usuário;
- Exibição da data de criação;
- Feedback visual para tarefas concluídas.

## Tecnologias utilizadas

- Flutter;
- Dart;
- Firebase Core;
- Firebase Authentication;
- Cloud Firestore;
- GetIt;
- ChangeNotifier;
- Material Design.

## Arquitetura

O projeto utiliza separação entre interface e regras de negócio:

- **Views:** apresentam os componentes visuais, formulários, listas e diálogos;
- **Controllers:** executam validações, controlam estados e acessam os serviços do Firebase;
- **GetIt:** disponibiliza as instâncias dos controllers;
- **Firebase Authentication:** gerencia cadastro, login, recuperação de senha e logout;
- **Cloud Firestore:** armazena usuários e tarefas.

## Estrutura sugerida

```text
lib/
├── controllers/
│   ├── cadastro_controller.dart
│   ├── login_controller.dart
│   └── tarefa_controller.dart
├── views/
│   ├── cadastro_view.dart
│   ├── esqueceu_senha_view.dart
│   ├── home_view.dart
│   └── login_view.dart
├── firebase_options.dart
├── service_locator.dart
└── main.dart
```

## Pré-requisitos

Antes de executar o projeto, instale e configure:

- Flutter SDK;
- Dart SDK;
- Android Studio, Visual Studio Code ou outra IDE compatível;
- Firebase CLI;
- FlutterFire CLI;
- Uma conta e um projeto no Firebase.

Verifique a instalação do Flutter:

```bash
flutter doctor
```

## Instalação

Clone o repositório:

```bash
git clone URL_DO_REPOSITORIO
```

Acesse a pasta do projeto:

```bash
cd tarefas
```

Instale as dependências:

```bash
flutter pub get
```

Caso os pacotes ainda não estejam configurados, adicione-os:

```bash
flutter pub add firebase_core
flutter pub add firebase_auth
flutter pub add cloud_firestore
flutter pub add get_it
```

## Configuração do Firebase

### 1. Criar o projeto

Crie um projeto no Firebase Console e registre as plataformas utilizadas pelo aplicativo.

### 2. Instalar o FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

### 3. Configurar o aplicativo

Na raiz do projeto, execute:

```bash
flutterfire configure
```

O comando gera o arquivo:

```text
lib/firebase_options.dart
```

### 4. Inicializar o Firebase

O arquivo `main.dart` deve inicializar o Firebase antes de executar o aplicativo:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  configurarDependencias();

  runApp(const MeuAplicativo());
}
```

## Configuração do Firebase Authentication

No Firebase Console:

1. Acesse **Authentication**;
2. Abra **Sign-in method**;
3. Habilite o provedor **E-mail/senha**;
4. Salve as alterações.

O Firebase Authentication será utilizado para:

- criar contas;
- realizar login;
- enviar e-mails de recuperação de senha;
- identificar o usuário autenticado;
- encerrar a sessão.

## Configuração do Cloud Firestore

No Firebase Console:

1. Acesse **Firestore Database**;
2. Clique em **Criar banco de dados**;
3. Selecione a localização adequada;
4. Configure as regras de segurança;
5. Publique as regras.

O projeto utiliza as coleções `usuarios` e `tarefas`.

## Estrutura da coleção `usuarios`

O UID gerado pelo Firebase Authentication é utilizado como identificador do documento.

```text
usuarios
└── UID_DO_USUARIO
    ├── uid: "UID_DO_USUARIO"
    ├── nomeCompleto: "João da Silva"
    ├── email: "joao@email.com"
    ├── criadoEm: Timestamp
    └── atualizadoEm: Timestamp
```

A senha não é armazenada no Firestore. O gerenciamento da senha é realizado exclusivamente pelo Firebase Authentication.

## Estrutura da coleção `tarefas`

```text
tarefas
└── ID_DA_TAREFA
    ├── titulo: "Preparar aula"
    ├── descricao: "Preparar os slides da próxima aula."
    ├── concluida: false
    ├── usuarioId: "UID_DO_USUARIO"
    ├── criadoEm: Timestamp
    └── atualizadoEm: Timestamp
```

O campo `usuarioId` vincula a tarefa ao proprietário e é preenchido automaticamente com o UID do usuário autenticado.

## Regras de segurança do Firestore

As regras abaixo garantem que cada usuário possa acessar somente o próprio cadastro e as próprias tarefas:

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    match /usuarios/{userId} {
      allow create, read, update: if request.auth != null
                                  && request.auth.uid == userId;

      allow delete: if false;
    }

    match /tarefas/{tarefaId} {
      allow read: if request.auth != null
                  && resource.data.usuarioId == request.auth.uid;

      allow create: if request.auth != null
                    && request.resource.data.usuarioId == request.auth.uid
                    && request.resource.data.titulo is string
                    && request.resource.data.descricao is string
                    && request.resource.data.concluida is bool
                    && request.resource.data.concluida == false;

      allow update: if request.auth != null
                    && resource.data.usuarioId == request.auth.uid
                    && request.resource.data.usuarioId
                       == resource.data.usuarioId
                    && request.resource.data.titulo is string
                    && request.resource.data.descricao is string
                    && request.resource.data.concluida is bool;

      allow delete: if request.auth != null
                    && resource.data.usuarioId == request.auth.uid;
    }
  }
}
```

As consultas do aplicativo também filtram as tarefas pelo UID autenticado:

```dart
FirebaseFirestore.instance
    .collection('tarefas')
    .where(
      'usuarioId',
      isEqualTo: FirebaseAuth.instance.currentUser!.uid,
    )
    .orderBy(
      'criadoEm',
      descending: true,
    )
    .snapshots();
```

## Índice composto

A consulta combina filtro por `usuarioId` e ordenação por `criadoEm`. O Firestore pode solicitar a criação de um índice composto.

Configure o índice com os seguintes campos:

```text
Coleção: tarefas
usuarioId: Ascending
criadoEm: Descending
```

Se o índice ainda não existir, a mensagem de erro exibida durante a execução normalmente apresenta um link para criá-lo no Firebase Console.

## Registro dos controllers no GetIt

Exemplo de `service_locator.dart`:

```dart
import 'package:get_it/get_it.dart';

import 'controllers/cadastro_controller.dart';
import 'controllers/login_controller.dart';
import 'controllers/tarefa_controller.dart';

final GetIt getIt = GetIt.instance;

void configurarDependencias() {
  if (!getIt.isRegistered<LoginController>()) {
    getIt.registerLazySingleton<LoginController>(
      () => LoginController(),
    );
  }

  if (!getIt.isRegistered<CadastroController>()) {
    getIt.registerLazySingleton<CadastroController>(
      () => CadastroController(),
    );
  }

  if (!getIt.isRegistered<TarefaController>()) {
    getIt.registerLazySingleton<TarefaController>(
      () => TarefaController(),
    );
  }
}
```

Nas views, os controllers são recuperados desta forma:

```dart
final ctrl = GetIt.I.get<TarefaController>();
```

Como os controllers estendem `ChangeNotifier`, a interface pode observar as alterações por meio de `ListenableBuilder`:

```dart
ListenableBuilder(
  listenable: ctrl,
  builder: (context, child) {
    return const Placeholder();
  },
);
```

## Rotas

Exemplo de configuração no `MaterialApp`:

```dart
MaterialApp(
  debugShowCheckedModeBanner: false,
  title: 'Tarefas',
  initialRoute: '/login',
  routes: {
    '/login': (context) => const LoginView(),
    '/cadastro': (context) => const CadastroView(),
    '/esqueceu-senha': (context) => const EsqueceuSenhaView(),
    '/home': (context) => const HomeView(),
  },
);
```

## Fluxo do aplicativo

```text
Cadastro
  → Firebase Authentication cria a conta
  → Firestore grava usuarios/{uid}
  → Usuário permanece autenticado
  → Home

Login
  → Firebase Authentication valida as credenciais
  → Home
  → Firestore carrega o nome do usuário
  → Firestore acompanha as tarefas em tempo real

Home
  → Criar tarefa
  → Editar tarefa
  → Marcar como concluída ou pendente
  → Excluir tarefa
  → Sair
  → Login
```

## Executando o projeto

Com um dispositivo conectado ou emulador aberto, execute:

```bash
flutter run
```

Para selecionar uma plataforma específica:

```bash
flutter devices
flutter run -d ID_DO_DISPOSITIVO
```

## Validações implementadas

### Cadastro

- nome completo obrigatório;
- nome e sobrenome;
- e-mail obrigatório e válido;
- senha com pelo menos seis caracteres;
- confirmação obrigatória;
- senha e confirmação devem ser iguais.

### Login

- e-mail obrigatório e válido;
- senha obrigatória;
- tratamento dos erros retornados pelo Firebase Authentication.

### Tarefas

- título obrigatório;
- título entre 3 e 100 caracteres;
- descrição obrigatória;
- descrição entre 3 e 500 caracteres;
- novas tarefas iniciam com `concluida: false`;
- somente o proprietário pode visualizar, editar ou excluir a tarefa.

## Observações de segurança

- Não armazene senhas no Cloud Firestore;
- Não confie apenas no filtro realizado pelo aplicativo;
- Mantenha as regras de segurança do Firestore publicadas e revisadas;
- Não permita que o campo `usuarioId` seja alterado durante a edição;
- Evite iniciar o Firestore em modo de teste em ambientes de produção;
- Não envie arquivos de configuração sensíveis ou credenciais administrativas ao repositório;
- Use o Firebase Authentication como fonte de identidade do usuário.

## Possíveis melhorias

- pesquisa de tarefas;
- filtros por situação;
- ordenação configurável;
- categorias e prioridades;
- prazos e lembretes;
- paginação;
- exclusão de conta;
- verificação de e-mail;
- autenticação com Google;
- testes unitários dos controllers;
- testes dos fluxos com Firebase Emulator Suite;
- modo claro e escuro;
- acessibilidade e internacionalização.

## Licença

Este projeto pode ser utilizado para fins acadêmicos e educacionais. Caso seja distribuído publicamente, recomenda-se incluir uma licença adequada, como MIT, BSD ou Apache 2.0.
