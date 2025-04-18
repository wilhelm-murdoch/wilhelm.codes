/** @type {import('tailwindcss').Config} */
const plugin = require("tailwindcss/plugin");

/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["../content/*.md", "../layouts/**/*.html"],
  safelist: [
    {
      pattern:
        /(text|bg|border-b|border)-(purple|blue|green|emerald|indigo|pink|orange|rose|red|yellow|slate)-(50|100|200|300|400|500|600|700|800)/,
    },
  ],
  theme: {},
  plugins: [
    require("@tailwindcss/typography"),
    plugin(function ({ addVariant }) {
      addVariant(
        "prose-inline-code",
        '&.prose-xl :where(:not(pre)>code):not(:where([class~="not-prose"] *))',
      );
      addVariant("not-last", "&:not(:last-child)");
    }),
  ],
};
