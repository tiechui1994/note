# Rust

## 基础

`::` 关联函数, 针对类型实现的. 静态方法.

一个 match 表达式由**分支(arms)**构成. 一个分支包含一个**模式(pattern)**和**表达式开头的值**与**分支模式相匹配时应该执行的代码**. Rust 获取提供给 match 的值并挨个检查每个分支的模式.


```
match guess.cmp(&numer) {
   Ordering::Less => println!("Too small!"),
   Ordering::Greater => println!("Too big!"),
   Ordering::Equal => println!("You win!"),
} 
```

> Ordering 是一个枚举, 成员包含 Less, Greater, Equal. 


Rust 中, 变量默认是不可改变的(immutable), 这意味着一旦我们给变量赋值, 这个值就不再可以修改了.

常量: 常量是绑定到一个名称的不允许改变的值. 常量与变量的区别:

```
1. 不允许对常量使用 mut. 常量不光默认不能变, 它总是不能变.

2. 声明常量使用 const, 并且必须注明值的类型.

3. 常量可以在任何作用域中声明, 包括全局作用域.

4. 常量只能被设置为常量表达式, 而不可以是其他任何只能在运行时计算的值.
```

复合类型: 将多个值组合成一个类型.

1. 元祖, 将多个其他类型的值组合进一个复合类型. 元祖长度固定, 一旦声明, 其长度不会增大或缩小.

```
let tup: (i32, f64, u8) = (100, 11.11, 1);

// 解构
let (x, y, z) = tup;

// 使用 `.` 直接访问
let y = tup.1; 
```

> 不带任何值的元组有个特殊的名称, 叫单元(unit)元组. 这种值以及对应的类型写作 `()`, 表示空值或空的返回类型. 如果表达式不返回任何其他值, 则会隐式返回单元值.

2. 数组, 数组当中的每个元素的类型必须相同. 数组的长度是固定的.

```
let arr = [1,2,2,2];
```

> 数组不如 vector 类型灵活. vector 类型是标准库提供的一个**允许**增长和缩小长度的类似数组的集合类型.

控制流:

if, 与其他语言是一样的.

loop, 重复执行代码(相当于while死循环)

```
// 常规
let mut c = 0;

let result = loop {
   c += 1;
   if c == 10 {
      break c*2;
   }
}

// 带标签. 标签格式: `'name`
let mut count = 0;

'count_up: loop {
   let mut remain = 10;
   loop {
      if remain == 9 {
    break;
      }
      if remain == 2 {
          break 'count_up;
      }
      remain -= 1;
   }
  
   count += 1;
}

```

while, for, 条件循环

## 所有权

所有权规则:

- Rust 中的每一个值都有一个 所有者(owner).
- 值在任一时刻有且只有一个所有者.
- 当所有者(变量)离开作用域, 这个值将被丢弃.

变量与数据交互的方式(一): 移动

