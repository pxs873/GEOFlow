# GEOFlow 官网部署前状态

日期：2026-06-17

## 当前结论

- `geoflow-site` 已锁版。
- 设计方向和页面结构不再改。
- 当前只处理部署前事项，不再继续大范围移动端细调，也不提前做报告内容页。

## 代码状态

- 独立 Next.js 官网保留在 `geoflow-site/`
- `/free-audit` 已接入 Formspree 提交代码路径
- 已补 `/thank-you` 成功页
- `npm run lint` 已通过
- `npm run build` 已通过

## 仍未完成的 3 件事

### 1. 生产环境变量

上线前需要配置：

```env
NEXT_PUBLIC_SITE_URL=https://<正式域名>
NEXT_PUBLIC_FORMSPREE_ENDPOINT=https://formspree.io/f/<form-id>
```

说明：

- `NEXT_PUBLIC_SITE_URL` 用于 `metadataBase`、Open Graph、`robots.txt`、`sitemap.xml`
- `NEXT_PUBLIC_FORMSPREE_ENDPOINT` 用于 `/free-audit` 真实提交

### 2. 部署权限

当前仓库状态：

- 远程仓库：`yaojingang/GEOFlow`
- 当前账号：`pxs873`
- GitHub `viewerPermission`：`READ`

结论：

- 目前不能直接把官网改动 push 到原仓库
- 当前账号下也还没有 `pxs873/GEOFlow` fork

推荐路径：

1. 新建或 fork 一个可写仓库
2. 把当前官网收口改动 push 到可写仓库
3. 在 Vercel 导入该仓库，并把 Root Directory 设为 `geoflow-site`

### 3. 线上 Formspree 实测

上线后需要验证：

1. `/free-audit` 是否真实提交成功
2. 提交后是否跳转到 `/thank-you`
3. Formspree 后台是否收到数据

## 当前阻塞

- 还没有真实的 `NEXT_PUBLIC_FORMSPREE_ENDPOINT`
- 还没有正式域名值可写入 `NEXT_PUBLIC_SITE_URL`
- 原仓库没有写权限
- 本机没有 `vercel` CLI

## 推荐下一步

优先顺序：

1. 确定正式域名
2. 创建 Formspree 表单并拿到 endpoint
3. 选择可写部署路径
   - 要么让原仓库开写权限
   - 要么直接 fork / 新建可写仓库
4. 接入 Vercel
5. 上线后做一次真实表单提交
