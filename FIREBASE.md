# Ligando o DRIP ao Firebase

Hoje o app roda em **modo demonstração**: contas, Want List e catálogo ficam
só no aparelho, e os lançamentos são de exemplo. Este guia liga o app a um
projeto Firebase de verdade. Nenhuma linha de código do app precisa mudar.

> **Aviso honesto:** o código de Firebase está escrito e passa na análise,
> mas **nunca rodou contra um projeto real**. Reserve um tempo para testar
> cadastro, login, Want List e exclusão de conta depois de configurar.

## O que é grátis e o que é pago

| Recurso | Plano grátis (Spark) | Observação |
| --- | --- | --- |
| Login por e-mail e senha | Sim | |
| Firestore (catálogo, Want List) | Sim, com cota diária | Suficiente para começar |
| Receber push no aparelho (FCM) | Sim | |
| **Enviar** push automático ("seu drop abriu") | **Não** | Exige Cloud Functions, que só existem no plano **Blaze** (pago por uso, pede cartão) |
| Storage (fotos do catálogo) | Depende da data de criação do projeto | Projetos novos podem exigir o Blaze; dá para usar URLs de imagens hospedadas em outro lugar |

Não ative o Blaze sem decidir isso antes. O app funciona sem ele; só não
envia push sozinho.

## Passo a passo

### 1. Criar o projeto

1. Abra <https://console.firebase.google.com> e crie um projeto.
2. Em **Authentication → Sign-in method**, ative **E-mail/senha**.
3. Em **Firestore Database**, crie o banco em **modo de produção**
   (região sugerida: `southamerica-east1`, São Paulo).

### 2. Instalar as ferramentas (uma vez)

```bash
npm install -g firebase-tools
```

```bash
firebase login
```

```bash
C:\src\flutter\bin\dart.bat pub global activate flutterfire_cli
```

### 3. Conectar o app ao projeto

As chaves do projeto **não ficam no código** (o repositório é público).
Dentro da pasta `drip`:

1. Copie `firebase.local.example.json` para `firebase.local.json`.
2. Preencha com os valores de **Configurações do projeto → Seus apps**
   (um app Web, um Android e, se quiser, um iOS). O Windows usa o app Web.
3. Rode o app passando o arquivo:

```bash
flutter run --dart-define-from-file=firebase.local.json
```

Ou use `.\tool\dev.ps1 -Real`, que faz o mesmo. Sem o arquivo, o app abre
em modo demonstração. `firebase.local.json`, `google-services.json`,
`GoogleService-Info.plist` e `web/firebase-messaging-sw.local.js` estão no
`.gitignore`: nunca os envie para o GitHub.

Para o login com Google no Android, baixe também o `google-services.json`
para `android/app/` (o plugin só é aplicado se o arquivo existir).

O identificador do app nas duas lojas é `com.dripapp.drip`.

### 4. Publicar as regras de segurança

```bash
firebase deploy --only firestore:rules,firestore:indexes --project SEU_PROJETO
```

Se for usar o Storage para as fotos:

```bash
firebase deploy --only storage --project SEU_PROJETO
```

Sem este passo o banco fica fechado (modo de produção nega tudo) e o app
mostra telas de erro.

### 5. Marcar a sua conta como equipe (admin)

Só contas com a marcação `admin: true` podem cadastrar marcas e drops pelas
regras. Essa marcação só pode ser gravada pelo Admin SDK. Crie sua conta no
app, copie o UID em **Authentication → Users** e rode, numa pasta qualquer
com `npm install firebase-admin` e a chave de serviço baixada em
**Configurações do projeto → Contas de serviço**:

```js
// marcar-admin.mjs  —  uso: node marcar-admin.mjs SEU_UID
import { initializeApp, cert } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { readFileSync } from 'node:fs';

initializeApp({
  credential: cert(JSON.parse(readFileSync('./chave-de-servico.json', 'utf8'))),
});
await getAuth().setCustomUserClaims(process.argv[2], { admin: true });
console.log('Pronto. Saia e entre de novo no app para valer.');
```

**Nunca** coloque a chave de serviço dentro da pasta do app nem a envie
para o GitHub: ela dá acesso total ao projeto.

Enquanto não houver um painel de administração, o catálogo pode ser
cadastrado direto no console do Firebase (que ignora as regras).

### 6. Cadastrar o catálogo

**`brands/{id}`**

| Campo | Tipo | Obrigatório |
| --- | --- | --- |
| `name` | texto | sim |
| `tagline` | texto | sim |
| `description` | texto | sim |
| `websiteUrl`, `logoUrl`, `coverUrl`, `origin` | texto | não |
| `tone` | número inteiro (variação de cor do fundo da arte; padrão 0) | não |

