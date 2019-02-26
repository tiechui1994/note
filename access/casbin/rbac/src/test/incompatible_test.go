package test

import (
	"github.com/iris-contrib/httpexpect"
	"github.com/kataras/iris/httptest"
	"router"
	"testing"
	"fmt"
)

func TestCasbinWrapper(t *testing.T) {
	app := router.GetIncompatibleApp()
	e := httptest.New(t, app)

	type ttcasbin struct {
		username string
		path     string
		method   string
		status   int
	}

	// 测试 alice, bob
	tt := []ttcasbin{
		{"alice", "/data1/res1", "GET", 200},
		{"alice", "/data1/res1", "POST", 403},
		{"alice", "/data1/res2", "GET", 200},
		{"alice", "/data1/res2", "POST", 403},

		{"bob", "/data2/res1", "GET", 200},
		{"bob", "/data2/res1", "POST", 200},
		{"bob", "/data2/res1", "DELETE", 200},
		{"bob", "/data2/res2", "GET", 200},
		{"bob", "/data2/res2", "POST", 403},
		{"bob", "/data2/res2", "DELETE", 403},

		{"bob", "/data2/fold/item1", "GET", 200},
		{"bob", "/data2/fold/item1", "POST", 403},
		{"bob", "/data2/fold/item1", "DELETE", 403},
		{"bob", "/data2/fold/item2", "GET", 200},
		{"bob", "/data2/fold/item2", "POST", 403},
		{"bob", "/data2/fold/item2", "DELETE", 403},
	}

	for _, tt := range tt {
		incompatibleCheck(e, tt.method, tt.path, tt.username, tt.status)
	}

	// 测试cathrin
	ttAdmin := []ttcasbin{
		{"cathrin", "/data1/item", "GET", 200},
		{"cathrin", "/data1/item", "POST", 200},
		{"cathrin", "/data1/item", "DELETE", 200},
		{"cathrin", "/data2/item", "GET", 403},
		{"cathrin", "/data2/item", "POST", 403},
		{"cathrin", "/data2/item", "DELETE", 403},
	}

	for _, tt := range ttAdmin {
		incompatibleCheck(e, tt.method, tt.path, tt.username, tt.status)
	}

	// 重新启动且删除了cathrin用户
	enforcer := router.GetEnforcer()
	enforcer.DeleteRolesForUser("cathrin")
	ttAdminDeleted := []ttcasbin{
		{"cathrin", "/data1/item", "GET", 403},
		{"cathrin", "/data1/item", "POST", 403},
		{"cathrin", "/data1/item", "DELETE", 403},

		{"cathrin", "/data2/item", "GET", 403},
		{"cathrin", "/data2/item", "POST", 403},
		{"cathrin", "/data2/item", "DELETE", 403},
	}

	for _, tt := range ttAdminDeleted {
		fmt.Println(tt.path, tt.method, tt.username)
		incompatibleCheck(e, tt.method, tt.path, tt.username, tt.status)
	}

}

func incompatibleCheck(e *httpexpect.Expect, method, path, username string, status int) {
	e.Request(method, path).WithBasicAuth(username, "password").Expect().Status(status)
}
