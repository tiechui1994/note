# gitlab-ci.yml 配置

在每个项目中, 使用名为 `.gitlab-ci.yml` 的 YAML 文件配置 GitLab CI/CD piplines.

> 管道是持续集成, 交付和部署的顶级组件.
>
> 管道包括:
>
> - 作业(job), 定义要做什么, 例如 build 或者 test 代码的 job
> - 阶段(stages), 定义何时运行 job, 例如, 在 build 代码的阶段之后运行 Test 代码的 stage.
>
> job 是由 runner 执行. 如果有足够的并行运行器, 则可以并行执行同一阶段(stage)中的多个job.
>
> 如果一个阶段中的所有的 job 都执行成功, 则管道将继续运行下一个阶段.
>
> 如果某个阶段中的任何一个 job 执行失败, 则(通常)不会执行下一阶段, 并且管道会提前结束.
>
> 典型的管道可能包括四个阶段:
> - build, 其 job 称为 `compile`
> - test, 具有两个job, `test1` 和 `test2`
> - staging, 其 job 称为 `deploy-to-stage`
> - production, 其 job 称为 `deploy-to-prod`

管道(pipline)配置从作业(job)开始. 作业是 `.gitlab-ci.yml` 文件的最基本元素.

作业是:
- 定义了约束, 指出应在什么条件下执行它们.
- 具有任意名称的顶级元素, 并且必须至少包含 `script` 子句.
- 不限制可以定义多少.

example:

```yaml
job1:
    script: "job1的执行脚本命令(shell)"

job2:
    script:
      - "job2的脚本命令1(shell)"
      - "job2的脚本命令2(shell)"
```

> 上述的文件是最简单的CI配置例子, 每个job都执行了不同的命令, 其中job1只执行了一条命令, job2通过数组的定义按顺序执行了
2条命令.

`job` 配置会被 `Runner` 读取并用于构建项目, 并且在 `Runner` 的环境中被执行. 很重要的一点是, 每个 `job` 都会独立的
运行, 相互间并不依赖.

**每个 job 必须具有唯一的名称, 但是有一些保留的 keywords 不能用于 job 名称:**
- `image`
- `services`
- `stages`
- `types`
- `before_script`
- `after_script`
- `variables`
- `cache`
- `include`

## 全局范围配置参数

| 保留字 | 必填 | 说明 |
| --- | --- | --- |
| image | 否 | 构建使用的Docker镜像名称, 使用Docker作为Excutor时有效 |
| services | 否 | 使用的Docker服务, 使用Docker作为Excutor时有效 |
| stages | 否 | 定义构建的stages | 
| before_script | 否 | 定义所有job执行之前需要执行的脚本命令 |
| after_script | 否 | 定义所有job执行完成后需要执行的脚本命令 |
| variables | 否 | 定义构建变量 |
| cache | 否 | 定义一组文件, 该组文件会在运行时被缓存, 下次运行仍然可以使用 |

- image 和 services

example:

```yaml
services:
  - name: postgres:11.7
    alias: db
    entrypoint: ["docker-entrypoint.sh"]
    command: ["postgres"]

image:
  name: ruby:2.6
  entrypoint: ["/bin/bash"]
```



- stages

用以定义可以被 `job` 使用的 `stage`. 定义 `stages` 可以实现柔性的多 `stage` 执行管道.

`stages` 定义的元素顺序决定了构建的执行顺序:

```
1. 同一stage的job是并行执行的.
2. 下一stage的jobs是当上一个stage的jobs全部执行完成后才会执行.
```

stages 案例:

```yaml
stages:
    - build
    - test 
    - deploy
```

> 首先, 所有stage属性为build的job会被并行执行.
>
> 如果所有stage属性为build是job都执行成功了, stage为test的job会被并行执行. 
>
> 如果所有stage属性为test是job都执行成功了, stage为deploy的job会被并行执行. 
>
> 如果所有stage属性为deploy是job都执行成功了, 则提交被标记为success.
>
> 如果任何一个前置的job失败了, 则提交被标记为failed并且任何下一个stage的job都不会被执行.


> 1.如果配置文件中没有定义stages, 那么默认情况下的stages属性为build、test和deploy.
> 2.如果一个job没有定义stage属性, 则它的stage属性默认为test.

- variables 

`GitlabCI` 允许在 `.gitlab-ci.yml` 文件当中设置构建环境的环境变量. 这些变量会被存储在 `git` 仓库中并用于
记录不敏感的项目配置信息.

```yaml
variables:
    DATABASE_URL: "mysql://root@root/data"
```

这些变量会在之后被用于执行所有的命令和脚本. `yaml` 配置的变量同样会被设置为所有被建立的 `service` 容器中, 这
可以让使用更加方便. 

除了用户自定义的变量外, 同样有Runner自动配置的变量. 比如 `CI_BUILD_REF_NAME`, 这个变量定义了正在构建的 `git`
仓库的 `branch` 或者 `tag` 的名称.


