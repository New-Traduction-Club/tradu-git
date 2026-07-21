use std::path::Path;
use git2::{Repository, StatusOptions};
use crate::log_msg;

#[flutter_rust_bridge::frb(sync)]
pub fn has_git_repo(path: String) -> bool {
    Path::new(&path).join(".git").exists()
}

pub fn git_clone(url: String, path: String) -> Result<String, String> {
    use git2::build::RepoBuilder;
    use git2::FetchOptions;

    log_msg(&format!("Rust Backend: Cloning {} into {}", url, path));

    #[allow(unused_mut)]
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
