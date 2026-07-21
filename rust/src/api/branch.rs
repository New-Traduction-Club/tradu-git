use git2::Repository;
use crate::log_msg;

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
    checkout_opts.force();
    repo.checkout_head(Some(&mut checkout_opts))
        .map_err(|e| format!("Failed to checkout new branch: {}", e))?;

    log_msg(&format!("Rust Backend: Created and switched to branch {}", branch_name));
    Ok("Success".to_string())
}

pub fn git_checkout_branch(path: String, branch_name: String) -> Result<String, String> {
    let repo = Repository::open(&path).map_err(|e| format!("Failed to open repository: {}", e))?;
    
    let refname = format!("refs/heads/{}", branch_name);
    
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
        
        let mut config = repo.config().unwrap();
        config.set_str("user.name", "Test User").unwrap();
        config.set_str("user.email", "test@example.com").unwrap();

        (temp_dir, repo)
    }

    fn commit_file(repo: &Repository, filename: &str, content: &str, msg: &str) {
        let workdir = repo.workdir().unwrap();
        let file_path = workdir.join(filename);
        fs::write(&file_path, content).unwrap();

        let mut index = repo.index().unwrap();
        index.add_path(std::path::Path::new(filename)).unwrap();
        let tree_id = index.write_tree().unwrap();
        let tree = repo.find_tree(tree_id).unwrap();

        let sig = git2::Signature::now("Test User", "test@example.com").unwrap();
        let parent = repo.head().and_then(|h| h.peel_to_commit()).ok();
        let parents = match &parent {
            Some(c) => vec![c],
            None => vec![],
        };

        repo.commit(Some("HEAD"), &sig, &sig, msg, &tree, &parents).unwrap();
    }

    #[test]
    fn test_branch_management() {
        let (temp_dir, repo) = setup_test_repo("branches");
        
        commit_file(&repo, "test.txt", "Initial", "Initial commit");

        let current = git_current_branch(temp_dir.to_str().unwrap().to_string()).unwrap();
        
        let create_res = git_create_branch(
            temp_dir.to_str().unwrap().to_string(),
            "feature-test".to_string()
        ).unwrap();
        assert_eq!(create_res, "Success");

        let current_after_create = git_current_branch(temp_dir.to_str().unwrap().to_string()).unwrap();
        assert_eq!(current_after_create, "feature-test");

        let list = git_list_branches(temp_dir.to_str().unwrap().to_string()).unwrap();
        assert!(list.contains(&current));
        assert!(list.contains(&"feature-test".to_string()));

        let checkout_res = git_checkout_branch(
            temp_dir.to_str().unwrap().to_string(),
            current.clone()
        ).unwrap();
        assert_eq!(checkout_res, "Success");

        let current_after_checkout = git_current_branch(temp_dir.to_str().unwrap().to_string()).unwrap();
        assert_eq!(current_after_checkout, current);

        let _ = fs::remove_dir_all(&temp_dir);
    }
}
