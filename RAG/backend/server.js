require('dotenv').config();
const express = require('express');
const multer = require('multer');
const cors = require('cors');
const ragService = require('./ragService');

const app = express();
app.use(cors());
app.use(express.json());

const upload = multer({ dest: 'uploads/' });

app.post('/upload', upload.single('file'), async (req, res) => {
  try {
    const filePath = req.file.path;
    await ragService.indexDocument(filePath);
    res.json({ message: 'Document indexed successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/chat', async (req, res) => {
  try {
    const { question } = req.body;
    const result = await ragService.answerQuestion(question);
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.listen(3001, () => console.log('Server running on port 3001'));