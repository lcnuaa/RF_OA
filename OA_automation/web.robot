*** Settings ***
Suite Setup       # 启动前先关闭远程java服务 stop remote server
Suite Teardown    # MyLibrary.excute automail script
Library           Collections
Library           String
Library           Selenium2Library
Library           AutoItLibrary
Library           MyLibrary.py
Library           RequestsLibrary

*** Variables ***
${url}            http://172.21.108.11
${正确执行返回码}        ${0}
&{header}         Content-Type=application/json;charset=UTF-8
${image_path}     E:\\RF_project\\OA_test\\OA_automation\\user_excel

*** Test Cases ***
查看镜像信息
    [Tags]    a
    Create Session    api    ${url}
    ${dict}    create dictionary    Content-Type=application/json;charset=UTF-8
    ${addr}    get request    api    /module/image/getImages    headers=${dict}
    ${data}    to json    ${addr.content}    True
    log    ${data}
    delete all sessions

修改镜像内容
    [Tags]    a
    Create Session    api    ${url}
    #先查询需要修改的镜像
    ${镜像信息}    get request    api    /module/image/getImages    headers=${header}
    ${data}    to json    ${镜像信息.content}
    ${镜像信息数据}    get from dictionary    ${data}    images
    #通过镜像id修改该镜像
    #但是首先要判断非个性化才能修改
    : FOR    ${单个镜像信息}    IN    @{镜像信息数据}
    \    log    ${单个镜像信息}
    \    ${镜像id}    get from dictionary    ${单个镜像信息}    imageId
    \    ${桌面类型}    get from dictionary    ${单个镜像信息}    deskTop
    \    ${系统类型id}    get from dictionary    ${单个镜像信息}    osId
    \    ${系统盘容量}    get from dictionary    ${单个镜像信息}    sysDiskCap
    \    ${cpu类型}    get from dictionary    ${单个镜像信息}    cpuType
    \    ${镜像名称}    get from dictionary    ${单个镜像信息}    imageName
    \    ${coresconfig}    get from dictionary    ${单个镜像信息}    coresconfig
    \    exit for loop if    "${桌面类型}"=="0"    #桌面类型为共享的时候跳出循环
    log    ${镜像id}
    #所有数据都要添加
    ${dict}    Create Dictionary    imageId=${镜像id}    memoryCap=2048    deskTop=0    open=true    start=false
    ...    osId=${系统类型id}    sysDiskCap=${系统盘容量}    cpuCount=1    cpuType=${cpu类型}    imageName=${镜像名称}    coresconfig=${coresconfig}
    comment    start参数为true时候失败
    ${aa}    post request    api    /module/image/modifyImage    data=${dict}    params=None    headers=${header}
    should be equal as strings    ${aa.status_code}    200
    ${bb}    to json    ${aa.content}
    ${返回结果码result}    get from dictionary    ${bb}    result
    should be equal    ${返回结果码result}    ${正确执行返回码}    修改镜像失败
    delete all sessions

复制镜像
    [Tags]    a
    Create Session    api    ${url}
    #先查询需要复制的镜像
    ${镜像信息}    get request    api    /module/image/getImages    headers=${header}
    ${data}    to json    ${镜像信息.content}
    ${镜像信息数据}    get from dictionary    ${data}    images
    #通过镜像id复制该镜像
    #复制个性化镜像
    :FOR    ${单个镜像信息}    IN    @{镜像信息数据}
    \    log    ${单个镜像信息}
    \    ${镜像id}    get from dictionary    ${单个镜像信息}    imageId
    \    ${镜像名称}    get from dictionary    ${单个镜像信息}    imageName
    \    ${镜像文件名}    get from dictionary    ${单个镜像信息}    imageFileName
    \    ${cpu个数}    get from dictionary    ${单个镜像信息}    cpuCount
    \    ${内存}    get from dictionary    ${单个镜像信息}    memoryCap
    \    ${系统id}    get from dictionary    ${单个镜像信息}    osId
    \    ${是否启用}    get from dictionary    ${单个镜像信息}    open
    \    ${桌面类型}    get from dictionary    ${单个镜像信息}    deskTop
    \    exit for loop if    "${桌面类型}"=="1"    #桌面类型为个性的时候跳出循环
    ${镜像名称}    set variable    复制个性化镜像
    ${dict}    create dictionary    imageId=${镜像id}    imageName=${镜像名称}    imageFileName=${镜像文件名}    cpuCount=${cpu个数}    memoryCap=${内存}
    ...    osId=${系统id}    open=${是否启用}    deskTop=${桌面类型}
    ${aa}    post request    api    /module/image/copyImage    data=${dict}    params=None    headers=${header}
    should be equal as strings    ${aa.status_code}    200
    ${bb}    to json    ${aa.content}
    ${返回结果码result}    get from dictionary    ${bb}    result
    should be equal    ${返回结果码result}    ${正确执行返回码}    复制个性镜像失败
    delete all sessions

