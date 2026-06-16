const DEFAULT_SITE_URL = "http://localhost:3000";

function normalizeSiteUrl(value?: string) {
  if (!value) {
    return DEFAULT_SITE_URL;
  }

  const trimmed = value.trim();

  if (!trimmed) {
    return DEFAULT_SITE_URL;
  }

  const withProtocol = /^https?:\/\//.test(trimmed) ? trimmed : `https://${trimmed}`;

  return withProtocol.replace(/\/$/, "");
}

const envSiteUrl =
  process.env.NEXT_PUBLIC_SITE_URL ||
  process.env.VERCEL_PROJECT_PRODUCTION_URL ||
  process.env.VERCEL_URL;

export const siteConfig = {
  name: "GEOFlow",
  description:
    "GEOFlow 帮助中国出海 AI / SaaS / B2B 软件公司，提升品牌在 AI 搜索结果中的出现率、引用率和推荐率。",
  siteUrl: normalizeSiteUrl(envSiteUrl),
  tagline: "Editorial-style AI search visibility guidance for China-to-global software teams.",
  intakeLabel: "Intake: use the free audit form",
};

export const navItems = [
  { href: "/", label: "首页" },
  { href: "/free-audit", label: "免费诊断" },
  { href: "/audit", label: "体检报告" },
  { href: "/growth-service", label: "提升服务" },
  { href: "/reports", label: "行业报告" },
  { href: "/about", label: "关于我们" },
];

export const homepagePainPoints = [
  {
    title: "搜品牌名，AI 回答不完整",
    description: "品牌有官网，但 AI 对你的产品、场景和优势理解不成体系，导致推荐时信息残缺。",
  },
  {
    title: "搜行业方案，竞品出现，你没有出现",
    description: "客户在比较方案时，AI 直接引用竞品案例或第三方内容，你的品牌没有被列入候选。",
  },
  {
    title: "官网内容很多，但 AI 不引用",
    description: "内容存在不等于能被 AI 使用。结构、实体表述、FAQ 和引用场景常常没有准备好。",
  },
  {
    title: "中文内容多，英文市场认知弱",
    description: "海外客户看到的是英文结果，但你的核心品牌信号仍然停留在中文资产里。",
  },
  {
    title: "不知道 AI 为什么推荐别人",
    description: "不知道对手是因为品牌权威、外部引用、FAQ 结构还是行业报告占了优势。",
  },
  {
    title: "不知道该先优化哪些内容资产",
    description: "功能页、博客、案例、FAQ、第三方页面、报告页都可能重要，但优先级不清晰。",
  },
];

export const serviceCapabilities = [
  {
    title: "AI 搜索曝光检测",
    description: "检查品牌在多类查询场景和多种 AI 搜索渠道中的出现情况、表述质量与稳定度。",
  },
  {
    title: "竞品引用对比",
    description: "看清客户在问同类问题时，为什么竞品先被提到，你的差距发生在哪些问题上。",
  },
  {
    title: "品牌实体与内容资产诊断",
    description: "针对官网页面、FAQ、案例、行业报告和第三方提及，找出 AI 难以理解的地方。",
  },
  {
    title: "30 天优化与复测",
    description: "围绕高优先级资产做一轮集中优化，并通过复测确认改善是否真的发生。",
  },
];

export const coreMetrics = [
  {
    label: "出现率 Mention Rate",
    value: "38%",
    delta: "+12%",
    detail: "品牌在核心查询中被 AI 提及的比例，是最基础的可见度指标。",
  },
  {
    label: "引用率 Citation Rate",
    value: "21%",
    delta: "+7%",
    detail: "AI 是否引用了你的官网、FAQ、案例或第三方页面来支撑回答。",
  },
  {
    label: "推荐率 Recommendation Rate",
    value: "14%",
    delta: "+5%",
    detail: "当用户直接问“推荐什么品牌/工具/方案”时，你被纳入答案的稳定程度。",
  },
  {
    label: "场景覆盖率 Query Coverage",
    value: "42 / 80",
    delta: "+9",
    detail: "覆盖的关键问题越多，品牌越容易在不同意图下被看到，而不是只在少数词出现。",
  },
  {
    label: "竞品差距 Competitor Gap",
    value: "-27%",
    delta: "-3%",
    detail: "你的品牌和头部竞品在同类查询中的差距，能帮助确定修复优先级。",
  },
  {
    label: "内容资产健康度",
    value: "74 / 100",
    delta: "+6",
    detail: "综合官网页面、FAQ、案例和报告的结构化程度，判断是否适合被 AI 理解和引用。",
  },
];

