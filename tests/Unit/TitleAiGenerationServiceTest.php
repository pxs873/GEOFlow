<?php

namespace Tests\Unit;

use App\Ai\Agents\MarkdownContentWriterAgent;
use App\Models\AiModel;
use App\Services\GeoFlow\TitleAiGenerationService;
use App\Support\GeoFlow\ApiKeyCrypto;
use Tests\TestCase;

class TitleAiGenerationServiceTest extends TestCase
{
    public function test_it_uses_chat_completions_driver_for_third_party_compatible_title_generation(): void
    {
        config()->set('geoflow.api_key_crypto_roots', ['test-app-key']);

        MarkdownContentWriterAgent::fake([
            "标题一\n标题二",
        ]);

        $apiKeyCrypto = app(ApiKeyCrypto::class);

        $model = new AiModel;
        $model->forceFill([
            'name' => 'Proxy Model',
            'api_url' => 'https://proxy.example.com/v1',
            'model_id' => 'gpt-4.1-mini',
            'api_key' => $apiKeyCrypto->encrypt('sk-test'),
            'status' => 'active',
        ]);
        $model->syncOriginal();

        $result = app(TitleAiGenerationService::class)->generateTitles(
            $model,
            ['GEOFlow'],
            2,
            'professional'
        );

        $this->assertSame(['标题一', '标题二'], $result['titles']);
        $this->assertFalse($result['fallback_used']);
        $this->assertNull($result['fallback_reason']);

        MarkdownContentWriterAgent::assertPrompted(function ($prompt): bool {
            return $prompt->model === 'gpt-4.1-mini'
                && $prompt->provider->driver() === 'deepseek'
                && ($prompt->provider->additionalConfiguration()['url'] ?? null) === 'https://proxy.example.com/v1';
        });
    }
}
