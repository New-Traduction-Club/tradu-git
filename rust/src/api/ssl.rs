use std::path::Path;
use crate::log_msg;

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
