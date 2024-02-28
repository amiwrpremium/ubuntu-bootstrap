# Bootstrap Script for Ubuntu 20.04 Server

## Description

This script is designed to be executed on a fresh Ubuntu 20.04 server to automate the setup process. It performs the following tasks:

1. Updates and upgrades apt repositories.
2. Installs GitHub CLI (gh).
3. Installs Docker along with Docker Compose.
4. Installs various utility tools including ufw, nano, bat, logwatch, fail2ban, git, and bpytop.
5. Configures SSH settings to enable PasswordAuthentication and PubkeyAuthentication.
6. Adds an SSH key to the authorized_keys file.

## Usage

To run the script, execute the following command:
```bash
sh bootstrap.sh
```

## Prerequisites

- This script is intended for use on Ubuntu 20.04 server.
- Ensure you have sudo privileges or run the script as root.

## Important Notes

- Make sure to review and understand the script before execution.
- Some operations (like modifying SSH configurations) may require root privileges.


## Script Structure

`bootstrap.sh`: The main script file containing all the necessary functions and commands.

## How to Use

1. Clone the repository to your `Ubuntu` server.
2. Navigate to the cloned directory.
3. Make sure `bootstrap.sh` has execute permissions:
```bash
chmod +x bootstrap.sh
```
4. Run the script:
```bash
sh bootstrap.sh
```
5. Follow the on-screen instructions if any.

## Disclaimer

- Use this script at your own risk. Always review scripts from unknown sources before execution.
- Ensure you have backups and take necessary precautions before running the script on a production server.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

- [Amir Mahdi Erfani](https://github.com/amiwrpremium)
