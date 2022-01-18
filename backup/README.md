# Backup & Upload
Script for backing up folder/databases to a remote host

## Usage
* Add an ssh key for the remote
* Customize the ENVIRONMENT SETUP section of the script
* Add any custom logic needed in the first {} block of the EXCECUTION section
* Run

## Cron
Can be set up as a cron job for automated runs. Example
```
0 2 * * * /xxx/create_backup.sh > /xxxx/result.log 2>&1
```