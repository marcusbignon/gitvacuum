#/bin/bash

#################
# Configuration #
#################
github_account="<username>" 
github_token="<token>"
github_organization="<org>"

temp_path="."
temp_dirname=".gitvacuum.${$}"
temp_basename=".gitvacuum.swp"

###############
# Script vars #
###############
github_auth="${github_account}:${github_token}"
github_perpage="100"
github_base_url="https://api.github.com/orgs/${github_organization}/repos"
github_query_string="?per_page=${github_perpage}"
github_url="${github_base_url}${github_query_string}"

temp_dir="${temp_path}/${temp_dirname}"
temp_file="${temp_dir}/${temp_basename}"

#############
# Functions #
#############
create_temp()
{
    if [ -d ${temp_dir} ] ; then
        remove_temp
    fi
    mkdir ${temp_dir}
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

########
# Main #
########

create_temp
repo_list
cp ${temp_file} ${temp_dir}/repos.txt
