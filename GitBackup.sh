#!/bin/bash
######################################################### 
#
# 本脚本专门克隆gitlab仓库，包括克隆仓库对应的wiki
#
# 作者：张鹏起
# mail: 3988263@qq.com
# 原理是先将需要克隆的仓库汇总到一起，然后逐一克隆每个仓库，顺便把每个仓库的wiki一起克隆
# 
#########################################################

## 组路径格式
GROUPURL=${1-"codes_group"}

## gitlab的访问地址
GITBASEURL=${2-"https://gitlab.xxx.xxx"}

## 访问令牌
GITLAB_TOKEN=${3-"fgpi77s2kiVvX232oFST9oaJ6LH"}

## 转换为curl可用的gitlab的url格式
GROUPPATH=${GROUPURL//\//%2F}
## 把https基本访问地址加入oauth2认证内容
GITAUTHURL=${GITBASEURL/\/\//\/\/oauth2:${GITLAB_TOKEN}@}

## gitlab的组api
APIURL="api/v4/groups"



## 当前目录为工作目录
WORKDIR=$(cd "$(dirname "$0")" && pwd)

_datetime=$(date "+%F %r")

## 日志文件
GITLOG="${WORKDIR}/backup_log_$(date "+%F").log"
[ ! -f "${GITLOG}" ] && touch ${GITLOG}


#
# Set Colors
#

bold=$(tput bold)
underline=$(tput sgr 0 1)
reset=$(tput sgr0)

red=$(tput setaf 1)
green=$(tput setaf 76)
white=$(tput setaf 7)
tan=$(tput setaf 202)
blue=$(tput setaf 25)

h1() { printf "\n${underline}${bold}${blue}%s${reset}\n" "[$(date "+%F %r")] $@" | tee -a ${GITLOG}
}
h2() { printf "\n${underline}${bold}${white}%s${reset}\n" "[$(date "+%F %r")] $@" | tee -a ${GITLOG}
}
debug() { printf "${white}%s${reset}\n" "[$(date "+%F %r")] $@" | tee -a ${GITLOG}
}
info() { printf "${white}➜ %s${reset}\n" "[$(date "+%F %r")] $@" | tee -a ${GITLOG}
}
success() { printf "${green}✔ %s${reset}\n" "[$(date "+%F %r")] $@" | tee -a ${GITLOG} 
}
error() { printf "${red}✖ %s${reset}\n" "[$(date "+%F %r")] $@" | tee -a ${GITLOG}
}


## 使用方法
function usage(){

echo -n "
 $0 组路径
 例如：$0 xxx/xxx/xxx
"

    exit 0
}

### 判断前提环境是否符合要求

## 判断是由有jq
type jq >/dev/null 2>&1 || { error >&2 "jq命令没有安装，无法继续并退出."; exit 1; }

## 判断是否有git和版本
type git >/dev/null 2>&1 || { error >&2 "git命令没有安装，无法继续并退出."; exit 1; }

## 判断是否有自签名证书CA或证书是否可用



## 生成临时目录
TMPDIR="$(mktemp -d -p ${WORKDIR})"

## 访问组下的所有项目api生成的json
PROJECTS_REPO_JSON="projects_repo_list.json"

## 访问组下的所有子组api生成的json
GROUPS_REPO_JSON="groups_repo_list.json"

## 临时生成所有项目汇总列表文件
REPOLIST="repolist.txt"

## 临时生成所有子组汇总列表文件
SUBGROUPLIST="subgrouplist.txt"



## 克隆项目仓库
## 路径参数
function git_clone(){
    [ -z $1 ] && error "git_clone 没有路径参数" && exit 1
    local _path=$1
    ## 克隆仓库
    git clone "${GITAUTHURL}/${_path}.git" ${_path} | tee -a ${GITLOG} 
    success "git clone ${GITAUTHURL}/${_path}.git -> ${_path}完毕"
    ## 顺便把wiki也clone
    git clone "${GITAUTHURL}/${_path}.wiki.git" "${_path}.wiki" | tee -a ${GITLOG} 
    success "git clone ${GITAUTHURL}/${_path}.wiki.git -> ${_path}完毕"

}

## pull项目仓库
## 路径参数
function git_pull(){

    [ -z $1 ] && error "git_pull 没有路径参数" && exit 1
    local _path=$1

    cd ${WORKDIR}/${_path}
    git status > /dev/null 2>&1

    if [ ! $? -eq 0 ]; then
        error "${_path}不是个仓库目录"
    else
        git pull > /dev/null 2>&1
        success "git pull ${_path}完毕"
    fi

    ## 如果wiki目录不存在，则clone这个项目的wiki,因为之前备份时使用其他工具，没有包含wiki，这里重新补上
    if [ ! -d "${WORKDIR}/${_path}.wiki" ]; then
        git_clone ${_path}

    else

        cd "${WORKDIR}/${_path}.wiki"
        git status > /dev/null 2>&1

        if [ ! $? -eq 0 ]; then
            error "${_path}.wiki不是个仓库目录"
        else
            git pull > /dev/null 2>&1
            success "git pull ${_path}.wiki完毕"
        fi

    fi


    ## 干完活回到工作目录中
    cd ${WORKDIR}

}

## fetch项目仓库
## 路径参数
function git_fetch(){
  [ -z $1 ] && error "git_fetch 没有路径参数" && exit 1    
    debug "git_fetch"
}

## 清理临时目录
function clean_tempdir(){
    rm -rf ${WORKDIR}/tmp.* > /dev/null 2>&1
    info "清理临时目录"
}


## 这个组路径下所有项目仓库列表
## 路径参数
function list_group_project_repo(){
   
    info "list_group_project_repo"
    for project in $(jq -r .projects[].path_with_namespace < ${TMPDIR}/${PROJECTS_REPO_JSON}); do

        echo  ${project} >> "${TMPDIR}/${REPOLIST}"
    
    done

}

## 将访问api的结果生成到临时文件中
##路径参数
function init_projects_info(){
    [ -z $1 ] && error "init_group_info 没有路径参数" && exit 1
    local _PATH=$1

    _PATH=${_PATH//\//%2F}

    curl -s --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    "${GITBASEURL}/${APIURL}/${_PATH}" | jq > "${TMPDIR}/${PROJECTS_REPO_JSON}"

    [ ! $? -eq 0 ] && error "访问${GITBASEURL}错误" && exit 1
    info "将访问${_PATH}的api的结果生成到临时文件中,${TMPDIR}/${PROJECTS_REPO_JSON}"

    list_group_project_repo

}


## 访问组下的所有子组api的结果生成到临时文件中
##路径参数
function list_groups_info(){
    [ -z $1 ] && error "init_group_info 没有路径参数" && exit 1
    local _PATH=$1

    _PATH=${_PATH//\//%2F}

    info "[list_groups_info] 获取这个组路径${_PATH}下所有项目列表"
    init_projects_info ${_PATH}

    info "[list_groups_info] 获取这个组路径${_PATH}下所有子组路径列表的json"
    curl -s --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    "${GITBASEURL}/${APIURL}/${_PATH}/subgroups" | jq > "${TMPDIR}/${GROUPS_REPO_JSON}"

    [ ! $? -eq 0 ] && error "访问${GITBASEURL}错误" && exit 1
    info "[list_groups_info] 将访问api的结果生成到临时文件中,${TMPDIR}/${GROUPS_REPO_JSON}"

    info "[list_groups_info] 保存这个组路径${_PATH}下所有子组路径列表"
    for project in $(jq -r .[].full_path < ${TMPDIR}/${GROUPS_REPO_JSON}); do

        echo  ${project} >> "${TMPDIR}/${SUBGROUPLIST}"

        ## 继续循环往下遍历子组
        list_groups_info ${project}
    
    done


}


## 开始克隆或者更新所有仓库
function git_all(){
    ## 如果没有项目仓库列表，则退出
    if [ ! -f "${TMPDIR}/${REPOLIST}" ]; then

        error "${TMPDIR}/${REPOLIST} 不存在"
        exit 1

    else

        for repo in $(cat ${TMPDIR}/${REPOLIST}); do
            ## 如果目录已经存在，则直接pull更新
            if [ -d "${WORKDIR}/${repo}" ]; then

                git_pull ${repo}

            else ## 如果目录不存在，则直接克隆
                git_clone ${repo}

            fi
            
        done

    fi
}


function main(){

    h2 "开始备份..."

    ## 干活前先清理一下
    clean_tempdir

    ## 生成临时目录
    TMPDIR=$(mktemp -d -p ${WORKDIR})

    ## 先将需要克隆的所有仓库统计到一个文件中
    list_groups_info ${GROUPURL}

    ## 再将所有仓库进行克隆或者更新
    git_all

    success "备份完毕."
}

main





