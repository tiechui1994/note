# 软件设计原则(SOLID)

## SRP 单一职责原则

## OCP 开闭原则

## LSP 里氏替换原则

## ISP 接口隔离原则

## DIP 依赖反转原则

- 稳定的抽象层

```
修改抽象接口 -> 修改具体的实现

修改具体的实现 -> 很少修改相应的抽象接口

编码原则:
    - 应在代码中多使用抽象接口, 尽量避免使用那些多变的具体实现类.
    - 不要在具体实现类上创建衍生类.
    - 不要覆盖(override)包含具体实现的函数.
    - 应避免在代码中写入与任何具体实现相关的名字, 或者是其他容易变动事物的名字.(硬编码)
```

- 工厂模式(抽象工厂模式)