<?php

namespace Tests\Feature;

use App\Models\Admin;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\View;
use RuntimeException;
use Tests\TestCase;

class AdminDashboardFallbackTest extends TestCase
{
    use RefreshDatabase;

    public function test_dashboard_returns_fallback_page_when_dashboard_view_rendering_fails(): void
    {
        $admin = Admin::query()->create([
            'username' => 'dashboard_fallback_admin',
            'password' => 'secret-123',
            'email' => 'dashboard-fallback@example.com',
            'display_name' => 'Dashboard Fallback Admin',
            'role' => 'super_admin',
            'status' => 'active',
        ]);

        View::composer('admin.dashboard', static function (): void {
            throw new RuntimeException('dashboard view failed');
        });

        $adminBase = '/'.trim((string) config('geoflow.admin_base_path', '/geo_admin'), '/');

        $this->actingAs($admin, 'admin')
            ->get(route('admin.dashboard'))
            ->assertOk()
            ->assertHeader('Content-Type', 'text/html; charset=UTF-8')
            ->assertSee('后台保底页')
            ->assertSee('仪表盘统计暂时打不开，但系统还能继续用')
            ->assertSee($adminBase.'/tasks', false)
            ->assertSee($adminBase.'/articles', false)
            ->assertSee($adminBase.'/ai-models', false)
            ->assertSee($adminBase.'/materials', false);
    }
}
