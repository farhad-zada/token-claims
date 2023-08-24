const nodemailer = require('nodemailer')

module.exports = async (to, subject, text) => {
  const transporter = nodemailer.createTransport({
    service: 'Gmail',
    auth: {
      user: process.env.GMAIL_ADDRESS,
      pass: process.env.GMAIL_APP_PASS,
    },
  })

  const mailOptions = {
    from: 'panworldist@gmail.com',
    to: to,
    subject: subject,
    html: text,
  }
  const info = await transporter.sendMail(mailOptions)
  return info
}
