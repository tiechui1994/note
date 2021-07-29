# github-action

Github Actions 是 Github 推出的持续集成(CI)服务, 基于它可以进行构建, 测试, 打包, 部署项目. 简单说就是将软件开发中的
的一些流程交给云服务器自动化处理. 例如: 开发者把代码push到Github后会自动测试, 编译, 发布.

基础概念:

- workflow(工作流程): 持续集成一次运行的过程

- job(任务): 一个 workflow 由一个或多个 job 构成, 含义是一次持续集成的运行, 可以完成多个任务.

- step(步骤): 每个 job 由多个 step 构成, 一步步完成.

- action(动作): 每个 step 可以依次执行一个或多个命令(action).

## workflow

[详细文档](https://docs.github.com/cn/actions/reference/workflow-syntax-for-github-actions)

Github Actions 的配置文件叫做 workflow 文件, 存放在代码仓库的 `.github/workflows` 目录中. workflow 采用 YAML
格式, 文件名可以任意取, 但是后缀名统一为 `.yml`. 一个库可以有多个 workflow 文件, Github 只要发现 `.github/workflows`
目录里面的 `.yml` 文件, 就会按照文件中所指定的触发条件自动运行该文件中的工作流程.

案例:
```yaml
# workflow
name: Hello World
on: push
jobs:
  first_job:
    name: first job
    runs-on: ubuntu-latest
    steps:
      - name: checkout
        uses: actions/checkout@master # 拉取当前项目文件, 经常使用
      - name: run single-line script
        run: echo "Hello world"
    
  second_job:
    name: second job
    runs-on: macos-latest
    steps:
      - name: run multi-line script
        env: 
          MY_VAR: Hello World
          MY_NAME: P3TERX
        run: |
          echo $MY_VAR
          echo name is $MY_NAME
```


语法:

- `name`, name 字段是 workflow 的名称. 若忽略此字段, 则默认使用 workflow 文件名.

- `on`, on 字段指定 workflow 被触发条件, 通常是某些事件. 例如: push, 即在代码push到仓库后被触发. on 字段也可以是
事件数组, 多种事件触发.
 
```yaml
on: [push, pull_request]
```

事件(event):

```yaml
# when push BRANCH (WEB EVENT)
on:
  push:
    branches:
      - master

# when push TAG (WEB EVENT)
on:
  push:
    tags:
      - 'v*'

# when release (WEB EVENT)
on:
  release:
    types: [published]

# when fork (WEB EVENT)
on:
  fork

# when deployment (WEB EVENT)
on:
  deployment

# when create tag or branch (WEB EVENT)
on:
  create

# when delete tag or branch (WEB EVENT)
on:
  delete

# when status (git提交的状态发生变化) (WEB EVENT)
on:
  status

# when watch (有人查看你的github项目时) (WEB EVENT)
on:
  watch:
    types: [started]

# when schedule (SCHEDULE EVENT)
on:
  schedule:
    - cron: 0 */6 * * *

# when trigger event by hand [REST API] (MANUAL EVENT)
# curl \
#   -H "Accept: application/vnd.github.v3+json" \
#   https://api.github.com/repos/tiechui1994/jobs/actions/workflows
#
# curl -X POST \
#   https://api.github.com/repos/tiechui1994/jobs/actions/workflows/ID/dispatches \
#   -H 'Accept: application/vnd.github.v3+json' \
#   -H 'Authorization: token TOKEN' \
#   -H 'Content-Type: application/json' \
#   -d '{
#	  "ref":"TAG|BRANCH",
#     "inputs": {
#        "name": "NAME",
#        "url": "URL"
#     }
#   }'
workflow_dispatch:
  inputs:
    xxx:
      description: 'xxx'
      required: true|false
      default: ''
```

- `jobs`, jobs 表示要执行一项或多项任务. 每一项任务必须关联一个ID(`job_id`), 例如: 案例中的 `first_job`, `second_job`
job_id 里面的 `name` 字段是任务名称. job_id 不能有空格, 只能使用数字,英文字母,`-`和`_`符号. name 名称随意, 若忽略
name 字段, 则默认会设置为 job_id.

jobs 里的 job 是并行执行的, 当需要串行执行时, 可以指定job的依赖关系, 即顺序执行.

```yaml
# in order exec job1, job2, job3
jobs:
  job1:
  job2:
    needs: job1
  job3:
    needs: [job1, job2]
```

### job 选项

- `name`, job 名称

- `runs-on`, runs-on 指定任务运行所需的虚拟服务器环境, 是必填字段, 目前可用的虚拟机如下:

| 虚拟环境 | YAML workflow |
| ------ | -------------- |
| Windows Server 2019 | windows-latest |
| Ubuntu 20.04 | ubuntu-20.04 或 ubuntu-latest |
| Ubuntu 18.04 | ubuntu-18.04 |
| Ubuntu 16.04 | ubuntu-16.04 |
| macOS X 10.15 | macos-latest |

> 注: 每个 job 的虚拟环境都是独立的.

- `container`, 指定job所使用的容器镜像.

- `services`, 服务容器. 服务容器是 Docker 容器. github 为工作流中配置的每个 service 创建一个新的Docker容器, 并在
job 完成后销毁. job 当中的 steps 可以同一 job 的所有服务容器通信. 可以使用工作流程中配置的标签访问服务容器, 服务容器
的主机名自动映射到标签名称. 默认状况下, 属于同一 Docker 网络的所有容器之间相互显示所有端口, 但在 Docker 网络外部不会显
示任何端口. 可以指定服务的 `image` (镜像), `env` (环境变量), `volumes`(挂载), `ports`(服务外部端口映射)

```yaml
jobs:
  container-job:
    runs-on: ubuntu-latest
    # define `container-job` exec container
    container: node:10.18-jessie

    services:
      postgres:
        # Docker Hub image
        image: postgres
        env:
          POSTGRES_PASSWORD: postgres
      mysql:
        image: mysql:5.7.23
        env:
          USERNAME: root
          PASSWORD: root
        # Port mappping
        ports:
          - 6379:6379
```

- `strategy`, 使用 strategy 定义矩阵. 在 `matrix` 定义矩阵. 在 `matrix` 当中定下选项的键和值.

- `steps`, steps 字段指定每个任务的运行步骤, 可用包含一个或多个步骤. 步骤开头使用 `-` 符号. 每个步骤可以包含的选项有,
`name`(步骤名称), `uses`(步骤使用的 action 或 docker 镜像, 必填), `run`(步骤运行的命令, 必填), `env`(步骤需要
的环境变量). `timeout-minutes`(超时, 单位是分钟)

## action

action 是 Github Actions 中的重要组成部分. action 是已经编写好的步骤脚本, 存放在 Github 仓库中.

获得action的途径, [官方的action仓库](https://github.com/actions), [Github Marketplace](https://github.com/marketplace?type=actions),
或者是自己手动编写.

既然 action 是代码仓库, 当然就有版本的概念. 引用某个具有版本的 action:

```yaml
steps:
  - uses: actions/setup-node@74bc508 # commit
  - uses: actions/setup-node@v2    # tag
  - uses: actions/setup-node@master  # branch
```

## 常用的 action

[设置输出文档](https://trstringer.com/github-actions-multiline-strings/)

- 拉取当前仓库文件

```yaml
steps:
  - name: checkout
    uses: actions/checkout@master 
    with:
      persist-credentials: false
```

- 文件上传

```yaml
- uses: actions/upload-artifact@v2
  with:
    name: my-artifact
    path: path/to/artifact/world.txt
```

- 不同版本的运行环境(使用矩阵)

```yaml
strategy:
  matrix:
    node: [14.x]

steps:
  - uses: actions/setup-node@v2
    with:
      node-version: ${{ matrix.node-version }}
```

使用到的 action 有 `actions/setup-node@v2`, `actions/setup-go@v2`, `actions/setup-python@v2`, `actions/setup-java@v2`

- 系统环境变量

```yaml
steps:
  - name: set env
    run: |
      echo "TAG=mysql_5.1" >> ${{github.env}}
```

> 后续的 step 可以使用通过 ${{env.TAG}} 来引用设置的环境变量. ${{github.env}} <=> ${GITHUB_ENV}

- 条件判断

```yaml
steps:
  - name: run when success
    if: ${{ success() }}
    run: |
      echo "success"
  
  - name: run when failure
    if: ${{ failure() }}
    run: |
      echo "failure"
  
  - name: run when env
    if: ${{ success() && env.TAG }}
    run: |
      echo "${{env.TAG}}"
```

- 设置输出, 同一个 job 引用

```yaml
steps:
  - id: xxx
    run: |
      python3 version.py
      echo "::set-output name=version::$(cat /tmp/version)"
    shell: bash
  
  - name: use
    run: |
      echo "version: ${{ steps.xxx.outputs.version }}"
```

- 设置输出, 跨越 job 引用

```yaml
job1:
  runs-on: ubuntu-latest
  outputs:
    version: ${{steps.xxx.outputs.version}}
  
  steps:
    - id: xxx
      run: |
        python3 version.py
        echo "::set-output name=version::$(cat /tmp/version)"
        
job2:
  runs-on: ubuntu-latest
  needs: [job1]
  
  steps:
    - id: use
      run: |
         echo "version: ${{ needs.job1.outputs.version }}"
```


设置输出(一般是run当中执行shell命令): `echo "::set-output name={key}::{value}"`, 其中 `{key}` 是输出名称,
`{value}` 是输出的值.

引用输出/上下文:

- 在同job下引用:

可以采用 `${{ steps.<stepid>.outputs.<key> }}` 的方式引用输出的值, 其中 `<stepid>` 是step的id, `<key>` 是输
出名称.

- 跨越job引用: 

首先, 要想跨越job使用, 则在输出结果的 job 当中需要添加 `outputs`, 设置对应的结果.  

其次, 在引用的job当中, 必须添加 `needs` 依赖, 保证被引用结果的 job 在此之前执行.

最后, 引用的方式是 `${{ needs.<jobid>.outputs.<key> }}`

- 引用其他变量: `${{ github.xxx }}`(github内置变量), `${{ secrets.xxx }}`(用户设置的secret变量)


一个完整案例:

```yaml
name: generate tzdb
on:
  schedule:
    - cron: '*/30 12 * * *'

jobs:
  build-job:
    name: build source code
    runs-on: ubuntu-latest

    steps:
      - name: checkout code
        uses: actions/checkout@v2
        with:
          persist-credentials: false

      - id: build
        name: build code
        run: |
          python3 version.py
          echo "::set-output name=version::$(cat /tmp/version)"
        shell: bash
      
      - name: upload tzdb
        if: ${{ steps.build.outputs.version }}
        uses: actions/upload-artifact@master
        with:
          name: ${{ steps.build.outputs.version }}_zoneinfo.zip
          path: ${{ github.workspace }}/${{ steps.build.outputs.version }}_zoneinfo.zip
      
      - name: release version
        if: ${{ steps.build.outputs.version }}
        uses: svenstaro/upload-release-action@v2
        with:
          repo_token: ${{ secrets.TOKEN }}
          file: ${{ github.workspace }}/${{s teps.build.outputs.version }}_zoneinfo.zip
          asset_name: ${{ steps.build.outputs.version }}_zoneinfo.zip
          tag: ${{ steps.build.outputs.version }}
          overwrite: true
          body: "release tzdb ${{steps.build.outputs.version}}"
```
