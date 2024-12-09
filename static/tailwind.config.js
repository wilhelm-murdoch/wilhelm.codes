/** @type {import('tailwindcss').Config} */
const plugin = require('tailwindcss/plugin')

/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "../content/*.md", 
    "../layouts/**/*.html"
  ],
  theme: {

  },
  plugins: [
    require('@tailwindcss/typography'),
    plugin(function ({addVariant}) {
      addVariant('prose-inline-code', '&.prose-xl :where(:not(pre)>code):not(:where([class~="not-prose"] *))');
    })
  ],
};
