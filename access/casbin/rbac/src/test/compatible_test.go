package test

import (
	"github.com/iris-contrib/httpexpect"
	"github.com/kataras/iris/httptest"
	"router"
	"testing"
)

func TestCasbinMiddleware(t *testing.T) {
	model := "/home/user/workspace/rbac/src/test/conf/comp_model.conf"
	policy := "/home/user/workspace/rbac/src/test/conf/comp_policy.csv"
	router.Init(model, policy)
	app := router.GetCompatibleApp()
	e := httptest.New(t, app, httptest.Debug(false))

	type ttcasbin struct {
		username string
		path     string
		method   string
		status   int
	}

	tt := []ttcasbin{
		{"alice", "/data1/res1", "GET", 200},
		{"alice", "/data1/res1", "POST", 200},
		{"alice", "/data1/res2", "GET", 200},
		{"alice", "/data1/res2", "POST", 200},

		{"bob", "/data2/res1", "GET", 200},
		{"bob", "/data2/res1", "POST", 200},
		{"bob", "/data2/res1", "DELETE", 200},
		{"bob", "/data2/res2", "GET", 200},
		{"bob", "/data2/res2", "POST", 404},
		{"bob", "/data2/res2", "DELETE", 404},

		{"bob", "/data2/fold/item1", "GET", 404},
		{"bob", "/data2/fold/item1", "POST", 200},
		{"bob", "/data2/fold/item1", "DELETE", 404},
		{"bob", "/data2/fold/item2", "GET", 404},
		{"bob", "/data2/fold/item2", "POST", 200},
		{"bob", "/data2/fold/item2", "DELETE", 404},
	}

	for _, tt := range tt {
		compatibleCheck(e, tt.method, tt.path, tt.username, tt.status)
	}
}

func compatibleCheck(e *httpexpect.Expect, method, path, username string, status int) {
	e.Request(method, path).WithBasicAuth(username, "password").Expect().Status(status)
}
