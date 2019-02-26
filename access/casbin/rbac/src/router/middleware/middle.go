package middleware

import (
	"github.com/casbin/casbin"
	"github.com/kataras/iris/context"
	"net/http"
)

type Casbin struct {
	enforcer *casbin.Enforcer
}

// 适用于整个应用程序的Wrapper或适用于特定路线或部分的ServeHTTP。
func New(e *casbin.Enforcer) *Casbin {
	return &Casbin{enforcer: e}
}

// 真正意义上的权限检查方法. 需要添加用户认证
func (c *Casbin) Check(r *http.Request) bool {
	username := Username(r)
	method := r.Method
	path := r.URL.Path
	return c.enforcer.Enforce(username, path, method)
}

// Wrapper是路由器包装器, 如果要将casbin用于整个iris应用程序, 则更推荐使用此方法。
// Usage:
// app.WrapRouter(middleware.Wrapper())
// app.Get("/dataset1/resource1", myHandler)
func (c *Casbin) Wrapper() func(w http.ResponseWriter, r *http.Request, router http.HandlerFunc) {
	return func(w http.ResponseWriter, r *http.Request, router http.HandlerFunc) {
		if !c.Check(r) {
			w.WriteHeader(http.StatusForbidden)
			w.Write([]byte("403 Forbidden"))
			return
		}
		router(w, r)
	}
}

// ServerHTTP是兼容iris的casbin handler
// Usage:
// app.Get("/dataset1/resource1", casbinMiddleware.ServeHTTP, myHandler)
func (c *Casbin) ServeHTTP(ctx context.Context) {
	if !c.Check(ctx.Request()) {
		ctx.StatusCode(http.StatusForbidden) // Status Forbiden
		ctx.StopExecution()
		return
	}
	ctx.Next()
}

func Username(r *http.Request) string {
	username, _, _ := r.BasicAuth()

	return username
}
