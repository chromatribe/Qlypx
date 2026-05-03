const express = require('express');
const bodyParser = require('body-parser');
const axios = require('axios');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 3000;

app.use(bodyParser.json());

// Discord/Slack Webhook URL from environment variables
const WEBHOOK_URL = process.env.WEBHOOK_URL;

app.post('/report', async (req, res) => {
    const { bundleId, version, os, content, timestamp } = req.body;

    console.log(`[${timestamp}] Received report from ${bundleId} v${version} (${os})`);

    if (WEBHOOK_URL) {
        try {
            // Forwarding to Discord/Slack
            const message = `🚨 *New Qlypx Diagnostic Report*\n*Version:* ${version}\n*OS:* ${os}\n*Timestamp:* ${timestamp}\n\n\`\`\`\n${content.substring(0, 1500)}\n\`\`\``;
            await axios.post(WEBHOOK_URL, {
                text: message,      // For Slack
                content: message    // For Discord
            });
            console.log('Successfully forwarded to Webhook');
        } catch (error) {
            console.error('Failed to forward to Webhook:', error.message);
        }
    }

    res.status(200).json({ status: 'ok' });
});

app.get('/', (req, res) => {
    res.send('Qlypx Diagnostic Server is running.');
});

app.listen(port, () => {
    console.log(`Diagnostic server listening at http://localhost:${port}`);
});
