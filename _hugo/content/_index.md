+++
title = "My presentation"
outputs = ["Reveal"]
+++

# Why buf?

---

# Let's build a grpc web app

---

{{< figure src="gh.drawio.4.svg" height=600 >}}

---


```diff
protoc -I./proto/ --go_out=paths=source_relative:backend/pkg/gen/proto/elizav1 eliza.proto
protoc -I././proto/ --go-grpc_out=paths=source_relative:backend/pkg/gen/proto/elizav1 eliza.proto
grpc
├── proto
│   └── eliza.proto
+ ├── backend
+ │   └── main.go
+ │       └── pkg
+ │           └── gen
+ │               └── proto
+ │                   └── elizav1
+ │                       ├── eliza.pb.go
+ │                       └── eliza_grpc.pb.go
```

---


```diff
protoc -I./proto/ --go_out=paths=source_relative:backend/pkg/gen/proto/elizav1 eliza.proto
protoc -I././proto/ --go-grpc_out=paths=source_relative:backend/pkg/gen/proto/elizav1 eliza.proto
protoc -I././proto/ --js_out=import_style=commonjs:frontend/src/gen eliza.proto
protoc -I././proto/ --grpc-web_out=import_style=typescript,,mode=grpcwebtext:frontend/src/gen eliza.proto
```

---

```diff
grpc
+ ├── Makefile
├── proto
│   └── eliza.proto
├── backend
│   └── main.go
│       └── pkg
│           └── gen
│               └── proto
│                   └── elizav1
│                       ├── eliza.pb.go
│                       └── eliza_grpc.pb.go

```

---

{{< figure src="gh.drawio.3.svg" height=600 >}}

--- 

![img_5.png](img_5.png)

---

{{< figure src="gh.drawio.2.svg" height=600 >}}

---
# protoc-gen-js

![img_6.png](img_6.png)

--- 

- https://github.com/grpc/grpc-web/issues/704 which is a duplicate of
- https://github.com/protocolbuffers/protobuf-javascript/issues/105 which is a duplicate of
- https://github.com/protocolbuffers/protobuf-javascript/issues/127 and the issue is to

---
# protoc-gen-js

![img.png](img.png)

---

# solution
![img_1.png](img_1.png)

---

# protoc-gen-grpc-web
- Requires envoy proxy
- Get envoy proxy installed
- set up config, run envoy, points at grpc service

---

```diff
grpc
+ ├── envoy.yaml
+ ├── envoy.Dockerfile
├── Makefile
├── proto
│   └── eliza.proto
├── backend
│   └── main.go
│       └── pkg
│           └── gen
│               └── proto
│                   └── elizav1
│                       ├── eliza.pb.go
│                       └── eliza_grpc.pb.go
+ └── frontend
+     ├ App.tsx
+     └── src
+         └── gen
+             ├── eliza_grpc_web_pb.js
+             ├── eliza_pb.d.ts
+             ├── eliza_pb.js
+             └── ElizaServiceClientPb.ts
```

---

{{< figure src="gh.drawio.1.svg" height=600 >}}

---

{{< figure src="gh.drawio.0.svg" height=600 >}}

---

# Finally

