import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'Tradu-Git'**
  String get appTitle;

  /// No description provided for @betaVersion.
  ///
  /// In es, this message translates to:
  /// **'Versión beta.'**
  String get betaVersion;

  /// No description provided for @loggingInGitHub.
  ///
  /// In es, this message translates to:
  /// **'Iniciando sesión en GitHub...'**
  String get loggingInGitHub;

  /// No description provided for @loginWithGitHub.
  ///
  /// In es, this message translates to:
  /// **'Iniciar Sesión con GitHub'**
  String get loginWithGitHub;

  /// No description provided for @continueWithoutAccount.
  ///
  /// In es, this message translates to:
  /// **'Continuar sin cuenta'**
  String get continueWithoutAccount;

  /// No description provided for @codeExchangeError.
  ///
  /// In es, this message translates to:
  /// **'Error al intercambiar el código por token.'**
  String get codeExchangeError;

  /// No description provided for @authError.
  ///
  /// In es, this message translates to:
  /// **'Error durante la autenticación: {error}'**
  String authError(String error);

  /// No description provided for @browserLaunchError.
  ///
  /// In es, this message translates to:
  /// **'Error al abrir el navegador: {error}'**
  String browserLaunchError(String error);

  /// No description provided for @repositories.
  ///
  /// In es, this message translates to:
  /// **'Repositorios'**
  String get repositories;

  /// No description provided for @searchRepositories.
  ///
  /// In es, this message translates to:
  /// **'Buscar repositorios...'**
  String get searchRepositories;

  /// No description provided for @cloneRepository.
  ///
  /// In es, this message translates to:
  /// **'Clonar repositorio'**
  String get cloneRepository;

  /// No description provided for @cloneGitUrl.
  ///
  /// In es, this message translates to:
  /// **'Clonar desde URL de Git'**
  String get cloneGitUrl;

  /// No description provided for @enterRepositoryUrl.
  ///
  /// In es, this message translates to:
  /// **'Ingrese la URL del repositorio Git'**
  String get enterRepositoryUrl;

  /// No description provided for @clone.
  ///
  /// In es, this message translates to:
  /// **'Clonar'**
  String get clone;

  /// No description provided for @cloningRepository.
  ///
  /// In es, this message translates to:
  /// **'Clonando repositorio...'**
  String get cloningRepository;

  /// No description provided for @noRepositoriesFound.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron repositorios.'**
  String get noRepositoriesFound;

  /// No description provided for @connectGitHubToSeeRepos.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión con GitHub para ver tus repositorios.'**
  String get connectGitHubToSeeRepos;

  /// No description provided for @openWorkspace.
  ///
  /// In es, this message translates to:
  /// **'Abrir espacio de trabajo'**
  String get openWorkspace;

  /// No description provided for @settings.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get settings;

  /// No description provided for @fileExplorer.
  ///
  /// In es, this message translates to:
  /// **'Explorador de archivos'**
  String get fileExplorer;

  /// No description provided for @unsavedDrafts.
  ///
  /// In es, this message translates to:
  /// **'Archivos sin guardar'**
  String get unsavedDrafts;

  /// No description provided for @gitChanges.
  ///
  /// In es, this message translates to:
  /// **'Cambios en Git'**
  String get gitChanges;

  /// No description provided for @branches.
  ///
  /// In es, this message translates to:
  /// **'Ramas'**
  String get branches;

  /// No description provided for @createBranch.
  ///
  /// In es, this message translates to:
  /// **'Crear rama'**
  String get createBranch;

  /// No description provided for @switchBranch.
  ///
  /// In es, this message translates to:
  /// **'Cambiar de rama'**
  String get switchBranch;

  /// No description provided for @commitHistory.
  ///
  /// In es, this message translates to:
  /// **'Historial de commits'**
  String get commitHistory;

  /// No description provided for @commitMessage.
  ///
  /// In es, this message translates to:
  /// **'Mensaje del commit'**
  String get commitMessage;

  /// No description provided for @commit.
  ///
  /// In es, this message translates to:
  /// **'Hacer commit'**
  String get commit;

  /// No description provided for @commitAndPush.
  ///
  /// In es, this message translates to:
  /// **'Hacer commit y push'**
  String get commitAndPush;

  /// No description provided for @push.
  ///
  /// In es, this message translates to:
  /// **'Subir cambios (Push)'**
  String get push;

  /// No description provided for @pull.
  ///
  /// In es, this message translates to:
  /// **'Obtener cambios (Pull)'**
  String get pull;

  /// No description provided for @saveFile.
  ///
  /// In es, this message translates to:
  /// **'Guardar archivo'**
  String get saveFile;

  /// No description provided for @discardChanges.
  ///
  /// In es, this message translates to:
  /// **'Descartar cambios'**
  String get discardChanges;

  /// No description provided for @noSelectedRepo.
  ///
  /// In es, this message translates to:
  /// **'Sin repositorio seleccionado.'**
  String get noSelectedRepo;

  /// No description provided for @fetchingGitStatus.
  ///
  /// In es, this message translates to:
  /// **'Buscando cambios en git...'**
  String get fetchingGitStatus;

  /// No description provided for @commitPushSuccess.
  ///
  /// In es, this message translates to:
  /// **'Commit y Push exitoso'**
  String get commitPushSuccess;

  /// No description provided for @commitError.
  ///
  /// In es, this message translates to:
  /// **'Error al hacer commit: {error}'**
  String commitError(String error);

  /// No description provided for @noPendingChanges.
  ///
  /// In es, this message translates to:
  /// **'Sin cambios pendientes'**
  String get noPendingChanges;

  /// No description provided for @wordWrap.
  ///
  /// In es, this message translates to:
  /// **'Ajuste de línea (Word Wrap)'**
  String get wordWrap;

  /// No description provided for @editorTheme.
  ///
  /// In es, this message translates to:
  /// **'Tema del editor'**
  String get editorTheme;

  /// No description provided for @simpleMode.
  ///
  /// In es, this message translates to:
  /// **'Modo simple'**
  String get simpleMode;

  /// No description provided for @githubToken.
  ///
  /// In es, this message translates to:
  /// **'Token de GitHub'**
  String get githubToken;

  /// No description provided for @connectedAs.
  ///
  /// In es, this message translates to:
  /// **'Conectado como {username}'**
  String connectedAs(String username);

  /// No description provided for @logout.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get logout;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get save;

  /// No description provided for @ok.
  ///
  /// In es, this message translates to:
  /// **'Aceptar'**
  String get ok;

  /// No description provided for @error.
  ///
  /// In es, this message translates to:
  /// **'Error'**
  String get error;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
