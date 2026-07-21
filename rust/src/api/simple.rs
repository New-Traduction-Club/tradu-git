pub use crate::api::ssl::*;
pub use crate::api::repo::*;
pub use crate::api::branch::*;
pub use crate::api::commit::*;

#[flutter_rust_bridge::frb(sync)]
pub fn greet(name: String) -> String {
    format!("Hello, {name}!")
}

pub fn setup_ssl_certificates(files_dir: String) -> Result<String, String> {
    crate::log_msg(&format!("setup_ssl_certificates compatibility stub called with files_dir: {}", files_dir));
    Ok("Bypassed".to_string())
}
