## JavaScript 的工具

- node, 是 JavaScript 语音的环境和平台.

- npm, yarn, bower 是一类, 包管理工具.

- webpack, browserify, rollup 是一类, JavaScript **模块打包** 方案 (方案+工具+插件)

- babel, TypeScript 是一类, ES编译器

- grunt, gulp, 前段工具, 结合插件, 合并, 压缩, 编译 sass/less, browser 自动载入资源.

- react, angular, vue 是一类, mvc, mvvm, mvp 之类的前段框架.

- Less, Sacss, css, Stylus 是一类, CSS 程式化方案

### 案例

**babel** 将 `es6` 语法转换成 `es5`. 

涉及的配置文件: 

- package.json
- .babelrc

package.json

```json
{
  "main": "index.js",
  "dependencies": {},
  "devDependencies": {
    "babel-cli": "^6.26.0",
    "babel-preset-es2015": "^6.24.1"
  },
  "scripts": {
    "build": "browserify src --out-dir dist"
  }
}
```

.babelrc

```json
{
  "presets": [
    "es2015"
  ],
  "plugins": []
}
```

