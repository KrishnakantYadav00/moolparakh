/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        navy: '#17324D',
        'navy-deep': '#10283D',
        teal: '#0F8B8D',
        'teal-mid': '#3AA3A4',
        'teal-soft': '#E8F5F4',
        canvas: '#F6F8FA',
        surface: '#FFFFFF',
        hairline: '#DCE3E8',
        ink: '#1F2933',
        muted: '#687681',
        risk: {
          critical: '#B3261E',
          'critical-bg': '#FBEAE8',
          high: '#B35309',
          'high-bg': '#FDF0E4',
          medium: '#8A6100',
          'medium-bg': '#FBF3DF',
          low: '#687681',
          'low-bg': '#EEF1F4',
          good: '#136F5B',
          'good-bg': '#E4F2ED',
        },
      },
      fontFamily: {
        sans: [
          'Inter',
          'ui-sans-serif',
          'system-ui',
          '-apple-system',
          'BlinkMacSystemFont',
          '"Segoe UI"',
          'sans-serif',
        ],
      },
      fontSize: {
        '2xs': ['11px', { lineHeight: '15px' }],
        xs: ['12px', { lineHeight: '17px' }],
        sm: ['13px', { lineHeight: '19px' }],
        base: ['14px', { lineHeight: '21px' }],
        md: ['16px', { lineHeight: '24px' }],
        lg: ['18px', { lineHeight: '26px' }],
        xl: ['20px', { lineHeight: '28px' }],
        '2xl': ['24px', { lineHeight: '31px' }],
        '3xl': ['28px', { lineHeight: '34px' }],
        '4xl': ['34px', { lineHeight: '38px' }],
        '5xl': ['40px', { lineHeight: '44px' }],
      },
      boxShadow: {
        card: '0 1px 2px rgba(16, 40, 61, 0.04)',
        raised: '0 6px 20px rgba(16, 40, 61, 0.10)',
        panel: '-12px 0 32px rgba(16, 40, 61, 0.12)',
      },
      borderRadius: {
        card: '10px',
      },
      keyframes: {
        fadeIn: { from: { opacity: '0' }, to: { opacity: '1' } },
        scaleIn: {
          from: { opacity: '0', transform: 'translateY(6px) scale(0.99)' },
          to: { opacity: '1', transform: 'translateY(0) scale(1)' },
        },
        slideInRight: {
          from: { transform: 'translateX(24px)', opacity: '0' },
          to: { transform: 'translateX(0)', opacity: '1' },
        },
        shimmer: {
          '0%': { backgroundPosition: '-320px 0' },
          '100%': { backgroundPosition: '320px 0' },
        },
      },
      animation: {
        fadeIn: 'fadeIn 160ms ease-out',
        scaleIn: 'scaleIn 180ms cubic-bezier(0.2, 0.7, 0.3, 1)',
        slideInRight: 'slideInRight 200ms cubic-bezier(0.2, 0.7, 0.3, 1)',
        shimmer: 'shimmer 1.4s linear infinite',
      },
    },
  },
  plugins: [],
};
