// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Tradu-Git';

  @override
  String get betaVersion => 'Beta version.';

  @override
  String get loggingInGitHub => 'Signing in to GitHub...';

  @override
  String get loginWithGitHub => 'Sign in with GitHub';

  @override
  String get continueWithoutAccount => 'Continue without account';

  @override
  String get codeExchangeError => 'Error exchanging code for token.';

  @override
  String authError(String error) {
    return 'Error during authentication: $error';
  }

  @override
  String browserLaunchError(String error) {
    return 'Error launching browser: $error';
  }

  @override
  String get repositories => 'Repositories';

  @override
  String get searchRepositories => 'Search repositories...';

  @override
  String get cloneRepository => 'Clone Repository';

  @override
  String get cloneGitUrl => 'Clone from Git URL';

  @override
  String get enterRepositoryUrl => 'Enter Git repository URL';

  @override
  String get clone => 'Clone';

  @override
  String get cloningRepository => 'Cloning repository...';

  @override
  String get noRepositoriesFound => 'No repositories found.';

  @override
  String get connectGitHubToSeeRepos =>
      'Sign in with GitHub to view your repositories.';

  @override
  String get openWorkspace => 'Open Workspace';

  @override
  String get settings => 'Settings';

  @override
  String get fileExplorer => 'File Explorer';

  @override
  String get unsavedDrafts => 'Unsaved Drafts';

  @override
  String get gitChanges => 'Git Changes';

  @override
  String get branches => 'Branches';

  @override
  String get createBranch => 'Create Branch';

  @override
  String get switchBranch => 'Switch Branch';

  @override
  String get commitHistory => 'Commit History';

  @override
  String get commitMessage => 'Commit message';

  @override
  String get commit => 'Commit';

  @override
  String get commitAndPush => 'Commit & Push';

  @override
  String get push => 'Push Changes';

  @override
  String get pull => 'Pull Changes';

  @override
  String get saveFile => 'Save File';

  @override
  String get discardChanges => 'Discard Changes';

  @override
  String get noSelectedRepo => 'No repository selected.';

  @override
  String get fetchingGitStatus => 'Checking git status...';

  @override
  String get commitPushSuccess => 'Commit & Push successful';

  @override
  String commitError(String error) {
    return 'Commit error: $error';
  }

  @override
  String get noPendingChanges => 'No pending changes';

  @override
  String get wordWrap => 'Word Wrap';

  @override
  String get editorTheme => 'Editor Theme';

  @override
  String get simpleMode => 'Simple Mode';

  @override
  String get githubToken => 'GitHub Token';

  @override
  String connectedAs(String username) {
    return 'Connected as $username';
  }

  @override
  String get logout => 'Log Out';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get ok => 'OK';

  @override
  String get error => 'Error';

  @override
  String get folderNotConfigured => 'Folder not configured';

  @override
  String get selectFolderDescription =>
      'You must select a folder where your repositories will be stored.';

  @override
  String get configureNow => 'Configure now';

  @override
  String get folderNotExist => 'Selected folder does not exist.';

  @override
  String get retry => 'Retry';

  @override
  String clonedSuccess(String name) {
    return 'Cloned: $name';
  }

  @override
  String get cloneRepositoryTitle => 'Clone Repository';

  @override
  String get gitUrlHttps => 'HTTPS URL';

  @override
  String get gitHubList => 'GitHub List';

  @override
  String get gitUrlLabel => 'Git URL (HTTPS)';

  @override
  String get localFolderName => 'Local folder name';

  @override
  String get cloning => 'Cloning...';

  @override
  String readError(String error) {
    return 'Read error: $error';
  }

  @override
  String get starting => 'Starting...';

  @override
  String get syncingRepo => 'Syncing repository...';

  @override
  String get repoSynced => 'Repository synced.';

  @override
  String syncError(String error) {
    return 'Sync error: $error';
  }

  @override
  String get dirNotFound => 'Directory not found.';

  @override
  String fileReadError(String error) {
    return 'File read error: $error';
  }

  @override
  String createFileIn(String name) {
    return 'Create file in $name';
  }

  @override
  String createFolderIn(String name) {
    return 'Create folder in $name';
  }

  @override
  String get discardChangesQuestion => 'Discard changes?';

  @override
  String discardUnsavedChangesContent(String fileName) {
    return 'If you close this tab, all unsaved changes in $fileName will be lost.';
  }

  @override
  String get discard => 'Discard';

  @override
  String get sessionLoggedOut => 'GitHub session closed.';

  @override
  String discardLocalChangesContent(String relPath) {
    return 'This will revert all local changes in \"$relPath\" and they cannot be recovered.';
  }

  @override
  String changesDiscardedIn(String relPath) {
    return 'Changes discarded in $relPath';
  }

  @override
  String discardError(String error) {
    return 'Discard error: $error';
  }

  @override
  String get syncingPull => 'Syncing: Pulling...';

  @override
  String get syncingPush => 'Syncing: Pushing...';

  @override
  String get syncFinishedSuccess => 'Sync finished successfully.';

  @override
  String get fetchingChanges => 'Fetching changes...';

  @override
  String get ready => 'Ready.';

  @override
  String fetchError(String error) {
    return 'Fetch error: $error';
  }

  @override
  String get createNewBranchTitle => 'Create new branch';

  @override
  String get noLocalBranchesFound => 'No local branches found.';

  @override
  String get activeBranchLabel => 'Active';

  @override
  String branchLoaded(String branchName) {
    return 'Loaded branch: $branchName';
  }

  @override
  String get branchSwitchErrorTitle => 'Error switching branch';

  @override
  String get createBranchErrorTitle => 'Error creating branch';

  @override
  String branchCreatedAndLoaded(String branchName) {
    return 'Created and loaded branch: $branchName';
  }

  @override
  String get sync => 'Sync';

  @override
  String get editor => 'Editor';

  @override
  String get wordWrapSubtitle =>
      'Wrap lines to fit screen without horizontal scrolling.';

  @override
  String get themeDefault => 'Default';

  @override
  String get themeBlack => 'Black';

  @override
  String get simpleModeSubtitle =>
      'Automatic Git synchronization when opening and saving files.';

  @override
  String get enableSimpleModeTitle => 'Enable Simple Mode';

  @override
  String get simpleModeIntro =>
      'Simple Mode automates Git operations for easier syncing:';

  @override
  String get simpleModeDetails =>
      '• Opening a repo automatically runs fetch and pull operations.\n• Saving any file automatically commits and pushes changes.';

  @override
  String get simpleModeWarning =>
      '• If there are conflicting remote changes, automatic operations may fail and require manual intervention.';

  @override
  String get enable => 'Enable';

  @override
  String get gitHubSessionClosed => 'GitHub session closed.';

  @override
  String get gitHubSessionStarted => 'Signed in to GitHub.';

  @override
  String get writeCommitMessage => 'Write a message.';

  @override
  String get commitDone => 'Commit created.';

  @override
  String get fileExists => 'File already exists.';

  @override
  String get folderExists => 'Folder already exists.';

  @override
  String createdSuccess(String name) {
    return 'Created: $name';
  }

  @override
  String createError(String error) {
    return 'Error creating: $error';
  }

  @override
  String fileExplorerError(String error) {
    return 'Could not open file explorer: $error';
  }

  @override
  String get noChangesToCommit => 'No changes to commit';
}
