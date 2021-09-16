## IBM CLI

1. 本地配置环境变量:

```
IBMCLOUD_HTTP_TIMEOUT=60                 A time limit for HTTP requests
IBMCLOUD_API_KEY=api_key_value           API Key used for login
```

2. login with apikey

> https://cloud.ibm.com/account/resource-groups 

> https://cloud.ibm.com/account/cloud-foundry

```
ibmcloud login -g GROUP -o ORG -s SPACE 
```

3. set attr

```
ibmcloud target -g GROUP -o ORG -s SPACE 
```

### Cloud Foundry

1. 查看 apps

```
ibmcloud cf apps
```

2. 部署 apps

> 带有 manifest.yml 文件

```
ibmcloud cf push 
```

3. 查看日志

```
ibmcloud cf logs APP
```
