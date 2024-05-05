# Jenkins 日常使用

## jenkins 环境变量重写

规则:

- 定义在全局 `environment {}` 的环境变量可以被局部 `environment {}` 当中的环境变量或脚本式定义(script)的环境
变量 `env.key="value"` 覆盖, 但是无法被更新.

- 定义在局部 `environment {}` 当中的环境变量或脚本式定义(script)的环境变量 `env.key="value"`, 可以被其他stage
的局部 `environment {}` 中的环境变量或脚本式定义(script)的环境变量 `env.key="value"` 覆盖, 并被更新.

- `withEnv(["WITH_ENV_VAR=100", "VALUE=${VALUE}"]) {}` 内置函数的这种写, 可以覆盖任意环境变量, 但是无法被更新.


案例: (上述3条规则的验证)

```
pipeline {
    agent any

    environment {
        NAME = "name"
    }

    stages {
        stage("1") {
            environment {
                  // 会重写全局环境变量 NAME
                NAME = "name.local" 
                  // 会重写系统内置的环境变量 BUILD_NUMBER
                BUILD_NUMBER = "10"
                // 局部变量
                LOCAL = "22"
            }

            steps {
                  // "NAME = name.local"
                echo "global NAME = ${env.NAME}" 
                  //  "BUILD_NUMBER = 10"
                echo "system BUILD_NUMBER = ${env.BUILD_NUMBER}" 

                script {
                      // 创建一个环境变量
                    env.LOCAL = "1" 
                    env.ANONY = "33"
                }
            }
        }

        stage("2") {
            steps {
                // "LOCAL = 1, ANONY = 33"
                echo "step1 LOCAL = ${env.LOCAL}, ANONY = ${env.ANONY}" 
                
                script {
                      // 局部 LOCAL 变量会被重写
                    env.LOCAL = "2" 
                    // 局部 ANONY 变量会被重写
                    env.ANONY = "55"
                }

                  // "LOCAL = 2 , ANONY = 55"
                echo "step1 LOCAL = ${env.LOCAL}, ANONY = ${env.ANONY} " 

                  // 全局 FOO 变量会被重写
                withEnv(["NAME=${env.LOCAL}"]) { 
                      // "NAME = 2"
                    echo "global NAME = ${env.NAME}" 
                }

                  // 局部 BUILD_NUMBER 变量会被重写
                withEnv(["BUILD_NUMBER=15"]) {
                      //  "BUILD_NUMBER = 15"
                    echo "system BUILD_NUMBER = ${env.BUILD_NUMBER}"
                }

                // 局部 LOCAL 变量会被重写
                withEnv(["LOCAL=200"]) {
                    //  "LOCAL = 200"
                    echo "step1 LOCAL = ${env.LOCAL}"
                }
            }
        }
    
        stage("3") {
            steps {
                // "NAME = name"
                echo "global NAME = ${env.NAME}" 
                
                // "BUILD_NUMBER = 1"
                echo "system BUILD_NUMBER = ${env.BUILD_NUMBER}"
                 
                // "LOCAL = 2"
                echo "step1 LOCAL = ${env.LOCAL}"

                // "ANONY = 55"
                echo "step1 ANONY = ${env.ANONY}"
            }
        }
    }
}
```
