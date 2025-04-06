const https = require('https');
const url = require('url');

exports.handler = async (event) => {
    console.log('Received event:', JSON.stringify(event, null, 2));

    const webhookUrl = process.env.WEBHOOK_URL;
    if (!webhookUrl) {
        throw new Error('WEBHOOK_URL environment variable is not set');
    }

    // Extract relevant information from the GuardDuty finding
    const finding = event.detail;
    const message = {
        type: finding.type,
        severity: finding.severity,
        title: finding.title,
        description: finding.description,
        resourceType: finding.resource.resourceType,
        resourceDetails: finding.resource.resourceDetails,
        accountId: finding.accountId,
        region: finding.region,
        eventTime: finding.eventTime
    };

    // Send to webhook
    try {
        await sendToWebhook(webhookUrl, message);
        return {
            statusCode: 200,
            body: JSON.stringify({ message: 'Successfully sent finding to webhook' })
        };
    } catch (error) {
        console.error('Error sending to webhook:', error);
        throw error;
    }
};

function sendToWebhook(webhookUrl, message) {
    return new Promise((resolve, reject) => {
        const parsedUrl = url.parse(webhookUrl);
        const options = {
            hostname: parsedUrl.hostname,
            path: parsedUrl.path,
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            }
        };

        const req = https.request(options, (res) => {
            let body = '';
            res.on('data', chunk => body += chunk);
            res.on('end', () => {
                if (res.statusCode >= 200 && res.statusCode < 300) {
                    resolve(body);
                } else {
                    reject(new Error(`Webhook request failed with status ${res.statusCode}: ${body}`));
                }
            });
        });

        req.on('error', (error) => {
            reject(error);
        });

        req.write(JSON.stringify(message));
        req.end();
    });
} 