- cache 

用于定义一系列需要在构建时被缓存的文件或者目录. 只能定义在项目工作环境中的目录或者文件.

默认情况下缓存功能是对每个 `job` 和 每个 `branch` 都开启的.

如果 `cache` 在 `job` 元素之外被替换, 这意味着全局设置, 并且所有的 job 会使用这个设置.

cache 案例: 

缓存所有 `bin` 目录下的文件和 `.config` 文件:

```yaml
rspec:
    script: test
    cache: 
      paths:
        - bin/
        - .config
```

缓存所有 `git` 未追踪的文件 和 `bin` 目录下的文件:

```yaml
rspec:
    script: test
    cache:
      untracked: true
      paths:
        - bin/
```

> `job` 级别定义的 `cache` 设置会覆盖全局级别的 `cache` 配置.

覆盖案例:

```yaml
cache:
    paths:
      - files/

rspec:
    script: test
    cache:
      paths:
        - bin/
```


## job 配置参数

`.gitlab-ci.yml` 允许配置无限个 `job`. 每个 `job` 必须有唯一的名称.

一个 `job` 由一系列定义构建行为的参数组成.

example:

```yaml
job_name:
  script:
    - rake spec
    - coverage
  stage: test
  only:
    - master
  except:
    - develop
  tags:
    - ruby
    - postgres
  allow_failure: true
```

| 关键字 | 必填 | 说明 |
| --- | --- | --- |
| script | 是 | 运行程序执行的 Shell 脚本 |
| when | 否 | 定义什么时候执行构建. 可选: `always`(默认值), `manual`, `delayed`, `on_success`, `on_failure` |
| stage | 否 | 定义构建的stage(默认是: `test`) | 
| after_script | 否	| 覆写全局的after_script命令 |
| before_script	| 否 | 覆写全局的before_script命令 |
| image | 否 | 使用Docker镜像. 也可用: `image:name`, `image:entrypoint` |
| services | 否 | 使用Docker服务镜像. 也可用: `services:name`, `services:alias`, `services:entrypoint`, `services:command` |
| type | 否 | stage的别名 |
| variables | 否 | 定义job级别的环境变量 |
| only | 否 | 限制创建job的时间. 也可用: `only:refs`, `only:variables`, `only:changes` |
| except | 否 | 限制不创建job的时间. 也可用: `except:refs`, `except:variables`, `except:changes` |
| tags | 否 | 定义一组tags用于选择合适的Runner |
| allow_failure | 否 | 运行构建失败. 失败的构建不会影响提交状态 |
| dependencies | 否 | 定义当前够你依赖的其他构建, 然后可以在它们直接传递artifacts |
| artifacts | 否 | 成功时附加到job的文件和目录列表. 也可用 `artifacts:paths`, `artifacts:name`, `artifacts:when`, `artifacts:expire_in`, `artifacts:reports`, `artifacts:exclude` |
| cache | 否 | 定义一组可以缓存以在随后的工作中共享的文件. 也可用: `cache:paths`, `cache:key`, `cache:policy` |
| environment | 否 | 定义当前构建完成后的运行环境的名称. 也可用: `environment:name`, `environment:action` |
| retry	| 否 | 定义job失败后的自动重试次数 |
| include | 否 | 允许此 job 包含外部 YAML 文件. 也可用: `include:local`, `include:file`, `include:remote` |
| release | 否 | 指定运行程序生成 Release 对象 |
| trigger | 否 | 定义 downstream 管道的 trigger |


- script

`script` 命令需要被包在双引号或者单引号之间. 例如, 包含符号 `:` 的命令都需要写在引号中, 这样 
`ymal` 的解析器才能正确的解析. 在使用包含以下符号的命令要特别小心:

```
'{, '}', '[', ']', 

':', ',', '&', '*', '#', '?', '|', '-', '<', '>', '=', '!', '%', '@', '`'
```


- only 和 except

`only` 和 `except` 参数说明了job什么时候将会被创建.

`only` 设置了需要被构建的 branches 和 tags 的名称.

`except` 设置了不需要被构建的 branches 和 tags的名称.

使用 refs 策略的规则:

```
1. only 和 except 是可以相互包含的. 如果一个 job 中 only 和 except 都被定义了, ref 会同时被 only, except 过滤.
2. only 和 except 支持正则表达式.
3. only 和 except 可以使用这几个关键字: branches, tags, triggers
4. only 和 except 允许使用指定的仓库地址, 但是不forks仓库.
```

`only` 和 `except` 允许使用特殊关键字:

| 值 | 描述 |
| --- | --- |
| branches | 当一个分支被push上来 |
| tags | 当一个打了tag的分支被push上来 |
| api | 当一个pipline被piplines api所触发调起, [详见piplines api](https://docs.gitlab.com/ce/api/pipelines.html) |
| external | 当使用了GitLab以外的CI服务 |
| pipelines | 针对多项目触发器而言, 当使用CI_JOB_TOKEN并使用gitlab所提供的api创建多个pipelines的时候 | 
| pushes | 当pipeline被用户的git push操作所触发的时候 | 
| schedules | 针对预定好的pipline而言 | 
| triggers | 用token创建piplines的时候 |
| web | 在GitLab页面上Pipelines标签页下,你按了run pipline的时候 |


案例: 

`job` 将会值在 `issue-` 开头的 `refs` 下执行, 反之则其他所有分支被跳过:

```yaml
job:
    only:
      - /^issue-.*$/
    except:
      - branches
