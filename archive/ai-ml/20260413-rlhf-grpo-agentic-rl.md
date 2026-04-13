# Post-training Core Technologies Explained: From SFT to RLHF, GRPO, and Agentic RL

> 副标题：LLM 后训练技术栈全景梳理

| | |
|---|---|
| **原始标题** | 后训练核心技术详解：从 SFT 到 RLHF、GRPO、再到 Agentic RL |
| **原始链接** | https://qingkeai.online/archives/RLHF-GRPO-AgenticRL |
| **原始发表日期** | 2026-04-13 |
| **归档日期** | 2026-04-13 |
| **分类** | [AI & 机器学习](../../archive/ai-ml/README.md) |
| **标签** | `LLM` `Reinforcement Learning` `Post-training` `RLHF` `GRPO` `Agentic RL` |

## 核心内容摘要

本文系统梳理了 LLM Post-training 的完整技术栈，从 SFT 基础出发，一路演进到 RLHF、GRPO、DPO 等偏好优化方法，最终延伸至 DeepSeek-R1 的纯 RL 推理能力激发与 Agentic RL 的多轮工具使用场景。

开篇明确 Post-training 在 LLM 训练流程中的位置——位于预训练之后，主要目的不是灌输新知识，而是让模型学会"怎么回答"，包括格式、风格、长度控制等。SFT（监督微调）在此阶段承担基础对齐任务。

RLHF 是偏好对齐的经典范式，通过 Reward Model 评估回答质量，再用 PPO 算法优化策略模型。但 PPO 计算开销大、训练不稳定。GRPO（Group Relative Policy Optimization）用同 Group 内回答的相对比较替代显式 Critic，大幅简化了流程。RLVR 则在可验证领域（如数学、代码）用规则奖励替代 Reward Model。

DPO 及其变体（SimPO、ORPO、KTO）走的是另一条路：不做 RL，直接通过偏好数据用分类或排序目标优化模型。DeepSeek-R1 证明了纯 RL 也能训练出强推理模型，其 R1-Zero 版本在训练过程中涌现出"Aha Moment"——模型自发展现出自我反思行为。

后续章节介绍了 GRPO 的工程改进（DAPO、Dr.GRPO）、Reward Model 从过程奖励（PRM）到生成式奖励模型的演进，以及 Synthetic Data 范式（生成-验证-训练闭环）的兴起。Agentic RL 部分则标志着从单轮问答到多轮工具调用、长期规划的能力跃迁。

## 关键要点

- **SFT 不灌输知识，只塑造行为**：Post-training 阶段的核心目标是教会模型"怎么回答"，而非学习新事实。格式遵循、风格一致性、长度控制都依赖 SFT。
- **RLHF 通过 Reward Model + PPO 实现偏好对齐**：Reward Model 先行训练，PPO 在 Reward 信号下优化策略。优势是泛化强，劣势是训练复杂、算力开销大。
- **GRPO 用 Group 内相对比较替代 Critic**：去掉单独训练的 Critic，以同批生成的回答之间的相对优劣作为信号，简化了流程并保留了大部分效果。
- **RLVR 在可验证领域用规则替代 Reward Model**：数学证明、代码执行结果等可直接验证的领域，用确定性规则奖励替代学习出来的 Reward Model，效率更高。
- **DeepSeek-R1-Zero 证明了纯 RL 的推理能力突破**：不经过 SFT 直接上 RL，模型不仅没有崩溃，还涌现出自我反思（Aha Moment）等高级推理行为，颠覆了"必须先 SFT 再 RL"的经验。
- **Agentic RL 标志着从"回答问题"到"使用工具完成复杂任务"的范式转移**：多轮交互、工具调用、长期规划能力成为新的优化目标，Reward 设计也从结果奖励扩展到过程奖励。

## 术语翻译

- **Post-training**：后训练
- **Supervised Fine-Tuning (SFT)**：监督微调
- **Reinforcement Learning from Human Feedback (RLHF)**：基于人类反馈的强化学习
- **Reward Model (RM)**：奖励模型
- **Proximal Policy Optimization (PPO)**：近端策略优化
- **Group Relative Policy Optimization (GRPO)**：组相对策略优化
- **RL with Verifiable Rewards (RLVR)**：基于可验证奖励的强化学习
- **Direct Preference Optimization (DPO)**：直接偏好优化
- **Process Reward Model (PRM)**：过程奖励模型
- **Synthetic Data**：合成数据

## 我的思考与感悟

这篇文章把后训练这条线从 SFT 到 Agentic RL 串得很清楚。几点感受：

第一，RLHF → GRPO → RLVR 的演进逻辑很清晰——都是在解决 PPO 太重的问题，核心思路是"能不用学习出来的 Critic/奖励就不用了，用结构化的相对比较或规则替代"。这和 LLM 推理阶段"SLM 替代复杂采样"的路子是一致的。

第二，DeepSeek-R1-Zero 的 Aha Moment 很值得关注——这说明推理能力可能不是"教"出来的，而是"给对信号就能涌现"的。这对训练 pipeline 设计有根本性影响：也许更重要的不是堆 SFT 数据，而是设计好 RL 的奖励结构。

第三，Agentic RL 把 post-training 的边界往外推了一层——不只是对齐问答，而是对齐"使用工具、规划行动"的能力。奖励设计会更难，但也更有意思。

---

*[← 返回分类](README.md) · [← 返回首页](../../README.md)*
