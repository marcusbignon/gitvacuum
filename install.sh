#!/bin/bash
#
# SCRIPT: install.sh
# AUTHOR: Marcus Bignon <marcus@bignon.com.br>
# DATE:   2021-01-30
#
# PURPOSE: Configures the github_api.secret file. 
# A new alias for gitvacuum.sh script must be created.
#

path="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

echo "Gitvacuum install..."
echo "Please, provide the requested information to store in the github_api.secret file."
echo -n "(1) Github account: "
read account
echo -n "(2) Organization: "
read organization
echo -n "(3) Github token: "
read token

echo "$account $organization $token" > "${path}/github_api.secret"
echo "File ${path}/github_api.secret successfully configured."

