use std::path::Path;
use git2::{Repository, StatusOptions};
use crate::log_msg;

#[flutter_rust_bridge::frb(sync)] // Synchronous check is fast
pub fn greet(name: String) -> String {
    format!("Hello, {name}!")
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
    log_msg("Rust Backend: init_app() started.");

    log_msg("Rust Backend: Disabling owner validation globally...");
    unsafe {
        libgit2_sys::git_libgit2_opts(
            libgit2_sys::GIT_OPT_SET_OWNER_VALIDATION as std::os::raw::c_int,
            0,
        );
    }
    log_msg("Rust Backend: Owner validation disabled.");

    // Probe and set system CA certificate directory on Android.
    let cert_dirs = [
        "/system/etc/security/cacerts",
        "/apex/com.android.consent/etc/security/cacerts",
        "/apex/com.android.runtime/etc/security/cacerts",
        "/etc/security/cacerts",
    ];
    for dir in cert_dirs {
        if Path::new(dir).exists() {
            log_msg(&format!("Rust Backend: Probing cert directory: {}", dir));
            unsafe {
                if git2::opts::set_ssl_cert_dir(dir).is_ok() {
                    log_msg(&format!("Rust Backend: set_ssl_cert_dir set to: {}", dir));
                    break;
                }
            }
        }
    }
}

pub fn setup_ssl_certificates(files_dir: String) -> Result<String, String> {
    log_msg(&format!("Rust Backend: setup_ssl_certificates compatibility stub called with files_dir: {}", files_dir));
    log_msg("Rust Backend: Skipping certificate bundling since SSL verification is bypassed via remote callbacks.");
    Ok("Bypassed".to_string())
}

#[flutter_rust_bridge::frb(sync)]
pub fn has_git_repo(path: String) -> bool {
    Path::new(&path).join(".git").exists()
}

pub fn git_clone(url: String, path: String) -> Result<String, String> {
    use git2::build::RepoBuilder;
    use git2::FetchOptions;

    log_msg(&format!("Rust Backend: Cloning {} into {}", url, path));

    let mut callbacks = git2::RemoteCallbacks::new();

    // Attach custom certificate validation callback for Android to bypass OpenSSL trust store reads.
    #[cfg(target_os = "android")]
    callbacks.certificate_check(|_cert, _valid| {
        log_msg("Rust Backend: certificate_check callback invoked, accepting certificate.");
        Ok(git2::CertificateCheckStatus::CertificateOk)
    });

    let mut fetch_opts = FetchOptions::new();
    fetch_opts.remote_callbacks(callbacks);

    let mut builder = RepoBuilder::new();
    builder.fetch_options(fetch_opts);

    match builder.clone(&url, Path::new(&path)) {
        Ok(_) => {
            log_msg("Rust Backend: Clone completed successfully!");
            Ok("Success".to_string())
        }
        Err(e) => {
            log_msg(&format!("Rust Backend: Clone failed: {}", e));
            Err(e.to_string())
        }
    }
}

