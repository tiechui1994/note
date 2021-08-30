# css 选择器

> 注: 以下的 `element` 可以是 **tag**, **class**, 或者 **id**

## 基本选择器

- 通用选择器: 选择所有元素. 可以将其限制为特定的名称空间或所有名称空间.

- 元素选择器: 按照给定的节点名称, 选择所有匹配的元素.

- 类选择器: 按照给定的 class属性的值, 选择所有匹配的元素.

- ID 选择器: 按照 id 属性选择一个与之匹配的元素.

- 属性选择器: 按照给定的属性, 选择所有匹配的元素.

1) **[attribute]** 优先级:2

eg: `[target]`, 选择所有带 `target` 属性的元素.

2) **[attribute=value]** 优先级:2

eg: `[target=_blank]`, 选择所有 `target`属性值为 "_blank" 的元素.

3) **element[attribute=value]**

eg: `a[target=_blank]`, 选择所有 a 标签`target`属性值为 "_blank" 的元素.


## 分组选择器

- 选择器列表: 将不同的选择器组合在一起的方法, 它选择所有能被列表中任意一个选择器选中的节点. 分隔符是 `,`

1) **A, B**, 其中 A, B 是选择器.

eg: `div, span` 会同时匹配 `<span>` 元素和 `<div>` 元素.

## 组合器

- 后代组合器: 组合器选择前一个元素的后代节点. 分隔符是空格

语法: **A B**, 其中 A, B 是选择器. 优先级:1

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


- 直接子代组合器: 组合器选择前一个元素的直接子代的节点. 分隔符是`>`.

语法: **A > B**, 其中 A, B 是选择器. 优先级:2

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

- 一般兄弟组合器: 组合器选择兄弟节点, 也就是说, 后一个节点在前一个节点后面的任意位置, 并且共享同一个父节点. 分隔符是`~`.

语法: **A ~ B**, 其中 A, B 是选择器.

eg: `p ~ span`, 匹配同一父元素下, `<p>` 元素后的所有 `<span>` 元素.

- 紧邻兄弟组合器: 组合器选择相邻元素, 即后一个元素紧跟前一个之后, 并且共享同一个父节点. 分隔符是`+`.

语法: **A ~ B**, 其中 A, B 是选择器.

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


- 列组合器: 组合器选择属于某个表格行的节点. 分隔符是 `||`

语法: **A || B**, 其中 A, B 是选择器.

eg: `col || td` 匹配所有 `<col>` 作用域内的 `<td>` 元素. 


## 伪选择器

- 伪类: 伪选择器支持按照未被包含在文档树中的状态信息来选择元素. 分隔符是`:`

1) `:link` 优先级:1

eg: `a:link` 选择所有未被访问的 `<a>` 元素

2) `:visited` 优先级:1

eg: `a:visited` 选择所有已经被访问的 `<a>` 元素

3) **:active** 优先级:1
 
eg: `a:active` 选择活动 `<a>` 标签

4) **:hover** 优先级:1

eg: `a:hover` 选择*鼠标指针位于 `<a>` 之上*的 `<a>` 元素

5) **:focus** 优先级:2

eg: `input:focus` 选择 *获得焦点的* `<input>` 元素.

---

6) **:before** 优先级:2

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

7) **:after** 优先级:2

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

8) **:first-child** 优先级:2

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


9) **:first-of-type** 优先级:3

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

10) **:last-of-type** 优先级:3

eg: `p:last-of-type` 选择属于 *其父元素的最后一个 `<p>` 元素* 的 *每个 `<p>` 元素*. 

> 言外之意, 父元素下 `p` 类型元素的最后一个. 更加强调的是 `child type of last`.

11) **:nth-child(n)** 优先级:3

eg: `p:nth-child(2)` 选择属于 *其父元素的第二个元素* 的 *每个 `<p>` 元素*.

> 言外之意, 父元素的第n个子元素是 `<p>`. 强调的是 `nth child`. 和 `:first-child` 功能上类似.

12) **:nth-last-child(n)** 优先级:3

和 `:nth-child(n)` 类似, 只是倒数计数.

13) **:nth-of-type(n)** 优先级:3

eg: `p:nth-of-type(2)` 选择属于 *其父元素第二个 `<p>` 元素* 的 *每个 `<p>` 元素*

14) **:nth-last-of-type(n)** 优先级:3

和 `:nth-of-type(n)` 类似, 只是倒数计数.


- 伪元素: 伪元素用于表示无法用 HTML 语义表达的实体. 分隔符是 `::`

eg: `p::first-line` 匹配所有 `<p>` 元素的第一行.
