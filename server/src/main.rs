#![no_main]
use std::net::TcpListener;
use std::os::unix::io::{AsRawFd, FromRawFd};
use std::process::{Command, Stdio};
use std::thread::spawn;

use libc::{c_int, sighandler_t, signal};
use libc::{SIGINT, SIGTERM};

const START_MESSAGE: &str = "stockfish server ready at port 4000\n\0";
const CONNECTION_MESSAGE: &str = "Connection received\n\0";

pub extern "C" fn handler(_: c_int) {
    std::process::exit(0);
}

unsafe fn set_os_handlers() {
    signal(SIGINT, handler as extern "C" fn(_) as sighandler_t);
    signal(SIGTERM, handler as extern "C" fn(_) as sighandler_t);
}

#[no_mangle]
pub extern "C" fn main(_argc: isize, _argv: *const *const u8) -> isize {
    unsafe { set_os_handlers() };
    let listener = TcpListener::bind("0.0.0.0:4000").unwrap();
    listener.set_ttl(60).unwrap();

    unsafe {
        libc::printf(START_MESSAGE.as_ptr().cast());
    }

    while let Some(Ok(stream)) = listener.incoming().next() {
        unsafe {
            libc::printf(CONNECTION_MESSAGE.as_ptr().cast());
        }

        spawn(move || {
            stream.set_ttl(60).unwrap();
            let fd = stream.as_raw_fd();
            unsafe {
                let stdio1 = Stdio::from_raw_fd(fd);
                let stdio2 = Stdio::from_raw_fd(fd);
                Command::new("/stockfish")
                    .stdin(stdio1)
                    .stdout(stdio2)
                    .spawn()
                    .unwrap()
                    .wait()
                    .unwrap();
            }
        });
    }

    0
}