pub fn git_status(path: String) -> Result<String, String> {
    let repo = Repository::open(&path).map_err(|e| format!("Failed to open repository: {}", e))?;
    
    let mut opts = StatusOptions::new();
    opts.include_untracked(true);
    let statuses = repo.statuses(Some(&mut opts)).map_err(|e| format!("Failed to get status: {}", e))?;
    
    let mut output = String::new();
    
    let branch_name = match repo.head() {
        Ok(head) => head.shorthand().unwrap_or("unknown").to_string(),
        Err(_) => "Detached HEAD or no commits".to_string(),
    };
    output.push_str(&format!("On branch {}\n", branch_name));
    
    let mut staged = Vec::new();
    let mut unstaged = Vec::new();
    let mut untracked = Vec::new();
    
    for entry in statuses.iter() {
        let file_path = entry.path().unwrap_or("unknown");
        let status = entry.status();
        
        if status.is_index_new() || status.is_index_modified() || status.is_index_deleted() || status.is_index_renamed() || status.is_index_typechange() {
            staged.push((file_path.to_string(), status));
        }
        
        if status.is_wt_modified() || status.is_wt_deleted() || status.is_wt_typechange() || status.is_wt_renamed() {
            unstaged.push((file_path.to_string(), status));
        }
        
        if status.is_wt_new() {
            untracked.push(file_path.to_string());
        }
    }
    
    if !staged.is_empty() {
        output.push_str("\nChanges to be committed:\n");
        for (f, s) in staged {
            let mode = if s.is_index_new() { "new file" } else if s.is_index_deleted() { "deleted" } else { "modified" };
            output.push_str(&format!("  {}: {}\n", mode, f));
        }
    }
    
    if !unstaged.is_empty() {
        output.push_str("\nChanges not staged for commit:\n");
        for (f, s) in unstaged {
            let mode = if s.is_wt_deleted() { "deleted" } else { "modified" };
            output.push_str(&format!("  {}: {}\n", mode, f));
        }
    }
    
    if !untracked.is_empty() {
        output.push_str("\nUntracked files:\n");
        for f in untracked {
            output.push_str(&format!("  {}\n", f));
        }
    }
    
    if output.len() == format!("On branch {}\n", branch_name).len() {
        output.push_str("\nnothing to commit, working tree clean\n");
    }
    
    Ok(output)
}

pub fn git_add(path: String, file_path: String) -> Result<String, String> {
    let repo = Repository::open(&path).map_err(|e| format!("Failed to open repository: {}", e))?;
    let mut index = repo.index().map_err(|e| format!("Failed to get repository index: {}", e))?;
    index.add_path(Path::new(&file_path)).map_err(|e| format!("Failed to add file to index: {}", e))?;
    index.write().map_err(|e| format!("Failed to write index: {}", e))?;
    log_msg(&format!("Rust Backend: Added {} to index", file_path));
    Ok("Success".to_string())
}

pub fn git_reset(path: String, file_path: String) -> Result<String, String> {
    let repo = Repository::open(&path).map_err(|e| format!("Failed to open repository: {}", e))?;
    
    let head = repo.head().and_then(|h| h.peel(git2::ObjectType::Commit));
    match head {
        Ok(head_obj) => {
            repo.reset_default(Some(&head_obj), &[&file_path])
                .map_err(|e| format!("Failed to reset default path: {}", e))?;
        }
        Err(_) => {
            let mut index = repo.index().map_err(|e| format!("Failed to get repository index: {}", e))?;
            index.remove_path(Path::new(&file_path)).map_err(|e| format!("Failed to remove file from index: {}", e))?;
            index.write().map_err(|e| format!("Failed to write index: {}", e))?;
        }
    }
    log_msg(&format!("Rust Backend: Reset {} in index", file_path));
    Ok("Success".to_string())
}

pub fn git_commit(
    path: String,
    message: String,
    author_name: String,
    author_email: String,
) -> Result<String, String> {
    let repo = Repository::open(&path).map_err(|e| format!("Failed to open repository: {}", e))?;
    let mut index = repo.index().map_err(|e| format!("Failed to get repository index: {}", e))?;
    let tree_id = index.write_tree().map_err(|e| format!("Failed to write index tree: {}", e))?;
    let tree = repo.find_tree(tree_id).map_err(|e| format!("Failed to find tree: {}", e))?;

    let sig = git2::Signature::now(&author_name, &author_email)
        .map_err(|e| format!("Failed to create signature: {}", e))?;

    let parent_commit = match repo.head().and_then(|h| h.peel_to_commit()) {
        Ok(c) => Some(c),
        Err(_) => None,
    };

    let parents = match &parent_commit {
        Some(c) => vec![c],
        None => vec![],
    };

    repo.commit(
        Some("HEAD"),
        &sig,
        &sig,
        &message,
        &tree,
        &parents,
    ).map_err(|e| format!("Failed to create commit: {}", e))?;

    log_msg(&format!("Rust Backend: Created commit with message: {}", message));
    Ok("Success".to_string())
}

