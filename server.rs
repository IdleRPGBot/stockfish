use std::net::{TcpListener, TcpStream};
use std::os::unix::io::{AsRawFd, FromRawFd, RawFd};
use std::process::{Command, Stdio};
use std::thread::spawn;

fn handle_client(stream: TcpStream) {
    spawn(move || {
        stream.set_ttl(60).unwrap();
        let fd: RawFd = stream.as_raw_fd();
        let other = stream.try_clone().unwrap();
        let other_fd: RawFd = other.as_raw_fd();
        unsafe {
            let stdio1 = Stdio::from_raw_fd(fd);
            let stdio2 = Stdio::from_raw_fd(other_fd);
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

fn main() -> std::io::Result<()> {
    let listener = TcpListener::bind("0.0.0.0:4000")?;
    listener.set_ttl(60).unwrap();

    println!("Successfully listening on port 4000");

    // accept connections and process them serially
    for stream in listener.incoming() {
        handle_client(stream?);
    }
    Ok(())
}
