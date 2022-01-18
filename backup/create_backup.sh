#!/bin/sh

#----------------------------------------------------------
# A basic backup script that backs up folders and databases
# to a remote host.
# assumes an ssh key has been added for the remote so no
# password is needed for ssh
# last updated 2022-01-18
#----------------------------------------------------------

### ENVIRONMENT SETUP ###

#Database file name (in the backup)
DBFILE=database.sql
#Host to upload to
REMOTEHOST='user@host'
#location to upload the backup to
TARLOCATION='/home/backuprunner/xxxxx/'
#backup filename
TARFILE=xxxxx_`date +"%Y%m%d"`.tar.gz
#files to include in the backup (space separated)
TARINCLUDE="${DBFILE} /var/www/xxxxx/"
#(optional) post status to a discord channel
DISCORD_WEBHOOK="xxxxx"
#name of the service (console output/temp folder creation)
BACKUP_RUNNER_NAME="xxxxx"

#This template includes a mysql dump examnple
DBSERVER=127.0.0.1
DATABASES='xxxxx'
DBUSER=backuprunner
DBPASS='xxxxx'

#Set up any env. vars the script might need
#export xxx 

### FUNCTIONS ###

#arg1 bool success arg2 string message
post_message () {
  #normal echo or post to a custom endpoint  

  local color=3066993
  local state="success"
  if [ "$1" = false ] ;
  then
    color=15158332
    state="failed"
  fi

  #discord webhook (or echo in case we have no hook)
  if [ -n "$DISCORD_WEBHOOK" ]; then
    curl -X POST $DISCORD_WEBHOOK -H 'Content-Type: application/json' -d "{\"username\": \"Backup Runner\",\"embeds\": [{\"title\": \"Backup of $BACKUP_RUNNER_NAME $state\",\"type\": \"rich\",\"color\": $color,\"description\": \"$2\n\nbackup target:\n${REMOTEHOST}:${TARLOCATION}${TARFILE}\"}]}"
  else
    echo "$BACKUP_RUNNER_NAME $state backup to ${REMOTEHOST}:${TARLOCATION}${TARFILE}"
  fi
}

#arg1 exit code
cleanup_and_exit () {
  # remove the tmp directory and its contents
  echo "cleaning up"
  cd ..
  rm -rf "./${BACKUP_RUNNER_NAME}_tmp"
  echo "exiting"
  exit $1
}

### EXCECUTION ###

mkdir -p "./${BACKUP_RUNNER_NAME}_tmp"
cd "./${BACKUP_RUNNER_NAME}_tmp"

{
  #Run the actual backup file generation here (db dumps etc)
  mysqldump --user=${DBUSER} --password=${DBPASS} --opt --databases ${DATABASES} > ${DBFILE}
} || {
  post_message false "Failed to create backup!" & cleanup_and_exit 1
}

# gzip and tar the database dump file and other folders included
# ssh to the remote host and upload the tar file
{
  tar -czf - $TARINCLUDE | ssh $REMOTEHOST "( cd ${TARLOCATION}; cat > ${TARFILE} )"
} || {
  post_message false "Failed to upload backup!" & cleanup_and_exit 1
}

# show the user the result
post_message true "Backup created"

cleanup_and_exit 0