export const serviceSteps = [
  {
    title: "提交品牌和官网",
    description: "先收集品牌名、官网、目标市场和主要竞品，快速界定体检范围。",
  },
  {
    title: "曝光体检",
    description: "在多类问题、多种 AI 搜索工具中观察出现率、引用率、推荐率和回答结构。",
  },
  {
    title: "问题清单与建议",
    description: "输出哪些内容资产最值得优先优化，哪些表述最影响品牌被理解。",
  },
  {
    title: "30 天提升与复测",
    description: "把建议转化成内容动作，并在下一轮复测中验证是否真正提升。",
  },
];

export const reportCards = [
  {
    category: "Visibility Research",
    title: "2026 中国 AI SaaS 出海品牌在 AI 搜索中的可见度观察",
    description: "聚焦中国出海 AI SaaS 品牌在主流 AI 搜索渠道中的出现模式与典型缺口。",
  },
  {
    category: "Recommendation Logic",
    title: "ChatGPT / Perplexity 如何推荐 B2B 软件品牌",
    description: "拆解 AI 回答中常见的推荐逻辑、引用来源和场景覆盖方式。",
  },
  {
    category: "GEO Strategy",
    title: "从 SEO 到 GEO：AI 搜索曝光优化迁移指南",
    description: "帮助团队把传统 SEO 内容资产，迁移为更适合 AI 推荐和引用的结构。",
  },
];

export const auditChecks = [
  {
    title: "会检查哪些 AI 搜索渠道",
    description: "ChatGPT、Perplexity、Google AI、DeepSeek、Kimi、豆包等主流工具的回答结果与推荐逻辑。",
  },
  {
    title: "会检查哪些指标",
    description: "出现率、引用率、推荐率、场景覆盖率、竞品差距和内容资产健康度。",
  },
  {
    title: "会检查哪些资产",
    description: "官网功能页、解决方案页、FAQ、案例、行业报告和关键第三方提及来源。",
  },
  {
    title: "会给出什么输出",
    description: "问题清单、优先级建议、需要补强的品牌信号，以及适合 30 天冲刺的动作包。",
  },
];

export const growthDeliverables = [
  {
    title: "适合谁",
    description: "已经有英文官网、开始做海外获客，但在 AI 搜索里的品牌曝光仍然偏弱的团队。",
  },
  {
    title: "交付物",
    description: "问题清单、内容资产优化建议、优先修复列表、复测结论和下一轮增长建议。",
  },
  {
    title: "优化对象",
    description: "品牌实体、官网页面、第三方内容、FAQ、行业报告、Prompt 场景和关键查询入口。",
  },
];

export const growthTimeline = [
  {
    title: "Week 1 体检与优先级排序",
    description: "确认品牌信号缺失点、竞品差距和高价值查询，输出第一轮修复清单。",
  },
  {
    title: "Week 2 官网与 FAQ 修复",
    description: "优先增强品牌实体表达、场景说明、FAQ 和关键页面的 AI 可理解性。",
  },
  {
    title: "Week 3 报告与外部引用补强",
    description: "把可复用的报告、案例、第三方内容和权威信号补到更容易被引用的位置。",
  },
  {
    title: "Week 4 复测与总结",
    description: "再次验证出现率、引用率和推荐率变化，并确定下一轮继续投入的方向。",
  },
];
