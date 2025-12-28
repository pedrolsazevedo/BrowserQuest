module.exports = {
    testEnvironment: 'node',
    testMatch: ['**/__tests__/**/*.test.js'],
    collectCoverageFrom: ['server/js/**/*.js', '!server/js/**/__tests__/**', '!server/js/lib/**'],
    coverageDirectory: 'coverage',
    verbose: true,
};
