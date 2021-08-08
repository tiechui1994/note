# JavaScript

## 对象和数组遍历

JavaScript 经常会用到遍历 `数组` 或 `对象` 的元素. 虽然很简单, 但是其中涉及到的细节还是很容易出错的, 那么今天就系统
的总结一下遍历对象和数组的用法细节.

### 遍历 `对象` 

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

--- 

### 遍历 `数组`

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