[it works](http://localhost:8073)

```diff
grpc
├── envoy.yaml
├── envoy.Dockerfile
├── Makefile
└── demo
    └── gen
        └── eliza
            └── v1
                └── eliza.proto
├── backend
│   └── main.go
│       └── pkg
│           └── gen
│               └── proto
│                   └── elizav1
│                       ├── eliza.pb.go
│                       └── eliza_grpc.pb.go
└── frontend
    ├ App.tsx
    └── src
        └── gen
            ├── eliza_grpc_web_pb.js
            ├── eliza_pb.d.ts
            ├── eliza_pb.js
            └── ElizaServiceClientPb.ts
```

---

```
grpcurl --plaintext localhost:8071 buf.connect.demo.eliza.v1.ElizaService/Say

```

---

# List of issues encountered

- https://github.com/grpc/grpc-web/issues/704
- https://github.com/grpc/grpc-web/issues/1242
- https://github.com/grpc/grpc-web/issues/1064
- https://github.com/protocolbuffers/protobuf-javascript/issues/105
- https://github.com/protocolbuffers/protobuf-javascript/issues/127

---


# What about buf?

---

# What about buf?

- `protoc -> buf`
- `grpc -> connect`
- ~~envoy~~
- ~~Makefile~~

---

- [buf.gen.yaml](buf.gen.yamll)
- [connect-codegen.go](connect-codegen.go)
- [App.tsx](App.tsx)

---



--- 

# What do we get?

```diff
connect
- ├── envoy.yaml
- ├── envoy.Dockerfile
- ├── Makefile
+ ├── buf.gen.yaml
└── demo
    └── gen
        └── eliza
            └── v1
                └── eliza.proto
├── backend
│   └── main.go
│            └── gen
│                └── eliza
│                    └── v1
│                       ├── eliza.pb.go
-                       └── eliza_grpc.pb.go
+                     └───── elizav1connect
+                                 └─────eliza.connect.go
└── frontend
|    ├ App.tsx
|    └── src
|          └── gen
|                └── demo
|                    └── eliza
|                        └── v1
+                          ├── eliza_connectweb.ts
+                          ├── eliza_pb.ts
-                          ├── eliza_grpc_web_pb.js
-                          ├── eliza_pb.d.ts
-                          ├── eliza_pb.js
-                          └── ElizaServiceClientPb.ts
```

---


# Where are the differences ?
```diff 
- # envoy.yaml
---
- admin:
-   access_log_path: "/tmp/admin_access.log"
-   address:
-     socket_address:
-       address: 0.0.0.0
-       port_value: 9901
- static_resources:
-   listeners:
-     - name: main-listener
-       address:
-         socket_address:
-           address: 0.0.0.0
-           port_value: 8082
-       filter_chains:
-         - filters:
-             - name: envoy.http_connection_manager
-               config:
-                 stat_prefix: ingress_http
-                 codec_type: AUTO
-                 route_config:
-                   name: local_route
-                   virtual_hosts:
-                     - name: local_service
-                       domains:
-                         - "*"
-                       routes:
-                         - match:
-                             prefix: "/buf.connect.demo.eliza.v1.ElizaService"
-                           route:
-                             cluster: ElizaService
-                             max_grpc_timeout: 0s
-                       cors:
-                         allow_origin_string_match:
-                           - prefix: "*"
-                         allow_methods: GET, PUT, DELETE, POST, OPTIONS
-                         allow_headers: keep-alive,user-agent,cache-control,content-type,content-transfer-encoding,grpc-status-details-bin,x-accept-content-transfer-encoding,x-accept-response-streaming,x-user-agent,x-grpc-web,grpc-timeout,authorization
-                         expose_headers: grpc-status-details-bin,grpc-status,grpc-message,authorization
-                         max_age: "1728000"
-                 http_filters:
-                   - name: envoy.grpc_web
-                   - name: envoy.cors
-                   - name: envoy.router

-   clusters:
-     - name: ElizaService
-       connect_timeout: 0.25s
-       type: logical_dns
-       http2_protocol_options: {}
-       lb_policy: round_robin
-       hosts:
-         - socket_address:
-             address: backend
-             port_value: 8081

```

--- 

# Where are the differences ?
```diff
- # Makefile
- proto:
- 	protoc -I./proto/ --go_out=paths=source_relative:backend/pkg/gen/proto/elizav1 eliza.proto
- 	protoc -I././proto/ --go-grpc_out=paths=source_relative:backend/pkg/gen/proto/elizav1 eliza.proto
- 	protoc -I././proto/ --js_out=import_style=commonjs:frontend/src/gen eliza.proto
- 	protoc -I././proto/ --grpc-web_out=import_style=typescript,,mode=grpcwebtext:frontend/src/gen eliza.proto
```

--- 



```go

grpcurl --plaintext localhost:8091 buf.connect.demo.eliza.v1.ElizaService/Say

curl --header 'Content-Type: application/json' --data '{"sentence": ""}' http://localhost:8091/buf.connect.demo.eliza.v1.ElizaService/Say


```

---

{{< figure src="gh.drawio.5.svg" height=600 >}}

---

# Let's delete more code

- using [buf.build/bufbuild/eliza](https://buf.build/bufbuild/eliza) instead of codegen
--- 

# What do we get?

```diff
connect
- ├── envoy.yaml
- ├── envoy.Dockerfile
- ├── Makefile
- ├── buf.gen.yaml
- └── demo
-     └── gen
-         └── eliza
-             └── v1
-                 └── eliza.proto
├── backend
│   └── main.go
- │       └── pkg
- │           └── gen
- │               └── proto
- │                   └── elizav1
- │                       ├── eliza.pb.go
- │                       └── eliza_grpc.pb.go
└── frontend
    ├ App.tsx
    └── src
-         └── gen
-             ├── eliza_grpc_web_pb.js
-             ├── eliza_pb.d.ts
-             ├── eliza_pb.js
-             └── ElizaServiceClientPb.ts
```

---

```diff

connect
  ├── backend
  │   └── main.go
  └── frontend
      └── App.tsx
```

{{< figure src="gh.drawio.6.svg" height=300 >}}

---

# Where are the differences ?

```diff
- import { ElizaServiceClient } from './gen/ElizaServiceClientPb.js'
- import { IntroduceRequest } from './gen/eliza_pb'

+ import { ElizaService } from '@buf/bufbuild_eliza.bufbuild_connect-web/buf/connect/demo/eliza/v1/eliza_connectweb.js'
+ import { IntroduceRequest } from '@buf/bufbuild_eliza.bufbuild_es/buf/connect/demo/eliza/v1/eliza_pb.js'
```

--- 

# Where are the differences ?

```diff
- "github.com/joshcarp/grpc-vs-connect/grpc-web/backend/pkg/gen/proto/elizav1"
+ "buf.build/gen/go/bufbuild/eliza/bufbuild/why-buf/buf/connect/demo/eliza/v1/elizav1connect"
+ elizav1 "buf.build/gen/go/bufbuild/eliza/protocolbuffers/go/buf/connect/demo/eliza/v1"
```

---


---
```diff

connect
  ├── backend
  │   └── main.go
  └── frontend
      └── App.tsx
```


---


```diff
                             files          blank        comment           code
-------------------------------------------------------------------------------
SUM:
 same                            4              4             22             63
 modified                        1              0              0             46
 added                           0              0              0             34
 removed                        11            348            734           1552


```


--- 


```diff
cloc --exclude-dir=node_modules --include-ext=go,js,ts,proto,yaml,Makefile --diff grpc connect

      32 text files.
classified 30 files
      19 text files.
classified 17 files
 1:        1 unique file.                          
 2:        2 unique files.                          
      34 files ignored.                           

github.com/AlDanial/cloc v 1.94  T=0.02 s (776.9 files/s, 136106.8 lines/s)
-------------------------------------------------------------------------------
Language                     files          blank        comment           code
-------------------------------------------------------------------------------
Go
 same                            0              0             16             42
 modified                        1              0              0             46
 added                           0              0              0             34
 removed                         2             92             65            629
JavaScript
 same                            1              2              1              7
 modified                        0              0              0              0
 added                           0              0              0              0
 removed                         2            157            516            490
TypeScript
 same                            3              2              5             14
 modified                        0              0              0              0
 added                           0              0              0              0
 removed                         4             88            122            340
YAML
 same                            0              0              0              0
 modified                        0              0              0              0
 added                           0              0              0              0
 removed                         2              1              0             67
Protocol Buffers
 same                            0              0              0              0
 modified                        0              0              0              0
 added                           0              0              0              0
 removed                         1             10             31             26
-------------------------------------------------------------------------------
SUM:
 same                            4              4             22             63
 modified                        1              0              0             46
 added                           0              0              0             34
 removed                        11            348            734           1552
-------------------------------------------------------------------------------
```

--- 

- No code generation needed
- No translation proxy needed
- No build scripts/Makefiles
- No using outdated tools