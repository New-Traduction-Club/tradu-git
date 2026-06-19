pub mod api;
mod frb_generated;

pub fn log_msg(msg: &str) {
    #[cfg(target_os = "android")]
    unsafe {
        use std::ffi::CString;
        extern "C" {
            fn __android_log_write(
                prio: std::os::raw::c_int,
                tag: *const std::os::raw::c_char,
                text: *const std::os::raw::c_char,
            ) -> std::os::raw::c_int;
        }
        let tag = CString::new("tradu_git_rust").unwrap();
        let text = CString::new(msg).unwrap();
        __android_log_write(4, tag.as_ptr(), text.as_ptr()); // 4 = Info prio
    }
    #[cfg(not(target_os = "android"))]
    {
        println!("{}", msg);
    }
}

#[cfg(target_os = "android")]
#[no_mangle]
pub unsafe extern "C" fn link(
    oldpath: *const std::os::raw::c_char,
    newpath: *const std::os::raw::c_char,
) -> std::os::raw::c_int {
    use std::ffi::CStr;
    use std::fs;
    use std::path::Path;

    let old_str = match CStr::from_ptr(oldpath).to_str() {
        Ok(s) => s,
        Err(_) => {
            errno::set_errno(errno::Errno(libc::EINVAL));
            return -1;
        }
    };
    let new_str = match CStr::from_ptr(newpath).to_str() {
        Ok(s) => s,
        Err(_) => {
            errno::set_errno(errno::Errno(libc::EINVAL));
            return -1;
        }
    };

    log_msg(&format!("Intercepted link call: {} -> {}", old_str, new_str));

    let old_path = Path::new(old_str);
    let new_path = Path::new(new_str);

    // According to POSIX link() spec: if the new path already exists, fail with EEXIST.
    if new_path.exists() {
        log_msg("Link destination path already exists! Returning EEXIST.");
        errno::set_errno(errno::Errno(libc::EEXIST));
        return -1;
    }

    match fs::copy(old_path, new_path) {
        Ok(_) => {
            log_msg("Successfully emulated link via copy.");
            0
        }
        Err(e) => {
            log_msg(&format!("Emulated link failed to copy: {}", e));
            if let Some(code) = e.raw_os_error() {
                errno::set_errno(errno::Errno(code));
            } else {
                errno::set_errno(errno::Errno(libc::EIO));
            }
            -1
        }
    }
}


