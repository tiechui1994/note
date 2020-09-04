## 常用的 css 选择器

> 注: 以下的 `element` 可以是 **tag**, **class**, 或者 **id**

- **`element  element`** 优先级:1

eg: `div p`, 选择 `<div>` 元素内部的所有 `<p>` 元素

> 言外之意, div 和 p 是父子关系

```
<style>
div > div {
    color: red;
}

div > p {
    color: blue;
}
</style>

<div>
   <div> 我是第一个div </div>
   <p> 我是第一个p </p> 
   <p> 我是第二个p  </p> 
   <div> 我是第二个div </div>
</div>
```

![image](/images/develop_css_contains.png)

- **`element > element`** 优先级:2

eg: `div > p`, 选择 `<div>` 元素内部所有的 `<p>` 元素.

> 言外之意, div 和 p 是父子关系

```
<style>
div > div {
    color: red;
}

div > p {
    color: blue;
}
</style>

<div>
   <div> 我是第一个div </div>
   <p> 我是第一个p </p> 
   <p> 我是第二个p  </p> 
   <div> 我是第二个div </div>
</div>
```

![image](/images/develop_css_contains.png)


- **`element + element`** 优先级:2

> element 和 element 是兄弟关系

eg: `div + p`, 选择紧跟在 `<div>` 元素之后的第一个 `<p>` 元素.

```
<style>
div > p {
    color: blue;
}
</style>

<div>
   <div> 我是第一个div </div>
   <p> 我是第一个p </p> 
   <p> 我是第二个p  </p> 
   <div> 我是第二个div </div>
</div>
```

![image](/images/develop_css_brother.png)


---


- **`[attribute]`** 优先级:2

eg: `[target]`, 选择所有带 `target` 属性的元素.

- **`[attribute=value]`** 优先级:2

eg: `[target=_blank]`, 选择所有 `target`属性值为 "_blank" 的元素.


---


- `:link` 优先级:1

eg: `a:link` 选择所有未被访问的 `<a>` 元素

- `:visited` 优先级:1

eg: `a:visited` 选择所有已经被访问的 `<a>` 元素

- **`:active`** 优先级:1
 
eg: `a:active` 选择活动 `<a>` 标签

- **`:hover`** 优先级:1

eg: `a:hover` 选择*鼠标指针位于 `<a>` 之上*的 `<a>` 元素

- **`:focus`** 优先级:2

eg: `input:focus` 选择 *获得焦点的* `<input>` 元素.


---

- **`:before`** 优先级:2

eg: `p:before` 在每个 `<p>` 元素之前插入内容. 

example:

```
<style>
p:before {
   content:"position: ";
   color:red;
}
</style>

<div>
   <p> div 第一个元素 </p> 
   <p> div 第二个元素 </p> 
   <p> div 第三个元素 </p> 
</div>
```

![image](/images/develop_css_before.png)

> 使用到 `:before`, `:after`, 则必然会使用到属性 `content`

- **`:after`** 优先级:2

eg: `p:after` 在每个 `<p>` 元素之前插入内容. 

example:

```
<style>
p:after {
   content:" end";
   color:red;
}
</style>

<div>
   <p> div 第一个元素 </p> 
   <p> div 第二个元素 </p> 
   <p> div 第三个元素 </p> 
</div>
```

![image](/images/develop_css_after.png)


---

- **`:first-child`** 优先级:2

eg: `p:first-child` 选择属于父元素的 *第一个元素子元素* 的 *每个`<p>`元素*

> 言外之意, 父元素的第一个子元素是 `<p>`. 强调的是 `first child`

example:

```
<style>
p:first-child {
    color: red;
}
</style>

<div>
   <p> div 第一个元素 </p> 
   <p> div 第二个元素 </p> 
   <p> div 第三个元素 </p> 
</div>

<span>
   <p> span 第一个元素 </p> 
   <p> span 第二个元素 </p> 
   <p> span 第三个元素 </p> 
</span>
```

![image](/images/develop_css_first_child.png)


- **`:first-of-type`** 优先级:3

eg: `p:first-of-type` 选择属于其父元素的首个 `<p>` 元素的每个 `<p>` 元素.

> 言外之意, 父元素下 `p` 类型元素的第一个. 更加强调的是 `child type of first`.

example:

```
<style>
p:first-of-type {
    color: red;
}
p:first-of-type {
    color: green;
}
</style>

<div>
   <h5> h5 类型第一个元素 </h5> 
   <p> p 类型第一个元素 </p> 
   <p> p 类型第二个元素 </p> 
   <h5> h5 类型第一个元素 </h5> 
</div>

<hr>

<span>
   <h5> h5 类型第一个元素 </h5> 
   <p> p 类型第一个元素 </p> 
   <h5> h5 类型第一个元素 </h5> 
   <p> p 类型第二个元素 </p> 
</span>
```

![image](/images/develop_css_first_of_type.png)

- **`:last-of-type`** 优先级:3

eg: `p:last-of-type` 选择属于 *其父元素的最后一个 `<p>` 元素* 的 *每个 `<p>` 元素*. 

> 言外之意, 父元素下 `p` 类型元素的最后一个. 更加强调的是 `child type of last`.

- **`:nth-child(n)`** 优先级:3

eg: `p:nth-child(2)` 选择属于 *其父元素的第二个元素* 的 *每个 `<p>` 元素*.

> 言外之意, 父元素的第n个子元素是 `<p>`. 强调的是 `nth child`. 和 `:first-child` 功能上类似.

- **`:nth-last-child(n)`** 优先级:3

和 `:nth-child(n)` 类似, 只是倒数计数.

- **`:nth-of-type(n)`** 优先级:3

eg: `p:nth-of-type(2)` 选择属于 *其父元素第二个 `<p>` 元素* 的 *每个 `<p>` 元素*

- **`:nth-last-of-type(n)`** 优先级:3

和 `:nth-of-type(n)` 类似, 只是倒数计数.