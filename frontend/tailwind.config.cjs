// Build-time only. Keep complete class names in HTML/JS, including dynamically rendered forms.
module.exports = {
  content: { relative: true, files: ['./*.html', './js/*.js'] },
  theme: {
    extend: {
      fontFamily: { sans: ['Montserrat', 'Arial', 'sans-serif'] },
      colors: { brand: { 50: '#eff6ff', 100: '#dbeafe', 400: '#60a5fa', 500: '#3b82f6', 600: '#1d4ed8', 700: '#1e3a8a' } }
    }
  },
  plugins: []
};