**`drops/{id}`**

| Campo | Tipo | Obrigatório |
| --- | --- | --- |
| `published` | booleano — **só aparece no app se for `true`** | sim |
| `name` | texto | sim |
| `brandId` | texto (id do documento da marca) | sim |
| `brandName` | texto | sim |
| `category` | `sneakers`, `apparel` ou `accessories` | sim |
| `description` | texto | sim |
| `releaseAt` | data e hora (vazio = "data a definir") | não |
| `hasTime` | booleano (`true` se o horário é confirmado) | não |
| `price` | número | não |
| `currency` | texto (padrão `BRL`) | não |
| `officialUrl` | texto — destino do botão "Comprar no site da marca" | não |
| `imageUrls` | lista de textos | não |
| `featured` | booleano (vai para o pôster do Discover) | não |
| `colorway` | texto | não |
| `art` | `sneaker`, `hoodie`, `tee`, `cap` ou `bag` (silhueta usada sem foto) | não |
| `tone` | número | não |
| `createdAt`, `updatedAt` | data e hora | sim |

## Como os dados de cada pessoa ficam guardados

- `users/{uid}` — `name`, `email`, `createdAt`, `updatedAt` e as listas
  `wantList`, `following`, `interests`, `notifOff`, `readActivity`.
- `users/{uid}/tokens/{id}` — aparelhos que aceitaram receber push.
- `users/{uid}/notifications/{id}` — avisos gravados pelo servidor
  (`title`, `body`, `at`, e opcionalmente `dropId`, `brandId`). O app só lê.

Só a própria pessoa lê e altera o que é dela (`firestore.rules`). Excluir a
conta apaga esse documento, os aparelhos, os avisos e o login.

Limites definidos nas regras: 1000 itens na Want List, 500 marcas
acompanhadas, 5000 atividades marcadas como lidas.

## O que ainda não existe

- **Envio de push.** O app pede permissão e registra o aparelho, mas nada
  dispara as notificações. Falta uma Cloud Function agendada (plano Blaze)
  que leia os drops prestes a abrir, encontre quem salvou e envie pelo FCM.
- **Push na web.** Exige chave VAPID e service worker próprios; ficou fora.
- **iOS.** Além do `flutterfire configure`, o push precisa de uma chave APNs
  (conta paga de desenvolvedor Apple) e da capability "Push Notifications"
  no Xcode, que só roda em Mac.
- **Painel de administração** para cadastrar drops sem abrir o console.
- **Testes das regras** com o emulador do Firebase.

## Desenvolvimento com dados prontos (Firebase local)

Para abrir o app já com catálogo e contas, sem tocar no projeto real nem
gastar cota, use os emuladores do Firebase:

```powershell
.\tool\dev.ps1               # escolhe o aparelho, como o flutter run
.\tool\dev.ps1 -d chrome     # qualquer argumento vai para o flutter run
.\tool\dev.ps1 -Celular      # celular físico na mesma rede Wi-Fi
```

O script liga os emuladores (Authentication e Firestore) numa janela
separada, grava marcas, drops e contas de teste (`tool/seed_emulator.dart`)
e roda `flutter run --dart-define=DRIP_EMULATOR=true`.

- Contas de teste e senha: veja o topo de `tool/seed_emulator.dart`
  (uma pessoa com Want List e avisos, uma conta vazia e uma da equipe).
- Painel para ver e editar os dados: http://localhost:4000
- Ctrl+C na janela dos emuladores salva tudo em `.emulator-data`, que volta
  na próxima vez. Apague essa pasta para começar do zero.
- Precisa de Java 21+: o script usa o que vem com o Android Studio.
- No emulador do Android o app acha o computador sozinho (`10.0.2.2`). No
  celular físico, o Windows pode pedir para liberar o Java no firewall.
- Na web, o Firebase mostra uma faixa vermelha de "emulator mode" sobre a
  barra de abas. É só um aviso de desenvolvimento.

### No Windows (app de computador)

```powershell
.\tool\dev.ps1 -d windows                                  # Firebase local, com dados
.\tool\dev.ps1 -Real -d windows                            # Firebase real (firebase.local.json)
```

- O Windows usa a mesma configuração do app web (`firebase_options.dart`).
- O primeiro build baixa o SDK C++ do Firebase e demora alguns minutos.
- No Windows não há push nem login com Google (os plugins não existem
  nessa plataforma); o botão do Google some sozinho. E-mail e senha
  funcionam normalmente.
