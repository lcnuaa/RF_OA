*** Settings ***
Library           RequestsLibrary
Library           Collections
Library           SSHLibrary

*** Variables ***
${command}        python get_file_num.py system
${url}            172.21.108.11
${username}       root
${pwd}            35w_"{<L

*** Test Cases ***
storage test
    Create Session    api    http://172.21.111.105:1668
    ${addr}    get request    api    /storage?number=test_init_cluster_no_raid    timeout=500
    log    ${addr}
    delete all sessions

ssh执行脚本
    open connection    ${url}
    ${username}    set variable    root
    ${pwd}    set variable    35w_"{<L
    login    ${username}    ${pwd}
    write    cd /home
    comment    ${a}    execute command    ${command}
    write    ${command}
    ${a}    Read    delay=1s
    should be equal as strings    ${a}    2
    close connection

获取环境中剩余资源
    open connection    ${url}
    login    ${username}    ${pwd}
    write    python /usr/lib/python2.6/site-packages/rccsystem/testcase.py get_resource
    ${a}    Read until    }
    log    ${a}
    ${c}    to json    ${a}
    ${b}    get from dictionary    ${c}    user_disk_use_size_G
    close connection