新增用户组
    [Tags]    a
    create session    url    ${url}
    ${header}    create dictionary    Content-Type=application/json
    ${镜像信息}    get request    url    /module/image/getImages    headers=${header}
    ${data}    to json    ${镜像信息.content}
    ${镜像信息数据}    get from dictionary    ${data}    images
    ${镜像个数}    get length    ${镜像信息数据}
    ${镜像ID数组}    create list
    : FOR    ${单个镜像信息}    IN    @{镜像信息数据}
    \    log    ${单个镜像信息}
    \    ${单个镜像ID}    get from dictionary    ${单个镜像信息}    imageId
    \    append to list    ${镜像ID数组}    ${单个镜像ID}
    log    ${镜像ID数组}
    ${新增用户组数据}    create dictionary    groupName=哲学    description=xx    vlanId=100    bridge=0    adDomainEnable=true
    ...    imageIds=${镜像ID数组}
    #用户组新增vlan，bridge，是否加入AD域字段
    ${新增用户组}    post request    url    /module/userGroup/addUserGroup    data=${新增用户组数据}    params=None    headers=${header}
    should be equal as strings    ${新增用户组.status_code}    200
    delete all sessions

查询单个用户组（先查询所有用户组获取id和名字）
    [Tags]    a
    create session    url    ${url}
    ${header}    create dictionary    Content-Type=application/json
    ${查询所有用户组}    get request    url    /module/userGroup/getUserGroups    headers=${header}
    ${查询所有用户组结果}    to json    ${查询所有用户组.content}
    ${用户组信息列表}    get from dictionary    ${查询所有用户组结果}    list
    ${用户组ID数组}    create list
    ${用户组名字数组}    create list
    : FOR    ${单个用户组信息}    IN    @{用户组信息列表}
    \    ${单个用户组ID}    get from dictionary    ${单个用户组信息}    id
    \    ${单个用户组名字}    get from dictionary    ${单个用户组信息}    name
    \    append to list    ${用户组名字数组}    ${单个用户组名字}
    \    append to list    ${用户组ID数组}    ${单个用户组ID}
    comment    可以通过用户组名来进行查询
    ${查询单个用户组}    get request    url    /module/userGroup/getUserGroup/${用户组ID数组[1]}    headers=${header}
    should be equal as strings    ${查询单个用户组.status_code}    200
    delete all sessions

修改用户组
    [Tags]    a
    create session    url    ${url}
    ${header}    create dictionary    Content-Type=application/json
    ${查询所有用户组}    get request    url    /module/userGroup/getUserGroups    headers=${header}
    ${查询所有用户组结果}    to json    ${查询所有用户组.content}
    ${用户组信息列表}    get from dictionary    ${查询所有用户组结果}    list
    ${用户组ID数组}    create list
    ${用户组名字数组}    create list
    : FOR    ${单个用户组信息}    IN    @{用户组信息列表}
    \    ${单个用户组ID}    get from dictionary    ${单个用户组信息}    id
    \    ${单个用户组名字}    get from dictionary    ${单个用户组信息}    name
    \    append to list    ${用户组名字数组}    ${单个用户组名字}
    \    append to list    ${用户组ID数组}    ${单个用户组ID}
    ${下标}    set variable    '0'
    : FOR    ${index}    ${name}    IN ENUMERATE    @{用户组名字数组}
    \    ${下标}    set variable    ${index}
    \    run keyword if    '${name}'=='哲学'    exit for loop
    ${dict}    create dictionary    groupId=${用户组ID数组[${下标}]}    groupName=法学    description=这是为什么    vlanId=200    adDomainEnable=false
    ...    #imageIds,bridge根据需求增加
    ${修改用户组}    post request    url    /module/userGroup/modifyUserGroup    data=${dict}    params=None    headers=${header}
    ${修改用户组返回信息}    to json    ${修改用户组.content}
    should be equal as strings    ${修改用户组.status_code}    200
    delete all sessions

