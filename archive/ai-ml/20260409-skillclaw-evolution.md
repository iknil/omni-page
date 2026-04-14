# Let Skills Evolve Collectively with Agentic Evolver

## 元数据

| 字段 | 值 |
|------|-----|
| 原始标题 | Let Skills Evolve Collectively with Agentic Evolver |
| 中文副标题 | SkillClaw：通过 Agentic Evolver 实现技能的集体进化 |
| 原始链接 | https://arxiv.org/abs/2604.08377 |
| 原始发表日期 | 2026-04-09 |
| PDF 归档 | ../assets/20260409-skillclaw-evolution.pdf |
| 标签 | AI Agent、LLM、持续学习、Skill Evolution |
| 分类 | ai-ml |

## 核心内容摘要

LLM agent（如 OpenClaw）依赖可复用的 skill 来完成复杂任务，但这些 skill 在部署后基本是静止的。结果是：相似的工作流、工具用法模式、失败模式在不同用户之间被反复"重新发现"，系统无法从经验中改进。虽然不同用户的交互提供了互补的信号——揭示 skill 何时成功、何时失败——但现有系统缺乏将这种异质经验转化为可靠 skill 更新的机制。

本文提出 **SkillClaw**，一个多用户 agent 生态下的集体 skill 进化框架，其核心思想是将跨用户、随时间累积的交互作为改进 skill 的主要信号。SkillClaw 持续聚合使用过程中产生的轨迹（trajectories），并用自主进化的 Evolver 来处理：识别重复出现的行为模式，将其转化为 skill 更新——既可以精化已有 skill，也可以扩展新能力。更新后的 skill 维护在共享仓库并同步给所有用户，使得在一个上下文中发现的改进能够系统性地传播，同时无需用户付出额外努力。

## 关键要点

1. **问题根源**：现有 LLM agent 的 skill 是静态的，跨用户的失败经验和成功实践无法积累成系统改进
2. **核心解法**：将多用户交互轨迹作为进化信号，通过自主 Evolver 识别行为模式并转化为 skill 更新
3. **集体进化机制**：Evolver 持续聚合轨迹 → 识别模式 → 精化或扩展 skill → 同步到共享仓库 → 全局传播
4. **跨用户知识迁移**：一处发现，全局受益，无需用户额外操作
5. **实验验证**：在 WildClawBench 上，仅凭有限交互和反馈，显著提升了 Qwen3-Max 在真实 agent 场景中的表现
6. **定位**：与 self-improving skill 方向直接相关，解决的是"单用户局部经验→全局 skill 进化"的问题

## 我的思考与感悟

SkillClaw 描述的"多用户轨迹聚合→自动识别模式→skill 更新"闭环，与我们在 self-improving agent 中尝试做的事情在方向上一致。它更强调跨用户层面的经验共享，而 self-improving 更偏个体层面。两者的结合点可能在于：

- 个体层面的 self-improvement 产生的经验，能否通过类似 SkillClaw 的共享机制惠及其他用户？
- Evolver 的实现细节（如何从轨迹中识别值得进化的模式）是关键，这需要进一步阅读论文正文

## 返回导航

← [../README.md](../README.md)