pub fn git_push(
    path: String,
    remote_name: String,
    branch_name: String,
    username: Option<String>,
    password: Option<String>,
) -> Result<String, String> {
    let repo = Repository::open(&path).map_err(|e| format!("Failed to open repository: {}", e))?;
    let mut remote = repo.find_remote(&remote_name).map_err(|e| format!("Failed to find remote: {}", e))?;
    
    let mut callbacks = git2::RemoteCallbacks::new();
    
    #[cfg(target_os = "android")]
    callbacks.certificate_check(|_cert, _valid| {
        Ok(git2::CertificateCheckStatus::CertificateOk)
    });
    
    let u_opt = username.clone();
    let p_opt = password.clone();
    if u_opt.is_some() || p_opt.is_some() {
        callbacks.credentials(move |_url, username_from_url, _allowed_types| {
            let u = u_opt.as_deref().or(username_from_url).unwrap_or("git");
            let p = p_opt.as_deref().unwrap_or("");
            git2::Cred::userpass_plaintext(u, p)
        });
    }

    let mut push_opts = git2::PushOptions::new();
    push_opts.remote_callbacks(callbacks);

    let refspec = format!("refs/heads/{}:refs/heads/{}", branch_name, branch_name);
    remote.push(&[&refspec], Some(&mut push_opts)).map_err(|e| format!("Push failed: {}", e))?;
    
    log_msg("Rust Backend: Push completed successfully.");
    Ok("Success".to_string())
}