修改用户组绑定镜像
    [Tags]    a
    [Timeout]    5 seconds
    delete all sessions
    create session    url    ${url}
    ${header}    create dictionary    Content-Type=application/json
    ${查询所有用户组}    get request    url    /module/userGroup/getUserGroups    headers=${header}
    ${查询所有用户组结果}    to json    ${查询所有用户组.content}
    ${用户组信息列表}    get from dictionary    ${查询所有用户组结果}    list
    ${用户组ID数组}    create list
    ${用户组名字数组}    create list
    : FOR    ${单个用户组信息}    IN    @{用户组信息列表}    #取出用户组名字及其对应ID
    \    ${单个用户组ID}    get from dictionary    ${单个用户组信息}    id
    \    ${单个用户组名字}    get from dictionary    ${单个用户组信息}    name
    \    append to list    ${用户组名字数组}    ${单个用户组名字}
    \    append to list    ${用户组ID数组}    ${单个用户组ID}
    ${下标}    set variable    '0'
    : FOR    ${index}    ${name}    IN ENUMERATE    @{用户组名字数组}    #取出用户组名字数组中的下标
    \    ${下标}    set variable    ${index}
    \    run keyword if    '${name}'=='法学'    exit for loop
    ${addr}    get request    url    /module/image/getImages    headers=${header}
    ${data}    to json    ${addr.content}
    ${所有镜像信息列表}    get from dictionary    ${data}    images
    ${镜像ID列表}    create list
    : FOR    ${单个镜像信息}    IN    @{所有镜像信息列表}    #取出镜像ID
    \    ${单个镜像ID}    get from dictionary    ${单个镜像信息}    imageId
    \    append to list    ${镜像ID列表}    ${单个镜像ID}
    log    ${镜像ID列表}
    ${移除的值}    remove from list    ${镜像ID列表}    0
    ${dict}    create dictionary    groupId=${用户组ID数组[${下标}]}    groupName=法学    description=呵呵    imageIds=${镜像ID列表}
    log    ${镜像ID列表}
    log    ${dict}
    ${修改用户组绑定镜像}    post request    url    /module/userGroup/modifyUserGroup/bindImages    data=${dict}    params=None    headers=${header}
    should be equal as strings    ${修改用户组绑定镜像.status_code}    200
    delete all sessions

删除用户组
    [Tags]    a
    create session    url    ${url}
    ${header}    create dictionary    Content-Type=application/json
    ${查询所有用户组}    get request    url    /module/userGroup/getUserGroups    headers=${header}
    ${查询所有用户组结果}    to json    ${查询所有用户组.content}
    ${用户组信息列表}    get from dictionary    ${查询所有用户组结果}    list
    ${用户组ID数组}    create list
    ${用户组名字数组}    create list
    : FOR    ${单个用户组信息}    IN    @{用户组信息列表}
    \    ${单个用户组ID}    get from dictionary    ${单个用户组信息}    id
    \    ${单个用户组名字}    get from dictionary    ${单个用户组信息}    name
    \    append to list    ${用户组名字数组}    ${单个用户组名字}
    \    append to list    ${用户组ID数组}    ${单个用户组ID}
    ${下标}    set variable    '0'
    ${删除用户组ID对应下标列表}    create list
    : FOR    ${index}    ${name}    IN ENUMERATE    @{用户组名字数组}
    \    ${下标}    set variable    ${index}
    \    run keyword if    '${name}'=='法学' or '${name}'=='科学'    append to list    ${删除用户组ID对应下标列表}    ${下标}
    log    ${删除用户组ID对应下标列表}
    log    ${用户组ID数组}
    reverse list    ${删除用户组ID对应下标列表}    #需要先倒转列表，从后开始往前删除，否则每次删除，列表下标都会变化
    ${删除用户组对应的ID列表}    create list
    : FOR    ${i}    IN    @{删除用户组ID对应下标列表}
    \    log    ${i}
    \    ${j}    remove from list    ${用户组ID数组}    ${i}
    \    append to list    ${删除用户组对应的ID列表}    ${j}
    \    log    ${用户组ID数组}
    : FOR    ${i}    IN    @{删除用户组对应的ID列表}
    \    ${删除用户组}    get request    url    /module/userGroup/deleteUserGroup/${i}    headers=${header}
    \    should be equal as strings    ${删除用户组.status_code}    200
    #web uri不支持列表传输，只能通过循环去逐个删除
    delete all sessions

