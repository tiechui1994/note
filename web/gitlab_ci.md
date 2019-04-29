# gitlab-ci.yml 配置说明

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

| 保留字 | 必填 | 说明 |
| --- | --- | --- |
| iamge | 否 | 构建使用的Docker镜像名称, 使用Docker作为Excutor时有效 |
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
