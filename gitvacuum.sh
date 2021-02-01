#/bin/bash

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

#############
# Functions #
#############
create_temp()
{
    if [ -d ${temp_dir} ] ; then
        remove_temp
    fi
    mkdir ${temp_dir}
    mkdir ${temp_repo_dir}
}

repo_list()
{
    github_page=1

    while : ; do
        github_url="${github_url}&page=${github_page}"
        curl -u ${github_auth} ${github_url} > ${temp_file}.0
        cat ${temp_file}.0 | awk '$0 ~ /full_name/ {print substr($2, 12, length($2)-13)}' > ${temp_file}.1
        if [ -s ${temp_file}.1 ] ; then
            cat ${temp_file}.1 >> ${temp_file}
        else
            break
        fi
        github_page=$(( ${github_page} + 1 ))
    done
}

repo_clone()
{
    count=1
    qt=3
    while read repo_name; do
        git clone -v ${github_repo_base_url}/${repo_name}.git ${temp_repo_dir}/${repo_name}
        if [ ${count} -ge ${qt} ] ; then
            break
        fi
        count=$(( ${count} + 1 ))
    done < ${temp_file}
}

########
# Main #
########

create_temp
repo_list
repo_clone
cp ${temp_file} ${temp_dir}/repos.txt
