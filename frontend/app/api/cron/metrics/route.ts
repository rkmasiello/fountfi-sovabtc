import { NextRequest, NextResponse } from 'next/server';
import { headers } from 'next/headers';
import { prisma } from '@/lib/prisma';
import { BlockchainService } from '@/lib/services/blockchainService';

export const runtime = 'nodejs';
export const maxDuration = 60; // 60 seconds max

export async function GET(request: NextRequest) {
  try {
    // Verify the request is from Vercel Cron
    const authHeader = headers().get('authorization');
    if (process.env.NODE_ENV === 'production' && authHeader !== `Bearer ${process.env.CRON_SECRET}`) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }
    
    console.log('[Cron] Starting metrics collection...');
    
    // Get all active deployments
    const deployments = await prisma.sovaBtcDeployment.findMany({
      where: { status: 'ACTIVE' },
      include: { network: true },
    });
    
    console.log(`[Cron] Found ${deployments.length} active deployments`);
    
    const blockchainService = new BlockchainService(prisma);
    const results = [];
    
    for (const deployment of deployments) {
      try {
        console.log(`[Cron] Collecting metrics for ${deployment.network.name}`);
        await blockchainService.fetchRealMetrics(deployment.chainId, deployment.id);
        
        results.push({
          chainId: deployment.chainId,
          network: deployment.network.name,
          status: 'success',
        });
        
        // Log activity
        await prisma.sovaBtcActivity.create({
          data: {
            type: 'METRICS_COLLECTED',
            description: `Metrics collected for ${deployment.network.name}`,
            metadata: {
              chainId: deployment.chainId,
              deploymentId: deployment.id,
              source: 'vercel-cron',
            },
            timestamp: new Date(),
          },
        });
      } catch (error) {
        console.error(`[Cron] Error collecting metrics for ${deployment.network.name}:`, error);
        results.push({
          chainId: deployment.chainId,
          network: deployment.network.name,
          status: 'error',
          error: error instanceof Error ? error.message : 'Unknown error',
        });
      }
    }
    
    return NextResponse.json({
      success: true,
      timestamp: new Date().toISOString(),
      deployments: results.length,
      results,
    });
  } catch (error) {
    console.error('[Cron] Metrics collection failed:', error);
    return NextResponse.json({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
    }, { status: 500 });
  }
}