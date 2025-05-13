import express from 'express';
import cors from 'cors';
import fetch from 'node-fetch';
import { jsonrepair } from 'jsonrepair';

const app = express();
app.use(cors());
app.use(express.json());

const OPENROUTER_API_KEY = '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';
const OPENROUTER_URL = 'https://openrouter.ai/api/v1/chat/completions';

// Helper to build the prompt
function buildPrompt({ jobTitle, company, requiredSkills, detailedRequirements, mode }) {
  const baseInfo = `
Job Title: ${jobTitle}
Company: ${company}
Required Skills: ${requiredSkills.join(', ')}
Detailed Requirements: ${detailedRequirements}
`;

  if (mode === 'cover_letter') {
    return `
${baseInfo}

You MUST return only valid JSON. DO NOT include any text, labels, or markdown formatting. Just return raw JSON, starting and ending with curly braces {}.

Format:
{
  "coverLetter": "the cover letter text"
}
`;
  } else if (mode === 'courses') {
    return `
${baseInfo}

Suggest maximum 3 online courses (with links) that would help a candidate prepare for this internship.

You MUST return only valid JSON. DO NOT include any explanation, text, labels, or markdown formatting. Just return raw JSON, starting and ending with curly braces {}.

Format:
{
  "recommendedCourses": [
    {"name": "Course Name", "url": "https://..."},
    {"name": "Course Name", "url": "https://..."},
    {"name": "Course Name", "url": "https://..."}
  ]
}
If a course URL is unknown, use an empty string.
`;
  } else if (mode === 'questions') {
    return `
${baseInfo}

List 5-7 problem solving or technical interview questions for this internship.

You MUST return only valid JSON. DO NOT include any text, labels, or markdown formatting. Just return raw JSON, starting and ending with curly braces {}.

Format:
{
  "questions": [
    "Question 1?",
    "Question 2?",
    "Question 3?"
  ]
}
`;
  }

  // Default to cover letter if mode is unrecognized
  return `
${baseInfo}

You MUST return only valid JSON. DO NOT include any text, labels, or markdown formatting. Just return raw JSON, starting and ending with curly braces {}.

Format:
{
  "coverLetter": "the cover letter text"
}
`;
}

// Helper to clean AI response
function extractJson(text) {
  // Remove markdown/code block formatting and extraneous labels
  let cleaned = text
    .replace(/^[\s\S]*?```json/i, '')   // Remove leading markdown block
    .replace(/```[\s\S]*$/i, '')        // Remove trailing ```
    .replace(/\*\*.*?\*\*/g, '');     // Remove bolded labels like **Response:**

  // Find the first { and the last }
  const firstBrace = cleaned.indexOf('{');
  const lastBrace = cleaned.lastIndexOf('}');
  if (firstBrace !== -1 && lastBrace !== -1 && lastBrace > firstBrace) {
    cleaned = cleaned.substring(firstBrace, lastBrace + 1);
  }
  return cleaned.trim();
}

app.post('/generate', async (req, res) => {
  console.log('Received /generate request:', req.body);
  try {
    const { jobTitle, company, requiredSkills, detailedRequirements, mode } = req.body;
    const prompt = buildPrompt({ jobTitle, company, requiredSkills, detailedRequirements, mode });

    console.log('Prompt:', prompt);

    const response = await fetch(OPENROUTER_URL, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${OPENROUTER_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'deepseek/deepseek-chat-v3-0324:free',
        messages: [
          {
            role: 'system',
            content: 'You are a helpful AI assistant that returns only valid JSON as instructed.'
          },
          {
            role: 'user',
            content: prompt
          }
        ],
        temperature: 0.7,
        max_tokens: 1000
      })
    });

    const data = await response.json();
    console.log('AI raw response:', data);

    const aiMessage = data.choices?.[0]?.message?.content;
    console.log('AI Message:', aiMessage);

    if (!aiMessage) {
      console.log('No aiMessage found!');
      return res.status(500).json({
        error: 'AI response missing or malformed',
        fullResponse: data
      });
    }

    const cleaned = extractJson(aiMessage);
    console.log('Cleaned:', cleaned);

    try {
      const parsed = JSON.parse(cleaned);
      console.log('Parsed JSON:', parsed);
      res.json(parsed);
    } catch (e) {
      console.log('Initial JSON.parse failed:', e);
      // Try to repair the JSON and parse again
      try {
        const repaired = jsonrepair(cleaned);
        console.log('Repaired:', repaired);
        const parsed = JSON.parse(repaired);
        res.json(parsed);
      } catch (repairErr) {
        console.log('Repair failed:', repairErr);
        res.status(500).send(`
  <pre>
  Error: Failed to parse AI response

  aiMessage:
  ${aiMessage}

  cleaned:
  ${cleaned}

  repairError:
  ${repairErr.toString()}
  </pre>
`);
      }
    }

  } catch (err) {
    console.log('Outer catch error:', err);
    res.status(500).json({ error: err.toString() });
  }
});

const PORT = 3000;
app.listen(PORT, () => {
  console.log(`🚀 Backend running at http://localhost:${PORT}`);
});