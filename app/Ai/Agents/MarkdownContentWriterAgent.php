<?php

namespace App\Ai\Agents;

use App\Jobs\ProcessGeoFlowTaskJob;
use Laravel\Ai\Attributes\Timeout;
use Laravel\Ai\Contracts\Agent;
use Laravel\Ai\Contracts\Conversational;
use Laravel\Ai\Promptable;

/**
 * 纯文本生成专用 Agent：通过 {@see Timeout} 配置 HTTP 超时（秒）。
 *
 * 须小于 {@see ProcessGeoFlowTaskJob::$timeout}，避免队列作业尚未结束而 HTTP 已先超时。
 */
#[Timeout(240)]
class MarkdownContentWriterAgent implements Agent, Conversational
{
    use Promptable;

    /**
     * @param  iterable<int, mixed>  $messages
     */
    public function __construct(
        public string $instructions = '你是专业中文写作助手，请输出高质量、可发布的 Markdown 文章。',
        public iterable $messages = [],
    ) {}

    /**
     * {@inheritdoc}
     */
    public function instructions(): string
    {
        return $this->instructions;
    }

    /**
     * {@inheritdoc}
     */
    public function messages(): iterable
    {
        return $this->messages;
    }
}
