#!/bin/sh
# Creates the drone tool for easily using and communicating with a drone

drone() {
  if [ "$DRONE_CONFIG_LOADED" != "TRUE" ]; then
    echo "Error: unable to find your local .config file.  Please make sure that you setup the drone tool correctly."
    echo "Go to \"https://mitll-racecar-mn.readthedocs.io/en/latest/gettingStarted/computerSetup.html\" for setup instructions."
  else
    local DRONE_DESTINATION_PATH="/home/drone/jupyter_ws/${DRONE_TEAM}"
    if [ $# -eq 1 ] && [ "$1" = "cd" ]; then
      cd "$DRONE_ABSOLUTE_PATH"/labs || return
    elif [ $# -eq 1 ] && [ "$1" = "connect" ]; then
      echo "Attempting to connect to drone (${DRONE_IP})..."
      ssh -t drone@"$DRONE_IP" "cd ${DRONE_DESTINATION_PATH} && export DISPLAY=:0 && bash"
    elif [ $# -eq 1 ] && [ "$1" = "jupyter" ]; then
      drone cd
      echo "Creating a Jupyter server..."
      jupyter-notebook --no-browser
    elif [ $# -eq 1 ] && [ "$1" = "remove" ]; then
      echo "Removing your team directory from your drone..."
      ssh drone@"$DRONE_IP" "cd /home/drone/jupyter_ws/ && rm -rf ${DRONE_TEAM}"
    elif [ $# -eq 1 ] && [ "$1" = "setup" ]; then
      echo "Creating your team directory (${DRONE_DESTINATION_PATH}) on your drone..."
      ssh drone@"$DRONE_IP" mkdir -p "$DRONE_DESTINATION_PATH"
      drone sync all
    elif [ $# -ge 2 ] && [ "$1" = "sim" ]; then
      python3 "$2" -s "$3" "$4" "$5" "$6"
    elif [ $# -eq 1 ] && [ "$1" = "backup" ]; then
      cd "$DRONE_ABSOLUTE_PATH"
      now="$(date)"
      if [ ! -d "backup" ]
      then
        echo "Backup folder not found, creating one now..."
        mkdir ./backup
        echo "Backup folder created, continuing..."
      else
        echo "Backup folder found, continuing..."
      fi
      shopt -s nullglob
      numfiles=(./backup/*)
      numfiles=${#numfiles[@]}
      mkdir ./backup/version_"$numfiles"
      echo "Current date: $now" > ./backup/version_"$numfiles"/info.txt
      echo "Drone ip: $DRONE_IP" >> ./backup/version_"$numfiles"/info.txt
      echo "Drone team: $DRONE_TEAM" >> ./backup/version_"$numfiles"/info.txt
      echo "Backup number: $numfiles"
      echo "Backup location: $DRONE_ABSOLUTE_PATH"/backup/version_"$numfiles"
      echo "Downloading files now..."
      scp -rp drone@$DRONE_IP:/home/drone/jupyter_ws $DRONE_ABSOLUTE_PATH/backup/version_$numfiles
    elif [ $# -eq 2 ] && [ "$1" = "sync" ]; then
      local valid_command=false
      if [ "$2" = "library" ] || [ "$2" = "all" ]; then
        echo "Copying your local copy of the drone library to your drone (${DRONE_IP})..."
        rsync -azP --delete "$DRONE_ABSOLUTE_PATH"/library drone@"$DRONE_IP":"$DRONE_DESTINATION_PATH"
        valid_command=true
      fi
      if [ "$2" = "labs" ] || [ "$2" = "all" ]; then
        echo "Copying your local copy of the drone labs to your drone (${DRONE_IP})..."
        rsync -azP --delete "$DRONE_ABSOLUTE_PATH"/labs drone@"$DRONE_IP":"$DRONE_DESTINATION_PATH"
        valid_command=true
      fi
      if [ "$valid_command" = false ]; then
        echo "'${2}' is not a recognized sync command.  Please enter one of the following:"
        echo "drone sync labs"
        echo "drone sync library"
        echo "drone sync all"
      fi
    elif [ $# -eq 1 ] && [ "$1" = "test" ]; then
      echo "drone tool set up successfully!"
      echo "  DRONE_ABSOLUTE_PATH: ${DRONE_ABSOLUTE_PATH}"
      echo "  DRONE_IP: ${DRONE_IP}"
      echo "  DRONE_TEAM: ${DRONE_TEAM}"
    else
      if [ $# -eq 1 ] && [ "$1" = "help" ]; then
        echo "The drone tool helps your computer communicate with your drone."
      else
        echo "That was not a recognized drone command."
      fi
      echo ""
      echo "Supported commands:"
      echo "  drone cd: move to the drone labs directory on your computer."
      echo "  drone connect: connects to your drone with ssh."
      echo "  drone help: prints this help message."
      echo "  drone jupyter: starts a jupyter server in the drone labs directory."
      echo "  drone remove: removes your team directory from your drone."
      echo "  drone setup: sets up your team directory on your drone."
      echo "  drone sim <filename.py>: runs the specified drone program for use with the simulator."
      echo "  drone sync library: copies your local drone library folder to your drone with scp."
      echo "  drone sync labs: copies your local drone labs folder to your drone with scp."
      echo "  drone sync all: copies all local drone files to your drone with scp."
      echo "  drone backup: Creates a backup of the physical drone code on a local computer."
      echo "  drone test: prints a message to check if the drone tool was set up successfully."
    fi
  fi
}
