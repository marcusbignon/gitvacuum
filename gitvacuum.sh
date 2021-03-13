#!/bin/bash
#
# SCRIPT: gitvacuum.sh
# AUTHOR: Marcus Bignon <marcus@bignon.com.br>
# DATE:   2021-01-30
#
# PURPOSE: Simple shellscript that lists and clones all repositories from GitHub.
#

set -euo pipefail
path="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# Configuration
# ---------------------------------------------------------
github_secrets_file="${path}/github_api.secret"
github_account=$( awk '{print $1}' "$github_secrets_file" )
github_organization=$( awk '{print $2}' "$github_secrets_file" )
github_token=$( awk '{print $3}' "$github_secrets_file" )

temp_path="."
temp_dirname=".gitvacuum.${$}"
temp_basename=".gitvacuum.swp"
temp_repo_dirname="repos"

# Script vars
# ---------------------------------------------------------
github_auth="${github_account}:${github_token}"
github_perpage="100"
github_base_url="https://api.github.com/orgs/${github_organization}/repos"
github_query_string="?per_page=${github_perpage}"
github_url="${github_base_url}${github_query_string}"
github_repo_base_url="https://${github_token}@github.com/${github_organization}"

temp_dir="${temp_path}/${temp_dirname}"
temp_file="${temp_dir}/${temp_basename}"
temp_repo_dir="${temp_dir}/${temp_repo_dirname}"

gz_time=$( date +"%Y-%m-%d_%H-%M-%S" )
gz_file_name="repos-${github_organization}-${gz_time}.tar.gz"
gz_file="${temp_dir}/${gz_file_name}"

# Functions
# ---------------------------------------------------------
_create_temp()
{
    _log "Creating temp files in ${temp_dir}..."
    if [ -d "$temp_dir" ] ; then
        _remove_temp
    fi
    mkdir -v "$temp_dir"
    mkdir -v "$temp_repo_dir"
}

_remove_temp()
{
    _log "Removing existing temp files..."
    rm -rfv "$temp_dir"
}

_log()
{
    local _msg="$1"
    local _dtime=$( date +"%Y-%m-%d %H:%M:%S" )
    echo -e "[ ${_dtime} ] ${_msg}"
}

_log_start()
{
    run_start=$( date +%s )
    _log "Starting gitvacuum..."
}

_log_end()
{
    local _run_end=$( date +%s )
    local _run_time=$((_run_end - run_start))
    _log "Finished. Execution time: ${_run_time} sec."
}

_repo_list()
{
    _log "Fetching repositories list from github.com (${github_organization})..."
    local _page=1
    while : ; do
        local github_url="${github_url}&page=${_page}"
        _log "Requesting page ${_page} (max ${github_perpage} records per page)..."
        curl -u "$github_auth" "$github_url" > "${temp_file}.0"
        cat "${temp_file}.0" | awk '$0 ~ /full_name/ {print substr($2, 12, length($2)-13)}' > "${temp_file}.1"
        if [ -s "${temp_file}.1" ] ; then
            cat "${temp_file}.1" >> "${temp_file}"
        else
            break
        fi
        _page=$(( $_page + 1 ))
    done
    local _count=$( cat "$temp_file" | wc -l )
    _log "Total requested pages: ${_page}"
    _log "Total repositories in the list: ${_count}"
}

_repo_clone()
{
    _log "Preparing to clone repositories from ${temp_file}..."
    while read repo_name; do
        _log "Cloning repository: ${repo_name}"
        git clone -v "${github_repo_base_url}/${repo_name}.git" "${temp_repo_dir}/${repo_name}"
        _log "${repo_name} done."
    done < "$temp_file"
}

_repo_compress()
{
    _log "Preparing to compress files (tar.gz)..."
    mv "$temp_file" "${temp_repo_dir}/repos.txt"
    tar -czvf "$gz_file" "${temp_repo_dir}"/*
    mv "$gz_file" ./.
    _log "Archive created: ./${gz_file_name}"
}

# Main
# ---------------------------------------------------------
_log_start
_create_temp
_repo_list
_repo_clone
_repo_compress
_remove_temp
_log_end

