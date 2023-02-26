# JavaScript 知识点

JavaScript 经常会使用的知识点, 尽管简单, 但是值得总结.

## Object 遍历

- 使用 `Object.keys()` 遍历, 返回一个数组, 包括对象自身的(不含继承的)所有可枚举属性(不含Symbol属性).

```
const obj = {
    'key1':'val1',
    'key2':'val2'
};

Object.keys(obj).forEach((key, index, arr) => {
    console.log(key, index, arr)
});
```

- 使用 `for..of` + `Object.entries(object)` 遍历, 返回一个包括对象自身的(不含继承的)所有可枚举属性(不含Symbol属
性)的 `[key, value]` 数组.

```
const obj = {
    'key1':'val1',
    'key2':'val2'
};

for (let [key,value] of Object.entries(obj)){
    console.log(key,value)
}
```

- 使用 `for...in` 遍历, 循环遍历对象 `自身的` 和 `继承的` 可枚举属性(不包含Symbol熟悉).

```
const obj = {
    'key1':'val1',
    'key2':'val2'
};

for(let key in obj) {
    console.log(key,":",obj[key])
}
```

- 使用 `Object.getOwnPropertyNames(object)` 遍历, 返回一个数组, 包含对象自身的所有属性(不含Symbol熟悉, 但是`包
括不可枚举属性`)

```
const obj = {
    'key1':'val1',
    'key2':'val2'
};

Object.getOwnPropertyNames(obj).forEach((key,index)=> {
    console.log(key, obj[key], index)
})
```

- 使用 `Reflect.ownKeys(object)` 遍历. 返回一个数组, 包含自身的所有属性, 不管属性名是 Symbol 或 字符串, 也不管是
否可枚举.

> es6 语法

```
const obj = {
    'key1':'val1',
    'key2':'val2'
};

Reflect.ownKeys(obj).forEach((key,index)=> {
    console.log(key, obj[key], index)
})
```

## Array 遍历 

- `for...in` 遍历

```
const arr = ["张三", "李四", "王五"];

for (let i in arr) {
    console.log(i,arr[i])
}
```

- `for...of` 遍历, 不仅支持数组, 还支持大多数类数组对象, 也支持字符串遍历

```
const arr = ["张三", "李四", "王五"];

for (let value of arr) {
    console.log(value)
}
```

- `forEach()` 方法

```
const arr = ["张三", "李四", "王五"];

arr.forEach((value, index) => {
    console.log(value, index)
})
```

总结: 虽然遍历数组经常使用, 但是其遍历方法少, 形式固定. 而对于遍历对象, 经常使用的方法也就是 `Object.keys()`, `for..in`
和 `for..of` + `Object.entries(object)`, 但是对于最后一种是很容易出错的, 开发的过程中需要小心使用.

## Array 合并

- 优美 `push` 合并

多数组合并.

```
const a = [1, 2, 3];
const b = [4, 5, 6];
const c = [];

c.push(...a, ...b);

// a: [1, 2, 3]
// b: [4, 5, 6]
// c: [1, 2, 3, 4, 5, 6]
```

- apply

```
const a = [1, 2, 3];
const b = [4, 5, 6];

a.push.apply(a, b);

// a: [1, 2, 3, 4, 5, 6]
// b: [4, 5, 6]
```

## Object.freeze() 

Object.freeze() 方法用于冻结对象, 禁止对于该对象的属性进行修改(由于数组本质也是对象, 因此该方法可以对数组使用).

> 一个被冻结的对象再也不能被修改; 冻结了一个对象则不能向这个对象添加新的属性, 不能删除已有属性, 不能修改该对象已有属性的可枚举性, 可配置性, 
> 可写性, 以及不能修改已有属性的值. 此外, 冻结一个对象后该对象的原型也不能被修改.

该方法的返回值是其参数本身.

需要注意的点:

- Object.freeze() 和 const 变量声明不同, 也不承担 const 的功能. 

const 的行为像 let, 它们唯一的区别是, const 定义了一个无法重新分配的变量. 通过 const 声明的变量是具有块级作用域的, 而不是像 var 声明的
变量具有函数作用域.

Object.freeze() 接收一个对象作为参数, 并返回一个相同的不可变的对象. 这意味着不能添加, 删除或更新该对象的任何属性.

案例:

```
const a = { x : { y: 10 }}
Object.freeze(a)

// 可以正常对 y 属性赋值
a.x.y = 100
console.log(a.x.y)

// 无法对 x 属性进行修改, 因为 a 的属性已经被冻结
a.x = { y : 200 }
console.log(a.x.y)
```

> 注: Object.freeze() 只是"浅冻结"(只能冻结对象的直接属性). 要想冻结对象的所有属性, 需要"深冻结"

**"深冻结":**

```
function deep_freeze(obj) {
  // 层级冻结属性
  Object.getOwnPropertyNames(obj).forEach(function(name) {
    var prop = obj[name];

    // 如果prop是个对象, 冻结它
    if (typeof prop == 'object' && prop !== null)
      deep_freeze(prop);
  });

  // 冻结自身(no-op if already frozen)
  return Object.freeze(obj);
}
```

