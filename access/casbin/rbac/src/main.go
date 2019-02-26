package main

import (
	"github.com/kataras/iris"
	"router"
)

func main() {
	app := router.GetCompatibleApp()
	app.Run(iris.Addr(":8080"))
}
