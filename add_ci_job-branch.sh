#!/bin/bash

source $HOME/mozart/bin/activate

cd $(dirname $0)

# source yaml parser
source ./yaml.sh


echoerr() { echo "$@" 1>&2; }


function check_error {
  STATUS=$?
  if [ $STATUS -ne 0 ]; then
    echo "Failed to run $1." 1>&2
    exit $STATUS
  fi
}


# source sds config
SDS_CFG=$HOME/.sds/config
if [ ! -e "$SDS_CFG" ]; then
  echoerr "Failed to find SDS configuration at $SDS_CFG. Run 'sds configure'."
  exit 1
fi
create_variables $SDS_CFG


if [ "$#" -ne 5 ]; then
  echo "Please specify url of github repo, branch, container storage type, and container ops user's UID and GID:" 1>&2
  echo "$0 <repo> <branch> <s3|s3s|gs|dav|davs> <uid> <gid>" 1>&2
  echo "e.g. $0 https://github.jpl.nasa.gov/hysds-org/hysds.git v2 s3 1001 1001" 1>&2
  echo "     $0 https://github.com/hysds-org/hysds.git master davs 1002 1002" 1>&2
  exit 1
fi

REPO=$1
BRANCH=$2
STORAGE=$3
OPS_UID=$4
OPS_GID=$5

# create jenkins job for repo
fab -f cluster.py -R ci add_ci_job:$REPO,$STORAGE,$OPS_UID,$OPS_GID,$BRANCH || check_error add_ci_job

# reload jenkins jobs from disk
fab -f cluster.py -R ci reload_configuration || check_error reload_configuration

# final message
REPO_HOOKS_SETTINGS=`echo $REPO | sed 's#.git$#/settings/hooks#'`
echo ""
echo ""
echo "Jenkins job create for:"
echo ""
echo "  $REPO"
echo ""
echo "Please ensure that a webhook has been configured at:"
echo ""
echo "  $REPO_HOOKS_SETTINGS"
echo ""
echo "to push 'Push' and 'Repository' events to:"
echo ""
echo "  http://${CI_FQDN}:8080/github-webhook/"
echo ""
echo "If you've configured a Jenkins account with an OAuth credential and full access"
echo "to your github account, this may be done automatically for you."
