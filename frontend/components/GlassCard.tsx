'use client';

import React from 'react';
import { cn } from '../lib/utils';

interface GlassCardProps {
  children: React.ReactNode;
  className?: string;
  hover?: boolean;
  variant?: 'dark' | 'light' | 'premium';
  animation?: 'floating' | 'pulse' | 'none';
  onClick?: () => void;
}

export function GlassCard({ 
  children, 
  className = '', 
  hover = true,
  variant = 'dark',
  animation = 'none',
  onClick
}: GlassCardProps) {
  const baseClasses = cn(
    'rounded-2xl p-6 transition-all duration-500',
    {
      'glass-card': variant === 'dark',
      'glass-card-light': variant === 'light',
      'premium-card': variant === 'premium',
      'glass-card-hover cursor-pointer': hover && onClick,
      'floating-animation': animation === 'floating',
      'pulse-glow': animation === 'pulse'
    },
    className
  );

  return (
    <div className={baseClasses} onClick={onClick}>
      {children}
    </div>
  );
}

interface GlassCardHeaderProps {
  title: string;
  subtitle?: string;
  icon?: React.ReactNode;
  action?: React.ReactNode;
}

export function GlassCardHeader({ title, subtitle, icon, action }: GlassCardHeaderProps) {
  return (
    <div className="flex items-start justify-between mb-6">
      <div className="flex items-start gap-3">
        {icon && (
          <div className="p-2 rounded-lg bg-white/5 text-blue-400">
            {icon}
          </div>
        )}
        <div>
          <h3 className="text-xl font-semibold text-white">{title}</h3>
          {subtitle && (
            <p className="text-sm text-gray-400 mt-1">{subtitle}</p>
          )}
        </div>
      </div>
      {action && (
        <div>{action}</div>
      )}
    </div>
  );
}

interface GlassCardContentProps {
  children: React.ReactNode;
  className?: string;
}

export function GlassCardContent({ children, className = '' }: GlassCardContentProps) {
  return (
    <div className={cn('space-y-4', className)}>
      {children}
    </div>
  );
}

interface GlassCardFooterProps {
  children: React.ReactNode;
  className?: string;
}

export function GlassCardFooter({ children, className = '' }: GlassCardFooterProps) {
  return (
    <div className={cn('mt-6 pt-6 border-t border-white/10', className)}>
      {children}
    </div>
  );
}

// Composite export for convenience
export const Card = {
  Root: GlassCard,
  Header: GlassCardHeader,
  Content: GlassCardContent,
  Footer: GlassCardFooter
};