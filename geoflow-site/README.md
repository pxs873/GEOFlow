# GEOFlow 官网

`geoflow-site` 是 GEOFlow 的独立中文官网项目，用于承接中国出海 AI / SaaS / B2B 软件公司的线索收集与品牌教育。

品牌定位：

> GEOFlow 帮助客户检测并提升品牌在 AI 搜索结果中的出现率、引用率和推荐率。

## 当前范围

第一版以静态官网和表单转化为主，已覆盖这些页面：

- `/` 首页
- `/free-audit` 免费诊断页
- `/audit` AI 搜索曝光体检报告页
- `/growth-service` 30 天提升服务页
- `/reports` 行业报告页
- `/about` 关于我们页
- `/robots.txt`
- `/sitemap.xml`

## 技术栈

- Next.js 16
- React 19
- TypeScript
- Tailwind CSS v4

## 本地开发

安装依赖后运行：

```bash
npm install
npm run dev
```

本地预览地址默认是 [http://localhost:3000](http://localhost:3000)。

如需在本地验证生产构建：

```bash
npm run lint
npm run build
```

## 环境变量

项目提供了 [.env.example](./.env.example) 作为示例。

需要关注的变量只有两个：

| 变量名 | 用途 | 是否必填 |
| --- | --- | --- |
| `NEXT_PUBLIC_SITE_URL` | 官网正式域名。用于 `metadataBase`、Open Graph、`robots.txt`、`sitemap.xml`。 | 生产环境建议必填 |
| `NEXT_PUBLIC_FORMSPREE_ENDPOINT` | Formspree 表单提交地址，用于 `/free-audit` 页面表单。 | 可选 |

说明：

- 本地开发时，如果没有配置 `NEXT_PUBLIC_SITE_URL`，项目会回退到 `http://localhost:3000`。
- 如果部署在 Vercel 且没有手动配置 `NEXT_PUBLIC_SITE_URL`，项目会优先读取 Vercel 提供的站点地址变量作为兜底。
- 如果没有配置 `NEXT_PUBLIC_FORMSPREE_ENDPOINT`，免费诊断表单会保留前端占位提交逻辑，不会真正发送数据。

## Formspree 接入

第一版官网默认支持 Formspree，接入步骤如下：

1. 在 Formspree 创建表单并拿到 endpoint，例如 `https://formspree.io/f/xxxxxx`。
2. 在本地 `.env.local` 和 Vercel 项目环境变量中设置 `NEXT_PUBLIC_FORMSPREE_ENDPOINT`。
3. 重新部署后，到 `/free-audit` 提交一次测试数据，确认收件箱能收到线索。

如果暂时没有 Formspree endpoint，也可以先继续做页面联调，表单会保持占位模式。

## Vercel 部署建议

建议按这个顺序上线：

1. 将 `geoflow-site` 部署到 Vercel。
2. 在 Vercel 项目里配置：
   - `NEXT_PUBLIC_SITE_URL`
   - `NEXT_PUBLIC_FORMSPREE_ENDPOINT`
3. 绑定正式域名。
4. 上线后检查：
   - 首页是否正常打开
   - `/free-audit` 表单是否能提交
   - `/robots.txt` 和 `/sitemap.xml` 是否引用了正式域名

## 目录说明

```text
src/app              页面与 metadata
src/components       头部、表单、卡片等复用组件
src/lib/site.ts      站点配置、导航、页面内容数据
public/              静态资源
```

## 交付边界

这个项目当前不是 Laravel CMS 的一部分，也不负责后台报告生成。它的职责是：

- 清晰表达 GEOFlow 的价值主张
- 承接免费诊断线索
- 为后续 Vercel 正式上线做好前端准备