查询/定位用户
    [Tags]    a
    Create Session    api    ${url}
    ${addr}    get request    api    /module/seat/getSeats/1/200/1    headers=${header}
    ${返回结果}    to json    ${addr.content}
    ${页面中的所有信息}    get from dictionary    ${返回结果}    page
    ${用户结果信息}    get from dictionary    ${页面中的所有信息}    result
    ${用户个数}    get length    ${用户结果信息}
    ${用户ID数组}    create list
    : FOR    ${单个用户信息}    IN    @{用户结果信息}
    \    log    ${单个用户信息}
    \    ${单个用户ID}    get from dictionary    ${单个用户信息}    seatId
    \    append to list    ${用户ID数组}    ${单个用户ID}
    log    ${用户ID数组}
    delete all sessions

新增单个用户
    [Tags]    a
    Create Session    url    ${url}
    #新增个性化用户
    ${dict}    create dictionary    groupId=1    imageId=10004    userName=lc    userPwd=q    vmIP=1.1.1.2
    ...    vmMask=255.255.255.0    vmGateway=1.1.1.1    vmDns=8.8.8.8    diskSize=20    cmAdmin=true
    ${addr}    post request    url    /module/seat/addSeat    data=${dict}    params=None    headers=${header}
    ...    timeout=10
    should be equal as strings    ${addr.status_code}    200
    ${返回结果}    to json    ${addr.content}
    ${返回结果码result}    get from dictionary    ${返回结果}    result
    ${返回错误信息errmsg}    get from dictionary    ${返回结果}    errMsg
    should be equal    ${返回结果码result}    ${正确执行返回码}    新建用户失败,${返回错误信息errmsg}
    #新增共享用户
    delete all sessions

修改用户
    [Tags]    a
    Create Session    url    ${url}
    comment    ${header}    create dictionary    Content-Type=application/json
    #修改用户，需要传入seatid
    ${data}    create dictionary    seatId=96    groupId=1    userName=lc    userPwd=q    vmIP=1.1.1.70
    ...    vmMask=255.255.254.0    vmGateway=1.1.1.1    vmDns=8.8.8.8    vmCpuCount=8    vmMemoryCap=1024    vmSysDiskCap=40
    ...    cmAdmin=false    universalDesktop=true    imageId=10000
    ${修改用户web返回结果}    post request    url    /module/seat/modifySeat    data=${data}    params=None    headers=&{header}
    ...    timeout=10
    should be equal as strings    ${修改用户web返回结果.status_code}    200
    ${修改用户返回结果}    to json    ${修改用户web返回结果.content}
    ${返回结果码result}    get from dictionary    ${修改用户返回结果}    result
    ${返回错误信息error_message}    get from dictionary    ${修改用户返回结果}    errMsg
    should be equal    ${返回结果码result}    ${正确执行返回码}    修改用户失败,${返回错误信息error_message}
    delete all sessions

批量创建用户（仅为web端，存储暂未查询）
    [Tags]    a
    create session    url    ${url}
    ${header}    create dictionary    Content-Type=application/json
    ${dict}    create dictionary    groupId=1    imageId=10000    userNamePrefix=lcn    userNameStart=1    userPwd=q
    ...    vmIPStart=1.1.1.42    vmMask=255.255.255.0    vmGateway=1.1.1.1    vmDns=8.8.8.8    diskSize=20    seatCount=5
    ${addr}    post request    url    /module/seat/addSeats    data=${dict}    params=None    headers=${header}
    ...    timeout=20
    should be equal as strings    ${addr.status_code}    200
    ${返回结果}    to json    ${addr.content}
    ${返回结果码result}    get from dictionary    ${返回结果}    result
    should be equal    ${返回结果码result}    ${正确执行返回码}    批量新建用户失败
    delete all sessions
    #加入inst，disk的查询

获取填充用户参数
    [Tags]    a
    create session    url    ${url}
    ${header}    create dictionary    Content-Type=application/json
    ${获取填充用户参数}    get request    url    /module/seat/getFillParas/1    headers=${header}
    ${返回结果}    to json    ${获取填充用户参数.content}

