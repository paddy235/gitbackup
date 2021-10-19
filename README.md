# gitbackup

专门克隆gitlab仓库，包括克隆仓库对应的wiki

https://gitee.com/paddy235/gitbackup


# gitbackup

#### 介绍
专门克隆gitlab仓库，包括克隆仓库对应的wiki

* 给定克隆的项目路径，会克隆目录下所有授权可访问的项目仓库
* 可以重复执行
* 当发现有更新的仓库,会使用git pull拉取更新
* 当发现wiki有更新,会使用git pull拉取更新
* 当使用了[其他工具ghorg](https://github.com/gabrie30/ghorg)克隆仓库，但是没有包含没有克隆wiki，则会补充克隆wiki




#### 软件架构

原理是先将需要克隆的仓库汇总到一起，然后逐一克隆每个仓库，顺便把每个仓库的wiki一起克隆

#### 安装教程

1.  前提准备-jq

官方源代码地址：https://github.com/stedolan/jq

mac 安装:
brew install jq

centos 安装：
yum install jq

ubuntu: 安装：
apt-get install jq

手动安装：

从https://github.com/stedolan/jq/releases 选择适合的版本文件，下载到操作系统中。


2. 前提准备-git

安装参考： 

https://git-scm.com/book/zh/v2/%E8%B5%B7%E6%AD%A5-%E5%AE%89%E8%A3%85-Git

3.  版本库的访问令牌

拥有读取api和仓库的权限

#### 使用说明

1.  配置脚本变量

GITBASEURL=${2-"https://gitlab.xxx.xxx"}

GITLAB_TOKEN=${3-"xxxxxxxxxxxxxxxxxxxxxxxx"}

2.  运行脚本

GitBackup.sh脚本所在目录位置即为工作目录，会在当下目录生成仓库组目录结构。

`./GitBackup.sh 组路径`


例如： `./GitBackup.sh projects/webapps/abb-code`

3.  xxxx

#### 参与贡献

1.  Fork 本仓库
2.  新建 Feat_xxx 分支
3.  提交代码
4.  新建 Pull Request


#### 特技

1.  使用 Readme\_XXX.md 来支持不同的语言，例如 Readme\_en.md, Readme\_zh.md
2.  Gitee 官方博客 [blog.gitee.com](https://blog.gitee.com)
3.  你可以 [https://gitee.com/explore](https://gitee.com/explore) 这个地址来了解 Gitee 上的优秀开源项目
4.  [GVP](https://gitee.com/gvp) 全称是 Gitee 最有价值开源项目，是综合评定出的优秀开源项目
5.  Gitee 官方提供的使用手册 [https://gitee.com/help](https://gitee.com/help)
6.  Gitee 封面人物是一档用来展示 Gitee 会员风采的栏目 [https://gitee.com/gitee-stars/](https://gitee.com/gitee-stars/)
