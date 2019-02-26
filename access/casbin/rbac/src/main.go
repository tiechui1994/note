package main

import (
	"github.com/kataras/iris"
	"router"
	"fmt"
)

func main() {
	app := router.GetCompatibleApp()

	app.Use(func(context iris.Context) {
		fmt.Printf("%v\t%v \n", context.Method(), context.Request().URL.Path)
	})
	// 静态资源
	app.RegisterView(iris.HTML("ui", ".html"))

	app.Get("/index.html", func(ctx iris.Context) {
		ctx.View("index.html")
	})

	app.Run(iris.Addr(":8080"))
}