批量填充用户
    [Tags]    a
    create session    url    ${url}
    ${header}    create dictionary    Content-Type=application/json
    ${dict}    create dictionary    groupId=1    vmIPStart=1.1.1.10    vmMask=255.255.255.0    vmGateway=1.1.1.1    fillCount=3
    ${批量填充用户web响应结果}    post request    url    /module/seat/fillSeats    data=${dict}    params=None    headers=${header}
    ...    timeout=20
    should be equal as strings    ${批量填充用户web响应结果.status_code}    200
    ${批量填充用户数据结果}    to json    ${批量填充用户web响应结果.content}
    ${返回结果码result}    get from dictionary    ${批量填充用户数据结果}    result
    ${正确执行返回码}    set variable    ${0}
    should be equal    ${返回结果码result}    ${正确执行返回码}    批量填充用户失败
    delete all sessions

批量删除用户
    [Tags]    a
    create session    url    ${url}
    ${header}    create dictionary    Content-Type=application/json
    ${查询用户}    get request    url    /module/seat/getSeats/1/200/1    headers=${header}
    ${返回结果}    to json    ${查询用户.content}
    ${页面中的所有信息}    get from dictionary    ${返回结果}    page
    ${用户结果信息}    get from dictionary    ${页面中的所有信息}    result
    ${用户个数}    get length    ${用户结果信息}
    ${用户ID数组}    create list
    ${婷凌的用户}    set variable    ltl
    : FOR    ${单个用户信息}    IN    @{用户结果信息}
    \    log    ${单个用户信息}
    \    ${单个用户ID}    get from dictionary    ${单个用户信息}    seatId
    \    ${某用户}    get from dictionary    ${单个用户信息}    userName
    \    log    ${某用户}
    \    run keyword if    '${某用户}'!='${婷凌的用户}'    append to list    ${用户ID数组}    ${单个用户ID}
    ${删除指定用户}    create dictionary    groupId=1    seatIds=${用户ID数组}
    ${addr}    post request    url    /module/seat/deleteSeats    data=${删除指定用户}    params=None    headers=${header}
    ...    timeout=20
    should be equal as strings    ${addr.status_code}    200
    ${批量删除用户的返回结果}    to json    ${addr.content}
    ${返回结果码result}    get from dictionary    ${批量删除用户的返回结果}    result
    ${正确执行返回码}    set variable    ${0}
    should be equal    ${返回结果码result}    ${正确执行返回码}    批量新建用户失败
    delete all sessions

（个性化场景下）还原系统盘
    [Tags]    a
    create session    url    ${url}
    ${镜像信息}    get request    url    /module/image/getImages    headers=${header}
    ${data}    to json    ${镜像信息.content}
    ${镜像信息数据}    get from dictionary    ${data}    images
    ${镜像个数}    get length    ${镜像信息数据}
    ${镜像ID数组}    create list
    : FOR    ${单个镜像信息}    IN    @{镜像信息数据}
    \    log    ${单个镜像信息}
    \    ${单个镜像ID}    get from dictionary    ${单个镜像信息}    imageId
    \    append to list    ${镜像ID数组}    ${单个镜像ID}    #获取已有的镜像id数组
    #新建一个用户
    ${dict}    create dictionary    groupId=1    imageId=10000    userName=lctest    userPwd=q    vmIP=1.1.1.2
    ...    vmMask=255.255.255.0    vmGateway=1.1.1.1    vmDns=8.8.8.8    diskSize=20    cmAdmin=true
    ${addr}    post request    url    /module/seat/addSeat    data=${dict}    params=None    headers=${header}
    ...    timeout=10
    should be equal as strings    ${addr.status_code}    200
    ${新增用户结果}    to json    ${addr.content}
    log    ${新增用户结果}
    #查询该新增用户的用户ID
    ${单个用户数据}    get from dictionary    ${新增用户结果}    seat
    ${新增用户ID}    get from dictionary    ${单个用户数据}    seatId
    #修改该用户的绑定镜像，即还原
    ${data}    get request    url    /module/seat/restoreSysDisk/${新增用户ID}/10001    headers=${header}
    ${修改用户返回结果}    to json    ${data.content}
    should be equal as strings    ${data.status_code}    200
    delete all sessions
    [Teardown]    delete all sessions    # 删除所有连接

