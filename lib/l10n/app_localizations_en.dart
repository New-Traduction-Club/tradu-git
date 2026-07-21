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
}
