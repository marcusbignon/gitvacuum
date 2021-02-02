#/bin/bash

set -euo pipefail

#################
# Configuration #
#################
github_secrets_file="./github_api.secret"
github_account=$( awk '{print $1}' ${github_secrets_file} )
github_token=$( awk '{print $3}' ${github_secrets_file} )
github_organization=$( awk '{print $2}' ${github_secrets_file} )

temp_path="."
temp_dirname=".gitvacuum.${$}"
temp_basename=".gitvacuum.swp"
temp_repo_dirname="repos"

###############
# Script vars #
###############
github_auth="${github_account}:${github_token}"
github_perpage="100"
github_base_url="https://api.github.com/orgs/${github_organization}/repos"
github_query_string="?per_page=${github_perpage}"
github_url="${github_base_url}${github_query_string}"
github_repo_base_url="https://github.com/${github_organization}"

temp_dir="${temp_path}/${temp_dirname}"
temp_file="${temp_dir}/${temp_basename}"
temp_repo_dir="${temp_dir}/${temp_repo_dirname}"

gz_time=$(date +"%Y-%m-%d_%H-%M-%S")
gz_file_name="repos-${github_organization}-${gz_time}.gz"
gz_file="${temp_dir}/${gz_file_name}"

#############
# Functions #
#############
create_temp()
{
    log "Creating temp files in ${temp_dir}..."
    if [ -d ${temp_dir} ] ; then
        remove_temp
    fi
    mkdir ${temp_dir}
    mkdir ${temp_repo_dir}
}

remove_temp()
{
    log "Removing existing temp files..."
    rm -rf ${temp_dir}
}

log()
{
    msg=${1}
    dtime=$(date +"%Y-%m-%d %H:%M:%S")
    echo -e "[ ${dtime} ] ${msg}"
}

log_start()
{
    run_start=`date +%s`
    log "Starting gitvacuum..."
}

log_end()
{
    run_end=`date +%s`
    run_time=$((run_end - run_start))
    log "Finished. Execution time: ${run_time} sec."
}

repo_list()
{
    log "Fetching repositories list from github.com (${github_organization})..."
    github_page=1
    while : ; do
        github_url="${github_url}&page=${github_page}"
        log "Requesting page ${github_page} (max ${github_perpage} records per page)..."
        curl -u ${github_auth} ${github_url} > ${temp_file}.0
        cat ${temp_file}.0 | awk '$0 ~ /full_name/ {print substr($2, 12, length($2)-13)}' > ${temp_file}.1
        if [ -s ${temp_file}.1 ] ; then
            cat ${temp_file}.1 >> ${temp_file}
        else
            break
        fi
        github_page=$(( ${github_page} + 1 ))
    done
    repos_count=$( cat ${temp_file} | wc -l )
    log "Total requested pages: ${github_page}"
    log "Total repositories in the list: ${repos_count}"
}

repo_clone()
{
    log "Preparing to clone repositories from ${temp_file}..."
    while read repo_name; do
        log "Cloning repository: ${repo_name}"
        git clone -v ${github_repo_base_url}/${repo_name}.git ${temp_repo_dir}/${repo_name}
        log "${repo_name} done."
    done < ${temp_file}
}

repo_compress()
{
    log "Preparing to compress files (tar.gz)..."
    mv ${temp_file} ${temp_repo_dir}/repos.txt
    tar -czvf ${gz_file} ${temp_repo_dir}/*
    mv ${gz_file} ./.
    log "Archive created: ./${gz_file_name}"
}

########
# Main #
########
log_start
create_temp
repo_list
repo_clone
repo_compress
remove_temp
log_end