pub fn git_pull(
    path: String,
    remote_name: String,
    branch_name: String,
    username: Option<String>,
    password: Option<String>,
    author_name: Option<String>,
    author_email: Option<String>,
) -> Result<String, String> {
    let repo = Repository::open(&path).map_err(|e| format!("Failed to open repository: {}", e))?;
    let mut remote = repo.find_remote(&remote_name).map_err(|e| format!("Failed to find remote: {}", e))?;

    let mut callbacks = git2::RemoteCallbacks::new();
    
    #[cfg(target_os = "android")]
    callbacks.certificate_check(|_cert, _valid| {
        Ok(git2::CertificateCheckStatus::CertificateOk)
    });
    
    let u_opt = username.clone();
    let p_opt = password.clone();
    if u_opt.is_some() || p_opt.is_some() {
        callbacks.credentials(move |_url, username_from_url, _allowed_types| {
            let u = u_opt.as_deref().or(username_from_url).unwrap_or("git");
            let p = p_opt.as_deref().unwrap_or("");
            git2::Cred::userpass_plaintext(u, p)
        });
    }

    let mut fetch_opts = git2::FetchOptions::new();
    fetch_opts.remote_callbacks(callbacks);

    remote.fetch(&[&branch_name], Some(&mut fetch_opts), None)
        .map_err(|e| format!("Fetch failed: {}", e))?;

    let fetch_head = repo.find_reference("FETCH_HEAD")
        .map_err(|e| format!("Failed to find FETCH_HEAD: {}", e))?;
    let fetch_commit = repo.reference_to_annotated_commit(&fetch_head)
        .map_err(|e| format!("Failed to peel FETCH_HEAD: {}", e))?;

    let analysis = repo.merge_analysis(&[&fetch_commit])
        .map_err(|e| format!("Merge analysis failed: {}", e))?;

    if analysis.0.is_up_to_date() {
        log_msg("Rust Backend: Pull completed. Already up to date.");
        return Ok("Up-to-date".to_string());
    } else if analysis.0.is_fast_forward() {
        let refname = format!("refs/heads/{}", branch_name);
        let mut reference = repo.find_reference(&refname)
            .map_err(|e| format!("Failed to find reference {}: {}", refname, e))?;
        
        reference.set_target(fetch_commit.id(), "Fast-Forward")
            .map_err(|e| format!("Failed to set reference target: {}", e))?;
        repo.set_head(&refname)
            .map_err(|e| format!("Failed to set HEAD: {}", e))?;
        repo.checkout_head(Some(git2::build::CheckoutBuilder::default().force()))
            .map_err(|e| format!("Checkout failed: {}", e))?;

        log_msg("Rust Backend: Pull completed via Fast-Forward.");
        Ok("Success-FF".to_string())
    } else if analysis.0.is_normal() {
        log_msg("Rust Backend: Non-fast-forward merge (normal merge) required.");
        
        repo.merge(&[&fetch_commit], None, None)
            .map_err(|e| format!("Merge failed: {}", e))?;

        let mut index = repo.index().map_err(|e| format!("Failed to get repository index: {}", e))?;
        if index.has_conflicts() {
            log_msg("Rust Backend: Merge conflicts detected. Rolling back merge state...");
            // Roll back the merge state
            let _ = repo.cleanup_state();
            let mut checkout_opts = git2::build::CheckoutBuilder::new();
            checkout_opts.force();
            let _ = repo.checkout_head(Some(&mut checkout_opts));
            return Err("Non-fast-forward merge required. Conflict resolution is not supported yet.".to_string());
        }

        let tree_id = index.write_tree().map_err(|e| format!("Failed to write index tree: {}", e))?;
        let tree = repo.find_tree(tree_id).map_err(|e| format!("Failed to find merged tree: {}", e))?;

        let head_commit = repo.head()
            .and_then(|h| h.peel_to_commit())
            .map_err(|e| format!("Failed to find HEAD commit: {}", e))?;
        let remote_commit = repo.find_commit(fetch_commit.id())
            .map_err(|e| format!("Failed to find remote commit: {}", e))?;

        // Retrieve standard merge message written by libgit2
        let msg = repo.message().unwrap_or_else(|_| format!("Merge branch '{}'", branch_name));

        // Get signature details from parameters or configuration
        let name = author_name.clone().unwrap_or_else(|| {
            repo.config().ok()
                .and_then(|c| c.get_string("user.name").ok())
                .unwrap_or_else(|| "Git User".to_string())
        });
        let email = author_email.clone().unwrap_or_else(|| {
            repo.config().ok()
                .and_then(|c| c.get_string("user.email").ok())
                .unwrap_or_else(|| "git@user.com".to_string())
        });

        let sig = git2::Signature::now(&name, &email)
            .map_err(|e| format!("Failed to create signature: {}", e))?;

        repo.commit(
            Some("HEAD"),
            &sig,
            &sig,
            &msg,
            &tree,
            &[&head_commit, &remote_commit],
        ).map_err(|e| format!("Failed to create merge commit: {}", e))?;

        repo.cleanup_state().map_err(|e| format!("Failed to clean merge state: {}", e))?;
        repo.checkout_head(None).map_err(|e| format!("Checkout after merge failed: {}", e))?;

        log_msg("Rust Backend: Merge commit created and pull completed successfully.");
        Ok("Success-Merge".to_string())
    } else {
        log_msg("Rust Backend: Unknown merge analysis result.");
        Err("Unknown merge analysis result. Cannot pull.".to_string())
    }
}

pub fn run_command(path: String, command_line: String) -> Result<String, String> {
    use std::process::Command;

    log_msg(&format!("Rust Backend: Executing command: {} in {}", command_line, path));

    let output = Command::new("sh")
        .arg("-c")
        .arg(&command_line)
        .current_dir(Path::new(&path))
        .output();

    match output {
        Ok(out) => {
            let stdout = String::from_utf8_lossy(&out.stdout).to_string();
            let stderr = String::from_utf8_lossy(&out.stderr).to_string();
            
            let mut result = String::new();
            if !stdout.is_empty() {
                result.push_str(&stdout);
            }
            if !stderr.is_empty() {
                if !result.is_empty() {
                    result.push_str("\n");
                }
                result.push_str("Error:\n");
                result.push_str(&stderr);
            }
            
            if result.is_empty() {
                result = format!("Command exited with status code: {}", out.status);
            }
            Ok(result)
        }
        Err(e) => {
            log_msg(&format!("Rust Backend: Failed to run command: {}", e));
            Err(format!("Failed to run command: {}", e))
        }
    }
}

