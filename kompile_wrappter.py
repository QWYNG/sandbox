#!/usr/bin/env python3
import subprocess
import shlex
import pty
import sys
import os


def kompile_wrapper(*args):    
    rm_cmd = "rm -rf *-kompiled/"
    print("Removing previous kompiled directories: ", " ".join(rm_cmd))
    subprocess.run(rm_cmd, shell=True)

    cmd = ["kompile", "--verbose"] + list(args) + ["--enable-llvm-debug"]

    master_fd, slave_fd = pty.openpty()

    subprocess.Popen(cmd, stdout=slave_fd, stderr=slave_fd, close_fds=True)
    os.close(slave_fd)

    stdout_decoded = []
    while True:
        try:
            output = os.read(master_fd, 1024).decode()
            if output:
                stdout_decoded.append(output)
                print(output, end="")  # Print for debugging purposes
            else:
                break
        except OSError:
            break

    stdout_decoded = "".join(stdout_decoded)
    os.close(master_fd)

    executing_line = None
    for line in stdout_decoded.splitlines():
        if "Executing:" in line:
            executing_line = line.split("Executing:")[1].strip()
            break

    if executing_line:
        # Modify the command by adding '-g' after 'llvm-kompile'
        modified_cmd = shlex.split(executing_line)
        modified_cmd.append("-g")

        print("Rerun: ", " ".join(modified_cmd))
        subprocess.run(modified_cmd, check=True)
    


if __name__ == "__main__":
    kompile_wrapper(*sys.argv[1:])