```

`job` 只会在打了 `tag` 的分支, 或者被 `api` 所触发, 或者每日构建任务上运行:

```yaml
job:
    only:
      - tags
      - triggers
      - schedules
```

- when

`when` 参数是确定该 `job` 在失败或者没失败的时候是否执行的参数.

`when` 支持以下几个值之一:

```
on_success 只有在之前场景执行的所有作业成功的时候才执行当前job, 这个就是默认值, 我们用最小配置的时候他默认就是这个值,
所以失败的时候pipeline会停止执行后续任务.

on_failure 只有在之前场景执行的任务中至少有一个失败的时候才执行.

always 不管之前场景阶段的状态, 总是执行.

manual 手动执行job的时候触发(webui上点的).
```

- environment

`environment` 是用于定义一个 `job` (作业)部署到某个具名的环境, 如果 `environment` 被指定, 但是没有叫该名的
`environment` 存在, 一个新的 `environment` 将会被自动创建(实际上这个环境并不是指向真实环境, 设置这条会将相应
`job` 显示在 `CI` 面板, `environments` 视图上, 然后可以反复操作相关 `job`)


- artifacts

`artifacts` 被用于在 `job` 作业成功后将制定列表里的文件或文件夹附加到 `job` 上, 传递给下一个 `job`, 如果要在
两个不同的 `job` 之间传递 `artifacts`, 必须设置 `dependencies`.

传递所有`binaries` 和 `.config`:

```yaml
job1:
    script: make build
    artifacts:
      paths:
        - binaries/
        - .config

job2:
    script: make test:osx
    dependencies:
      - job1
```

`artifacts:name` 允许对 `artifacts` 压缩包重命名, 这样可以为每个 `artifact` 压缩包指定一个特别的名字.
`artifacts:name` 的值可以使用任何预定义的变量, 它的默认值是 `artifacts`. 如果不设置, 在 `gitlab` 上看
到 `artifacts.zip` 的下载名.

```yaml
job:
  script: make
  artifacts:
    name: "$CI_JOB_NAME"
```


`artifacts:when` 用于 `job` 失败或者未失败时使用.

`artifacts:when` 能设置以下值:

```
on_success 这个值是默认的, 当job成功时上传artifacts
on_failure 当job执行失败时, 上传artifacts
always 不管失败与否, 都上传
```

```yaml
job:
  script: make
  artifacts:
    when: on_failure
```


`artifacts:expire_in` 用于设置 `artifacts` 上传包的失效时间. 如果不设置, `artifacts` 的打包是永远存在于
`gitlab` 上的. 过期之后, 用户将无法访问到 `artifacts` 包, `artifacts` 将会在每小时执行的定时任务里被清除.

```yaml
job:
  artifacts:
    expire_in: 1 week
```

- dependencies

该特性需要和 `artifacts` 一起使用, 是用于将 `artifacts` 在两个 `job` 之间(主要是两个不同stage的job之间) 传
递的.

为了使用该特性,  需要在 `job` 上下文中定义 `dependencies` 并且列出所有运行本作业之前的作业(包涵 `artifacts` 
下载设置的). 只能在需要传递的 `job` 的前一个 `job` (上一个 `stage` 状态）里定义. 如果在定义了 `artifacts` 
的 `job` 里或者该 `job` 后面的 `job` 里定义 `dependencies`, `runner` 会扔出一个错误. 如果想阻止下载
`artifacts`, 需要设置一个 `空数组` 来跳过下载, 当使用 `dependencies` 的时候, 前一个 `job` 不会因为 `job` 
执行失败或者手动操作的阻塞而报错.

```yaml
build:osx:
  stage: build
  script: make build:osx
  artifacts:
    paths:
      - binaries/

build:linux:
  stage: build
  script: make build:linux
  artifacts:
    paths:
      - binaries/

test:osx:
  stage: test
  script: make test:osx
  dependencies:
    - build:osx

test:linux:
  stage: test
  script: make test:linux
  dependencies:
    - build:linux

deploy:
  stage: deploy
  script: make deploy
```

> 这里定义了两个job有artifacts, 分别是: `build:osx` 和 `build:linux`. 当 `test:osx` 的作业被执行的时候,
> 从 `build:osx` 来的 `artifacts` 会被下载并解压缩出来, 同样的事情发生在 `test:linux` 上. \
> deploy job 会下载所有的 artifacts. 因为它的优先级最高.