pub struct GitCommitInfo {
    pub hash: String,
    pub author: String,
    pub email: String,
    pub time: i64,
    pub message: String,
}

pub fn git_log(path: String, max_count: usize) -> Result<Vec<GitCommitInfo>, String> {
    let repo = Repository::open(&path).map_err(|e| format!("Failed to open repository: {}", e))?;
    
    let head = match repo.head() {
        Ok(h) => h,
        Err(_) => return Ok(vec![]), // No commits yet
    };
    
    let mut revwalk = repo.revwalk().map_err(|e| format!("Failed to create revwalk: {}", e))?;
    revwalk.push_head().map_err(|e| format!("Failed to push HEAD to revwalk: {}", e))?;
    
    let mut commits = Vec::new();
    for id_result in revwalk.take(max_count) {
        let id = id_result.map_err(|e| format!("Failed in revwalk iteration: {}", e))?;
        let commit = repo.find_commit(id).map_err(|e| format!("Failed to find commit: {}", e))?;
        
        let author = commit.author();
        commits.push(GitCommitInfo {
            hash: id.to_string(),
            author: author.name().unwrap_or("unknown").to_string(),
            email: author.email().unwrap_or("unknown").to_string(),
            time: commit.time().seconds(),
            message: commit.message().unwrap_or("").to_string(),
        });
    }
    
    Ok(commits)
}

pub fn git_discard_changes(path: String, file_path: String) -> Result<String, String> {
    let repo = Repository::open(&path).map_err(|e| format!("Failed to open repository: {}", e))?;
    
    let status = repo.status_file(std::path::Path::new(&file_path));
    let is_untracked = match status {
        Ok(s) => s.is_wt_new(),
        Err(_) => false,
    };

    if is_untracked {
        let full_path = std::path::Path::new(&path).join(&file_path);
        if full_path.exists() {
            if full_path.is_dir() {
                std::fs::remove_dir_all(&full_path).map_err(|e| format!("Failed to delete directory: {}", e))?;
            } else {
                std::fs::remove_file(&full_path).map_err(|e| format!("Failed to delete file: {}", e))?;
            }
            Ok(format!("Deleted untracked file {}", file_path))
        } else {
            Err(format!("File does not exist: {}", file_path))
        }
    } else {
        let mut checkout_opts = git2::build::CheckoutBuilder::new();
        checkout_opts.force();
        checkout_opts.path(&file_path);
        
        repo.checkout_head(Some(&mut checkout_opts))
            .map_err(|e| format!("Failed to discard changes: {}", e))?;
        Ok(format!("Discarded changes in {}", file_path))
    }
}

pub fn git_fetch(
    path: String,
    remote_name: String,
    branch_name: String,
    username: Option<String>,
    password: Option<String>,
) -> Result<String, String> {
    let repo = Repository::open(&path).map_err(|e| format!("Failed to open repository: {}", e))?;
    let mut remote = repo.find_remote(&remote_name).map_err(|e| format!("Failed to find remote: {}", e))?;

    let mut callbacks = git2::RemoteCallbacks::new();
    
    #[cfg(target_os = "android")]
    callbacks.certificate_check(|_cert, _valid| {
        Ok(git2::CertificateCheckStatus::CertificateOk)
    });
    
    let u_opt = username.clone();
    let p_opt = password.clone();
    if u_opt.is_some() || p_opt.is_some() {
        callbacks.credentials(move |_url, username_from_url, _allowed_types| {
            let u = u_opt.as_deref().or(username_from_url).unwrap_or("git");
            let p = p_opt.as_deref().unwrap_or("");
            git2::Cred::userpass_plaintext(u, p)
        });
    }

    let mut fetch_opts = git2::FetchOptions::new();
    fetch_opts.remote_callbacks(callbacks);

    remote.fetch(&[&branch_name], Some(&mut fetch_opts), None)
        .map_err(|e| format!("Fetch failed: {}", e))?;

    Ok("Fetch successful".to_string())
}

