# github action

Github Actions 是 Github 推出的持续集成(CI)服务, 基于它可以进行构建, 测试, 打包, 部署项目. 简单说就是将软件开发中的
的一些流程交给云服务器自动化处理. 例如: 开发者把代码push到Github后会自动测试, 编译, 发布.

## action 使用

基础概念:

- workflow(工作流程): 持续集成一次运行的过程

- job(任务): 一个 workflow 由一个或多个 job 构成, 含义是一次持续集成的运行, 可以完成多个任务.

- step(步骤): 每个 job 由多个 step 构成, 一步步完成.

- action(动作): 每个 step 可以依次执行一个或多个命令(action).

### workflow

Github Actions 的配置文件叫做 workflow 文件, 存放在代码仓库的 `.github/workflows` 目录中. workflow 采用 YAML
格式, 文件名可以任意取, 但是后缀名统一为 `.yml`. 一个库可以有多个 workflow 文件, Github 只要发现 `.github/workflows`
目录里面的 `.yml` 文件, 就会按照文件中所指定的触发条件自动运行该文件中的工作流程.

案例:

```yaml
name: Hello World
on: push
jobs:
  first_job:
    name: first job
    runs-on: ubuntu-lastest
    steps:
      - name: checkout
        uses: actions/checkout@master
      - name: run single-line script
        run: echo "Hello world"
  second_job:
    name: second job
    runs-on: macos-lastest
    steps:
      - name: run multi-line script
        env: 
          MY_VAR: Hello World
          MY_NAME: P3TERX
        run: |
          echo $MY_VAR
          echo name is $MY_NAME
```




