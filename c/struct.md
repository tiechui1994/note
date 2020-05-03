## typedef vs struct

以下语句将 `LENGTH` 定义为 `int` 的同义, 然后使用此 `typedef` 将 `leghth,width,height` 
声明为 `int` 变量:

```cgo
typedef int LENGTH;
LENGTH length, width, height;
```

`typedef` 可用于定义 `struct`, `union` 或 `C++ class`.

```cgo
typedef struct {
    int drams;
    int grains;
} WEIGHT;

// used
WEIGHT chicken, cow;
```


`yds` 的类型为 "不带参数的函数指针, 返回int".

```cgo
typedef int SCROLL(void);
extern SCROLL *yds;
```