pub struct GitCompareInfo {
    pub ahead: usize,
    pub behind: usize,
}

pub fn git_compare_branches(
    path: String,
    local_branch: String,
    remote_name: String,
) -> Result<GitCompareInfo, String> {
    let repo = Repository::open(&path).map_err(|e| format!("Failed to open repository: {}", e))?;
    
    let local_refname = format!("refs/heads/{}", local_branch);
    let local_ref = repo.find_reference(&local_refname)
        .map_err(|e| format!("Failed to find local branch {}: {}", local_branch, e))?;
    let local_oid = local_ref.target()
        .ok_or_else(|| "Local branch does not point to a valid commit".to_string())?;

    let remote_refname = format!("refs/remotes/{}/{}", remote_name, local_branch);
    let remote_oid = if let Ok(remote_ref) = repo.find_reference(&remote_refname) {
        remote_ref.target().ok_or_else(|| "Remote branch does not point to a valid commit".to_string())?
    } else {
        if let Ok(fetch_head) = repo.find_reference("FETCH_HEAD") {
            fetch_head.target().ok_or_else(|| "FETCH_HEAD is invalid".to_string())?
        } else {
            return Ok(GitCompareInfo { ahead: 0, behind: 0 });
        }
    };

    let (ahead, behind) = repo.graph_ahead_behind(local_oid, remote_oid)
        .map_err(|e| format!("Failed to calculate ahead/behind: {}", e))?;

    Ok(GitCompareInfo { ahead, behind })
}

pub fn git_current_branch(path: String) -> Result<String, String> {
    let repo = Repository::open(&path).map_err(|e| format!("Failed to open repository: {}", e))?;
    if repo.is_empty().unwrap_or(false) {
        return Ok("master".to_string());
    }
    if let Ok(head) = repo.head() {
        if let Some(shorthand) = head.shorthand() {
            return Ok(shorthand.to_string());
        }
    }
    if let Ok(r) = repo.find_reference("HEAD") {
        if let Some(target) = r.symbolic_target() {
            return Ok(target.strip_prefix("refs/heads/").unwrap_or(target).to_string());
        }
    }
    Ok("unknown".to_string())
}

pub fn git_list_branches(path: String) -> Result<Vec<String>, String> {
    let repo = Repository::open(&path).map_err(|e| format!("Failed to open repository: {}", e))?;
    let branches = repo.branches(Some(git2::BranchType::Local))
        .map_err(|e| format!("Failed to list branches: {}", e))?;
    
    let mut names = Vec::new();
    for item in branches {
        let (branch, _) = item.map_err(|e| format!("Error in branch iteration: {}", e))?;
        if let Some(name) = branch.name().map_err(|e| format!("Failed to get branch name: {}", e))? {
            names.push(name.to_string());
        }
    }
    Ok(names)
}

pub fn git_create_branch(path: String, branch_name: String) -> Result<String, String> {
    let repo = Repository::open(&path).map_err(|e| format!("Failed to open repository: {}", e))?;
    
    let head_commit = repo.head()
        .and_then(|h| h.peel_to_commit())
        .map_err(|e| format!("Failed to find HEAD commit for new branch: {}", e))?;

    repo.branch(&branch_name, &head_commit, false)
        .map_err(|e| format!("Failed to create branch: {}", e))?;

    let refname = format!("refs/heads/{}", branch_name);
    repo.set_head(&refname)
        .map_err(|e| format!("Failed to set HEAD to new branch: {}", e))?;

    let mut checkout_opts = git2::build::CheckoutBuilder::new();
    checkout_opts.safe();
    repo.checkout_head(Some(&mut checkout_opts))
        .map_err(|e| format!("Failed to checkout new branch: {}", e))?;

    log_msg(&format!("Rust Backend: Created and switched to branch {}", branch_name));
    Ok("Success".to_string())
}

