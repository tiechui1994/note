package router

import (
	"github.com/casbin/casbin"
	"github.com/kataras/iris"
	"router/middleware"
	"os"
)

var (
	enforcer      *casbin.Enforcer
	defaultModel  string
	defaultPolicy string
)

func Init(params ...string) {
	if len(params) < 2 {
		dir, _ := os.Getwd()
		defaultModel = dir + "/src/model.conf"
		defaultPolicy = dir + "/src/policy.csv"
		enforcer = casbin.NewEnforcer(defaultModel, defaultPolicy, false)
		return
	}

	enforcer = casbin.NewEnforcer(params[0], params[1], false)
}

func hi(ctx iris.Context) {
	ctx.Writef("Hello %s", middleware.Username(ctx.Request()))
}

func GetCompatibleApp() *iris.Application {
	if enforcer == nil {
		Init()
	}

	rbca := middleware.New(enforcer) // 获取一个包装enforcer的中间件
	app := iris.New()                // 构建App

	//request -> 授权验证 -> 真正的API
	app.Use(rbca.ServeHTTP) // 兼容模式中间件

	// 路由
	app.Any("/data1/{p:path}", hi)
	app.Get("/data1/res1", hi)

	app.Get("/data2/res2", hi)
	app.Post("/data2/fold/{p:path}", hi)
	app.Any("/data2/res1", hi)

	return app
}

func GetIncompatibleApp() *iris.Application {
	if enforcer == nil {
		Init()
	}

	rbca := middleware.New(enforcer) // 获取一个包装enforcer的中间件
	app := iris.New()                // 构建App

	// request -> 授权认证 -> 真正的API
	app.WrapRouter(rbca.Wrapper()) // app全部使用验证方式(不兼容)

	// 路由
	app.Get("/", hi)

	app.Any("/data1/{p:path}", hi)
	app.Get("/data1/res1", hi)

	app.Get("/data2/res2", hi)
	app.Get("/data2/fold/{p:path}", hi)
	app.Any("/data2/res1", hi)

	return app
}

func GetEnforcer() *casbin.Enforcer {
	return enforcer
}
