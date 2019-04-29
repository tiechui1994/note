# gitlab-ci.yml 配置说明

## 全局配置

一个 `yaml` 文件定义了一组各不相同的 `job`, 并定义了它们应该怎么运行. 这组 `jobs` 会被定义为 `yaml`
文件的顶级元素, 并且每个 `job` 的子元素中总有一个名为 `script` 的节点.

> A set of jobs, 强调是Set所以名称必须不同.

```yaml
job1:
    script: "job1的执行脚本命令(shell)"

job2:
    script:
      - "job2的脚本命令1(shell)"
      - "job2的脚本命令2(shell)"
```

> 上述的文件是最简单的CI配置例子, 每个job都执行了不同的命令, 其中job1只执行了一条命令, job2通过数组的定义按
顺序执行了2条命令.

`Job` 配置会被 `Runner` 读取并用于构建项目, 并且在 `Runner` 的环境中被执行. 很重要的一点是, 每个 `job` 
都会独立的运行, 相互间并不依赖.

案例:

```yaml
image: ruby:lastest

service:
    - postgres

before_script:
    - bundle install

after_script:
    - rm secrets

stages:
    - build
    - test
    - deploy

job1:
    stage: build
    script:
      - execute-script-for-job1
    only:
      - master
    tags:
      - docker
```

- 保留字

这些单词不能被用于命名job.


| 保留字 | 必填 | 说明 |
| --- | --- | --- |
| image | 否 | 构建使用的Docker镜像名称, 使用Docker作为Excutor时有效 |
| services | 否 | 使用的Docker服务, 使用Docker作为Excutor时有效 |
| stages | 否 | 定义构建的stages | 
| types | 否 | stages的别名 |
| before_script | 否 | 定义所有job执行之前需要执行的脚本命令 |
| after_script | 否 | 定义所有job执行完成后需要执行的脚本命令 |
| variables | 否 | 定义构建变量 |
| cache | 否 | 定义一组文件, 该组文件会在运行时被缓存, 下次运行仍然可以使用 |


- stages

用以定义可以被 `job` 使用的 `stage`. 定义 `stages` 可以实现柔性的多 `stage` 执行管道.

`stages` 定义的元素顺序决定了构建的执行顺序:

```
1. 同样的stage的job是并行执行的.
2. 下一个stage的jobs是当上一个stage的jobs全部执行完成后才会执行.
```

stages 案例: \
```yaml
stages:
    - build
    - test 
    - deploy
```

> 首先, 所有stage属性为build的job会被并行执行. \
> 如果所有stage属性为build是job都执行成功了, stage为test的job会被并行执行. \
> 如果所有stage属性为test是job都执行成功了, stage为deploy的job会被并行执行. \
> 如果所有stage属性为deploy是job都执行成功了, 则提交被标记为success.
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


## Jobs 配置

`.gitlab-ci.yml` 允许配置无限个 `job`. 每个 `job` 必须有唯一的名称.

一个 `job` 由一系列定义构建行为的参数组成.

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
| script | 是 | 定义了Runner会执行的脚本命令 |
| image | 否 | 使用Docker镜像 |
| services | 否 | 使用Docker服务 |
| stage | 否 | 定义构建的stage(默认是: `test`) | 
| type | 否 | stage的别名 |
| variables | 否 | 定义job级别的环境变量 |
| only | 否 | 定义一组构建会创建的git refs |
| except | 否 | 定义一组构建不会创建的 git refs |
| tags | 否 | 定义一组tags用于选择合适的Runner |
| allow_failure | 否 | 运行构建失败. 失败的构建不会影响提交状态 |
| when | 否 | 定义什么时候执行构建. 可选: on_success, on_failure, always, manual |
| dependencies | 否 | 定义当前够你依赖的其他构建, 然后可以在它们直接传递artifacts |
| artifacts | 否 | 定义一组构建artifact |
| cache | 否 | 定义一组可以缓存以在随后的工作中共享的文件 |
| before_script	| 否 | 覆写全局的before_script命令 |
| after_script | 否	| 覆写全局的after_script命令 |
| environment | 否 | 定义当前构建完成后的运行环境的名称 |