pub fn git_checkout_branch(path: String, branch_name: String) -> Result<String, String> {
    let repo = Repository::open(&path).map_err(|e| format!("Failed to open repository: {}", e))?;
    
    let refname = format!("refs/heads/{}", branch_name);
    
    // Find target commit to check if it exists
    let target_ref = repo.find_reference(&refname)
        .map_err(|e| format!("Failed to find branch reference: {}", e))?;
    let _target_commit = target_ref.peel_to_commit()
        .map_err(|e| format!("Branch reference is not a valid commit: {}", e))?;

    repo.set_head(&refname)
        .map_err(|e| format!("Failed to set HEAD: {}", e))?;
    
    let mut checkout_opts = git2::build::CheckoutBuilder::new();
    checkout_opts.safe();
    
    repo.checkout_head(Some(&mut checkout_opts))
        .map_err(|e| format!("Failed to switch branch. You may have uncommitted changes that would be overwritten: {}", e))?;

    log_msg(&format!("Rust Backend: Switched to branch {}", branch_name));
    Ok("Success".to_string())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;
    use std::path::PathBuf;

    fn setup_test_repo(name: &str) -> (PathBuf, Repository) {
        let temp_dir = std::env::temp_dir().join(format!("git_test_{}_{}", name, std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH).unwrap().as_nanos()));
        fs::create_dir_all(&temp_dir).unwrap();
        let repo = Repository::init(&temp_dir).unwrap();
        
        // Write initial user config
        let mut config = repo.config().unwrap();
        config.set_str("user.name", "Test User").unwrap();
        config.set_str("user.email", "test@example.com").unwrap();

        (temp_dir, repo)
    }

    fn commit_file(repo: &Repository, filename: &str, content: &str, msg: &str) {
        let path = repo.path().parent().unwrap().join(filename);
        fs::write(&path, content).unwrap();

        let mut index = repo.index().unwrap();
        index.add_path(std::path::Path::new(filename)).unwrap();
        index.write().unwrap();

        let tree_id = index.write_tree().unwrap();
        let tree = repo.find_tree(tree_id).unwrap();

        let sig = git2::Signature::now("Test User", "test@example.com").unwrap();

        let parent_commit = match repo.head().and_then(|h| h.peel_to_commit()) {
            Ok(c) => Some(c),
            Err(_) => None,
        };

        let parents = match &parent_commit {
            Some(c) => vec![c],
            None => vec![],
        };

        repo.commit(
            Some("HEAD"),
            &sig,
            &sig,
            msg,
            &tree,
            &parents,
        ).unwrap();
    }

    #[test]
    fn test_git_pull_clean_merge() {
        let (remote_dir, remote_repo) = setup_test_repo("remote");
        commit_file(&remote_repo, "test.txt", "Line 1\nLine 2\nLine 3\n", "Initial commit");

        let local_dir = std::env::temp_dir().join(format!("git_local_{}", std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH).unwrap().as_nanos()));
        let local_repo = git2::build::RepoBuilder::new()
            .clone(remote_dir.to_str().unwrap(), &local_dir)
            .unwrap();

        let mut config = local_repo.config().unwrap();
        config.set_str("user.name", "Local User").unwrap();
        config.set_str("user.email", "local@example.com").unwrap();

        commit_file(&remote_repo, "test.txt", "Line 1\nLine 2\nLine 3\nRemote Line\n", "Remote commit");

        commit_file(&local_repo, "test.txt", "Local Line\nLine 1\nLine 2\nLine 3\n", "Local commit");

        // Resolve current branch name dynamically from HEAD
        let head = remote_repo.head().unwrap();
        let branch_name = head.shorthand().unwrap().to_string();

        let result = git_pull(
            local_dir.to_str().unwrap().to_string(),
            "origin".to_string(),
            branch_name,
            None,
            None,
            Some("Merge Author".to_string()),
            Some("merge@author.com".to_string()),
        );

        assert!(result.is_ok(), "Merge failed: {:?}", result);
        assert_eq!(result.unwrap(), "Success-Merge");

        let merged_content = fs::read_to_string(local_dir.join("test.txt")).unwrap();
        assert!(merged_content.contains("Local Line"));
        assert!(merged_content.contains("Remote Line"));

        // Cleanup
        let _ = fs::remove_dir_all(&remote_dir);
        let _ = fs::remove_dir_all(&local_dir);
    }

    #[test]
    fn test_git_pull_conflict_rollback() {
        let (remote_dir, remote_repo) = setup_test_repo("remote_conf");
        commit_file(&remote_repo, "test.txt", "Line 1\nLine 2\nLine 3\n", "Initial commit");

        let local_dir = std::env::temp_dir().join(format!("git_local_conf_{}", std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH).unwrap().as_nanos()));
        let local_repo = git2::build::RepoBuilder::new()
            .clone(remote_dir.to_str().unwrap(), &local_dir)
            .unwrap();

        commit_file(&remote_repo, "test.txt", "Line 1\nConflicting Remote\nLine 3\n", "Remote commit conflicting");

        commit_file(&local_repo, "test.txt", "Line 1\nConflicting Local\nLine 3\n", "Local commit conflicting");

        let head = remote_repo.head().unwrap();
        let branch_name = head.shorthand().unwrap().to_string();

        let result = git_pull(
            local_dir.to_str().unwrap().to_string(),
            "origin".to_string(),
            branch_name,
            None,
            None,
            Some("Merge Author".to_string()),
            Some("merge@author.com".to_string()),
        );

        assert!(result.is_err());
        let error_msg = result.err().unwrap();
        assert!(error_msg.contains("Conflict resolution is not supported yet"));

        let content = fs::read_to_string(local_dir.join("test.txt")).unwrap();
        assert_eq!(content, "Line 1\nConflicting Local\nLine 3\n");

        // Verify status is clean
        let statuses = local_repo.statuses(None).unwrap();
        assert!(statuses.is_empty(), "Working directory not clean after conflict rollback!");

        // Cleanup
        let _ = fs::remove_dir_all(&remote_dir);
        let _ = fs::remove_dir_all(&local_dir);
    }

    #[test]
    fn test_branch_management() {
        let (temp_dir, repo) = setup_test_repo("branches");
        
        // Initial commit (required to have HEAD exist)
        commit_file(&repo, "test.txt", "Initial", "Initial commit");

        // Verify current branch is the initialized default
        let current = git_current_branch(temp_dir.to_str().unwrap().to_string()).unwrap();
        
        // Create new branch
        let create_res = git_create_branch(
            temp_dir.to_str().unwrap().to_string(),
            "feature-test".to_string()
        ).unwrap();
        assert_eq!(create_res, "Success");

        // Verify current branch is now feature-test
        let current_after_create = git_current_branch(temp_dir.to_str().unwrap().to_string()).unwrap();
        assert_eq!(current_after_create, "feature-test");

        // List branches (should contain initial branch and feature-test)
        let list = git_list_branches(temp_dir.to_str().unwrap().to_string()).unwrap();
        assert!(list.contains(&current));
        assert!(list.contains(&"feature-test".to_string()));

        // Switch back to initial branch
        let checkout_res = git_checkout_branch(
            temp_dir.to_str().unwrap().to_string(),
            current.clone()
        ).unwrap();
        assert_eq!(checkout_res, "Success");

        // Verify switched back
        let current_after_checkout = git_current_branch(temp_dir.to_str().unwrap().to_string()).unwrap();
        assert_eq!(current_after_checkout, current);

        let _ = fs::remove_dir_all(&temp_dir);
    }
}
