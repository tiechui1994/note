## Vue 开发

### vue route 路由跳转传递参数

- 使用 `$router` 方式

源组件:

```
<template>
    <button @click="sendParams"> 跳转 </button> 
</template>

<script>
export default {
    methods:{
        sendParams() {
            this.$router.push({
                path: 'target', 
                name: 'target' // 要跳转的路径的name, 在router文件夹下的 index.js文件内找,
                params: { 
                    name: 'value', 
                },
                query: {
                    id:10
                }
            })
        }
    }
}
</script>
```

> **这里是 $router.push() 操作**
> params, 是要传送的参数, 参数可以直接 k:v 形式传递
> query, 是通过 url 来传递参数, 是 k:v 的格式


目标组件:

```
<script>
export default {
    methods:{
        getParams() {
           const params = this.$route.params;
           const query = this.$route.query;
           console.log(params, query)
        }
    }
    watch: {
        '$route': 'getParams'
    }
}
</script>
```

> **获取路由参数的时候使用的是 *$route.params* 和 *$route.query***
> 使用 watch 监听器监测 `$route` 对象的变化, 一旦发生变动, 调用 `getParams()` 方法, 在此方法当中获取传递的参数, 并进行更新操作.

- 使用 `router-link` 

源组件:

```
<router-link 
    :to="{
        path: 'target',
        name: 'target'
        params: { 
            name: 'name', 
            data: data
        },
        query: {
            name: 'name', 
        }
    }">
</router-link>
```

> 参数和上面的 `$router.push` 当中的参数含义相同.

目标组件:

```
<script>
export default {
    methods:{
        getParams() {
           const params = this.$route.params;
           const query = this.$route.query;
           console.log(params, query)
        }
    }
    watch: {
        '$route': 'getParams'
    }
}
</script>
```


总结:

1. 上述的两种方式是相同的效果, 其中参数 `path`, `name` 是必填参数. 

2. 上述的参数传递过程中, 在跳转到目标页面是没有刷新操作的.

### vue 路由跳转

路由参数类型 `Location`, `Route`:
```
Location {
  name?: string;
  path?: string;
  hash?: string;
  query?: Dictionary<string>;
  params?: Dictionary<string>;
  append?: boolean;
  replace?: boolean;
}

Route {
  path: string;
  name?: string;
  hash: string;
  query: Dictionary<string>;
  params: Dictionary<string>;
  fullPath: string;
  matched: RouteRecord[];
  redirectedFrom?: string;
  meta?: any;
}
```


- `this.$router.push(Location, Callback)`

> 在导航后会保存 `history` 记录. 当需要跳转的路由压栈.

- `this.$router.replace(Location, Callback)`

> Location 的 `replace` 属性为 `true`, 在导航后不会留下 `history` 记录. 即修改当前的路由为目标路由.

- `this.$router.go(N)`

> 向路由栈当中PUSH(N为正数)或者POP(N为负数) N 个路由

- `this.$router.resolve(Location, Route)`

> 解析路由, Location是需要跳转的位置, Route是当前的路由信息

### vue 组件事件无法使用

例如:

```html
<div>
    <icon @click="clickFunc"></icon>
</div>
```

> icon 组件的点击事件无法被执行.

解决方法:

 ```html
<div>
    <icon @click.native="clickFunc"></icon>
</div>
```

### vue 组件之间方法调用

- 父组件调用子组件的方法

1) 直接调用

```
this.$refs["xxx"].func()
```


- 子组件调用父组件的方法

1) 在子组件中通过 `this.$parent.event` 来调用父组件方法.

```
<!--parent-->
<template>
    <child></child>
</template>
<script>
    export default {
       components: {
          child
       },
       methods: {
          parentMethod() {
             console.log('parent');
          }
       }
    }
</script>

<!--child-->
<template>
    <button @click="childMethod()">点击</button>
</template>
<script>
    export default {
       methods: {
          childMethod() {
              this.$parent.parentMethod();
          }
       }
    }
</script>
```

2) 父组件把方法作为参数传入子组件, 子组件直接调用

```
<!--parent-->
<template>
    <child :parentMethod="parentMethod"></child>
</template>
<script>
    export default {
       components: {
          child
       },
       methods: {
          parentMethod() {
             console.log('parent');
          }
       }
    }
</script>

<!--child-->
<template>
    <button @click="childMethod()">点击</button>
</template>
<script>
    export default {
       ptops:{
           parentMethod: {
              type: Function
           }
       },
       methods: {
          childMethod() {
              this.parentMethod();
          }
       }
    }
</script>
```

> 首先父组件将函数作为参数传入子组件, 接着, 子组件触发事件 -> 子组件调用传入的函数参数

3) 在子组件使用 `$emit` 触发一个事件, 父组件监听该事件. 在传递事件过程中可以携带参数.

```
<!--parent-->
<template>
    <child @parentMethod="parentMethod"></child>
</template>
<script>
    export default {
       components: {
          child
       },
       methods: {
          parentMethod() {
             console.log('parent');
          }
       }
    }
</script>

<!--child-->
<template>
    <button @click="childMethod()">点击</button>
</template>
<script>
    export default {
       methods: {
          childMethod() {
              this.$emit('parentMethod');
          }
       }
    }
</script>
```

> 首先父组件监听事件, 接着, 子组件触发事件 -> 父组件接收事件 -> 执行
