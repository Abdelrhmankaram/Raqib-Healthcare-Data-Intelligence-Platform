import fs from 'fs/promises';
import pdfParse from 'pdf-parse';
import mammoth from 'mammoth';

export async function readFileContent(filePath, mimeType) {
    try {
        const buffer = await fs.readFile(filePath);

        if (mimeType === 'text/plain') {
            return buffer.toString('utf-8');
        } else if (mimeType === 'application/pdf') {
            const data = await pdfParse(buffer);
            return data.text;
        } else if (mimeType === 'application/vnd.openxmlformats-officedocument.wordprocessingml.document') {
            const result = await mammoth.extractRawText({ buffer });
            return result.value;
        } else {
            throw new Error('Unsupported file type');
        }
    } catch (error) {
        console.error('File processing error:', error);
        throw new Error(`Failed to process file: ${error.message}`);
    }
}