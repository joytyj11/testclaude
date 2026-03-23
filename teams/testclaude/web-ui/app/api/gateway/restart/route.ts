import { NextResponse } from 'next/server';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

export async function POST() {
  try {
    // 重启 OpenClaw Gateway
    await execAsync('openclaw gateway restart 2>&1');
    
    return NextResponse.json({ success: true });
  } catch (error: any) {
    console.error('Gateway restart failed:', error);
    return NextResponse.json(
      { success: false, error: error.message },
      { status: 500 }
    );
  }
}
