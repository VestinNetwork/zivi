"use strict";
process.on('SIGTERM', () => {
    console.log('SIGTERM signal received.');
    process.exit(0);
});
process.on('uncaughtException', (err) => {
    console.error('Uncaught Exception:', err);
});
process.on('unhandledRejection', (reason) => {
    console.error('Unhandled Rejection:', reason);
});
