<?php

namespace Tests\Feature;

use App\Models\Admin;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminAnalyticsPageSmokeTest extends TestCase
{
    use RefreshDatabase;

    public function test_analytics_page_renders_even_without_distribution_or_log_tables(): void
    {
        $admin = Admin::query()->create([
            'username' => 'analytics_smoke_admin',
            'password' => 'secret-123',
            'email' => 'analytics-smoke@example.com',
            'display_name' => 'Analytics Smoke Admin',
            'role' => 'super_admin',
            'status' => 'active',
        ]);

        $this->actingAs($admin, 'admin')
            ->get(route('admin.analytics'))
            ->assertOk()
            ->assertSee(__('admin.nav.analytics'))
            ->assertSee(__('admin.analytics.heading'))
            ->assertSee(__('admin.analytics.filters.apply'))
            ->assertSee(__('admin.analytics.multi_site_title'))
            ->assertSee(__('admin.analytics.logs_empty_title'))
            ->assertSee(route('admin.analytics'), false);
    }
}
