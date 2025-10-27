/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: 'var(--color-primary)',
        'primary-dark': 'var(--color-primary-dark)',
        'primary-light': 'var(--color-primary-light)',
      },
      fontFamily: {
        sans: ['Noto Sans JP', 'Noto Sans SC', 'sans-serif'],
      },
    },
  },
  plugins: [],
}
