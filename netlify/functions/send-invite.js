const { Resend } = require('resend');

const resend = new Resend(process.env.RESEND_API_KEY);
const SITE_URL = process.env.SITE_URL || 'https://auditsaas.netlify.app';

exports.handler = async (event) => {
  if (event.httpMethod !== 'POST') {
    return { statusCode: 405, body: 'Method not allowed' };
  }

  try {
    const { email, role, orgName, inviterName } = JSON.parse(event.body);

    if (!email || !orgName) {
      return { statusCode: 400, body: JSON.stringify({ error: 'Missing required fields' }) };
    }

    const signUpUrl = `${SITE_URL}/pages/login.html?invite=${encodeURIComponent(email)}`;
    const roleName = (role || 'preparer').charAt(0).toUpperCase() + (role || 'preparer').slice(1);

    const { data, error } = await resend.emails.send({
      from: 'Axiom <noreply@conferix.com>',
      to: email,
      subject: `You've been invited to ${orgName} on Axiom`,
      html: `
        <div style="font-family: 'Inter', -apple-system, sans-serif; max-width: 520px; margin: 0 auto; padding: 32px 0;">
          <div style="background: #0A1A2F; padding: 24px 28px; border-radius: 12px 12px 0 0;">
            <h1 style="color: white; margin: 0; font-size: 22px; font-weight: 700;">Axiom</h1>
          </div>
          <div style="background: white; border: 1px solid #e5e7eb; border-top: none; padding: 28px; border-radius: 0 0 12px 12px;">
            <p style="font-size: 15px; color: #374151; line-height: 1.6; margin: 0 0 16px;">
              ${inviterName ? `<strong>${inviterName}</strong> has` : 'You have been'} invited you to join <strong>${orgName}</strong> on Axiom as a <strong>${roleName}</strong>.
            </p>
            <p style="font-size: 14px; color: #6b7280; line-height: 1.6; margin: 0 0 24px;">
              Axiom is an audit workpaper and workflow platform. Click below to create your account and join the team.
            </p>
            <a href="${signUpUrl}" style="display: inline-block; background: #3A7BFF; color: white; padding: 12px 28px; border-radius: 8px; text-decoration: none; font-weight: 600; font-size: 14px;">
              Join ${orgName}
            </a>
            <p style="font-size: 12px; color: #9ca3af; margin: 24px 0 0; line-height: 1.5;">
              If the button doesn't work, copy this link:<br>
              <a href="${signUpUrl}" style="color: #3A7BFF; word-break: break-all;">${signUpUrl}</a>
            </p>
          </div>
          <p style="font-size: 11px; color: #9ca3af; text-align: center; margin-top: 16px;">
            Axiom Audit Platform
          </p>
        </div>
      `
    });

    if (error) {
      console.error('Resend error:', error);
      return { statusCode: 500, body: JSON.stringify({ error: error.message }) };
    }

    return { statusCode: 200, body: JSON.stringify({ success: true, id: data.id }) };

  } catch (err) {
    console.error('Function error:', err);
    return { statusCode: 500, body: JSON.stringify({ error: err.message }) };
  }
};
