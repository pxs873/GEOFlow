# GEOFlow 香港服务器部署清单

## 当前资源

- 服务器地域：中国香港
- 服务器系统：Ubuntu
- 服务器配置：2 核 CPU / 4GB 内存 / 60GB 系统盘
- 公网 IP：43.161.240.101
- 计划域名：globalentrypro.com
- 域名状态：实名认证审核中，审核通过后再做 DNS 解析

## 还差什么

1. 域名实名认证通过。
2. 域名添加 A 记录：`globalentrypro.com -> 43.161.240.101`。
3. 腾讯云轻量服务器防火墙放行 `80`、`443`、`18080`。
4. 在 Ubuntu 终端部署 GEOFlow。
5. 域名解析生效后配置免费 HTTPS。
6. 首次登录后台后修改默认管理员密码。

## 先用 IP 部署

域名审核没过也可以先部署，临时访问地址使用：

```bash
http://43.161.240.101:18080
```

进入腾讯云 OrcaTerm 终端后执行：

```bash
curl -fsSL https://raw.githubusercontent.com/yaojingang/GEOFlow/main/deploy-scripts/geoflow-docker-deploy.sh -o geoflow-docker-deploy.sh
GEOFLOW_NONINTERACTIVE=1 \
GEOFLOW_YES=1 \
GEOFLOW_APP_URL=http://43.161.240.101:18080 \
GEOFLOW_APP_DIR=/opt/geoflow \
GEOFLOW_WEB_PORT=18080 \
GEOFLOW_REVERB_PORT=18081 \
GEOFLOW_ADMIN_BASE_PATH=geo_admin \
bash geoflow-docker-deploy.sh
```

部署完成后访问：

```text
http://43.161.240.101:18080/geo_admin/login
```

默认后台账号：

```text
admin
password
```

登录后立即修改密码。

## 域名通过后改成正式地址

DNS 解析完成后，在服务器执行：

```bash
cd /opt/geoflow
sed -i 's#^APP_URL=.*#APP_URL=https://globalentrypro.com#' .env.prod
docker compose --env-file .env.prod -f docker-compose.prod.yml up -d
```

## 免费 SSL

SSL 不需要购买。域名解析到服务器并生效后，用 Caddy 或 Nginx + Certbot 配免费 Let’s Encrypt 证书。

推荐最终访问地址：

```text
https://globalentrypro.com
https://globalentrypro.com/geo_admin/login
```
