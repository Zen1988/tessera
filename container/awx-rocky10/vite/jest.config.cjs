const { jest: existing } = require('./package.json');

module.exports = {
  resetMocks: true,
  ...existing,
  roots: ['<rootDir>/src'],
  testEnvironment: 'jsdom',
  setupFilesAfterEnv: ['<rootDir>/src/setupTests.js'],
  modulePaths: ['<rootDir>/src'],
  moduleNameMapper: {
    '\\.(css|scss|sass)$': '<rootDir>/testUtils/tao-style-stub.cjs',
    '\\.(svg|png|jpe?g|gif|woff2?|ttf|ico)$': '<rootDir>/testUtils/tao-asset-stub.cjs',
  },
  transform: {
    '^.+\\.[cm]?jsx?$': ['babel-jest', {
      babelrc: false,
      configFile: false,
      presets: [['@babel/preset-env', { targets: { node: 'current' } }], '@babel/preset-react'],
      plugins: ['babel-plugin-macros'],
    }],
  },
  transformIgnorePatterns: [
    '/node_modules/(?!(?:d3[^/]*|internmap|delaunator|robust-predicates|has-ansi|ansi-regex)/)',
  ],
};
