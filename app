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
APP_ROOT="/var/www/app"
SOCKET_PATH="$APP_ROOT/shared/sockets/"

DAEMON_OPTS="-C $APP_ROOT/current/config/puma.rb -e production"
WEB_SERVER_SOCKET_PATH="$SOCKET_PATH/puma.socket"
WEB_SERVER_STATE_PATH="$SOCKET_PATH/puma.state"

STOP_APP="RAILS_ENV=production bundle exec pumactl -S $WEB_SERVER_STATE_PATH stop"
START_APP="RAILS_ENV=production bundle exec pumactl start -q -d -S $WEB_SERVER_STATE_PATH $DAEMON_OPTS"
NAME="app"
DESC="app service"
## END YOUR SETTING

check_pid(){
  if [ -f $WEB_SERVER_PID ]; then
    PID=`cat $WEB_SERVER_PID`
    STATUS=`ps aux | grep $PID | grep -v grep | wc -l`
  else
    STATUS=0
    PID=0
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
      sudo -u git -H bash -l -c "RAILS_ENV=production bundle exec puma $DAEMON_OPTS"
      sudo -u git -H bash -l -c "mkdir -p $PID_PATH && $START_SIDEKIQ  > /dev/null  2>&1 &"
      echo "$DESC started"
    fi
  fi
}

stop() {
  cd $APP_ROOT
  check_pid
  if [ "$PID" -ne 0 -a "$STATUS" -ne 0 ]; then
    ## Program is running, stop it.
    kill -QUIT `cat $WEB_SERVER_PID`
    sudo -u git -H bash -l -c "mkdir -p $PID_PATH && $STOP_SIDEKIQ  > /dev/null  2>&1 &"
    rm "$WEB_SERVER_PID" >> /dev/null
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
    kill -USR2 `cat $WEB_SERVER_PID`
    sudo -u git -H bash -l -c "mkdir -p $PID_PATH && $STOP_SIDEKIQ  > /dev/null  2>&1 &"
    if [ `whoami` = root ]; then
      sudo -u git -H bash -l -c "mkdir -p $PID_PATH && $START_SIDEKIQ  > /dev/null  2>&1 &"
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
  reload|force-reload)
        echo -n "Reloading $NAME configuration: "
        kill -HUP `cat $PID`
        echo "done."
        ;;
  status)
        status
        ;;
  *)
        echo "Usage: sudo service gitlab {start|stop|restart|reload}" >&2
        exit 1
        ;;
esac

exit 0
