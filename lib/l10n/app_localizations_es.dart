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

  @override
  String get folderNotConfigured => 'Carpeta no configurada';

  @override
  String get selectFolderDescription =>
      'Debes seleccionar una carpeta donde se almacenarán tus repositorios.';

  @override
  String get configureNow => 'Configurar ahora';

  @override
  String get folderNotExist => 'La carpeta seleccionada no existe.';

  @override
  String get retry => 'Reintentar';

  @override
  String clonedSuccess(String name) {
    return 'Clonado: $name';
  }

  @override
  String get cloneRepositoryTitle => 'Clonar Repositorio';

  @override
  String get gitUrlHttps => 'URL HTTPS';

  @override
  String get gitHubList => 'Lista de GitHub';

  @override
  String get gitUrlLabel => 'URL Git (HTTPS)';

  @override
  String get localFolderName => 'Nombre de la carpeta local';

  @override
  String get cloning => 'Clonando...';

  @override
  String readError(String error) {
    return 'Error al leer: $error';
  }

  @override
  String get starting => 'Iniciando...';

  @override
  String get syncingRepo => 'Sincronizando repositorio...';

  @override
  String get repoSynced => 'Repositorio sincronizado.';

  @override
  String syncError(String error) {
    return 'Error al sincronizar: $error';
  }

  @override
  String get dirNotFound => 'Directorio no encontrado.';

  @override
  String fileReadError(String error) {
    return 'Error al leer archivos: $error';
  }

  @override
  String createFileIn(String name) {
    return 'Crear archivo en $name';
  }

  @override
  String createFolderIn(String name) {
    return 'Crear carpeta en $name';
  }

  @override
  String get discardChangesQuestion => '¿Descartar cambios?';

  @override
  String discardUnsavedChangesContent(String fileName) {
    return 'Si cierras esta pestaña, se perderán todos los cambios no guardados en $fileName.';
  }

  @override
  String get discard => 'Descartar';

  @override
  String get sessionLoggedOut => 'Sesión de GitHub cerrada.';

  @override
  String discardLocalChangesContent(String relPath) {
    return 'Esto revertirá todos los cambios locales en \"$relPath\" y no se pueden recuperar.';
  }

  @override
  String changesDiscardedIn(String relPath) {
    return 'Cambios descartados en $relPath';
  }

  @override
  String discardError(String error) {
    return 'Error al descartar cambios: $error';
  }

  @override
  String get syncingPull => 'Sincronizando: Haciendo Pull...';

  @override
  String get syncingPush => 'Sincronizando: Haciendo Push...';

  @override
  String get syncFinishedSuccess => 'Sincronización finalizada con éxito.';

  @override
  String get fetchingChanges => 'Buscando cambios (Fetch)...';

  @override
  String get ready => 'Listo.';

  @override
  String fetchError(String error) {
    return 'Error al buscar cambios: $error';
  }

  @override
  String get createNewBranchTitle => 'Crear nueva rama';

  @override
  String get noLocalBranchesFound => 'No se encontraron ramas locales.';

  @override
  String get activeBranchLabel => 'Activa';

  @override
  String branchLoaded(String branchName) {
    return 'Cargada rama: $branchName';
  }

  @override
  String get branchSwitchErrorTitle => 'Error al cambiar de rama';

  @override
  String get createBranchErrorTitle => 'Error al crear rama';

  @override
  String branchCreatedAndLoaded(String branchName) {
    return 'Creada y cargada rama: $branchName';
  }

  @override
  String get sync => 'Sincronizar';

  @override
  String get editor => 'Editor';

  @override
  String get wordWrapSubtitle =>
      'Ajustar líneas para que quepan en la pantalla sin movimiento horizontal.';

  @override
  String get themeDefault => 'Por defecto';

  @override
  String get themeBlack => 'Negro';

  @override
  String get simpleModeSubtitle =>
      'Sincronización automática de Git al abrir y guardar archivos.';

  @override
  String get enableSimpleModeTitle => 'Activar Modo Simple';

  @override
  String get simpleModeIntro =>
      'El Modo Simple automatiza las operaciones de Git para facilitar la sincronización:';

  @override
  String get simpleModeDetails =>
      '• Al abrir un repositorio, se realizarán automáticamente las operaciones de búsqueda y obtención de cambios.\n• Al guardar cualquier archivo se creará un commit automático y se enviarán los cambios.';

  @override
  String get simpleModeWarning =>
      '• Si hay cambios conflictivos en el repositorio remoto, las operaciones automáticas podrían fallar y requerir interacción humana.';

  @override
  String get enable => 'Activar';

  @override
  String get gitHubSessionClosed => 'Sesión de GitHub cerrada.';

  @override
  String get gitHubSessionStarted => 'Sesión iniciada en GitHub.';

  @override
  String get writeCommitMessage => 'Escribe un mensaje.';

  @override
  String get commitDone => 'Commit hecho.';

  @override
  String get fileExists => 'El archivo ya existe.';

  @override
  String get folderExists => 'La carpeta ya existe.';

  @override
  String createdSuccess(String name) {
    return 'Creado: $name';
  }

  @override
  String createError(String error) {
    return 'Error al crear: $error';
  }

  @override
  String fileExplorerError(String error) {
    return 'No se pudo abrir el explorador de archivos: $error';
  }

  @override
  String get noChangesToCommit => 'Sin cambios para hacer commit';
}
