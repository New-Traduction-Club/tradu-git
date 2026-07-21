use std::path::Path;
use git2::Repository;
use crate::log_msg;

pub struct GitCommitInfo {
    pub hash: String,
    pub author: String,
    pub email: String,
    pub time: i64,
    pub message: String,
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
    
    #[allow(unused_mut)]
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

    #[allow(unused_mut)]
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

        let msg = repo.message().unwrap_or_else(|_| format!("Merge branch '{}'", branch_name));

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

pub fn git_log(path: String, max_count: usize) -> Result<Vec<GitCommitInfo>, String> {
    let repo = Repository::open(&path).map_err(|e| format!("Failed to open repository: {}", e))?;
    
    let _head = match repo.head() {
        Ok(h) => h,
        Err(_) => return Ok(vec![]),
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

    #[allow(unused_mut)]
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