统一分配资源账号
    [Tags]    b
    create session    url    ${url}
    ${header}    create dictionary    Content-Type=application/json
    ${addr}    get request    url    /module/seat/getSeats/1/200/1    headers=${header}
    ${返回结果}    to json    ${addr.content}
    ${页面中的所有信息}    get from dictionary    ${返回结果}    page
    ${用户结果信息}    get from dictionary    ${页面中的所有信息}    result
    ${用户ID数组}    create list
    ${婷凌的用户}    set variable    ltl
    : FOR    ${单个用户信息}    IN    @{用户结果信息}
    \    log    ${单个用户信息}
    \    ${单个用户ID}    get from dictionary    ${单个用户信息}    seatId
    \    ${某用户}    get from dictionary    ${单个用户信息}    userName
    \    log    ${某用户}
    \    run keyword if    '${某用户}'!='${婷凌的用户}'    append to list    ${用户ID数组}    ${单个用户ID}
    ${分配资源账号web响应结果}    post request    url    /module/seat/ccr/assign    data=${用户ID数组}    params=None    headers=${header}
    ...    timeout=20
    should be equal as strings    ${分配资源账号web响应结果.status_code}    200
    ${分配资源账号的返回结果}    to json    ${分配资源账号web响应结果.content}
    ${返回结果码result}    get from dictionary    ${分配资源账号的返回结果}    result
    ${返回错误信息error_message}    get from dictionary    ${分配资源账号的返回结果}    errMsg
    ${正确执行返回码}    set variable    ${0}
    should be equal    ${返回结果码result}    ${正确执行返回码}    分配用户资源账号失败,${返回错误信息error_message}
    delete all sessions

统一回收资源账号（有分配且未使用的才回收）
    [Tags]    b
    create session    url    ${url}
    ${header}    create dictionary    Content-Type=application/json
    ${addr}    get request    url    /module/seat/getSeats/1/200/1    headers=${header}
    ${返回结果}    to json    ${addr.content}
    ${页面中的所有信息}    get from dictionary    ${返回结果}    page
    ${用户结果信息}    get from dictionary    ${页面中的所有信息}    result
    ${用户ID数组}    create list
    ${婷凌的用户}    set variable    ltl
    : FOR    ${单个用户信息}    IN    @{用户结果信息}
    \    log    ${单个用户信息}
    \    ${单个用户ID}    get from dictionary    ${单个用户信息}    seatId
    \    ${某用户}    get from dictionary    ${单个用户信息}    userName
    \    log    ${某用户}
    \    run keyword if    '${某用户}'!='${婷凌的用户}'    append to list    ${用户ID数组}    ${单个用户ID}
    ${检查是否有资源账号web响应结果}    post request    url    /module/seat/ccr/checkSeatForCCR    data=${用户ID数组}    params=None    headers=${header}
    ...    timeout=20
    should be equal as strings    ${检查是否有资源账号web响应结果.status_code}    200
    ${分配资源账号的返回结果}    to json    ${检查是否有资源账号web响应结果.content}
    log    ${分配资源账号的返回结果}
    ${返回结果码result}    get from dictionary    ${分配资源账号的返回结果}    result
    ${返回错误信息error_message}    get from dictionary    ${分配资源账号的返回结果}    errMsg
    ${正确执行返回码}    set variable    ${0}
    should be equal    ${返回结果码result}    ${正确执行返回码}    检查用户资源账号失败,${返回错误信息error_message}
    ${取消资源账号授权web响应结果}    post request    url    /module/seat/ccr/cancel    data=${用户ID数组}    params=None    headers=${header}
    ...    timeout=20
    should be equal as strings    ${取消资源账号授权web响应结果.status_code}    200
    ${取消资源账号的返回结果}    to json    ${取消资源账号授权web响应结果.content}
    log    ${取消资源账号的返回结果}
    ${返回结果码result}    get from dictionary    ${取消资源账号的返回结果}    result
    ${返回错误信息error_message}    get from dictionary    ${取消资源账号的返回结果}    errMsg
    ${正确执行返回码}    set variable    ${0}
    should be equal    ${返回结果码result}    ${正确执行返回码}    取消用户资源账号失败,${返回错误信息error_message}
    delete all sessions

