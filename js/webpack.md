## webpack

什么是 webpack ?

本质上, webpack 是一个现代 JavaScript 应用程序的静态模块打包器(module bundler). 

webpack 的核心概念:

- 入口 (entry)

- 出口 (output)

- loader

- 插件 (plugins)

### 入口 (entry)

entry 指示 webpack 应该使用哪个模块, 来作为构建其内部 `依赖图` 的开始. 进入入口起点之后, webpack 会找出哪些模块和
库是入口起点(直接和间接)依赖的.

每个依赖项随即被处理, 最后输出到称为 *bundles* 的文件中.

配置 `entry` 属性, 来指定一个入口起点(或多个入口起点). 默认值是 `./src`

webpack.config.js

```
module.exports = {
   entry: './path/to/entry/index.js' 
};
```

### 出口 (output)

output 告诉 webpack 在哪里输出所创建的 *bundles*, 以及如何命名这些文件. 默认值是 `./dist` 

webpack.config.js

```
const path = require('path');

module.exports = {
    output: {
        path: path.resolve(__dirname, 'dist'),
        filename: 'webpack.bundle.js'
    }
}
```

> - path 目标输出目录的绝对路径.
> - filename 输出文件的文件名. 如果配置创建了多个单独的 `chunk` (使用多个入口起点, 或者使用 `CommonsChunkPlugin`
> 这样的插件), 则应该使用占位符来确保每一个文件具有唯一的名称.

```
const path = require('path');

module.exports = {
    output: {
        path: path.resolve(__dirname, 'dist'),
        filename: '[name].js' // 使用占位符 [name] 
    }
}
```

### loader

loader 让 webpack 能够去处理那些 `非JavaScript` 文件 (webpack自身只理解 JavaScript). loader 可以将所有类型的
文件中转换为 webpack 能够处理的有效模块, 然后就可以利用 webpack 的打包能力, 对它们进行处理.

loader 的两个目标:

- `test` 属性, 用于标识出应该被对应的 loader 进行转换的某个或某些文件.

- `use` 属性, 表示进行转换时, 应该使用哪个 loader

```
module.exports = {
    module: {
       rules: [
          { test: /\.txt$/, use: 'raw-loader' }, 
          { test: /\.css$/, use: 'css-loader' }, // css
          { test: /\.ts$/, use: 'ts-loader' }    // typescript
       ]
    }
}
```

> 上面配置中, 对一个单独的 module 对象定义了 `rules` 属性, 里面包含两个必要的属性: `test` 和 `use`

在应用程序中, 有三种使用 `loader` 的方式:

- 配置: 在 `webpack.config.js` 文件中指定 loader
- 内联: 在每个 `import` 语句中显示指定 loader
- CLI: 在 shell 命令中指定 loader

> 配置

`module.rules` 允许在 webpack 配置中指定多个 `loader`. 

```
module.exports = {
    module: {
       rules: [
          {
            test: /\.css$/, 
            use: [
                { loader: 'style-loader' },
                { loader: 'css-loader', options: { modules: true } }
            ]
          }
       ]
    }
}
```

> 内联

可以在 `import` 语句或任何等效于 "import" 的方式中指定 loader. 使用 **!** 将资源中的 loader 分开. 分开的每个部分
都相对于当前目录解析.

```
import styles from 'style-loader!css-loader?modules!./styles.css';
```


### 插件 (plugins)

loader 被用于转换某些类型的模块, plugins 可以用于执行范围更广的任务. 插件的范围包括, 从打包优化和压缩, 一直到重新定义
环境中的变量.

要想使用一个 plugin, 首先需要 `require()` 它, 然后将它添加到 `plugins` 数组中. 多数插件可以通过选项 `option` 自
定义.

webpack.config.js

```
const HtmlWebpackPlugin = require('html-webpack-plugin');

module.exports = {
    plugin: [
        new HtmlWebpackPlugin({template:'./src/index.html'})
    ]
}
```