// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Tradu-Git';

  @override
  String get betaVersion => 'Versión beta.';

  @override
  String get loggingInGitHub => 'Iniciando sesión en GitHub...';

  @override
  String get loginWithGitHub => 'Iniciar Sesión con GitHub';

  @override
  String get continueWithoutAccount => 'Continuar sin cuenta';

  @override
  String get codeExchangeError => 'Error al intercambiar el código por token.';

  @override
  String authError(String error) {
    return 'Error durante la autenticación: $error';
  }

  @override
  String browserLaunchError(String error) {
    return 'Error al abrir el navegador: $error';
  }

  @override
  String get repositories => 'Repositorios';

  @override
  String get searchRepositories => 'Buscar repositorios...';

  @override
  String get cloneRepository => 'Clonar repositorio';

  @override
  String get cloneGitUrl => 'Clonar desde URL de Git';

  @override
  String get enterRepositoryUrl => 'Ingrese la URL del repositorio Git';

  @override
  String get clone => 'Clonar';

  @override
  String get cloningRepository => 'Clonando repositorio...';

  @override
  String get noRepositoriesFound => 'No se encontraron repositorios.';

  @override
  String get connectGitHubToSeeRepos =>
      'Inicia sesión con GitHub para ver tus repositorios.';

  @override
  String get openWorkspace => 'Abrir espacio de trabajo';

  @override
  String get settings => 'Configuración';

  @override
  String get fileExplorer => 'Explorador de archivos';

  @override
  String get unsavedDrafts => 'Archivos sin guardar';

  @override
  String get gitChanges => 'Cambios en Git';

  @override
  String get branches => 'Ramas';

  @override
  String get createBranch => 'Crear rama';

  @override
  String get switchBranch => 'Cambiar de rama';

  @override
  String get commitHistory => 'Historial de commits';

  @override
  String get commitMessage => 'Mensaje del commit';

  @override
  String get commit => 'Hacer commit';

  @override
  String get commitAndPush => 'Hacer commit y push';

  @override
  String get push => 'Subir cambios (Push)';

  @override
  String get pull => 'Obtener cambios (Pull)';

  @override
  String get saveFile => 'Guardar archivo';

  @override
  String get discardChanges => 'Descartar cambios';

  @override
  String get noSelectedRepo => 'Sin repositorio seleccionado.';

  @override
  String get fetchingGitStatus => 'Buscando cambios en git...';

  @override
  String get commitPushSuccess => 'Commit y Push exitoso';

  @override
  String commitError(String error) {
    return 'Error al hacer commit: $error';
  }

  @override
  String get noPendingChanges => 'Sin cambios pendientes';

  @override
  String get wordWrap => 'Ajuste de línea (Word Wrap)';

  @override
  String get editorTheme => 'Tema del editor';

  @override
  String get simpleMode => 'Modo simple';

  @override
  String get githubToken => 'Token de GitHub';

  @override
  String connectedAs(String username) {
    return 'Conectado como $username';
  }

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get ok => 'Aceptar';

  @override
  String get error => 'Error';
}
