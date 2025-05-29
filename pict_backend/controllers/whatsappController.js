const axios = require("axios");

exports.sendLittered = async (req, res) => {
    console.log("HITT")
    const message = req.body.message;
    const url = 'https://graph.facebook.com/v18.0/144528362069356/messages';
    const accessToken = '<YOUR_WHATSAPP_TOKEN'; // Replace with your actual Facebook access token

const data = {
  messaging_product: 'whatsapp',
  to: '919653288604',
  type: 'text',
  text: {
    body:message,
   
  },
};

const headers = {
  Authorization: `Bearer ${accessToken}`,
  'Content-Type': 'application/json',
};

axios.post(url, data, { headers })
  .then(response => {
    const message = response.data
    console.log(response.data);
    return res.status(200).json({ message });
  })
  .catch(error => {
    const message=error.response.data
    console.error(error.response.data);
    return res.status(500).json({ message: message });
  });
}