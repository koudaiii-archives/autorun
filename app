#! /bin/bash

# App 
# Maintainer: @koudaiii
# App Version: 0.1

### BEGIN INIT INFO
# Provides:          app
# Required-Start:    $local_fs $remote_fs $network $syslog redis-server
# Required-Stop:     $local_fs $remote_fs $network $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Application for Capistrano and Puma
# Description:       Application for Capistrano and Puma
### END INIT INFO

### BEGIN YOUR SETTING
APP_USER="app"
APP_PATH="/var/www/app"

APP_ROOT="$APP_PATH/current"
SOCKET_PATH="$APP_PATH/shared/sockets"

DAEMON_OPTS="-C $APP_ROOT/config/puma.rb -e production"
WEB_SERVER_SOCKET_PATH="$SOCKET_PATH/puma.sock"
WEB_SERVER_STATE_PATH="$SOCKET_PATH/puma.state"

STOP_APP="bundle exec pumactl -S $WEB_SERVER_STATE_PATH stop"
STOP_DELAYED_JOB="RAILS_ENV=production bin/delayed_job stop"
START_APP="bundle exec pumactl start -q -d -S $WEB_SERVER_STATE_PATH $DAEMON_OPTS"
START_DELAYED_JOB="RAILS_ENV=production bin/delayed_job start"

NAME="app"
DESC="Application service"

## END YOUR SETTING
PID=`ps aux | grep $WEB_SERVER_SOCKET_PATH | grep -v grep |  awk '{ print $2 }'` 

check_pid(){
  if [ "$PID" -ne 0 ]; then
    STATUS=`ps aux | grep $PID | grep -v grep | wc -l`
  else
    PID=0
    STATUS=0
  fi
}

start() {
  cd $APP_ROOT
  check_pid
  if [ "$PID" -ne 0 -a "$STATUS" -ne 0 ]; then
    # Program is running, exit with error code 1.
    echo "Error! $DESC $NAME is currently running!"
    exit 1
  else
    if [ `whoami` = root ]; then
      sudo -u $APP_USER -H bash -l -c "$START_APP"
      sudo -u $APP_USER -H bash -l -c "$START_DELAYED_JOB"
      echo "$DESC started"
    fi
  fi
}

stop() {
  cd $APP_ROOT
  check_pid
  if [ "$PID" -ne 0 -a "$STATUS" -ne 0 ]; then
    ## Program is running, stop it.
    sudo -u $APP_USER -H bash -l -c "$STOP_APP  > /dev/null  2>&1 &"
    sudo -u $APP_USER -H bash -l -c "$STOP_DELAYED_JOB  > /dev/null  2>&1 &"
    echo "$DESC stopped"
  else
    ## Program is not running, exit with error.
    echo "Error! $DESC not started!"
    exit 1
  fi
}

restart() {
  cd $APP_ROOT
  check_pid
  if [ "$PID" -ne 0 -a "$STATUS" -ne 0 ]; then
    echo "Restarting $DESC..."
    sudo -u $APP_USER -H bash -l -c "$STOP_APP  > /dev/null  2>&1 &"
    sudo -u $APP_USER -H bash -l -c "$STOP_DELAYED_JOB  > /dev/null  2>&1 &"
    if [ `whoami` = root ]; then
      sudo -u $APP_USER -H bash -l -c "$START_APP  > /dev/null  2>&1 &"
      sudo -u $APP_USER -H bash -l -c "$START_DELAYED_JOB  > /dev/null  2>&1 &"
    fi
    echo "$DESC restarted."
  else
    echo "Error, $NAME not running!"
    exit 1
  fi
}

status() {
  cd $APP_ROOT
  check_pid
  if [ "$PID" -ne 0 -a "$STATUS" -ne 0 ]; then
    echo "$DESC / Puma with PID $PID is running."
  else
    echo "$DESC is not running."
    exit 1
  fi
}

## Check to see if we are running as root first.
## Found at http://www.cyberciti.biz/tips/shell-root-user-check-script.html
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root"
    exit 1
fi

case "$1" in
  start)
        start
        ;;
  stop)
        stop
        ;;
  restart)
        restart
        ;;
  status)
        status
        ;;
  *)
        echo "Usage: sudo service gitlab {start|stop|restart}" >&2
        exit 1
        ;;
esac

exit 0