下载excel模板
    [Tags]    b
    open browser    ${url}
    maximize browser window
    add image path    ${image_path}
    log    ${image_path}
    sleep    1
    Selenium2Library.input text    xpath=.//*[@id='j_username']    admin1
    comment    sleep    5
    click element    xpath=.//*[@id='j_password_text']
    sleep    3
    Selenium2Library.input text    xpath=.//*[@id='j_password']    admin1
    comment    sleep    3
    click element    xpath=.//*[@id='form1']/table/tbody/tr[5]/td/div/div
    sleep    3
    click element    xpath=.//*[@id='menuContainer']/div[2]/div[5]/div/a
    sleep    3
    click    download_module.png
    sleep    5
    click    download.png
    sleep    10
    close browser
    click    desktop.png
    Run Keyword And Continue On Failure    screen should contain    class_excel.png
    stop remote server
    [Teardown]    stop remote server    # 每次都关闭java进程，无论成功与否

导入excel模板
    [Tags]    b
    open browser    ${url}
    maximize browser window
    add image path    ${image_path}
    sleep    1
    Selenium2Library.input text    xpath=.//*[@id='j_username']    admin1
    comment    sleep    5
    click element    xpath=.//*[@id='j_password_text']
    sleep    2
    Selenium2Library.input text    xpath=.//*[@id='j_password']    admin1
    comment    sleep    3
    click element    xpath=.//*[@id='form1']/table/tbody/tr[5]/td/div/div
    sleep    3
    click element    xpath=.//*[@id='menuContainer']/div[2]/div[5]/div/a
    sleep    3
    click    import_excel.png
    sleep    3
    click    upload_excel.png
    sleep    3
    SikuliLibrary.input text    filename.png    test.xls
    sleep    3
    click    open_file.png
    sleep    2
    click    ok.png
    close browser
    stop remote server
    [Teardown]    stop remote server    # 每次都关闭java进程，无论成功与否

批量还原（未完成针对个性化用户）
    Create Session    url    ${url}
    ${header}    create dictionary    Content-Type=application/json
    #新建用户组，取出组id    #imageid暂时先用已有的镜像id
    ${新增用户组数据}    create dictionary    groupName=哲学    description=xx    vlanId=1000    bridge=0    adDomainEnable=true
    ...    imageIds=${镜像ID数组}
    ${新增用户组}    post request    url    /module/userGroup/addUserGroup    data=${新增用户组数据}    params=None    headers=${header}
    should be equal as strings    ${新增用户组.status_code}    200
    #新建用户
    #查找用户id
    #再查找所需要还原的系统id
    ${addr}    get request    url    /module/seat/batchRestoreSysDisk/{seatid}/{imageid}    params=None    headers=${header}    timeout=10
    should be equal as strings    ${addr.status_code}    200
    ${返回结果}    to json    ${addr.content}
    ${返回结果码result}    get from dictionary    ${返回结果}    result
    ${返回错误信息errmsg}    get from dictionary    ${返回结果}    errMsg
    should be equal    ${返回结果码result}    ${正确执行返回码}    批量还原系统盘失败,${返回错误信息errmsg}
    delete all sessions

批量切换（未完成个性共享切换）
    Create Session    url    ${url}
    ${header}    create dictionary    Content-Type=application/json
    ${addr}    get request    api    /module/seat/getSeats/1/200/1    headers=${header}
    ${返回结果}    to json    ${addr.content}
    ${页面中的所有信息}    get from dictionary    ${返回结果}    page
    ${用户结果信息}    get from dictionary    ${页面中的所有信息}    result
    ${用户个数}    get length    ${用户结果信息}
    ${用户ID数组}    create list
    : FOR    ${单个用户信息}    IN    @{用户结果信息}
    \    log    ${单个用户信息}
    \    ${单个用户ID}    get from dictionary    ${单个用户信息}    seatId
    \    append to list    ${用户ID数组}    ${单个用户ID}
    log    ${用户ID数组}
    ${镜像类型切换共享到个性化}    get request    url    /module/seat/batchSeatTypeModify/${用户ID数组}/{imageid}/{desktop}    data=${新增用户组数据}    params=None    headers=${header}
    should be equal as strings    ${新增用户组.status_code}    200

批量切换（未完成，共享切换为个性化）

新增镜像（osid有问题）
    [Tags]
    Create Session    api    ${url}
    ${header}    create dictionary    Content-Type=application/json
    ${dict}    Create Dictionary    imageName=test    imageFileName=test1    isoId=xx    #isois参数加进去就有问题，待讨论
    ${aa}    post request    api    /module/image/addImage    data=${dict}    params=None    headers=${header}
    log    ${aa}
    log    ${aa.content}
    should be equal as strings    ${aa.status_code}    200
    delete all sessions
