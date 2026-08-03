## 一、工程结构
```text
sync-images/
├── .github/
│   └── workflows/
│       ├── batch-sync.yml          # 批量同步工作流
│       └── single-sync.yml         # 单镜像同步工作流
├── images.txt                      # 批量同步镜像清单
└── pull-aliyun.sh                  # Node-0 批量拉取脚本
```
## 二、配置 GitHub Variables 和 Secrets
### Variables（非敏感信息）
在 GitHub 仓库 `Settings` → `Secrets and variables` → `Actions` → **Variables** 选项卡中添加：

| Variable 名称      | 说明                | 示例值                              |
| :----------------- | :------------------ | :---------------------------------- |
| `ALIYUN_REGISTRY`  | 阿里云 ACR 仓库地址 | `registry.cn-hangzhou.aliyuncs.com` |
| `ALIYUN_NAMESPACE` | 命名空间名称        | `my-namespace`                      |

### Secrets（敏感信息）

在 **Secrets** 选项卡中添加：

| Secret 名称       | 说明                               | 示例值          |
| :---------------- | :--------------------------------- | :-------------- |
| `ALIYUN_USERNAME` | ACR 用户名（访问凭证中的账号全名） | `your-username` |
| `ALIYUN_PASSWORD` | ACR 固定密码                       | `your-password` |

## 三、使用说明

### 3.1 单镜像同步（single-sync.yml）

1. 在 GitHub Actions 页面选择 `Single Image Sync to Aliyun ACR`
2. 点击 `Run workflow`
3. 输入公共镜像名（如 `nginx:stable-alpine`、`nacos/nacos-server:v3.2.3`、`mysql`）和 ACR 镜像名（非必需，用户指定优先）
4. 点击 `Run workflow` 执行

#### 转换示例

| 公共镜像名                                             | 用户输入 `target_image` | 最终 ACR 镜像名       |
| :----------------------------------------------------- | :---------------------- | :-------------------- |
| `container-registry.oracle.com/database/free:23.3.0.0` | `oracle:free23.3.0.0`   | `oracle:free23.3.0.0` |
| `nginx:stable-alpine`                                  | （留空）                | `nginx:stable-alpine` |
| `nginx:stable-alpine`                                  | `nginx`                 | `nginx:latest`        |
| `nacos/nacos-server:v3.2.3`                            | （留空）                | `nacos-server:v3.2.3` |
| `nacos/nacos-server:v3.2.3`                            | `nacos:v3.2.3`          | `nacos:v3.2.3`        |
| `mysql`                                                | （留空）                | `mysql:latest`        |
| `mysql`                                                | `mysql:8.0`             | `mysql:8.0`           |
| `apache/rocketmq:5.5.0`                                | （留空）                | `rocketmq:5.5.0`      |
| `apache/rocketmq:5.5.0`                                | `rocketmq:5.5.0`        | `rocketmq:5.5.0`      |

### 3.2 批量同步（batch-sync.yml）

| 触发方式          | 说明                                                         |
| :---------------- | :----------------------------------------------------------- |
| `images.txt` 变更 | 修改 `images.txt` 并 push 到 main/master 分支，自动触发批量同步 |
| 手动触发          | 在 GitHub Actions 页面选择 `Batch Sync Docker Images to Aliyun ACR`，点击 `Run workflow` |
| 定时触发          | 取消 `schedule` 注释后，每天 UTC 02:00 和 14:00 自动执行     |

#### 转换示例

| 公共镜像                 | 自动生成的 ACR 镜像名 |
| :----------------------- | :-------------------- |
| `nginx:stable-alpine`    | `nginx:stable-alpine` |
| `mysql:8.4`              | `mysql:8.4`           |
| `mongo`                  | `mongo:last`          |
| `apache/rocketmq:5.5.0`  | `rocketmq:5.5.0`      |
| `prom/prometheus:latest` | `prometheus:latest`   |

### 3.3 Node-0 拉取镜像

```bash
# 1. 将 images.txt 和 pull-aliyun.sh 复制到 node-0
scp images.txt pull-aliyun.sh node-0:/home/www/

# 2. 切换到 www 用户
sudo su - www

# 3. 赋予脚本执行权限
chmod +x pull-aliyun.sh

# 4. 执行拉取
./pull-aliyun.sh

# 或指定镜像清单文件
./pull-aliyun.sh my-images.txt

# 5. 验证结果
docker images | head -20
```

